//! Kernel-driver transport (real prod path).
//!
//! Opens `\\.\KoffeeMem` (the driver's user-visible device), sends IOCTLs
//! for read/write/module-base. The driver itself lives in `../driver/` and
//! is loaded via a BYOVD manual mapper before this ever runs.
//!
//! IOCTL codes + struct layouts MUST match `../../driver/src/ioctl.h`
//! byte-for-byte; both sides `#[repr(C)]` / `#pragma pack`.
//!
//! Currently a skeleton -- returns Unimplemented until the driver ships.
//! The trait signatures + IOCTL layouts are stable so feature code can be
//! written against this without waiting on the driver build.

use super::Transport;
use crate::ioctl;
use std::io;

pub struct DriverTransport {
    pid: u32,
    // once wired: HANDLE from CreateFileA("\\\\.\\KoffeeMem", ...)
    // handle: HANDLE,
}

impl Transport for DriverTransport {
    fn open(pid: u32) -> io::Result<Self> {
        // TODO(driver): CreateFileA("\\\\.\\KoffeeMem", GENERIC_READ|GENERIC_WRITE, ...)
        // TODO(driver): DeviceIoControl(IOCTL_KFM_ATTACH, &pid, sizeof(pid), NULL, 0, ...)
        //   -- tells the driver which process future read/write IOCTLs target
        let _ = pid;
        let _ = ioctl::IOCTL_KFM_ATTACH;   // silence dead-code warning until wired
        Err(unimplemented("driver transport"))
    }

    fn read(&mut self, addr: usize, buf: &mut [u8]) -> io::Result<()> {
        // TODO(driver): DeviceIoControl(IOCTL_KFM_READ, &KfmReadIn{pid, addr, size}, ..., buf, ..., ...)
        let _ = (addr, buf, ioctl::IOCTL_KFM_READ);
        Err(unimplemented("driver read"))
    }

    fn write(&mut self, addr: usize, buf: &[u8]) -> io::Result<()> {
        // TODO(driver): DeviceIoControl(IOCTL_KFM_WRITE, &KfmWriteIn{pid, addr, size, data...}, ..., NULL, ...)
        let _ = (addr, buf, ioctl::IOCTL_KFM_WRITE);
        Err(unimplemented("driver write"))
    }

    fn module_base(&mut self, pid: u32, name: &str) -> io::Result<usize> {
        // TODO(driver): DeviceIoControl(IOCTL_KFM_MODULE_BASE, &KfmModuleIn{pid, name}, ..., &base, ...)
        let _ = (pid, name, ioctl::IOCTL_KFM_MODULE_BASE);
        Err(unimplemented("driver module_base"))
    }
}

fn unimplemented(what: &str) -> io::Error {
    io::Error::new(
        io::ErrorKind::Unsupported,
        format!("driver transport not built yet ({}) -- build with default features for the mock", what),
    )
}
