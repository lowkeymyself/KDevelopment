//
// KoffeeMem -- minimal memory-transport kernel driver.
//
// Single responsibility: attach to a target process (Roblox), copy bytes in
// and out of its address space, expose via IOCTLs. No features here.
//
// Read/write path: MmCopyVirtualMemory (the exported primitive userland
// ReadProcessMemory/WriteProcessMemory ride on) with the target as one end
// and the current process as the other; the buffered SystemBuffer is kernel
// space and global. The MM layer walks the target VADs under its own locks,
// so on teardown (target process dying mid-ioctl) it returns
// STATUS_PARTIAL_COPY instead of faulting. No raw attach, no SEH, no .pdata
// dependence -- a fault on a torn VA is impossible by construction.
//
// Soak evidence: the previous raw attach copy (KeStackAttachProcess +
// RtlCopyMemory, no SEH registration possible in a manually-mapped module)
// was proven to bugcheck 0x1E when the target died mid-ioctl -- 080826-8937
// shows the faulting IP inside the mapped pool reading the target's .data
// VA (7ff62abe1020). The MmCopy path removes the entire class.
//
// Per-handle state (attached PID) is kept via IRP_MJ_CREATE FsContext, so
// each userland handle can target a different PID if we ever need it.
//

// ntifs.h is a superset of ntddk.h: PsLookupProcessByProcessId lives there.
#include <ntifs.h>
#include <ntddk.h>
#include "ioctl.h"

// Kernel headers don't define the user-mode process VM access rights.
#ifndef PROCESS_VM_READ
#define PROCESS_VM_READ  0x0010u
#define PROCESS_VM_WRITE 0x0020u
#endif

// -- forward decls --------------------------------------------------------

DRIVER_INITIALIZE DriverEntry;
DRIVER_UNLOAD    KfmUnload;
DRIVER_DISPATCH  KfmCreateClose;
DRIVER_DISPATCH  KfmDeviceControl;

// PsGetProcessPeb isn't in the public WDK headers -- prototype it ourselves so
// the linker resolves it out of ntoskrnl.exe. Works from Vista onward.
NTKERNELAPI PVOID NTAPI PsGetProcessPeb(_In_ PEPROCESS Process);

// -- minimal LDR/PEB structs (read-only, offsets stable) ------------------

typedef struct _KFM_PEB_LDR_DATA {
    ULONG  Length;
    UCHAR  Initialized;
    PVOID  SsHandle;
    LIST_ENTRY InLoadOrderModuleList;
    LIST_ENTRY InMemoryOrderModuleList;
    LIST_ENTRY InInitializationOrderModuleList;
} KFM_PEB_LDR_DATA, *PKFM_PEB_LDR_DATA;

