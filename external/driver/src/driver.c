//
// KoffeeMem -- minimal memory-transport kernel driver.
//
// Single responsibility: attach to a target process (Roblox), copy bytes in
// and out of its address space, expose via IOCTLs. No features here.
//
// Read/write path: PsLookupProcessByProcessId -> KeStackAttachProcess ->
// RtlCopyMemory (probed under __try/__except). Runs from the target's own
// thread context so we don't leave working-set fingerprints Hyperion's
// Deleter2 pool detection would flag on foreign threads.
//
// Per-handle state (attached PID) is kept via IRP_MJ_CREATE FsContext, so
// each userland handle can target a different PID if we ever need it. Today
// there's exactly one: RobloxPlayerBeta.exe.
//

#include <ntddk.h>
#include "ioctl.h"

// -- forward decls --------------------------------------------------------

DRIVER_INITIALIZE DriverEntry;
DRIVER_UNLOAD    KfmUnload;
DRIVER_DISPATCH  KfmCreateClose;
DRIVER_DISPATCH  KfmDeviceControl;

// PsLookupProcessByProcessId is declared in ntddk.h.

// PsGetProcessPeb isn't in the public WDK headers -- prototype it ourselves so
// the linker resolves it out of ntoskrnl.exe. Works from Vista onward.
NTKERNELAPI PVOID NTAPI PsGetProcessPeb(_In_ PEPROCESS Process);

// Minimal LDR structures for the PEB walk. Layout is stable across NT versions
// for the fields we actually touch (In*ModuleList links, DllBase, SizeOfImage,
// BaseDllName). We only read; no packing hazards.
typedef struct _KFM_PEB_LDR_DATA {
    ULONG  Length;
    UCHAR  Initialized;
    PVOID  SsHandle;
    LIST_ENTRY InLoadOrderModuleList;
    LIST_ENTRY InMemoryOrderModuleList;
    LIST_ENTRY InInitializationOrderModuleList;
} KFM_PEB_LDR_DATA, *PKFM_PEB_LDR_DATA;

typedef struct _KFM_PEB {
    UCHAR  InheritedAddressSpace;
    UCHAR  ReadImageFileExecOptions;
    UCHAR  BeingDebugged;
    UCHAR  BitField;
    PVOID  Mutant;
    PVOID  ImageBaseAddress;
    PKFM_PEB_LDR_DATA Ldr;
    // ... more fields; we only need Ldr.
} KFM_PEB, *PKFM_PEB;

typedef struct _KFM_UNICODE_STRING {
    USHORT Length;
    USHORT MaximumLength;
    PWSTR  Buffer;
} KFM_UNICODE_STRING, *PKFM_UNICODE_STRING;

typedef struct _KFM_LDR_DATA_TABLE_ENTRY {
    LIST_ENTRY InLoadOrderLinks;
    LIST_ENTRY InMemoryOrderLinks;
    LIST_ENTRY InInitializationOrderLinks;
    PVOID      DllBase;
    PVOID      EntryPoint;
    ULONG      SizeOfImage;
    KFM_UNICODE_STRING FullDllName;
    KFM_UNICODE_STRING BaseDllName;
    // ... more fields.
} KFM_LDR_DATA_TABLE_ENTRY, *PKFM_LDR_DATA_TABLE_ENTRY;

// -- device names ---------------------------------------------------------

#define KFM_DEVICE_NAME  L"\\Device\\KoffeeMem"
#define KFM_SYMLINK_NAME L"\\??\\KoffeeMem"

// -- per-handle context ---------------------------------------------------

typedef struct _KFM_HCTX {
    HANDLE targetPid;
} KFM_HCTX, *PKFM_HCTX;

// -- helpers --------------------------------------------------------------

static NTSTATUS KfmCompleteIrp(_In_ PIRP Irp, _In_ NTSTATUS Status, _In_ ULONG_PTR Info) {
    Irp->IoStatus.Status = Status;
    Irp->IoStatus.Information = Info;
    IoCompleteRequest(Irp, IO_NO_INCREMENT);
    return Status;
}

