// Koffee Helper -- OS-level input bridge (v0.1.1)
//
// Roblox exposes no XButton1/XButton2 (mouse 4/5) through its input API, so the
// Lua suite is blind to them. This tiny background program samples those buttons
// at the OS level (Win32 GetAsyncKeyState) and publishes their live state over a
// localhost HTTP endpoint that the in-game script polls with its `request` fn.
//
//   GET http://127.0.0.1:7912/  ->  {"xb1":false,"xb2":true,"ok":true}
//
// v0.1.1: linked as a `windows` subsystem so double-clicking spawns NO console
// (real background program). Pass ANY argument (e.g. `KoffeeHelper.exe --console`)
// to attach a console and see the status prints -- the dev-visibility mode.

// no console window on double-click; any arg re-attaches one at runtime
#![windows_subsystem = "windows"]

use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::thread;
use std::time::Duration;

use tiny_http::{Header, Response, Server};

// virtual-key codes (winuser.h)
const VK_XBUTTON1: i32 = 0x05;
const VK_XBUTTON2: i32 = 0x06;

const PORT: u16 = 7912;

// user32!GetAsyncKeyState -- high bit of the return means "currently down".
#[link(name = "user32")]
extern "system" {
    fn GetAsyncKeyState(v_key: i32) -> i16;
}

// AllocConsole gives this GUI-subsystem process a fresh console when the user
// asks for one via a CLI arg; without it, println! is a silent no-op.
#[link(name = "kernel32")]
extern "system" {
    fn AllocConsole() -> i32;
}

#[inline]
fn key_down(vk: i32) -> bool {
    (unsafe { GetAsyncKeyState(vk) } as u16 & 0x8000) != 0
}

fn main() {
    // any CLI arg switches on the dev-visible console (default: silent background)
    let show_console = std::env::args().len() > 1;
    if show_console {
        unsafe { AllocConsole(); }
    }

    let xb1 = Arc::new(AtomicBool::new(false));
    let xb2 = Arc::new(AtomicBool::new(false));

    // sampler thread: ~1000Hz poll so a fast tap is never missed
    {
        let (xb1, xb2) = (Arc::clone(&xb1), Arc::clone(&xb2));
        thread::spawn(move || loop {
            xb1.store(key_down(VK_XBUTTON1), Ordering::Relaxed);
            xb2.store(key_down(VK_XBUTTON2), Ordering::Relaxed);
            thread::sleep(Duration::from_millis(1));
        });
    }

    let addr = format!("127.0.0.1:{}", PORT);
    let server = match Server::http(&addr) {
        Ok(s) => s,
        Err(e) => {
            // background mode has no console -- pop one so the user sees the error
            if !show_console { unsafe { AllocConsole(); } }
            eprintln!("[koffee-helper] could not bind {addr}: {e}");
            eprintln!("[koffee-helper] another copy may already be running.");
            pause();
            return;
        }
    };

    println!("========================================");
    println!("  Koffee Helper  ->  http://{addr}/");
    println!("  Reading XButton1 / XButton2 for Koffee.");
    println!("  Leave this window open while you play.");
    println!("========================================");

    // one reusable JSON content-type header
    let json = Header::from_bytes(&b"Content-Type"[..], &b"application/json"[..])
        .expect("valid header");

    for request in server.incoming_requests() {
        let body = format!(
            "{{\"xb1\":{},\"xb2\":{},\"ok\":true}}",
            xb1.load(Ordering::Relaxed),
            xb2.load(Ordering::Relaxed)
        );
        let response = Response::from_string(body).with_header(json.clone());
        let _ = request.respond(response);
    }
}

// keep the console open on a bind error so the user can read it
fn pause() {
    use std::io::Read;
    let _ = std::io::stdin().read(&mut [0u8]);
}
