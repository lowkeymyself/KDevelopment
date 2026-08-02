//! KoffeeTestTarget -- dev-only target process for the kernel driver.
//!
//! Runs in the VM alongside the driver. It's a stand-in for Roblox: same
//! shape of problem (an external process attaches, reads structs, writes
//! back), zero AC or code protection so we can iterate the driver without
//! risking Roblox / a BSOD from touching something we shouldn't.
//!
//! What it exposes to a reader:
//!   1. A magic marker at a known-per-process address (`get_probe_addr()`).
//!      Read this first to confirm the driver hit the right process at the
//!      right address.
//!   2. A `GameState` struct with fields the driver can read AND write:
//!         - counter: bumps every tick (observable liveness).
//!         - marker : magic value the driver overwrites to prove writes land.
//!         - players: fixed-size array of Player structs, so we exercise
//!                    array-of-struct reads (which is what player-list /
//!                    ESP code will do against Roblox).
//!   3. Verbose stdout: PID, address of `STATE`, size, current values --
//!      copy-paste those into the driver test command.
//!
//! IMPORTANT: `STATE` is behind a `static mut` deliberately so its address
//! is deterministic within a run + easy to expose. Never do this in real code.

use std::io::Write;
use std::time::Duration;

const MAGIC_PROBE: u64 = 0xC0FFEE00_DEADBEEF;

#[repr(C)]
#[derive(Debug, Copy, Clone)]
struct Player {
    id:       u32,
    team:     u32,     // arbitrary team id
    health:   f32,
    _pad:     f32,     // keeps position 16-byte aligned (matches how real game structs commonly look)
    position: [f32; 3],
    _pad2:    f32,
}

impl Player {
    const fn new(id: u32, team: u32) -> Self {
        Self { id, team, health: 100.0, _pad: 0.0, position: [0.0, 0.0, 0.0], _pad2: 0.0 }
    }
}

#[repr(C)]
#[derive(Debug)]
struct GameState {
    probe:      u64,          // MAGIC_PROBE -- read this first to confirm attach
    counter:    u64,          // ticks per second; driver observes liveness
    marker:     u32,          // driver overwrites this -> we print the new value to confirm the write landed
    _pad:       u32,
    player_ct:  u32,
    _pad2:      u32,
    players:    [Player; 8],  // fixed 8-slot player list
}

static mut STATE: GameState = GameState {
    probe:     MAGIC_PROBE,
    counter:   0,
    marker:    0xDEAD_BEEF,
    _pad:      0,
    player_ct: 4,
    _pad2:     0,
    players: [
        Player::new(1, 1),
        Player::new(2, 1),
        Player::new(3, 2),
        Player::new(4, 2),
        Player::new(0, 0), Player::new(0, 0), Player::new(0, 0), Player::new(0, 0),
    ],
};

fn main() {
    let pid = std::process::id();
    // Address-of a mutable static field requires `unsafe`; taking the address
    // of the whole static does not. We never DEREF here -- just numeric
    // addresses for the driver.
    let state_addr   = &raw const STATE as usize;
    let state_size   = std::mem::size_of::<GameState>();
    let probe_addr   = unsafe { &raw const STATE.probe as usize };
    let marker_addr  = unsafe { &raw const STATE.marker as usize };
    let counter_addr = unsafe { &raw const STATE.counter as usize };
    let players_addr = unsafe { &raw const STATE.players as usize };

    println!("== KoffeeTestTarget ==");
    println!("  pid            = {}", pid);
    println!("  &STATE         = 0x{:X}   ({} bytes)", state_addr, state_size);
    println!("  &STATE.probe   = 0x{:X}   (u64 = 0x{:016X}; read this first to verify attach)",
             probe_addr, MAGIC_PROBE);
    println!("  &STATE.counter = 0x{:X}   (u64, bumps every 1s)", counter_addr);
    println!("  &STATE.marker  = 0x{:X}   (u32; driver writes here to prove writes work)", marker_addr);
    println!("  &STATE.players = 0x{:X}   (8 x Player, {} bytes each)",
             players_addr, std::mem::size_of::<Player>());
    println!();
    println!("Driver flow to test:");
    println!("  1. ATTACH pid   = {}", pid);
    println!("  2. READ  addr   = 0x{:X}  size = 8   -> expect 0x{:016X}", probe_addr, MAGIC_PROBE);
    println!("  3. WRITE addr   = 0x{:X}  bytes = <u32, e.g. 0x12345678>", marker_addr);
    println!("  4. Observe stdout below -- marker's new value prints on the NEXT tick.");
    println!();
    println!("Ticking (Ctrl+C to stop)...");
    println!();

    let stdout = std::io::stdout();
    let mut out = stdout.lock();
    loop {
        // SAFETY: single-thread mutator; no other reader in this process. The
        // whole *point* is that another process (our driver) is the parallel
        // reader/writer, and that's uncoordinated by design -- worst case a
        // torn u32 read on the driver side, which is fine for a dev target.
        unsafe {
            STATE.counter = STATE.counter.wrapping_add(1);
        }
        let (c, m) = unsafe { (STATE.counter, STATE.marker) };
        let _ = writeln!(out, "tick counter={:>6}  marker=0x{:08X}", c, m);
        let _ = out.flush();
        std::thread::sleep(Duration::from_secs(1));
    }
}