// safe cross-process copy via KeStackAttachProcess. src/dst semantics:
//   direction == 0 -> read  (target -> local)   src = targetAddr, dst = local buf
//   direction == 1 -> write (local -> target)   src = local buf,  dst = targetAddr
// Runs inside the target's address space between attach/detach; __try/__except
// converts a bad address into STATUS_ACCESS_VIOLATION instead of a bug-check.
static NTSTATUS KfmCopy(_In_ HANDLE Pid, _In_ ULONG_PTR TargetAddr, _Inout_ PVOID Local,
                       _In_ ULONG Size, _In_ ULONG Direction)
{
    PEPROCESS proc = NULL;
    NTSTATUS  st   = PsLookupProcessByProcessId(Pid, &proc);
    if (!NT_SUCCESS(st)) return st;

    KAPC_STATE apc;
    KeStackAttachProcess(proc, &apc);

    __try {
        if (Direction == 0) {
            // read: target -> local
            ProbeForRead((PVOID)TargetAddr, Size, 1);
            RtlCopyMemory(Local, (PVOID)TargetAddr, Size);
        } else {
            // write: local -> target
            ProbeForWrite((PVOID)TargetAddr, Size, 1);
            RtlCopyMemory((PVOID)TargetAddr, Local, Size);
        }
    } __except(EXCEPTION_EXECUTE_HANDLER) {
        st = GetExceptionCode();
    }

    KeUnstackDetachProcess(&apc);
    ObDereferenceObject(proc);
    return st;
}

// Case-insensitive ASCII vs UNICODE compare. We only ever compare against the
// last path component (BaseDllName in the LDR entry), so no path splitting.
// Returns TRUE when the two strings are equal, casefolded ASCII-A..Z only
// (module names on Windows are all ASCII in practice).
static BOOLEAN KfmEqIA(_In_ PCSTR Ascii, _In_ PCWCH Wide, _In_ SIZE_T WideChars) {
    SIZE_T i;
    for (i = 0; i < WideChars; i++) {
        UCHAR a = (UCHAR)Ascii[i];
        WCHAR w = Wide[i];
        if (a == 0) return FALSE;                          // ASCII ran out early
        if (w > 0x7F) return FALSE;                        // non-ASCII in module name
        if (a >= 'a' && a <= 'z') a = (UCHAR)(a - 32);     // fold
        if (w >= L'a' && w <= L'z') w = (WCHAR)(w - 32);
        if ((WCHAR)a != w) return FALSE;
    }
    return (Ascii[i] == 0);                                // ASCII exhausted too = match
}

// PEB walk (target's LDR module list) -> return base + size for the named
// module. Case-insensitive ASCII match against BaseDllName. MUST be called from
// inside a KeStackAttachProcess block (PEB pointers are target-VA and only
// valid while we own that address space). SEH-wrapped: a torn PEB from an
// exiting process becomes STATUS_ACCESS_VIOLATION instead of a bug-check.
static NTSTATUS KfmFindModule(_In_ PEPROCESS Proc, _In_ PCSTR Name,
                              _Out_ PULONG64 Base, _Out_ PULONG64 Size)
{
    *Base = 0;
    *Size = 0;

    PKFM_PEB peb = (PKFM_PEB)PsGetProcessPeb(Proc);
    if (!peb) return STATUS_NOT_FOUND;

    NTSTATUS st = STATUS_NOT_FOUND;
    __try {
        PKFM_PEB_LDR_DATA ldr = peb->Ldr;
        if (!ldr) __leave;

        // Cap the walk so a corrupted list can't spin us forever. 4096 loaded
        // modules is well above any real process (Roblox loads ~200).
        PLIST_ENTRY head = &ldr->InLoadOrderModuleList;
        PLIST_ENTRY cur  = head->Flink;
        for (ULONG i = 0; i < 4096 && cur && cur != head; i++) {
            PKFM_LDR_DATA_TABLE_ENTRY e = CONTAINING_RECORD(
                cur, KFM_LDR_DATA_TABLE_ENTRY, InLoadOrderLinks);

            SIZE_T wideChars = (SIZE_T)(e->BaseDllName.Length / sizeof(WCHAR));
            if (e->BaseDllName.Buffer && wideChars > 0
                && KfmEqIA(Name, e->BaseDllName.Buffer, wideChars)) {
                *Base = (ULONG64)(ULONG_PTR)e->DllBase;
                *Size = (ULONG64)e->SizeOfImage;
                st    = STATUS_SUCCESS;
                __leave;
            }
            cur = cur->Flink;
        }
    } __except(EXCEPTION_EXECUTE_HANDLER) {
        st = GetExceptionCode();
    }
    return st;
}

