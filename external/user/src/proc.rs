//! Process discovery -- find Roblox's PID by exe name.
//!
//! Uses ToolHelp's Process32First/Process32Next snapshot -- reliable, no
//! special privileges needed just to enumerate. This runs BEFORE we open
//! any handle to the target, so it can't be flagged by Hyperion.

use std::ffi::CStr;
use windows_sys::Win32::Foundation::{CloseHandle, INVALID_HANDLE_VALUE};
use windows_sys::Win32::System::Diagnostics::ToolHelp::{
    CreateToolhelp32Snapshot, Process32First, Process32Next, PROCESSENTRY32,
    TH32CS_SNAPPROCESS,
};

/// Return the PID of the first process whose exe name matches (case-insensitive).
/// Returns None if not found (roblox not running).
pub fn find_process(exe_name: &str) -> Option<u32> {
    let target = exe_name.to_lowercase();
    unsafe {
        let snap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
        if snap == INVALID_HANDLE_VALUE { return None; }

        let mut entry: PROCESSENTRY32 = std::mem::zeroed();
        entry.dwSize = std::mem::size_of::<PROCESSENTRY32>() as u32;

        let mut pid = None;
        if Process32First(snap, &mut entry) != 0 {
            loop {
                // szExeFile is a fixed-size CHAR array, NUL-terminated.
                let name_ptr = entry.szExeFile.as_ptr() as *const i8;
                if let Ok(name) = CStr::from_ptr(name_ptr).to_str() {
                    if name.to_lowercase() == target {
                        pid = Some(entry.th32ProcessID);
                        break;
                    }
                }
                if Process32Next(snap, &mut entry) == 0 { break; }
            }
        }
        CloseHandle(snap);
        pid
    }
}
