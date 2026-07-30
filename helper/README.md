# Koffee Helper

The external half of Koffee. Roblox exposes no XButton1/XButton2 (mouse 4/5)
through its input API, so the in-game Lua suite is blind to them. This tiny
background program reads those buttons at the OS level and publishes their live
state over a localhost HTTP endpoint the script polls.

First OS-level feature of Koffee; more slot in behind the same bridge later
(arbitrary keys, stream-proof primitives, etc.).

## Build

Needs the Rust toolchain (`rustup`).

```
cargo build --release
```

Output: `target/release/KoffeeHelper.exe` (~250 KB, single binary, no runtime deps).

## Run

**Default (silent background):** double-click `KoffeeHelper.exe`. No window,
runs invisibly in the background — check Task Manager to see it.

**Dev/debug mode (visible console):** pass any argument, e.g.
`KoffeeHelper.exe --console`. Opens a console showing status prints.

Either way, it serves:

```
GET http://127.0.0.1:7912/  ->  {"xb1":false,"xb2":true,"ok":true}
```

- `xb1` = XButton1 (mouse "back") currently held
- `xb2` = XButton2 (mouse "forward") currently held

The Koffee script auto-detects it (`[koffee] helper connected` in the console)
and exposes `XButton1` / `XButton2` as bindable keys. Bind e.g. aimbot to
`xb2`: click the activation pill, then press the button.

If the helper isn't running, those binds simply do nothing — everything else
works as normal.

## Notes

- Port is `7912` (hardcoded for now).
- Silent-by-default via `#![windows_subsystem = "windows"]` + `AllocConsole()`
  when any arg is passed. To shut it down: Task Manager.
- Local only — binds `127.0.0.1`, never exposed to the network.