// -- dispatch: create / close --------------------------------------------

NTSTATUS KfmCreateClose(_In_ PDEVICE_OBJECT Device, _In_ PIRP Irp) {
    UNREFERENCED_PARAMETER(Device);

    PIO_STACK_LOCATION sp = IoGetCurrentIrpStackLocation(Irp);
    if (sp->MajorFunction == IRP_MJ_CREATE) {
        PKFM_HCTX ctx = (PKFM_HCTX)ExAllocatePool2(POOL_FLAG_NON_PAGED, sizeof(KFM_HCTX), 'mfKt');
        if (!ctx) return KfmCompleteIrp(Irp, STATUS_INSUFFICIENT_RESOURCES, 0);
        ctx->targetPid = NULL;
        sp->FileObject->FsContext = ctx;
    } else if (sp->MajorFunction == IRP_MJ_CLOSE) {
        PKFM_HCTX ctx = (PKFM_HCTX)sp->FileObject->FsContext;
        if (ctx) {
            ExFreePool(ctx);
            sp->FileObject->FsContext = NULL;
        }
    }
    return KfmCompleteIrp(Irp, STATUS_SUCCESS, 0);
}

// -- dispatch: device control (the IOCTL handlers) -----------------------

NTSTATUS KfmDeviceControl(_In_ PDEVICE_OBJECT Device, _In_ PIRP Irp) {
    UNREFERENCED_PARAMETER(Device);

    PIO_STACK_LOCATION sp   = IoGetCurrentIrpStackLocation(Irp);
    PKFM_HCTX          ctx  = (PKFM_HCTX)sp->FileObject->FsContext;
    ULONG              code = sp->Parameters.DeviceIoControl.IoControlCode;
    ULONG              inLen  = sp->Parameters.DeviceIoControl.InputBufferLength;
    ULONG              outLen = sp->Parameters.DeviceIoControl.OutputBufferLength;
    PVOID              buf    = Irp->AssociatedIrp.SystemBuffer;

    NTSTATUS  st   = STATUS_INVALID_DEVICE_REQUEST;
    ULONG_PTR info = 0;

    if (!ctx) return KfmCompleteIrp(Irp, STATUS_INVALID_HANDLE, 0);

    switch (code) {
        case IOCTL_KFM_ATTACH: {
            if (inLen < sizeof(KFM_ATTACH_IN)) { st = STATUS_BUFFER_TOO_SMALL; break; }
            PKFM_ATTACH_IN in = (PKFM_ATTACH_IN)buf;
            ctx->targetPid = (HANDLE)(ULONG_PTR)in->pid;
            st = STATUS_SUCCESS;
            break;
        }
        case IOCTL_KFM_READ: {
            if (inLen < sizeof(KFM_READ_IN)) { st = STATUS_BUFFER_TOO_SMALL; break; }
            if (!ctx->targetPid) { st = STATUS_INVALID_HANDLE; break; }
            PKFM_READ_IN in = (PKFM_READ_IN)buf;
            if (in->size == 0 || in->size > outLen) { st = STATUS_BUFFER_TOO_SMALL; break; }
            st = KfmCopy(ctx->targetPid, (ULONG_PTR)in->addr, buf, in->size, 0);
            if (NT_SUCCESS(st)) info = in->size;
            break;
        }
        case IOCTL_KFM_WRITE: {
            if (inLen < sizeof(KFM_WRITE_IN)) { st = STATUS_BUFFER_TOO_SMALL; break; }
            if (!ctx->targetPid) { st = STATUS_INVALID_HANDLE; break; }
            PKFM_WRITE_IN in = (PKFM_WRITE_IN)buf;
            if (in->size == 0 || (ULONG)(sizeof(KFM_WRITE_IN) + in->size) > inLen) {
                st = STATUS_BUFFER_TOO_SMALL; break;
            }
            PVOID payload = (PUCHAR)buf + sizeof(KFM_WRITE_IN);
            st = KfmCopy(ctx->targetPid, (ULONG_PTR)in->addr, payload, in->size, 1);
            break;
        }
        case IOCTL_KFM_MODULE_BASE: {
            if (inLen < sizeof(KFM_MODULE_IN)) { st = STATUS_BUFFER_TOO_SMALL; break; }
            if (outLen < sizeof(KFM_MODULE_OUT)) { st = STATUS_BUFFER_TOO_SMALL; break; }
            if (!ctx->targetPid) { st = STATUS_INVALID_HANDLE; break; }

            PKFM_MODULE_IN  in  = (PKFM_MODULE_IN)buf;
            PKFM_MODULE_OUT out = (PKFM_MODULE_OUT)buf;

            // guarantee NUL termination on the name.
            CHAR name[65];
            RtlCopyMemory(name, in->name, 64);
            name[64] = 0;

            PEPROCESS proc = NULL;
            st = PsLookupProcessByProcessId(ctx->targetPid, &proc);
            if (!NT_SUCCESS(st)) break;

            KAPC_STATE apc;
            KeStackAttachProcess(proc, &apc);
            ULONG64 b = 0, s = 0;
            NTSTATUS fnd = KfmFindModule(proc, name, &b, &s);
            KeUnstackDetachProcess(&apc);
            ObDereferenceObject(proc);

            if (NT_SUCCESS(fnd)) {
                out->base = b;
                out->size = s;
                info = sizeof(KFM_MODULE_OUT);
                st = STATUS_SUCCESS;
            } else {
                st = fnd;
            }
            break;
        }
        default:
            st = STATUS_INVALID_DEVICE_REQUEST;
    }

    return KfmCompleteIrp(Irp, st, info);
}

