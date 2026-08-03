//! Koffee External -- entry point.
//!
//! This binary is the loader + host process. Responsibilities:
//!   1. Find the Roblox process (or wait for it to launch).
//!   2. Open a transport to its memory -- either the real kernel driver
//!      (production) or a mock (host-side dev without a driver).
//!   3. Discover the Roblox main module base address (required for every
//!      offset-based read).
//!   4. Run the feature loop (later -- this scaffolding just proves the
//!      transport works).
//!
//! Feature code will live in sibling modules and only ever touch the
//! `Transport` trait -- never a raw syscall or `DeviceIoControl`. Swapping
//! transports (mock <-> real driver <-> future EV-signed driver) never
//! reaches feature code.

mod ioctl;
mod proc;
mod transport;

use std::process::ExitCode;
use transport::Transport;

// pick the transport at compile-time via a feature flag. defaults to mock so
// `cargo run` on a dev host works out of the box (no driver, no admin).
// build with `cargo run --features real-driver` in the VM once the driver
// is installed.
#[cfg(not(feature = "real-driver"))]
type ChosenTransport = transport::mock::MockTransport;
#[cfg(feature = "real-driver")]
type ChosenTransport = transport::driver::DriverTransport;

const ROBLOX_EXE: &str = "RobloxPlayerBeta.exe";

fn main() -> ExitCode {
    println!("koffee-external v{} -- {}", env!("CARGO_PKG_VERSION"),
        if cfg!(feature = "real-driver") { "real driver" } else { "mock transport (dev)" });

    // Target selection order:
    //   1. CLI arg 1 (`KoffeeExternal.exe SomeTarget.exe`) -- first driver-testing use case
    //      is `KoffeeTestTarget.exe`, so we need to point at anything.
    //   2. `KOFFEE_TARGET_EXE` env var -- convenient for running under a shell / debugger.
    //   3. default = RobloxPlayerBeta.exe (prod path).
    let target_exe: String = std::env::args().nth(1)
        .or_else(|| std::env::var("KOFFEE_TARGET_EXE").ok())
        .unwrap_or_else(|| ROBLOX_EXE.to_string());

    // 1. locate the target process.
    let pid = match proc::find_process(&target_exe) {
        Some(p) => p,
        None => {
            eprintln!("[!] {} not found -- launch it first.", target_exe);
            return ExitCode::from(2);
        }
    };
    println!("[+] found {} pid = {}", target_exe, pid);

    // 2. open the transport.
    let mut t = match ChosenTransport::open(pid) {
        Ok(t) => t,
        Err(e) => {
            eprintln!("[!] transport open failed: {}", e);
            return ExitCode::from(3);
        }
    };
    println!("[+] transport ready");

    // 3. main-module base. this is the first real memory-adjacent op; if it
    //    works, the transport works.
    let base = match t.module_base(pid, &target_exe) {
        Ok(b) => b,
        Err(e) => {
            eprintln!("[!] module_base failed: {}", e);
            return ExitCode::from(4);
        }
    };
    println!("[+] {} base = 0x{:X}", target_exe, base);

    // 4. proof-of-life read: dump 16 bytes at the module base (should start
    //    with 'MZ' -- PE header). NOTHING to do with Deleter2 yet -- this is
    //    just "did the transport actually read a byte back."
    let mut buf = [0u8; 16];
    if let Err(e) = t.read(base, &mut buf) {
        eprintln!("[!] proof-of-life read failed: {}", e);
        return ExitCode::from(5);
    }
    println!("[+] bytes @ base: {}", hex(&buf));
    if &buf[0..2] == b"MZ" {
        println!("[+] MZ signature present -- transport is reading real memory.");
    } else {
        println!("[?] no MZ signature -- transport may be returning garbage. investigate.");
    }

    // scaffolding stops here. next: implement `game::` module (typed reads of
    // roblox structs off known offsets) + `features::` modules that mirror
    // the lua one-for-one.
    println!("[.] scaffolding done. feature loop lands next.");
    ExitCode::SUCCESS
}

fn hex(bytes: &[u8]) -> String {
    let mut s = String::with_capacity(bytes.len() * 3);
    for (i, b) in bytes.iter().enumerate() {
        if i > 0 { s.push(' '); }
        s.push_str(&format!("{:02X}", b));
    }
    s
}
