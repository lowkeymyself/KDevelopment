// KoffeeHelper.exe -- entry point.
//
// Alpha2 responsibilities (this file):
//   1. Log a startup banner.
//   2. Kick the silent-aim tick thread (owns attach + hook install/remove
//      + target-write loop).
//   3. Bind the HTTP server on 127.0.0.1:27374. Blocks the main thread on
//      the accept loop until unrecoverable failure.
//
// Alpha3 additions (planned, not implemented here):
//   * Spawn KoffeeLoader.exe as a child, wait for "READY" on its stdout,
//     bail with a clear error if it prints "LOAD_FAIL: ..." instead.
//   * Swap koffee::mem's ReadProcessMemory/WriteProcessMemory calls for
//     DeviceIoControl against the koffee driver's r/w IOCTLs (path A
//     completed -- no more OpenProcess handle needed for raw r/w).

#include "http.h"
#include "log.h"
#include "aim/silentaim.h"

#include <cstdint>
#include <cstdlib>

namespace {

// Fixed, hardcoded. koffee.lua knows this too -- do not change without
// bumping both sides in lock-step and noting it in the session log.
constexpr std::uint16_t kBridgePort = 27374;

}  // namespace

int main() {
    koffee::log("KoffeeHelper starting (v0.3.0-alpha2)");
    koffee::log("silent aim: raycast inline hook + native target picker");
    koffee::log("bridge: 127.0.0.1:27374 (GET /health /status, POST /config /clear)");

    // Start the silent-aim tick thread first. It self-attaches to Roblox
    // on its own cadence -- helper doesn't block startup on Roblox running.
    koffee::aim::start();

    // Blocks. Returns only on unrecoverable bind/listen failure.
    const int rc = koffee::http::serve(kBridgePort);

    // Best-effort disarm on unusual exit.
    koffee::aim::stop();

    if (rc != 0) {
        koffee::log_err("http server failed to start");
        return EXIT_FAILURE;
    }
    return EXIT_SUCCESS;
}