// -- unload ---------------------------------------------------------------

VOID KfmUnload(_In_ PDRIVER_OBJECT Driver) {
    UNICODE_STRING symlink;
    RtlInitUnicodeString(&symlink, KFM_SYMLINK_NAME);
    IoDeleteSymbolicLink(&symlink);
    if (Driver->DeviceObject) IoDeleteDevice(Driver->DeviceObject);
}

// -- entry ----------------------------------------------------------------

NTSTATUS DriverEntry(_In_ PDRIVER_OBJECT Driver, _In_ PUNICODE_STRING RegPath) {
    UNREFERENCED_PARAMETER(RegPath);

    UNICODE_STRING devName, symName;
    RtlInitUnicodeString(&devName, KFM_DEVICE_NAME);
    RtlInitUnicodeString(&symName, KFM_SYMLINK_NAME);

    PDEVICE_OBJECT devObj = NULL;
    NTSTATUS st = IoCreateDevice(Driver, 0, &devName, FILE_DEVICE_UNKNOWN, 0, FALSE, &devObj);
    if (!NT_SUCCESS(st)) return st;

    st = IoCreateSymbolicLink(&symName, &devName);
    if (!NT_SUCCESS(st)) {
        IoDeleteDevice(devObj);
        return st;
    }

    Driver->MajorFunction[IRP_MJ_CREATE]         = KfmCreateClose;
    Driver->MajorFunction[IRP_MJ_CLOSE]          = KfmCreateClose;
    Driver->MajorFunction[IRP_MJ_DEVICE_CONTROL] = KfmDeviceControl;
    Driver->DriverUnload                         = KfmUnload;

    devObj->Flags |= DO_BUFFERED_IO;
    devObj->Flags &= ~DO_DEVICE_INITIALIZING;

    DbgPrint("[KoffeeMem] loaded, device = %wZ\n", &devName);
    return STATUS_SUCCESS;
}
