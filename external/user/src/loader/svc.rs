//! Service registration via registry + NtLoadDriver / NtUnloadDriver.
//!
//! Replicates kdmapper's service.cpp in Rust.
//! Privilege escalation uses RtlAdjustPrivilege(10 = SeLoadDriverPrivilege).

use std::io;
use windows_sys::Win32::System::Registry::{
    RegCloseKey, RegCreateKeyExW, RegDeleteTreeW, RegOpenKeyExW, RegSetValueExW,
    HKEY_LOCAL_MACHINE, KEY_WRITE, REG_DWORD, REG_EXPAND_SZ,
};
use windows_sys::Win32::System::LibraryLoader::{GetModuleHandleA, GetProcAddress};

// ── ntdll fn pointers ──────────────────────────────────────────────────────

#[repr(C)]
pub struct UnicodeString {
    pub length:         u16,
    pub maximum_length: u16,
    pub _pad:           u32,
    pub buffer:         *mut u16,
}

type FnRtlAdjPriv  = unsafe extern "system" fn(u32, u8, u8, *mut u8) -> i32;
type FnNtLoad      = unsafe extern "system" fn(*const UnicodeString) -> i32;
type FnNtUnload    = unsafe extern "system" fn(*const UnicodeString) -> i32;
type FnRtlInitUs   = unsafe extern "system" fn(*mut UnicodeString, *const u16);

fn get_ntdll(sym: &[u8]) -> Option<*const ()> {
    unsafe {
        let h = GetModuleHandleA(b"ntdll.dll\0".as_ptr());
        if h.is_null() { return None; }
        Some(GetProcAddress(h, sym.as_ptr())? as *const ())
    }
}

fn rtl_adjust_privilege(priv_id: u32, enable: bool) -> io::Result<()> {
    let f: FnRtlAdjPriv = unsafe {
        std::mem::transmute(
            get_ntdll(b"RtlAdjustPrivilege\0")
                .ok_or_else(|| io::Error::new(io::ErrorKind::NotFound, "RtlAdjustPrivilege"))?
        )
    };
    let mut was: u8 = 0;
    let st = unsafe { f(priv_id, enable as u8, 0, &mut was) };
    if st < 0 {
        Err(io::Error::new(io::ErrorKind::PermissionDenied,
            format!("RtlAdjustPrivilege({}) = 0x{:08X}", priv_id, st as u32)))
    } else {
        Ok(())
    }
}

fn make_unicode_string(wide: &[u16]) -> UnicodeString {
    // wide must be null-terminated; Length excludes the null.
    let byte_len = (wide.len().saturating_sub(1)) * 2;
    UnicodeString {
        length:         byte_len as u16,
        maximum_length: (wide.len() * 2) as u16,
        _pad:           0,
        buffer:         wide.as_ptr() as *mut u16,
    }
}

fn to_wide_nul(s: &str) -> Vec<u16> {
    s.encode_utf16().chain(std::iter::once(0)).collect()
}

// ── public API ─────────────────────────────────────────────────────────────

