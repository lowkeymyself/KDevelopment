//! Tiny self-log helper: mirrors diagnostics into a file directly from Rust so
//! the VM's temperamental console redirection can't swallow output. Controlled
//! by env var KOFE_DBGLOG (path). Silent, no-op when unset.

use std::fs::{File, OpenOptions};
use std::io::{self, Write};
use std::sync::Mutex;

static G: Mutex<Option<File>> = Mutex::new(None);

pub fn init() {
    let Ok(path) = std::env::var("KOFE_DBGLOG") else { return };
    let f = OpenOptions::new().create(true).append(true).open(path);
    match f {
        Ok(f) => {
            *G.lock().unwrap() = Some(f);
            log(format_args!("=== dbg init ok ==="));
        }
        Err(e) => println!("[dbglog] open failed: {}", e),
    }
}

pub fn log(args: std::fmt::Arguments) {
    let mut g = G.lock().unwrap();
    if let Some(f) = g.as_mut() {
        let _ = writeln!(f, "{}", args);
        let _ = f.flush();
    }
}

pub fn flush() {
    if let Some(f) = G.lock().unwrap().as_mut() {
        let _ = f.flush();
    }
}

pub fn sync_now() {
    let _ = flush();
    let _ = io::stdout().flush();
}