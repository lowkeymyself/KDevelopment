//! IOCTL codes + struct layouts shared with the kernel driver.
//!
//! These MUST match `../../driver/src/ioctl.h` byte-for-byte. When adding a
//! new IOCTL, add it here AND in the header, run a build in the VM, verify
//! the codes match. Struct layouts are `#[repr(C)]` on this side and
//! `#pragma pack(push, 1)` on the C side -- no padding surprises.
//!
//! CTL_CODE(DeviceType, Function, Method, Access) formula:
//!   (DeviceType << 16) | (Access << 14) | (Function << 2) | Method
//!
//! We use FILE_DEVICE_UNKNOWN (0x22), METHOD_BUFFERED (0), FILE_ANY_ACCESS (0).

const FILE_DEVICE_UNKNOWN: u32 = 0x0000_0022;
const METHOD_BUFFERED: u32 = 0;
const FILE_ANY_ACCESS: u32 = 0;

const fn ctl_code(function: u32) -> u32 {
    (FILE_DEVICE_UNKNOWN << 16) | (FILE_ANY_ACCESS << 14) | (function << 2) | METHOD_BUFFERED
}

/// Bind driver to a target PID. Subsequent read/write IOCTLs use this PID.
pub const IOCTL_KFM_ATTACH: u32 = ctl_code(0x800);
/// Read N bytes from the attached process at address A.
pub const IOCTL_KFM_READ: u32 = ctl_code(0x801);
/// Write N bytes to the attached process at address A.
pub const IOCTL_KFM_WRITE: u32 = ctl_code(0x802);
/// Return the base address of a loaded module by name in the attached process.
pub const IOCTL_KFM_MODULE_BASE: u32 = ctl_code(0x803);

// -- payloads. keep tiny + fixed-layout. ------------------------------------

#[repr(C)]
#[derive(Copy, Clone)]
pub struct KfmAttachIn {
    pub pid: u32,
}

#[repr(C)]
#[derive(Copy, Clone)]
pub struct KfmReadIn {
    pub addr: u64,
    pub size: u32,
    pub _pad: u32,
}
// output is just `size` bytes of raw data.

#[repr(C)]
#[derive(Copy, Clone)]
pub struct KfmWriteIn {
    pub addr: u64,
    pub size: u32,
    pub _pad: u32,
    // followed by `size` bytes of raw data in the same input buffer.
}

/// Module-base lookup input: fixed-length ASCII name buffer to avoid
/// variable-length hazards in the shared struct.
#[repr(C)]
#[derive(Copy, Clone)]
pub struct KfmModuleIn {
    pub name: [u8; 64],   // ASCII, NUL-terminated, case-insensitive match on the driver side
}

#[repr(C)]
#[derive(Copy, Clone)]
pub struct KfmModuleOut {
    pub base: u64,
    pub size: u64,
}
