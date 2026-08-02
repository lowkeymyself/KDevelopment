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
- [ ] Kernel driver skeleton + IOCTL protocol
- [ ] Real DriverTransport (Rust user side of the IOCTL)
- [ ] KDMapper-based loader with a picked vulnerable driver
- [ ] Roblox base-address / player-list read (first real memory op)
- [ ] Feature port begins
