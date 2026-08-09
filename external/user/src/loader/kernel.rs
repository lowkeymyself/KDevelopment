//! Kernel utility layer: module enumeration, PE section lookup, pattern scanning.
//!
//! All functions that touch kernel memory receive a read closure so they stay
//! decoupled from the concrete transport type (Rtc, mock, ...).

use std::io;
use windows_sys::Win32::System::Memory::{
    VirtualAlloc, VirtualFree, MEM_COMMIT, MEM_RESERVE, MEM_RELEASE, PAGE_READWRITE,
};
use windows_sys::Win32::System::LibraryLoader::{GetModuleHandleA, GetProcAddress};

// ── ntdll function pointers ────────────────────────────────────────────────

type FnNtqsi = unsafe extern "system" fn(u32, *mut u8, u32, *mut u32) -> i32;

fn ntqsi() -> Option<FnNtqsi> {
    unsafe {
        let h = GetModuleHandleA(b"ntdll.dll\0".as_ptr());
        if h.is_null() { return None; }
        let p = GetProcAddress(h, b"NtQuerySystemInformation\0".as_ptr())?;
        Some(std::mem::transmute(p))
    }
}

// ── RTL module info ────────────────────────────────────────────────────────

#[repr(C)]
struct ModInfo {
    _section:             u64,
    _mapped_base:         u64,
    pub image_base:       u64,   // runtime load VA
    pub image_size:       u32,
    _flags:               u32,
    _load_order:          u16,
    _init_order:          u16,
    _load_count:          u16,
    pub offset_to_name:   u16,   // byte offset into full_path_name where filename starts
    pub full_path_name:   [u8; 256],
}

/// Returns the runtime load address of a kernel module by its filename (case-insensitive).
/// e.g. `"ntoskrnl.exe"`, `"ci.dll"`, `"WdFilter.sys"`.
pub fn get_kernel_module_address(name: &str) -> Option<u64> {
    let f = ntqsi()?;
    const CLASS_MODULE: u32 = 11;

    let mut sz: u32 = 0;
    unsafe { f(CLASS_MODULE, std::ptr::null_mut(), 0, &mut sz) };
    sz = sz.saturating_add(0x1000);

    let buf = unsafe {
        VirtualAlloc(std::ptr::null(), sz as usize, MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE)
    } as *mut u8;
    if buf.is_null() { return None; }

    let st = unsafe { f(CLASS_MODULE, buf, sz, &mut sz) };
    if st < 0 {
        unsafe { VirtualFree(buf as _, 0, MEM_RELEASE) };
        return None;
    }

    let count = unsafe { *(buf as *const u32) } as usize;
    // RTL_PROCESS_MODULES: ULONG(4) + implicit pad(4) → ModInfo array at offset 8
    let mods = unsafe { buf.add(8) as *const ModInfo };
    let needle = name.to_ascii_lowercase();

    let found = (0..count).find_map(|i| {
        let m = unsafe { &*mods.add(i) };
        let off = m.offset_to_name as usize;
        let end = m.full_path_name.iter().position(|&b| b == 0).unwrap_or(256);
        let fname = String::from_utf8_lossy(&m.full_path_name[off.min(end)..end]);
        if fname.to_ascii_lowercase() == needle { Some(m.image_base) } else { None }
    });

    unsafe { VirtualFree(buf as _, 0, MEM_RELEASE) };
    found
}

// ── PE section lookup (operates on header bytes in user memory) ────────────

/// Find a named section in PE header bytes. Returns `(virtual_address, virtual_size)`.
pub fn find_section_in_headers(headers: &[u8], name: &[u8]) -> Option<(u32, u32)> {
    let e_lfanew = u32::from_le_bytes(headers.get(0x3C..0x40)?.try_into().ok()?) as usize;
    if headers.get(e_lfanew..e_lfanew + 4)? != b"PE\0\0" { return None; }
    let num_sec  = u16::from_le_bytes(headers.get(e_lfanew+6..e_lfanew+8)?.try_into().ok()?) as usize;
    let opt_size = u16::from_le_bytes(headers.get(e_lfanew+20..e_lfanew+22)?.try_into().ok()?) as usize;
    let sec_base = e_lfanew + 24 + opt_size; // IMAGE_FIRST_SECTION

    for i in 0..num_sec {
        let o = sec_base + i * 40;
        let raw_name = headers.get(o..o+8)?;
        let raw_end  = raw_name.iter().position(|&b| b == 0).unwrap_or(8);
        if &raw_name[..raw_end] == name {
            let va = u32::from_le_bytes(headers.get(o+12..o+16)?.try_into().ok()?);
            let vs = u32::from_le_bytes(headers.get(o+16..o+20)?.try_into().ok()?);
            return Some((va, vs));
        }
    }
    None
}

// ── Pattern scanning ───────────────────────────────────────────────────────

/// Scan `data` for `pattern`/`mask` ('x' = exact match, '?' = wildcard).
/// Returns the byte offset of the first match.
pub fn find_pattern(data: &[u8], pattern: &[u8], mask: &[u8]) -> Option<usize> {
    let plen = pattern.len();
    if plen == 0 || data.len() < plen { return None; }
    'outer: for i in 0..=(data.len() - plen) {
        for j in 0..plen {
            if mask.get(j).copied() == Some(b'x') && data[i + j] != pattern[j] {
                continue 'outer;
            }
        }
        return Some(i);
    }
    None
}

/// Read `size` bytes from kernel VA `addr` via a read closure, then pattern-scan.
/// Returns the matching kernel VA on success.
pub fn find_pattern_at_kernel<F>(
    addr: u64, size: usize,
    pattern: &[u8], mask: &[u8],
    read: &mut F,
) -> io::Result<Option<u64>>
where
    F: FnMut(u64, &mut [u8]) -> io::Result<()>,
{
    const MAX: usize = 512 * 1024 * 1024; // 512 MB sanity cap
    if size == 0 || size > MAX { return Ok(None); }
    let mut buf = vec![0u8; size];
    read(addr, &mut buf)?;
    Ok(find_pattern(&buf, pattern, mask).map(|off| addr + off as u64))
}

/// Read 0x1000 bytes of headers from `module_base`, find section, then scan pattern.
pub fn find_pattern_in_section_at_kernel<F>(
    section_name: &[u8],
    module_base: u64,
    pattern: &[u8],
    mask: &[u8],
    read: &mut F,
) -> io::Result<Option<u64>>
where
    F: FnMut(u64, &mut [u8]) -> io::Result<()>,
{
    let mut hdrs = [0u8; 0x1000];
    read(module_base, &mut hdrs)?;

    let (sec_va, sec_size) = match find_section_in_headers(&hdrs, section_name) {
        Some(x) => x,
        None => return Ok(None),
    };

    find_pattern_at_kernel(
        module_base + sec_va as u64,
        sec_size as usize,
        pattern, mask,
        read,
    )
}

/// Resolve an RIP-relative reference: `*(Instruction + OffsetOffset)` + InstructionSize.
pub fn resolve_relative_address<F>(
    instr: u64, offset_off: u64, instr_size: u64,
    read: &mut F,
) -> io::Result<u64>
where
    F: FnMut(u64, &mut [u8]) -> io::Result<()>,
{
    let mut rip_off_bytes = [0u8; 4];
    read(instr + offset_off, &mut rip_off_bytes)?;
    let rip_off = i32::from_le_bytes(rip_off_bytes) as i64;
    Ok((instr + instr_size).wrapping_add(rip_off as u64))
}
