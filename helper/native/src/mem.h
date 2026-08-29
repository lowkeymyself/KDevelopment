// Memory primitive for the helper.
//
// Alpha2: user-mode `OpenProcess` + `ReadProcessMemory` / `WriteProcessMemory`.
// Path A per the alpha2 plan — same UD ceiling as semun (minus its direct-
// syscall stubs), acceptable while we prove the wire end-to-end.
//
// Alpha3 (planned): swap the r/w implementation for a shim over the koffee
// kernel driver's DeviceIoControl surface. The `koffee::mem` public API
// stays the same so the aim/hook code doesn't move. The `OpenProcess` handle
// is still opened for `VirtualAllocEx / Protect / Query / Free /
// FlushInstructionCache / SetProcessValidCallTargets` — those need a handle
// no matter what.
#pragma once

#include <windows.h>

#include <atomic>
#include <cstddef>
#include <cstdint>
#include <string>
#include <string_view>

namespace koffee::mem {

// Attach state — singleton. Rebound on Roblox restart via `attach()` re-call.
struct process_ctx {
    HANDLE        handle{nullptr};   // OpenProcess handle; needed for r/w AND the Win32 alloc/protect calls
    std::uint32_t pid{0};
    std::uint64_t module_base{0};    // RobloxPlayerBeta.exe base
    std::atomic<bool> attached{false};
};

inline process_ctx g_ctx{};

// Locate RobloxPlayerBeta.exe by name and OpenProcess with the rights needed
// for the aim pipeline. Returns false if the process isn't running or the
// handle acquisition failed. Idempotent — safe to call every loop tick.
bool attach();
void release();

// Resolve a module's base address inside the attached process. Case-
// insensitive name match; returns 0 on miss. Used by the raycast hook to
// find code-cave modules (winsta.dll, win32u.dll, ...).
std::uint64_t find_module(std::string_view name);

// Raw read/write. Small trailing return: number of bytes actually
// transferred (0 on failure). Callers should treat non-full transfers as
// failures too — Windows can succeed a partial read and we don't want that
// treated as OK.
std::size_t read_bytes(std::uint64_t address, void* dst, std::size_t size);
std::size_t write_bytes(std::uint64_t address, const void* src, std::size_t size);

// Typed convenience wrappers. Zero-initialised return on read failure — same
// semantics as semun's `read<T>`, which the raycast port assumes.
template <typename T>
T read(std::uint64_t address) {
    T v{};
    read_bytes(address, &v, sizeof(T));
    return v;
}

template <typename T>
bool write(std::uint64_t address, const T& value) {
    return write_bytes(address, &value, sizeof(T)) == sizeof(T);
}

// Bounds check used across the hook path. A user-space VA on x64 sits below
// the canonical high-half; anything above/below the practical usable range
// is a bad pointer and rejected before we deref.
inline bool addr_ok(std::uint64_t a) {
    return a >= 0x10000ull && a < 0x00007FFFFFFFFFFFull;
}

}  // namespace koffee::mem
