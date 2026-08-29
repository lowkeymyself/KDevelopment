#include "mem.h"
#include "log.h"

#include <windows.h>
#include <tlhelp32.h>
#include <psapi.h>

#include <cstring>
#include <string>

namespace koffee::mem {

namespace {

constexpr const char* kRobloxExe = "RobloxPlayerBeta.exe";

std::uint32_t find_pid_by_name(const char* exe_name) {
    HANDLE snap = ::CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (snap == INVALID_HANDLE_VALUE) return 0;

    PROCESSENTRY32W e{};
    e.dwSize = sizeof(e);

    // Widen the ASCII compare so we can lstrcmpiW on ExeFile (which is wchar_t).
    std::wstring wname;
    for (const char* p = exe_name; *p; ++p) wname.push_back(static_cast<wchar_t>(*p));

    std::uint32_t pid = 0;
    if (::Process32FirstW(snap, &e)) {
        do {
            if (::lstrcmpiW(wname.c_str(), e.szExeFile) == 0) {
                pid = e.th32ProcessID;
                break;
            }
        } while (::Process32NextW(snap, &e));
    }

    ::CloseHandle(snap);
    return pid;
}

// Resolve module base via EnumProcessModulesEx + GetModuleBaseName. Faster
// than Toolhelp module enumeration and doesn't race with LoadLibrary as
// hard. Case-insensitive compare on the module basename.
std::uint64_t find_module_base_ex(HANDLE proc, std::string_view name) {
    HMODULE mods[512];
    DWORD needed = 0;
    if (!::EnumProcessModulesEx(proc, mods, sizeof(mods), &needed,
                                LIST_MODULES_ALL)) {
        return 0;
    }
    const std::size_t count = needed / sizeof(HMODULE);
    if (count > (sizeof(mods) / sizeof(HMODULE))) return 0;

    for (std::size_t i = 0; i < count; ++i) {
        char base_name[MAX_PATH]{};
        DWORD n = ::GetModuleBaseNameA(proc, mods[i], base_name,
                                       sizeof(base_name));
        if (!n) continue;
        std::string_view bn{base_name, n};
        if (bn.size() != name.size()) continue;
        // Case-insensitive compare.
        bool match = true;
        for (std::size_t k = 0; k < bn.size(); ++k) {
            const char a = static_cast<char>(std::tolower(bn[k]));
            const char b = static_cast<char>(std::tolower(name[k]));
            if (a != b) { match = false; break; }
        }
        if (match) return reinterpret_cast<std::uint64_t>(mods[i]);
    }
    return 0;
}

}  // namespace

bool attach() {
    if (g_ctx.attached.load(std::memory_order_acquire) && g_ctx.handle) {
        // Idempotent -- return true if we already hold a live handle.
        DWORD exit_code = 0;
        if (::GetExitCodeProcess(g_ctx.handle, &exit_code)
            && exit_code == STILL_ACTIVE) {
            return true;
        }
        release();
    }

    const std::uint32_t pid = find_pid_by_name(kRobloxExe);
    if (!pid) return false;

    // Rights: r/w + query for VirtualQueryEx + op for VirtualAllocEx/Protect.
    // Ordered from least-privileged first — some AV soft-blocks ALL_ACCESS
    // requests but lets the narrower set through.
    constexpr DWORD desired =
        PROCESS_QUERY_INFORMATION |
        PROCESS_VM_READ |
        PROCESS_VM_WRITE |
        PROCESS_VM_OPERATION;

    HANDLE h = ::OpenProcess(desired, FALSE, pid);
    if (!h || h == INVALID_HANDLE_VALUE) {
        koffee::log_err("OpenProcess failed -- helper needs to run as admin");
        return false;
    }

    const std::uint64_t base = find_module_base_ex(h, kRobloxExe);
    if (!base) {
        ::CloseHandle(h);
        return false;
    }

    g_ctx.handle = h;
    g_ctx.pid = pid;
    g_ctx.module_base = base;
    g_ctx.attached.store(true, std::memory_order_release);
    return true;
}

void release() {
    g_ctx.attached.store(false, std::memory_order_release);
    if (g_ctx.handle && g_ctx.handle != INVALID_HANDLE_VALUE) {
        ::CloseHandle(g_ctx.handle);
    }
    g_ctx.handle = nullptr;
    g_ctx.pid = 0;
    g_ctx.module_base = 0;
}

std::uint64_t find_module(std::string_view name) {
    if (!g_ctx.attached.load(std::memory_order_acquire) || !g_ctx.handle) {
        return 0;
    }
    return find_module_base_ex(g_ctx.handle, name);
}

std::size_t read_bytes(std::uint64_t address, void* dst, std::size_t size) {
    if (!addr_ok(address) || !dst || !size) return 0;
    if (!g_ctx.attached.load(std::memory_order_relaxed) || !g_ctx.handle) return 0;

    SIZE_T got = 0;
    const BOOL ok = ::ReadProcessMemory(
        g_ctx.handle,
        reinterpret_cast<LPCVOID>(address),
        dst,
        size,
        &got);
    // Treat partial as failure -- the callers assume all-or-nothing.
    if (!ok || got != size) return 0;
    return got;
}

std::size_t write_bytes(std::uint64_t address, const void* src, std::size_t size) {
    if (!addr_ok(address) || !src || !size) return 0;
    if (!g_ctx.attached.load(std::memory_order_relaxed) || !g_ctx.handle) return 0;

    SIZE_T wrote = 0;
    const BOOL ok = ::WriteProcessMemory(
        g_ctx.handle,
        reinterpret_cast<LPVOID>(address),
        src,
        size,
        &wrote);
    if (!ok || wrote != size) return 0;
    return wrote;
}

}  // namespace koffee::mem
