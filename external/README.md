# Koffee External

Standalone Windows program that ports the Koffee Lua script to native code, reading/writing `RobloxPlayerBeta.exe` memory directly via a kernel driver -- no executor required.

Two halves:

- `driver/` -- minimal Windows kernel driver (C, WDK). Attaches to Roblox, does memory read/write, exposes IOCTLs. This is the ONLY component that runs in kernel; everything else is Rust userland.
- `user/` -- Rust program that opens the driver, discovers Roblox's PID + module base, and runs the feature set (Silent Aim, Pos Spoof, ESP, etc.) via the driver transport. Ports the Lua modules one-for-one.

## Why kernel + why usermode wouldn't work

Full research + sources in [../../Notes/External Questions.md](../../../Documents/Obsidian%20Vault/Notes/External%20Questions.md) (Obsidian vault). Short version: Hyperion's Deleter2 pool detects any external thread reading watched game structures within ~30ms via thread-origin checks. Every paid Roblox external in 2025-2026 uses a kernel driver for this reason. Matcha does the same.

## Distribution model

- User launches `KoffeeExternal.exe` (loader) as admin, once per Windows boot, BEFORE Roblox.
- Loader manual-maps the driver via BYOVD (KDMapper-style with a currently-safe vulnerable signed driver).
- Requires Memory Integrity OFF (`Windows Security -> Device Security -> Core Isolation -> Memory Integrity`).
- Loader stays running; opens IPC to a UI (existing `helper/` extends into this role) that talks to the driver.

## Build (host machine)

Host builds the Rust userland with a **mock transport** -- no driver required, feature dev works cross-platform:

```
cd external/user
cargo run
```

Mock transport prints simulated reads/writes; useful for iterating feature code without a VM.

## Build (VM machine)

Driver + real-transport build happens in the Windows VM with WDK installed. Setup docs land in `driver/README.md` as we build them.

## Status

- [x] Scaffolding + Transport trait + mock transport (proof-of-life on host)
- [x] `KoffeeTestTarget` dev target bin (safe VM read/write test target for the driver -- see `user/src/bin/testtarget.rs`)
- [x] Kernel driver skeleton + IOCTL protocol (KfmFindModule stubbed; rest wired)
- [x] `KfmFindModule` PEB walk (`PsGetProcessPeb` + `InLoadOrderModuleList`, case-insensitive `BaseDllName` match, SEH-wrapped, capped at 4096 modules to survive a corrupted list)
- [x] Real `DriverTransport` (Rust): `CreateFileA("\\\\.\\KoffeeMem")` + `DeviceIoControl` for ATTACH/READ/WRITE/MODULE_BASE, `Drop` closes the handle. `Cargo.toml` gains a `real-driver` feature flag (default = mock).
- [x] Driver build project (`KoffeeMem.vcxproj`/`.sln`, WDM x64 Debug/Release) + full VM runbook (`driver/README.md`)
- [x] `KoffeeExternal` bin accepts a target-exe arg / `KOFFEE_TARGET_EXE` env var so the first live round-trip can point at `KoffeeTestTarget.exe` before touching Roblox
- [ ] First live driver round-trip against `KoffeeTestTarget` in the VM
- [ ] Loader (BYOVD manual mapper with a picked vulnerable signed driver)
- [ ] First live read of a real target's module base
- [ ] Feature port begins

**Currently in progress** -- driver + Rust IOCTL layer both stand up on their own build gates (Rust `cargo check` clean for both `default` and `--features real-driver`; driver still needs a WDK build in the VM). Next: the `driver.vcxproj` + VM build recipe, then the first live round-trip against `KoffeeTestTarget`.
