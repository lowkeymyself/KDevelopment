//! Koffee driver loader — standalone.
//!
//! One job: ensure the kernel driver is mapped and its device is reachable.
//! Invoked as a subprocess by `KoffeeHelper.exe` (native C++ under
//! `helper/native/`) at helper startup. This binary calls
//! `loader::ensure_loaded()`, writes `READY` on stdout when the driver is up,
//! then exits. The helper waits for that line, opens `\\.\<koffee device>`
//! via `DeviceIoControl`, and owns the session from there.
//!
//! Everything user-facing (silent aim, wallbang, target selection, HTTP
//! bridge to koffee.lua) lives in the native helper. This binary is deliberately
//! minimal — the smaller the loader surface, the less to re-audit whenever the
//! driver rebuilds.

mod loader;

use std::process::ExitCode;

fn main() -> ExitCode {
    match loader::ensure_loaded() {
        Ok(()) => {
            // Contract with KoffeeHelper: single trimmed line on stdout,
            // followed by immediate exit. The helper reads until it sees this
            // line, then closes the child's stdio and proceeds. Do NOT change
            // the token without updating the helper's parser.
            println!("READY");
            ExitCode::SUCCESS
        }
        Err(e) => {
            // Same contract for failure: prefix + message on stderr, non-zero
            // exit. Helper surfaces the message to its log so the user has a
            // real diagnostic instead of "loader failed."
            eprintln!("LOAD_FAIL: {e}");
            ExitCode::FAILURE
        }
    }
}
