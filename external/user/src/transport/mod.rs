//! Memory transport abstraction.
//!
//! Every feature reads/writes through this trait -- never a raw syscall or
//! `DeviceIoControl`. That's how we swap implementations (mock for host
//! dev, kernel-driver IOCTL for prod, hypothetical EV-signed driver later)
//! without touching a single feature file.
//!
//! Design contract:
//!   - `open()` acquires whatever handle/context the impl needs and holds it.
//!     Cheap subsequent reads should NOT reacquire.
//!   - `read()` / `write()` return `Err` on ANY failure -- never silently
//!     return zeros or garbage. Features rely on this to detect a stale
//!     handle (roblox restarted, driver crashed, etc.) and re-open.
//!   - `module_base()` looks up a loaded module's base address in the target
//!     process. For the kernel transport this walks PEB from kernel context;
//!     for mock it fabricates.

pub mod mock;
pub mod driver;

use std::io;

pub trait Transport: Sized {
    /// Attach to the target process. Called once at startup + on
    /// reconnect (roblox restart).
    fn open(pid: u32) -> io::Result<Self>;

    /// Read `buf.len()` bytes from the target's address space at `addr`.
    /// Fills `buf` on success; returns Err on any partial/failed read.
    fn read(&mut self, addr: usize, buf: &mut [u8]) -> io::Result<()>;

    /// Write `buf` to the target's address space at `addr`.
    fn write(&mut self, addr: usize, buf: &[u8]) -> io::Result<()>;

    /// Look up the base address of a named module (e.g. "RobloxPlayerBeta.exe")
    /// loaded in the target process. Case-insensitive match on the module
    /// name, ignoring path.
    fn module_base(&mut self, pid: u32, name: &str) -> io::Result<usize>;

    // -- typed helpers, default impls in terms of read/write --------------

    fn read_t<T: Copy>(&mut self, addr: usize) -> io::Result<T> {
        let mut v = std::mem::MaybeUninit::<T>::uninit();
        // SAFETY: MaybeUninit gives us a valid byte-buffer view; we fill
        // every byte via read() before assume_init. T: Copy rules out drop
        // hazards.
        let slice = unsafe {
            std::slice::from_raw_parts_mut(
                v.as_mut_ptr() as *mut u8,
                std::mem::size_of::<T>(),
            )
        };
        self.read(addr, slice)?;
        Ok(unsafe { v.assume_init() })
    }

    fn write_t<T: Copy>(&mut self, addr: usize, value: &T) -> io::Result<()> {
        let slice = unsafe {
            std::slice::from_raw_parts(
                value as *const T as *const u8,
                std::mem::size_of::<T>(),
            )
        };
        self.write(addr, slice)
    }
}
