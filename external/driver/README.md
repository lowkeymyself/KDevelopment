# Koffee Memory Driver

Minimal Windows kernel-mode driver. Attaches to a target process (Roblox) and exposes read/write of its address space via IOCTLs to userland. Nothing more.

## Design

Single responsibility: memory transport. No features live here. Every game-logic decision lives in the Rust userland (`../user/`) so we can iterate features without touching kernel code.

Exposes device `\Device\KoffeeMem` (symlink `\??\KoffeeMem` -> user opens as `\\.\KoffeeMem`) with four IOCTLs:

| IOCTL                    | Purpose                                                            |
|--------------------------|--------------------------------------------------------------------|
| `IOCTL_KFM_ATTACH`       | Bind driver to a target PID (sets per-handle context)              |
| `IOCTL_KFM_READ`         | Copy N bytes from target's address space into userland output buf  |
| `IOCTL_KFM_WRITE`        | Copy N bytes from userland input buf into target's address space   |
| `IOCTL_KFM_MODULE_BASE`  | Walk target's PEB LDR list, return base+size of a named module     |

IOCTL codes + struct layouts are shared with Rust in `src/ioctl.h` (mirrored by `../user/src/ioctl.rs`). Any change here MUST be mirrored there.

## Read/Write mechanism

`PsLookupProcessByProcessId` -> `KeStackAttachProcess` -> `RtlCopyMemory` (probed). Wrapped in `__try/__except` so a bad address returns an error instead of a bug-check. Reads are done from the target's own thread context so we don't leave working-set fingerprints that Hyperion's Deleter2 would flag on external threads. (See `../../Notes/External Questions.md` for the detailed detection model.)

`MmCopyVirtualMemory` is an alternative if the attach+copy path ever triggers something -- swap-in is one function change.

## Build

**Do this inside the Windows VM.** Requires the Windows Driver Kit (WDK 10.0.22621+) and Visual Studio 2022 with Desktop C++ workload.

- Install VS 2022 Build Tools -> Desktop C++.
- Install WDK: https://learn.microsoft.com/windows-hardware/drivers/download-the-wdk
- Open `driver.vcxproj` (added at first build) in VS or `msbuild`.
- Output: `KoffeeMem.sys`.

## Load (in VM)

The driver is unsigned during dev. Two options:

1. **Test-signing mode** for fastest iteration:
   ```
   bcdedit /set testsigning on
   bcdedit /set nointegritychecks on
   shutdown /r /t 0
   ```
   Then `sc create KoffeeMem type= kernel binPath= C:\path\to\KoffeeMem.sys && sc start KoffeeMem`.

2. **KDMapper (BYOVD)** -- the prod path. Not used during dev; slower to iterate. Wired later when we ship a real loader.

## Debugging

- Set up WinDbg + kernel debugging to the VM per Microsoft's docs. Crash dumps go to `%SystemRoot%\Minidump`.
- `DbgPrint` output visible in DebugView (Sysinternals) OR the attached WinDbg.
- Every `IRP_MJ_DEVICE_CONTROL` handler is `__try/__except` wrapped -- worst case is `STATUS_ACCESS_VIOLATION` returned to userland, not a BSOD.

## Status

- [ ] Skeleton: DriverEntry, dispatch table, device creation
- [ ] IOCTL handlers (attach, read, write, module_base)
- [ ] Verify basic read of Roblox base returns MZ
- [ ] Add write path
- [ ] BYOVD loader integration
