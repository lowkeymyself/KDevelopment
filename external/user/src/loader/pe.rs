//! PE image parsing -- all ops on raw `&[u8]` slices, zero unsafe.
//!
//! Covers the subset needed by the manual mapper:
//!   * basic header fields (size, entry point, image base, timestamp)
//!   * section copy (headers + sections into a flat VirtualAddress-mapped buffer)
//!   * base relocations
//!   * import table (thunk patching for import resolution)
//!   * stack-cookie fixup

// ── header access helpers ─────────────────────────────────────────────────

fn u16_at(data: &[u8], off: usize) -> Option<u16> {
    Some(u16::from_le_bytes(data.get(off..off+2)?.try_into().ok()?))
}
fn u32_at(data: &[u8], off: usize) -> Option<u32> {
    Some(u32::from_le_bytes(data.get(off..off+4)?.try_into().ok()?))
}
fn u64_at(data: &[u8], off: usize) -> Option<u64> {
    Some(u64::from_le_bytes(data.get(off..off+8)?.try_into().ok()?))
}

/// Byte offset of the NT headers in `data`.
fn nt_offset(data: &[u8]) -> Option<usize> {
    if data.get(0..2)? != b"MZ" { return None; }
    Some(u32_at(data, 0x3C)? as usize)
}

fn nt_ok(data: &[u8]) -> Option<usize> {
    let nt = nt_offset(data)?;
    if data.get(nt..nt+4)? != b"PE\0\0" { return None; }
    Some(nt)
}

fn opt_off(data: &[u8]) -> Option<usize> { Some(nt_ok(data)? + 24) } // after FileHeader

// ── public API ────────────────────────────────────────────────────────────

pub fn size_of_image(data: &[u8]) -> Option<u32> {
    u32_at(data, opt_off(data)? + 0x38)   // SizeOfImage at +0x38 in OptionalHeader64
}

pub fn address_of_entry_point(data: &[u8]) -> Option<u32> {
    u32_at(data, opt_off(data)? + 0x10)   // AddressOfEntryPoint at +0x10
}

pub fn image_base(data: &[u8]) -> Option<u64> {
    u64_at(data, opt_off(data)? + 0x18)   // ImageBase at +0x18 (64-bit)
}

pub fn time_date_stamp(data: &[u8]) -> Option<u32> {
    u32_at(data, nt_ok(data)? + 8)        // FileHeader.TimeDateStamp at +8
}

pub fn size_of_headers(data: &[u8]) -> Option<u32> {
    u32_at(data, opt_off(data)? + 0x3C)   // SizeOfHeaders at +0x3C
}

fn num_sections(data: &[u8]) -> Option<u16> {
    u16_at(data, nt_ok(data)? + 6)
}

fn size_of_optional(data: &[u8]) -> Option<u16> {
    u16_at(data, nt_ok(data)? + 20)
}

fn sections_offset(data: &[u8]) -> Option<usize> {
    let nt = nt_ok(data)?;
    Some(nt + 24 + size_of_optional(data)? as usize)
}

// ── section iteration ─────────────────────────────────────────────────────

pub struct Section {
    pub va:             u32,   // VirtualAddress
    pub virtual_size:   u32,   // Misc.VirtualSize
    pub raw_off:        u32,   // PointerToRawData
    pub raw_size:       u32,   // SizeOfRawData
    pub characteristics: u32,
}

pub fn sections(data: &[u8]) -> Vec<Section> {
    let n   = num_sections(data).unwrap_or(0) as usize;
    let off = match sections_offset(data) { Some(o) => o, None => return vec![] };
    (0..n).filter_map(|i| {
        let o = off + i * 40;
        Some(Section {
            va:              u32_at(data, o+12)?,  // VirtualAddress
            virtual_size:    u32_at(data, o+8)?,   // Misc.VirtualSize
            raw_off:         u32_at(data, o+20)?,  // PointerToRawData
            raw_size:        u32_at(data, o+16)?,  // SizeOfRawData
            characteristics: u32_at(data, o+36)?,  // Characteristics
        })
    }).collect()
}

