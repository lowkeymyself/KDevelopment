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

**Do this inside the Windows VM.** Requires the Windows Driver Kit (WDK 10.0.22621+) and Visual Studio 2022 with the "Desktop development with C++" workload.

- Install VS 2022 Community/Build Tools with "Desktop development with C++".
- Install the Windows SDK matching the WDK version.
- Install WDK: <https://learn.microsoft.com/windows-hardware/drivers/download-the-wdk>. During the WDK installer, tick "Install the Windows Driver Kit Visual Studio extension" so `WindowsKernelModeDriver10.0` shows up as a Platform Toolset.
- **Snapshot the VM after this, name it `clean-install`.** Anything after can be rolled back.

Two build paths:

**A) Visual Studio (GUI):** open `KoffeeMem.sln`, `Debug|x64`, right-click project → **Build**. Output at `x64\Debug\KoffeeMem\KoffeeMem.sys`.

**B) Command line:** open a `Developer Command Prompt for VS 2022` and:

```cmd
cd C:\path\to\Koffee\external\driver
msbuild KoffeeMem.vcxproj /p:Configuration=Debug /p:Platform=x64
dir /s /b KoffeeMem.sys
```

If you get `error MSB4019: The imported project "...WindowsKernelModeDriver10.0..."`: the WDK's VS integration isn't installed. Re-run the WDK installer and tick the extension option.

## Load (in VM) -- KDMapper (recommended)

Same tool as the prod path -- no test-signing, no watermark, no `sc create`, no service entry left behind. `DriverEntry` is dual-mode: called with `NULL` under KDMapper it synthesizes its own DriverObject via `IoCreateDriver`, so the KDMapper and `sc start` paths hit the exact same init body.

**One-time: get kdmapper.exe.**

Build from source (small C++ project):

```cmd
git clone https://github.com/TheCruZ/kdmapper.git C:\kdmapper
:: open C:\kdmapper\kdmapper.sln in VS 2022, Release|x64, Build
:: output at C:\kdmapper\x64\Release\kdmapper.exe
```

Or drop a prebuilt `kdmapper.exe` in `C:\kdmapper\` if you have one.

**Load the driver (admin cmd, every session):**

```cmd
C:\kdmapper\x64\Release\kdmapper.exe C:\Koffee\external\driver\x64\Debug\KoffeeMem\KoffeeMem.sys
```

Expected: `[+] Success` (or similar); no BSOD; DebugView (Sysinternals, run as admin, **Capture → Capture Kernel** on) shows `[KoffeeMem] loaded, device = \Device\KoffeeMem`.

Under the hood: kdmapper loads Intel's `iqvw64e.sys` (a currently-safe signed driver with a known kernel-write primitive), uses it to allocate non-paged pool + copy our `KoffeeMem.sys` into it + fix imports/relocs + call our `DriverEntry`, then unloads `iqvw64e.sys`. Our driver stays resident until reboot.

**Unload:** no `sc stop` under KDMapper. Reboot the VM (or roll back to the snapshot) to unload. This is fine -- the VM boots fast; snapshot after `clean-install` and roll back for a fresh state.

## Alternative: `sc create` (test-signing mode)

Only if KDMapper is unavailable. Cost: reboot required to enable test-signing, "Test Mode" watermark on desktop.

```cmd
bcdedit /set testsigning on
shutdown /r /t 0

:: after reboot:
sc create KoffeeMem type= kernel binPath= C:\Koffee\external\driver\x64\Debug\KoffeeMem\KoffeeMem.sys
sc start KoffeeMem
sc query KoffeeMem
```

If `sc start` errors 577, sign the .sys: `signtool sign /a /v /s TrustedPublisher /n WDKTestCert KoffeeMem.sys` from an elevated Developer Command Prompt.

To unload: `sc stop KoffeeMem && sc delete KoffeeMem`.

## First round-trip: `KoffeeTestTarget`

Once the driver loads, prove the transport end-to-end WITHOUT touching Roblox. `../user/src/bin/testtarget.rs` is a Rust bin with a deterministic memory region for the driver to read/write against.

```cmd
cd C:\path\to\Koffee\external\user
cargo build --release --bin KoffeeTestTarget
cargo build --release --bin KoffeeExternal --features real-driver

start .\target\release\KoffeeTestTarget.exe
.\target\release\KoffeeExternal.exe KoffeeTestTarget.exe
```

The `KoffeeExternal.exe` binary accepts an optional target-exe argument (falls back to `KOFFEE_TARGET_EXE` env var, then `RobloxPlayerBeta.exe`). Expected output when the round-trip works:

```
[+] found KoffeeTestTarget.exe pid = <pid>
[+] transport ready
[+] KoffeeTestTarget.exe base = 0x140000000  (or wherever ASLR placed it)
[+] bytes @ base: 4D 5A 90 00 03 00 00 00 04 00 00 00 FF FF 00 00
[+] MZ signature present -- transport is reading real memory.
```

If you see `MZ` (`4D 5A`) at the base -- ATTACH + READ + MODULE_BASE all work, the driver is real. Same command against `RobloxPlayerBeta.exe` is the prod smoke test.

## Debugging

- Set up WinDbg + kernel debugging to the VM per Microsoft's docs. Crash dumps go to `%SystemRoot%\Minidump`.
- `DbgPrint` output in DebugView (kernel capture enabled) OR the attached WinDbg.
- Every `IRP_MJ_DEVICE_CONTROL` handler is `__try/__except` wrapped -- worst case is `STATUS_ACCESS_VIOLATION` returned to userland, not a BSOD.

## Status

- [x] Skeleton: DriverEntry, dispatch table, device creation
- [x] IOCTL handlers (attach, read, write, module_base)
- [x] `KfmFindModule` PEB walk (`PsGetProcessPeb` + `InLoadOrderModuleList`, SEH-guarded)
- [x] Rust `DriverTransport` + `real-driver` Cargo feature
- [x] `.vcxproj`/`.sln` + VM build recipe
- [ ] First live driver round-trip against `KoffeeTestTarget` in the VM
- [ ] Verify basic read of Roblox base returns MZ
- [ ] BYOVD loader integration
