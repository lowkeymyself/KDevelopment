//! Kernel-driver transport (real prod path).
//!
//! Opens `\\.\KoffeeMem` (the driver's user-visible device), sends IOCTLs
//! for read/write/module-base. The driver itself lives in `../driver/` and
//! is loaded via a BYOVD manual mapper before this ever runs.
//!
//! IOCTL codes + struct layouts MUST match `../../driver/src/ioctl.h`
//! byte-for-byte; both sides `#[repr(C)]` / `#pragma pack`.
//!
//! Failure modes surface as `io::Error`:
//!   - Driver not loaded / device path not present -> NotFound at `open()`.
//!   - Handle stale (Roblox restarted) -> subsequent IOCTLs return the OS
//!     error; the caller is expected to `open()` again.
//!   - Read/write past a valid page -> the driver's SEH catches it and we
//!     get a mapped NTSTATUS (STATUS_ACCESS_VIOLATION etc).
//!
//! Concurrency: NOT `Sync`. Every hot-path caller owns their own transport,
//! or wraps this in a mutex. The underlying HANDLE is safe to reuse from a
//! single thread but Windows DeviceIoControl serializes per-handle anyway.

use super::Transport;
use crate::ioctl;
use std::io;
use std::ptr;
use windows_sys::Win32::Foundation::{CloseHandle, GetLastError, HANDLE, INVALID_HANDLE_VALUE};
use windows_sys::Win32::Storage::FileSystem::{
    CreateFileA, DefineDosDeviceW, DDD_RAW_TARGET_PATH,
    FILE_ATTRIBUTE_NORMAL, FILE_SHARE_READ, FILE_SHARE_WRITE, OPEN_EXISTING,
};
use windows_sys::Win32::System::IO::DeviceIoControl;

// GENERIC_READ / GENERIC_WRITE aren't exposed through the FileSystem feature set
// consistently -- declare them locally. Values match wingdi.h / winnt.h.
const GENERIC_READ: u32 = 0x8000_0000;
const GENERIC_WRITE: u32 = 0x4000_0000;

// User-visible device path. Must match the KFM_SYMLINK_NAME in driver.c
// (`\??\KoffeeMem` maps to `\\.\KoffeeMem` from userland).
const DEVICE_PATH: &[u8] = b"\\\\.\\KoffeeMem\0";

pub struct DriverTransport {
    pid: u32,
    handle: HANDLE,
}

// SAFETY: HANDLE is a bare pointer type in windows-sys but the underlying
// kernel handle is thread-safe for DeviceIoControl (per-call serialization).
// We still don't impl `Sync` because feature code owns one per thread.
unsafe impl Send for DriverTransport {}

impl DriverTransport {
    /// Raw IOCTL round-trip. Returns bytes-out written into the output slice
    /// (or 0 if the IOCTL has no output). Any nonzero NTSTATUS becomes an
    /// `io::Error` carrying `GetLastError()` for the userland caller.
    fn ioctl(&self, code: u32, input: &[u8], output: &mut [u8]) -> io::Result<u32> {
        let mut bytes_returned: u32 = 0;
        let ok = unsafe {
            DeviceIoControl(
                self.handle,
                code,
                if input.is_empty() { ptr::null() } else { input.as_ptr() as *const _ },
                input.len() as u32,
                if output.is_empty() { ptr::null_mut() } else { output.as_mut_ptr() as *mut _ },
                output.len() as u32,
                &mut bytes_returned,
                ptr::null_mut(),
            )
        };
        if ok == 0 {
            let err = unsafe { GetLastError() };
            return Err(io::Error::from_raw_os_error(err as i32));
        }
        Ok(bytes_returned)
    }
}

impl Drop for DriverTransport {
    fn drop(&mut self) {
        if !self.handle.is_null() && self.handle != INVALID_HANDLE_VALUE {
            unsafe { CloseHandle(self.handle) };
        }
    }
}