/// Copy headers + initialized sections into a flat `VirtualAddress`-indexed buffer
/// of `size_of_image` bytes (zero-initialised).
pub fn copy_to_image(data: &[u8]) -> Option<Vec<u8>> {
    let img_size = size_of_image(data)? as usize;
    let mut image = vec![0u8; img_size];

    // Headers.
    let hdr_size = size_of_headers(data)? as usize;
    let hdr_size = hdr_size.min(img_size).min(data.len());
    image[..hdr_size].copy_from_slice(&data[..hdr_size]);

    // Sections.
    for sec in sections(data) {
        let chars = sec.characteristics;
        const UNINIT: u32 = 0x0000_0080; // IMAGE_SCN_CNT_UNINITIALIZED_DATA
        if chars & UNINIT != 0 || sec.raw_size == 0 { continue; }

        let dst_va  = sec.va as usize;
        let src_off = sec.raw_off as usize;
        let copy    = (sec.raw_size as usize).min(sec.virtual_size as usize);

        if dst_va + copy > img_size { continue; }
        if src_off + copy > data.len() { continue; }
        image[dst_va..dst_va + copy].copy_from_slice(&data[src_off..src_off + copy]);
    }
    Some(image)
}

// ── relocations ───────────────────────────────────────────────────────────

/// Apply base relocations in-place. `delta` = new_base − original_image_base.
pub fn apply_relocations(image: &mut [u8], original_base: u64, new_base: u64) {
    let delta = new_base.wrapping_sub(original_base);
    if delta == 0 { return; }

    let opt = match opt_off(image) { Some(o) => o, None => return };
    // DataDirectory[5] = base reloc (at opt+0x98 in PE64)
    let reloc_rva  = match u32_at(image, opt + 0x98) { Some(v) => v as usize, None => return };
    let reloc_size = match u32_at(image, opt + 0x9C) { Some(v) => v, None => return };
    if reloc_rva == 0 || reloc_size == 0 { return; }

    let mut pos = reloc_rva;
    let end = reloc_rva + reloc_size as usize;

    while pos + 8 <= end && pos < image.len() {
        let page_rva = match u32_at(image, pos) { Some(v) => v as usize, None => break };
        let blk_size = match u32_at(image, pos + 4) { Some(v) => v as usize, None => break };
        if blk_size < 8 || pos + blk_size > end { break; }

        let entries = (blk_size - 8) / 2;
        for i in 0..entries {
            let entry = match u16_at(image, pos + 8 + i * 2) { Some(v) => v, None => break };
            let kind   = (entry >> 12) as u32;
            let offset = (entry & 0x0FFF) as usize;
            const DIR64: u32 = 10; // IMAGE_REL_BASED_DIR64
            if kind != DIR64 { continue; }
            let target = page_rva + offset;
            if target + 8 > image.len() { continue; }
            let old = u64::from_le_bytes(image[target..target+8].try_into().unwrap());
            let new = old.wrapping_add(delta);
            image[target..target+8].copy_from_slice(&new.to_le_bytes());
        }
        pos += blk_size;
    }
}

// ── imports ───────────────────────────────────────────────────────────────

pub struct Import<'a> {
    pub module_name: &'a str,       // e.g. "ntoskrnl.exe"
    pub thunk_va:    u32,           // IAT entry VA in image (to patch with resolved addr)
    pub fn_name:     &'a str,       // e.g. "ExAllocatePoolWithTag"
}

/// Iterate over all imports in `image`. `image` must be the flat VirtualAddress-mapped buffer.
pub fn imports<'a>(image: &'a [u8]) -> Vec<Import<'a>> {
    let opt = match opt_off(image) { Some(o) => o, None => return vec![] };
    // DataDirectory[1] = import (at opt+0x78 in PE64)
    let import_rva = match u32_at(image, opt + 0x78) { Some(v) => v as usize, None => return vec![] };
    if import_rva == 0 { return vec![]; }

    let mut result = Vec::new();
    let mut desc_off = import_rva;

    loop {
        // IMAGE_IMPORT_DESCRIPTOR is 20 bytes.
        let first_thunk = match u32_at(image, desc_off + 16) { Some(v) => v, None => break };
        if first_thunk == 0 { break; }

        let orig_first_thunk = match u32_at(image, desc_off) { Some(v) => v as usize, None => break };
        let name_rva         = match u32_at(image, desc_off + 12) { Some(v) => v as usize, None => break };

        let mod_name = {
            let slice = match image.get(name_rva..) { Some(s) => s, None => break };
            let end   = slice.iter().position(|&b| b == 0).unwrap_or(0);
            match std::str::from_utf8(&slice[..end]) { Ok(s) => s, Err(_) => break }
        };

        // Walk OriginalFirstThunk (hint/name table).
        let mut thunk_off  = orig_first_thunk;
        let mut iat_off    = first_thunk as usize;

        loop {
            let hint_name_rva = match u64_at(image, thunk_off) { Some(v) => v, None => break };
            if hint_name_rva == 0 { break; }
            // skip ordinal imports (bit 63 set)
            if hint_name_rva & (1u64 << 63) != 0 { thunk_off += 8; iat_off += 8; continue; }

            let hn_off = hint_name_rva as usize + 2; // skip Hint (u16)
            let fn_slice = match image.get(hn_off..) { Some(s) => s, None => break };
            let fn_end   = fn_slice.iter().position(|&b| b == 0).unwrap_or(0);
            let fn_name  = match std::str::from_utf8(&fn_slice[..fn_end]) { Ok(s) => s, Err(_) => break };

            result.push(Import {
                module_name: mod_name,
                thunk_va:    iat_off as u32, // VA in image where resolved addr goes
                fn_name,
            });

            thunk_off += 8;
            iat_off   += 8;
        }

        desc_off += 20;
    }

    result
}

