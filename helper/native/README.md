# KoffeeHelper (native)

Native (C++) helper for the Koffee suite. Runs on the user's desktop as a
background service, bridges between `koffee.lua` (running inside Roblox) and
the kernel driver that does the actual memory work for silent aim + wallbang.

## Status

**v0.3.0-alpha1** — teardown + skeleton only. This binary currently:

- binds `127.0.0.1:27374`
- responds to `GET /health` with `{"status":"ok",...}`
- does nothing else

Alpha2 wires the full pipeline: loader subprocess, driver device open,
raycast inline hook, `POST /config` from `koffee.lua`.

## Build

```
cmake -S . -B build -G "Visual Studio 17 2022" -A x64
cmake --build build --config Release
```

Output: `build/Release/KoffeeHelper.exe`

Console subsystem during alpha (log goes to stdout). Flips to WIN32 subsystem
+ file log once we ship a real release build.

## Requirements

- Windows 10/11 x64
- MSVC 2022 (any edition — Community works)
- CMake 3.20+

No admin rights needed to build. Runtime will need admin (alpha2, when the
loader subprocess and driver load land) — that's out of scope for alpha1.

## Layout

```
helper/native/
├── CMakeLists.txt
├── README.md
└── src/
    ├── main.cpp        entry, port config, http bind
    ├── http.h / .cpp   minimal winsock http (hand-rolled, alpha1 only)
    └── log.h / .cpp    tiny prefixed logger, stdout + stderr
```

## Related

- `../` (Rust `helper/`) — old input-bridge Rust helper. Alpha2+ folds its
  mouse-button-read functionality into this native helper; kept alongside for
  now, will be retired once feature parity lands.
- `../../external/user/` — Rust loader crate (`KoffeeLoader.exe`). Alpha2
  spawns this as a subprocess on startup and waits for its `READY` line.
- `../../external/driver/` — kernel driver source. Untouched by this switch;
  audit-clean per the 2026-08-28 stability review.