impl Transport for DriverTransport {
    fn open(pid: u32) -> io::Result<Self> {
        // If the kernel driver's IoCreateSymbolicLink failed from within the
        // IoCreateDriver init callback (known Win11 context restriction), the
        // device object exists at \Device\KoffeeMem but \\.\KoffeeMem won't
        // resolve. DefineDosDeviceW creates a session-local mapping that makes
        // CreateFileA("\\.\KoffeeMem") work regardless of the kernel symlink.
        // DDD_RAW_TARGET_PATH(1): treat target as raw NT path, no conversion.
        // Ignore failure (e.g., name already exists / insufficient rights).
        let dev_name_w: Vec<u16> = "KoffeeMem\0".encode_utf16().collect();
        let tgt_path_w: Vec<u16> = "\\Device\\KoffeeMem\0".encode_utf16().collect();
        println!("[dbg] transport::open: calling DefineDosDeviceW");
        unsafe { DefineDosDeviceW(DDD_RAW_TARGET_PATH, dev_name_w.as_ptr(), tgt_path_w.as_ptr()) };

        println!("[dbg] transport::open: calling CreateFileA on device");
        let handle = unsafe {
            CreateFileA(
                DEVICE_PATH.as_ptr(),
                GENERIC_READ | GENERIC_WRITE,
                FILE_SHARE_READ | FILE_SHARE_WRITE,
                ptr::null(),
                OPEN_EXISTING,
                FILE_ATTRIBUTE_NORMAL,
                ptr::null_mut(),
            )
        };
        if handle == INVALID_HANDLE_VALUE || handle.is_null() {
            let err = unsafe { GetLastError() };
            return Err(io::Error::new(
                io::ErrorKind::NotFound,
                format!(
                    "CreateFile({}) failed (os error {}). Driver not loaded?",
                    String::from_utf8_lossy(&DEVICE_PATH[..DEVICE_PATH.len() - 1]),
                    err
                ),
            ));
        }
        println!("[dbg] transport::open: CreateFileA OK, handle={:?}", handle);

        let this = DriverTransport { pid, handle };

        // Bind the driver-side per-handle context to this PID. Every future
        // read/write IOCTL implicitly targets it -- no per-call PID plumbing.
        println!("[dbg] transport::open: sending IOCTL_KFM_ATTACH for pid={}", pid);
        let attach = ioctl::KfmAttachIn { pid };
        let input = unsafe {
            std::slice::from_raw_parts(
                &attach as *const _ as *const u8,
                std::mem::size_of::<ioctl::KfmAttachIn>(),
            )
        };
        this.ioctl(ioctl::IOCTL_KFM_ATTACH, input, &mut [])?;
        println!("[dbg] transport::open: ATTACH OK");
        Ok(this)
    }

    fn read(&mut self, addr: usize, buf: &mut [u8]) -> io::Result<()> {
        if buf.is_empty() {
            return Ok(());
        }
        if buf.len() > u32::MAX as usize {
            return Err(io::Error::new(io::ErrorKind::InvalidInput, "read too large"));
        }
        let req = ioctl::KfmReadIn {
            addr: addr as u64,
            size: buf.len() as u32,
            _pad: 0,
        };
        let input = unsafe {
            std::slice::from_raw_parts(
                &req as *const _ as *const u8,
                std::mem::size_of::<ioctl::KfmReadIn>(),
            )
        };
        let got = self.ioctl(ioctl::IOCTL_KFM_READ, input, buf)?;
        if (got as usize) != buf.len() {
            return Err(io::Error::new(
                io::ErrorKind::UnexpectedEof,
                format!("short read: wanted {}, got {}", buf.len(), got),
            ));
        }
        Ok(())
    }

    fn write(&mut self, addr: usize, buf: &[u8]) -> io::Result<()> {
        if buf.is_empty() {
            return Ok(());
        }
        if buf.len() > u32::MAX as usize {
            return Err(io::Error::new(io::ErrorKind::InvalidInput, "write too large"));
        }
        // Layout: [KfmWriteIn header][payload bytes]. Single buffered input.
        let header = ioctl::KfmWriteIn {
            addr: addr as u64,
            size: buf.len() as u32,
            _pad: 0,
        };
        let mut input = Vec::with_capacity(std::mem::size_of::<ioctl::KfmWriteIn>() + buf.len());
        let hdr_bytes = unsafe {
            std::slice::from_raw_parts(
                &header as *const _ as *const u8,
                std::mem::size_of::<ioctl::KfmWriteIn>(),
            )
        };
        input.extend_from_slice(hdr_bytes);
        input.extend_from_slice(buf);
        self.ioctl(ioctl::IOCTL_KFM_WRITE, &input, &mut [])?;
        Ok(())
    }

    fn module_base(&mut self, _pid: u32, name: &str) -> io::Result<usize> {
        // Driver keeps the attached PID in FsContext; ignore the caller's pid
        // arg. Name is truncated to 63 bytes + NUL to fit the fixed buffer.
        let name_bytes = name.as_bytes();
        if name_bytes.len() > 63 {
            return Err(io::Error::new(
                io::ErrorKind::InvalidInput,
                "module name too long (max 63 bytes)",
            ));
        }
        let mut req = ioctl::KfmModuleIn { name: [0u8; 64] };
        req.name[..name_bytes.len()].copy_from_slice(name_bytes);

        let input = unsafe {
            std::slice::from_raw_parts(
                &req as *const _ as *const u8,
                std::mem::size_of::<ioctl::KfmModuleIn>(),
            )
        };
        let mut out_bytes = [0u8; std::mem::size_of::<ioctl::KfmModuleOut>()];
        let got = self.ioctl(ioctl::IOCTL_KFM_MODULE_BASE, input, &mut out_bytes)?;
        if (got as usize) != std::mem::size_of::<ioctl::KfmModuleOut>() {
            return Err(io::Error::new(
                io::ErrorKind::UnexpectedEof,
                "driver returned short KfmModuleOut",
            ));
        }
        let out: ioctl::KfmModuleOut = unsafe { std::ptr::read_unaligned(out_bytes.as_ptr() as *const _) };
        if out.base == 0 {
            return Err(io::Error::new(
                io::ErrorKind::NotFound,
                format!("module '{}' not loaded in pid {}", name, self.pid),
            ));
        }
        Ok(out.base as usize)
    }
}