/// Patch IAT entry `thunk_va` in `image` with the resolved kernel function address.
pub fn patch_iat(image: &mut [u8], thunk_va: usize, resolved_addr: u64) -> bool {
    if thunk_va + 8 > image.len() { return false; }
    image[thunk_va..thunk_va+8].copy_from_slice(&resolved_addr.to_le_bytes());
    true
}

// ── exception directory (for RtlAddFunctionTable) ────────────────────────

/// DataDirectory[3] = Exception (.pdata): `(rva, size)` of the RUNTIME_FUNCTION
/// array. The mapped driver's SEH (__try/__except in KfmCopy) only becomes
/// findable by the kernel exception unwinder once this table is registered.
pub fn exception_directory(data: &[u8]) -> Option<(u32, u32)> {
    let opt = opt_off(data)?;
    let rva  = u32_at(data, opt + 0x70 + 3 * 8)?;
    let size = u32_at(data, opt + 0x70 + 3 * 8 + 4)?;
    if rva == 0 || size == 0 { return None; }
    Some((rva, size))
}

// ── stack-cookie fix ──────────────────────────────────────────────────────

/// Randomise the security cookie in the image's LoadConfig directory.
/// Mirrors kdmapper's FixSecurityCookie; no-ops if no LoadConfig or no cookie.
pub fn fix_security_cookie(image: &mut [u8], kernel_base: u64) {
    let opt = match opt_off(image) { Some(o) => o, None => return };
    // DataDirectory[10] = LoadConfig (at opt+0xC0 in PE64)
    let lc_rva = match u32_at(image, opt + 0xC0) { Some(v) => v as usize, None => return };
    if lc_rva == 0 { return; }
    // SecurityCookie is at offset 0x58 in IMAGE_LOAD_CONFIG_DIRECTORY64.
    let cookie_rva_off = lc_rva + 0x58;
    let cookie_rva     = match u64_at(image, cookie_rva_off) { Some(v) => v, None => return };
    if cookie_rva == 0 { return; }

    // The cookie field holds the kernel VA after relocation; subtract kernel_base to get RVA.
    let cookie_image_off = match cookie_rva.checked_sub(kernel_base) {
        Some(off) => off as usize,
        None      => return,
    };
    if cookie_image_off + 8 > image.len() { return; }

    let current = u64_at(image, cookie_image_off).unwrap_or(0);
    if current != 0x2B992DDFA232 { return; } // not default → already set

    use std::time::{SystemTime, UNIX_EPOCH};
    let seed = SystemTime::now().duration_since(UNIX_EPOCH).map(|d| d.as_nanos() as u64).unwrap_or(0xDEAD);
    // Security cookie must be 48-bit (bits 48-63 = 0). __security_check_cookie does
    // `rol rcx,16; test cx,0xFFFF; jne FAST_FAIL` — non-zero high word triggers a
    // kernel FAST_FAIL right after IofCompleteRequest, which looks like a hang to
    // user mode (IRP event set, but thread never scheduled before BSOD).
    let new_cookie = ((0x2B992DDFA232u64 ^ seed) | 1) & 0x0000_FFFF_FFFF_FFFF;
    image[cookie_image_off..cookie_image_off+8].copy_from_slice(&new_cookie.to_le_bytes());
}
