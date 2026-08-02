//! Mock transport -- host-side dev without the driver.
//!
//! Simulates a target process in-memory: a `HashMap<usize, u8>` backing store.
//! Every read hits the backing store; unwritten addresses return 0. Every
//! read/write is printed so we can see feature code exercise the transport.
//!
//! Used by default (no `real-driver` feature). Lets us build + run the whole
//! Rust userland on a dev host with no VM, no admin, no driver.

use super::Transport;
use std::collections::HashMap;
use std::io;

pub struct MockTransport {
    pid: u32,
    /// sparse byte store. reads of unwritten addresses return 0.
    mem: HashMap<usize, u8>,
    /// fabricated module bases so `module_base()` returns something plausible.
    modules: HashMap<String, usize>,
}

impl MockTransport {
    fn log(&self, op: &str, addr: usize, size: usize) {
        println!("[mock] {} pid={} addr=0x{:X} size={}", op, self.pid, addr, size);
    }
}

impl Transport for MockTransport {
    fn open(pid: u32) -> io::Result<Self> {
        let mut modules = HashMap::new();
        // fabricate a plausible base so module_base() succeeds. real driver
        // will return the actual EPROCESS ImageBase.
        modules.insert("robloxplayerbeta.exe".into(), 0x14000_0000);

        let mut mem = HashMap::new();
        // seed an "MZ" at the fabricated base so the proof-of-life check in
        // main.rs actually passes under the mock.
        mem.insert(0x14000_0000, b'M');
        mem.insert(0x14000_0001, b'Z');

        Ok(Self { pid, mem, modules })
    }

    fn read(&mut self, addr: usize, buf: &mut [u8]) -> io::Result<()> {
        self.log("read", addr, buf.len());
        for (i, byte) in buf.iter_mut().enumerate() {
            *byte = *self.mem.get(&(addr + i)).unwrap_or(&0);
        }
        Ok(())
    }

    fn write(&mut self, addr: usize, buf: &[u8]) -> io::Result<()> {
        self.log("write", addr, buf.len());
        for (i, &byte) in buf.iter().enumerate() {
            self.mem.insert(addr + i, byte);
        }
        Ok(())
    }

    fn module_base(&mut self, _pid: u32, name: &str) -> io::Result<usize> {
        let key = name.to_lowercase();
        self.modules.get(&key).copied().ok_or_else(|| {
            io::Error::new(io::ErrorKind::NotFound, format!("mock: no module '{}'", name))
        })
    }
}