typedef struct _KFM_PEB {
    UCHAR  Reserved[0x18];
    PVOID  Ldr;                     // at 0x18: PKFM_PEB_LDR_DATA
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

// MmCopyVirtualMemory -- exported, documented; the exact primitive
// ReadProcessMemory/WriteProcessMemory ride on. Walks the target VADs under
// MM locks, so a torn process returns STATUS_PARTIAL_COPY instead of faulting.
NTKERNELAPI NTSTATUS NTAPI MmCopyVirtualMemory(
    _In_  PEPROCESS FromProcess,
    _In_  PVOID     FromAddress,
    _In_  PEPROCESS ToProcess,
    _In_  PVOID     ToAddress,
    _In_  SIZE_T    BufferSize,
    _In_  KPROCESSOR_MODE PreviousMode,
    _Out_ PSIZE_T    NumberOfBytesCopied);

// Copy `Size` bytes between the target process (at TargetAddr) and the caller
// (Local = the buffered SystemBuffer, kernel VA). Direction:
//   0 == target -> caller         1 == caller -> target
// Safe path: MmCopyVirtualMemory with the target as From/To and the current
// process as the other end (the kernel SystemBuffer is global). Teardown of
// the target returns an error status; this driver never touches a raw VA.
static NTSTATUS KfmCopy(_In_ PEPROCESS Proc, _In_ PVOID TargetAddr, _Inout_ PVOID Local,
                        _In_ ULONG Size, _In_ ULONG Direction)
{
    if (Size == 0) return STATUS_SUCCESS;
    if (TargetAddr == NULL) return STATUS_INVALID_PARAMETER;

    SIZE_T done = 0;
    NTSTATUS st = (Direction == 0)
        ? MmCopyVirtualMemory(Proc, TargetAddr, PsGetCurrentProcess(), Local, Size, KernelMode, &done)
        : MmCopyVirtualMemory(PsGetCurrentProcess(), Local, Proc, TargetAddr, Size, KernelMode, &done);
    return st;
}

// Case-insensitive ASCII vs UNICODE compare (fold ASCII..Z only).
static BOOLEAN KfmEqIA(_In_ PCSTR Ascii, _In_ PCWCH Wide, _In_ SIZE_T WideChars) {
    SIZE_T i;
    for (i = 0; i < WideChars; i++) {
        UCHAR a = (UCHAR)Ascii[i];
        WCHAR w = Wide[i];
        if (a == 0) return FALSE;
        if (w > 0x7F) return FALSE;
        if (a >= 'a' && a <= 'z') a = (UCHAR)(a - 32);
        if (w >= L'a' && w <= L'z') w = (WCHAR)(w - 32);
        if ((WCHAR)a != w) return FALSE;
    }
    return (Ascii[i] == 0);
}

// PEB-based module lookup, entirely via direct attached copies (KfmCopy).
// Caps the walk at 4096 entries.
static NTSTATUS KfmFindModule(_In_ PEPROCESS Proc, _In_ PCSTR Name,
                              _Out_ PULONG64 Base, _Out_ PULONG64 Size)
{
    *Base = 0; *Size = 0;

    KFM_PEB peb;
    NTSTATUS st = KfmCopy(Proc, (PVOID)PsGetProcessPeb(Proc), &peb, sizeof(KFM_PEB), 0);
    if (!NT_SUCCESS(st)) return st;
    PVOID ldrVa = peb.Ldr;
    if (!ldrVa) return STATUS_NOT_FOUND;

    KFM_PEB_LDR_DATA ldrLocal;
    st = KfmCopy(Proc, ldrVa, &ldrLocal, sizeof(KFM_PEB_LDR_DATA), 0);
    if (!NT_SUCCESS(st)) return st;

    PLIST_ENTRY head = &ldrLocal.InLoadOrderModuleList;
    PLIST_ENTRY cur  = head->Flink;
    for (ULONG i = 0; i < 4096 && cur && cur != head; i++) {
        KFM_LDR_DATA_TABLE_ENTRY ent;
        st = KfmCopy(Proc,
                     (PVOID)((ULONG_PTR)cur - FIELD_OFFSET(KFM_LDR_DATA_TABLE_ENTRY, InLoadOrderLinks)),
                     &ent, sizeof(KFM_LDR_DATA_TABLE_ENTRY), 0);
        if (!NT_SUCCESS(st)) return st;

        SIZE_T wideChars = (SIZE_T)(ent.BaseDllName.Length / sizeof(WCHAR));
        if (ent.BaseDllName.Buffer && wideChars > 0) {
            WCHAR nameBuf[128];
            if (wideChars > 128) wideChars = 128;
            st = KfmCopy(Proc, ent.BaseDllName.Buffer, nameBuf, (ULONG)(wideChars * sizeof(WCHAR)), 0);
            if (!NT_SUCCESS(st)) return st;
            if (KfmEqIA(Name, nameBuf, wideChars)) {
                *Base = (ULONG64)(ULONG_PTR)ent.DllBase;
                *Size = (ULONG64)ent.SizeOfImage;
                return STATUS_SUCCESS;
            }
        }
        cur = ent.InLoadOrderLinks.Flink;
    }
    return STATUS_NOT_FOUND;
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

#define KFM_MAX_IO (0x100000u)  // 1 MiB per ioctl; the demo never needs more.

NTSTATUS KfmDeviceControl(_In_ PDEVICE_OBJECT Device, _In_ PIRP Irp) {
    UNREFERENCED_PARAMETER(Device);

    PIO_STACK_LOCATION sl = IoGetCurrentIrpStackLocation(Irp);
    PKFM_HCTX          ctx = (PKFM_HCTX)sl->FileObject->FsContext;
    ULONG              code = sl->Parameters.DeviceIoControl.IoControlCode;
    ULONG              inLen = sl->Parameters.DeviceIoControl.InputBufferLength;
    ULONG              outLen = sl->Parameters.DeviceIoControl.OutputBufferLength;
    PVOID              buf = Irp->AssociatedIrp.SystemBuffer;

    NTSTATUS st = STATUS_INVALID_DEVICE_REQUEST;
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
            if (in->size == 0 || in->size > outLen || in->size > KFM_MAX_IO) {
                st = STATUS_BUFFER_TOO_SMALL; break;
            }
            ULONG rdSize = in->size;
            ULONG_PTR rdAddr = (ULONG_PTR)in->addr;

            PEPROCESS proc = NULL;
            st = PsLookupProcessByProcessId(ctx->targetPid, &proc);
            if (!NT_SUCCESS(st)) break;

            st = KfmCopy(proc, (PVOID)rdAddr, buf, rdSize, 0);
            ObDereferenceObject(proc);
            if (NT_SUCCESS(st)) info = rdSize;
            break;
        }
        case IOCTL_KFM_WRITE: {
            if (inLen < sizeof(KFM_WRITE_IN)) { st = STATUS_BUFFER_TOO_SMALL; break; }
            if (!ctx->targetPid) { st = STATUS_INVALID_HANDLE; break; }
            PKFM_WRITE_IN in = (PKFM_WRITE_IN)buf;
            if (in->size == 0 || in->size > KFM_MAX_IO) { st = STATUS_BUFFER_TOO_SMALL; break; }
            if ((ULONG_PTR)sizeof(KFM_WRITE_IN) + in->size > (ULONG_PTR)inLen) {
                st = STATUS_BUFFER_TOO_SMALL; break;
            }
            PVOID payload = (PUCHAR)buf + sizeof(KFM_WRITE_IN);

            PEPROCESS proc = NULL;
            st = PsLookupProcessByProcessId(ctx->targetPid, &proc);
            if (!NT_SUCCESS(st)) break;

            st = KfmCopy(proc, (PVOID)(ULONG_PTR)in->addr, payload, in->size, 1);
            ObDereferenceObject(proc);
            break;
        }
        case IOCTL_KFM_MODULE_BASE: {
            if (inLen < sizeof(KFM_MODULE_IN)) { st = STATUS_BUFFER_TOO_SMALL; break; }
            if (outLen < sizeof(KFM_MODULE_OUT)) { st = STATUS_BUFFER_TOO_SMALL; break; }
            if (!ctx->targetPid) { st = STATUS_INVALID_HANDLE; break; }

            PKFM_MODULE_IN  in  = (PKFM_MODULE_IN)buf;
            PKFM_MODULE_OUT out = (PKFM_MODULE_OUT)buf;

            CHAR name[65];
            RtlCopyMemory(name, in->name, 64);
            name[64] = 0;

            PEPROCESS proc = NULL;
            st = PsLookupProcessByProcessId(ctx->targetPid, &proc);
            if (!NT_SUCCESS(st)) break;

            ULONG64 b = 0, s = 0;
            NTSTATUS fnd = KfmFindModule(proc, name, &b, &s);
            ObDereferenceObject(proc);

            if (NT_SUCCESS(fnd)) {
                out->base = b;
                out->size = s;
                info = sizeof(KFM_MODULE_OUT);
                st = STATUS_SUCCESS;
            } else {
                st = (fnd == STATUS_NOT_FOUND) ? STATUS_NOT_FOUND : fnd;
            }
            break;
        }
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

// Real init body -- runs with a REAL DriverObject (IoCreateDriver path).
static NTSTATUS KfmRealEntry(_In_ PDRIVER_OBJECT Driver, _In_opt_ PUNICODE_STRING RegPath) {
    UNREFERENCED_PARAMETER(RegPath);

    UNICODE_STRING devName, symName;
    RtlInitUnicodeString(&devName, KFM_DEVICE_NAME);
    RtlInitUnicodeString(&symName, KFM_SYMLINK_NAME);

    PDEVICE_OBJECT devObj = NULL;
    NTSTATUS st = IoCreateDevice(Driver, 0, &devName, FILE_DEVICE_UNKNOWN, 0, FALSE, &devObj);
    if (!NT_SUCCESS(st)) return st;

    // Symlink creation is non-fatal: the BYOVD path may lack the session
    // namespace; the caller creates a DOS alias via DefineDosDeviceW.
    IoCreateSymbolicLink(&symName, &devName);

    Driver->MajorFunction[IRP_MJ_CREATE]         = KfmCreateClose;
    Driver->MajorFunction[IRP_MJ_CLOSE]          = KfmCreateClose;
    Driver->MajorFunction[IRP_MJ_DEVICE_CONTROL] = KfmDeviceControl;
    Driver->DriverUnload                         = KfmUnload;

    devObj->Flags |= DO_BUFFERED_IO;
    devObj->Flags &= ~DO_DEVICE_INITIALIZING;
    return STATUS_SUCCESS;
}

// IoCreateDriver isn't in the public WDK headers -- prototype it out of
// ntoskrnl. Used by the BYOVD path to synthesize a proper DriverObject.
NTSTATUS IoCreateDriver(_In_opt_ PUNICODE_STRING DriverName,
                        _In_     PDRIVER_INITIALIZE InitializationFunction);

// deprecated-but-exported ExQueueWorkItem: the only safe way to reach
// IoCreateDriver from the NtAddAtom SYSCALL-redirect context.
typedef VOID (*PWORKER_THREAD_ROUTINE)(PVOID Parameter);

NTKERNELAPI VOID NTAPI ExQueueWorkItem(
    _Inout_ struct _WORK_QUEUE_ITEM *WorkItem,
    _In_    WORK_QUEUE_TYPE          QueueType);

static NTSTATUS NTAPI KfmMappedInit(_In_ PDRIVER_OBJECT Driver, _In_ PUNICODE_STRING RegPath) {
    return KfmRealEntry(Driver, RegPath);
}

static VOID NTAPI KfmByovdWorker(_In_ PVOID Context) {
    UNICODE_STRING drvName;
    RtlInitUnicodeString(&drvName, L"\\Driver\\KoffeeMem");
    NTSTATUS st = IoCreateDriver(&drvName, KfmMappedInit);
    UNREFERENCED_PARAMETER(st);
    ExFreePool(Context);   // Context == the WORK_QUEUE_ITEM we allocated
}

// DUAL-MODE ENTRY.
//   sc create/start   -> Windows calls us with (Driver != NULL).
//   BYOVD (mapper)    -> mapper calls us with (NULL, NULL) after copy to pool.
NTSTATUS DriverEntry(_In_opt_ PDRIVER_OBJECT Driver, _In_opt_ PUNICODE_STRING RegPath) {
    if (Driver != NULL) {
        return KfmRealEntry(Driver, RegPath);
    }

    // BYOVD path: allocate + queue a work item (lives in NonPagedPool; stays
    // valid across the carrier unload that follows immediately).
    PWORK_QUEUE_ITEM item = (PWORK_QUEUE_ITEM)ExAllocatePool2(
        POOL_FLAG_NON_PAGED, sizeof(WORK_QUEUE_ITEM), 'wfKK');
    if (item == NULL) return STATUS_INSUFFICIENT_RESOURCES;

    ExInitializeWorkItem(item, KfmByovdWorker, item);
    ExQueueWorkItem(item, DelayedWorkQueue);
    return STATUS_SUCCESS;
}