/// Create a kernel-driver service key in the registry and call NtLoadDriver.
///
/// * `driver_path` – full Win32 path to the .sys file on disk.
/// * `svc_name`    – arbitrary service name (used as registry key name).
pub fn register_and_start(driver_path: &str, svc_name: &str) -> io::Result<()> {
    // 1. Build registry key paths.
    let services_subkey = format!("SYSTEM\\CurrentControlSet\\Services\\{}", svc_name);
    let image_path      = format!("\\??\\{}", driver_path);

    // 2. Create the service key.
    let mut hkey = std::ptr::null_mut();
    let subkey_w: Vec<u16> = to_wide_nul(&services_subkey);
    let rc = unsafe {
        RegCreateKeyExW(
            HKEY_LOCAL_MACHINE,
            subkey_w.as_ptr(),
            0, std::ptr::null(), 0, KEY_WRITE, std::ptr::null(), &mut hkey, std::ptr::null_mut(),
        )
    };
    if rc != 0 {
        return Err(io::Error::new(io::ErrorKind::Other,
            format!("RegCreateKeyExW failed: {}", rc)));
    }

    // 3. Set ImagePath (REG_EXPAND_SZ).
    let img_w: Vec<u16> = to_wide_nul(&image_path);
    let rc = unsafe {
        RegSetValueExW(
            hkey,
            to_wide_nul("ImagePath").as_ptr(),
            0, REG_EXPAND_SZ,
            img_w.as_ptr() as *const u8,
            (img_w.len() * 2) as u32,
        )
    };
    if rc != 0 {
        unsafe { RegCloseKey(hkey); }
        let _ = delete_service_key(&services_subkey);
        return Err(io::Error::new(io::ErrorKind::Other,
            format!("RegSetValueExW ImagePath failed: {}", rc)));
    }

    // 4. Set Type = 1 (SERVICE_KERNEL_DRIVER).
    let svc_type: u32 = 1;
    let rc = unsafe {
        RegSetValueExW(
            hkey,
            to_wide_nul("Type").as_ptr(),
            0, REG_DWORD,
            &svc_type as *const u32 as *const u8,
            4,
        )
    };
    if rc != 0 {
        unsafe { RegCloseKey(hkey); }
        let _ = delete_service_key(&services_subkey);
        return Err(io::Error::new(io::ErrorKind::Other,
            format!("RegSetValueExW Type failed: {}", rc)));
    }

    // 4b. Set Start = 3 (SERVICE_DEMAND_START).
    //     CRITICAL: without an explicit Start value, Windows inherits the default
    //     which may be 0 (boot start). If the process crashes before cleanup, the
    //     registry key survives reboot and Windows tries to load a temp .sys file
    //     that no longer exists → BSOD at boot. Demand-start (3) prevents auto-load.
    let svc_start: u32 = 3;
    let rc = unsafe {
        RegSetValueExW(
            hkey,
            to_wide_nul("Start").as_ptr(),
            0, REG_DWORD,
            &svc_start as *const u32 as *const u8,
            4,
        )
    };
    // 4c. Set ErrorControl = 1 (SERVICE_ERROR_NORMAL) for robustness.
    let svc_err: u32 = 1;
    let rc2 = unsafe {
        RegSetValueExW(
            hkey,
            to_wide_nul("ErrorControl").as_ptr(),
            0, REG_DWORD,
            &svc_err as *const u32 as *const u8,
            4,
        )
    };
    unsafe { RegCloseKey(hkey); }
    if rc != 0 || rc2 != 0 {
        let _ = delete_service_key(&services_subkey);
        return Err(io::Error::new(io::ErrorKind::Other,
            format!("RegSetValueExW Start/ErrorControl failed: {}/{}", rc, rc2)));
    }

    // 5. Elevate to SeLoadDriverPrivilege (id=10).
    crate::loader::dbg::log(format_args!("svc: RtlAdjustPrivilege(SeLoadDriverPrivilege) calling"));
    rtl_adjust_privilege(10, true)?;
    crate::loader::dbg::log(format_args!("svc: SeLoadDriverPrivilege ok"));

    // 6. NtLoadDriver.
    let fn_load: FnNtLoad = unsafe {
        std::mem::transmute(
            get_ntdll(b"NtLoadDriver\0")
                .ok_or_else(|| io::Error::new(io::ErrorKind::NotFound, "NtLoadDriver"))?
        )
    };

    let reg_path = format!(
        "\\Registry\\Machine\\System\\CurrentControlSet\\Services\\{}",
        svc_name
    );
    let reg_w = to_wide_nul(&reg_path);
    let us    = make_unicode_string(&reg_w);

    crate::loader::dbg::log(format_args!("svc: NtLoadDriver calling reg={}", reg_path));
    let st = unsafe { fn_load(&us as *const _) };
    crate::loader::dbg::log(format_args!("svc: NtLoadDriver status=0x{:08X}", st as u32));
    // 0xC0000035 = STATUS_OBJECT_NAME_COLLISION: the driver is already resident
    // from a previous run (RTCore64 ships no unload routine, so a session that
    // ended without a force-unload leaves it in the kernel). The device is
    // reusable as-is. Keep the fresh service key so the final cleanup's
    // NtUnloadDriver still has a registry path to reference.
    const NAME_COLLISION: i32 = 0xC0000035u32 as i32;
    if st == NAME_COLLISION {
        println!("[+] loader: driver already resident -- reusing existing instance");
        return Ok(());
    }
    if st < 0 {
        let _ = delete_service_key(&services_subkey);
        return Err(io::Error::new(io::ErrorKind::Other,
            format!("NtLoadDriver failed: 0x{:08X} -- is VulnerableDriverBlocklistEnable=0 and Memory Integrity off?",
                st as u32)));
    }
    Ok(())
}

/// NtUnloadDriver + delete service registry key.
pub fn stop_and_remove(svc_name: &str) -> io::Result<()> {
    let fn_unload: FnNtUnload = unsafe {
        std::mem::transmute(
            get_ntdll(b"NtUnloadDriver\0")
                .ok_or_else(|| io::Error::new(io::ErrorKind::NotFound, "NtUnloadDriver"))?
        )
    };

    let services_subkey = format!("SYSTEM\\CurrentControlSet\\Services\\{}", svc_name);

    // Check the key exists first.
    let subkey_w = to_wide_nul(&services_subkey);
    let mut hkey = std::ptr::null_mut();
    let rc = unsafe {
        RegOpenKeyExW(HKEY_LOCAL_MACHINE, subkey_w.as_ptr(), 0, KEY_WRITE, &mut hkey)
    };
    if rc == 2 { // ERROR_FILE_NOT_FOUND
        return Ok(()); // already gone
    }
    if rc == 0 { unsafe { RegCloseKey(hkey); } }

    let reg_path = format!(
        "\\Registry\\Machine\\System\\CurrentControlSet\\Services\\{}",
        svc_name
    );
    let reg_w = to_wide_nul(&reg_path);
    let us    = make_unicode_string(&reg_w);

    unsafe { fn_unload(&us as *const _) };
    // ignore unload status -- we still try to remove the key

    let _ = delete_service_key(&services_subkey);
    Ok(())
}

fn delete_service_key(subkey: &str) -> io::Result<()> {
    let subkey_w = to_wide_nul(subkey);
    let rc = unsafe { RegDeleteTreeW(HKEY_LOCAL_MACHINE, subkey_w.as_ptr()) };
    if rc != 0 {
        Err(io::Error::new(io::ErrorKind::Other,
            format!("RegDeleteTreeW failed: {}", rc)))
    } else {
        Ok(())
    }
}
