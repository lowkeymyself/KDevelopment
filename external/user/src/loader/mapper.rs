//! Manual PE mapper: alloc kernel pool → copy + fix image → resolve imports → call DriverEntry.
//!
//! Replicates kdmapper::MapDriver with AllocatePool mode (NonPagedPoolExecute).

use std::io;
use crate::loader::{kernel::get_kernel_module_address, pe, rtc::Rtc};

/// Map the driver bytes into the kernel.
///
/// Returns `(pool_va, entry_va)` on success:
/// - `pool_va`  = allocated kernel pool base (what was actually given by ExAllocatePoolWithTag)
/// - `entry_va` = kernel VA of DriverEntry (pool_va + rva)
pub fn map_driver(
    rtc: &mut Rtc,
    ntos_base: u64,
    sys_bytes: &[u8],
) -> io::Result<(u64, u64)> {
    // 1. Parse headers.
    let img_size = pe::size_of_image(sys_bytes)
        .ok_or_else(|| io::Error::new(io::ErrorKind::InvalidData, "invalid SizeOfImage"))?;
    let entry_rva = pe::address_of_entry_point(sys_bytes)
        .ok_or_else(|| io::Error::new(io::ErrorKind::InvalidData, "invalid AddressOfEntryPoint"))?;
    let orig_base = pe::image_base(sys_bytes)
        .ok_or_else(|| io::Error::new(io::ErrorKind::InvalidData, "invalid ImageBase"))?;

    println!("[+] mapper: SizeOfImage=0x{:X} EntryRVA=0x{:X} OrigBase=0x{:X}",
        img_size, entry_rva, orig_base);

    // 2. Allocate kernel pool (NonPagedPoolExecute = 0).
    let pool_va = rtc.alloc_pool(ntos_base, img_size as u64)?;
    println!("[+] mapper: pool allocated at 0x{:X}", pool_va);
    // The carrier only touches VAs inside registered windows; allow the pool.
    rtc.add_window(pool_va, img_size as u64);

    // 3. Build a flat local image (headers + sections at their VAs).
    let mut image = pe::copy_to_image(sys_bytes)
        .ok_or_else(|| io::Error::new(io::ErrorKind::InvalidData, "copy_to_image failed"))?;

    // 4. Apply base relocations (delta = pool_va − orig_base).
    pe::apply_relocations(&mut image, orig_base, pool_va);

    // 5. Fix stack cookie.
    pe::fix_security_cookie(&mut image, pool_va);

    // 6. Resolve imports.
    //    KoffeeMem.sys only imports from ntoskrnl.exe; we re-use ntos_base.
    let imports = pe::imports(&image);
    // Collect patches first (immutable borrow on `image` ends before mutable patch).
    let patches: Vec<(usize, u64)> = {
        let mut v = Vec::new();
        for imp in &imports {
            // Try the module named in the import table; fall back to ntoskrnl.
            let mod_base_opt = if imp.module_name.eq_ignore_ascii_case("ntoskrnl.exe") {
                Some(ntos_base)
            } else {
                let b = get_kernel_module_address(imp.module_name);
                b.or(Some(ntos_base)) // fallback
            };
            let Some(mod_base) = mod_base_opt else {
                return Err(io::Error::new(io::ErrorKind::NotFound,
                    format!("kernel module not loaded: {}", imp.module_name)));
            };
            let fn_va = rtc.get_module_export(mod_base, imp.fn_name)
                .or_else(|| rtc.get_module_export(ntos_base, imp.fn_name))
                .ok_or_else(|| io::Error::new(io::ErrorKind::NotFound,
                    format!("export not found: {} ({})", imp.fn_name, imp.module_name)))?;
            v.push((imp.thunk_va as usize, fn_va));
        }
        v
    };
    for (thunk_va, fn_va) in patches {
        println!("[dbg] mapper: import IAT@0x{:X} → kernel fn at 0x{:X}", thunk_va, fn_va);
        pe::patch_iat(&mut image, thunk_va, fn_va);
    }

    // 7. Write fixed image to kernel pool.
    rtc.write_memory(pool_va, &image)?;
    println!("[+] mapper: image written to kernel pool");

    // 8. Verify pool content at DriverEntry offset.
    let entry_rva_usize = entry_rva as usize;
    if entry_rva_usize + 16 <= image.len() {
        println!("[dbg] mapper: local DriverEntry bytes (first 16): {:02X?}",
            &image[entry_rva_usize..entry_rva_usize+16]);
    }
    let entry_va = pool_va + entry_rva as u64;
    let mut readback = [0u8; 16];
    if rtc.read_memory(entry_va, &mut readback).is_ok() {
        println!("[dbg] mapper: kernel pool DriverEntry bytes (first 16): {:02X?}", &readback);
        if readback[..16] == image[entry_rva_usize..entry_rva_usize+16] {
            println!("[dbg] mapper: pool write verified OK");
        } else {
            println!("[dbg] mapper: POOL WRITE MISMATCH -- bytes differ!");
        }
    } else {
        println!("[dbg] mapper: read-back of pool failed");
    }
    Ok((pool_va, entry_va))
}
