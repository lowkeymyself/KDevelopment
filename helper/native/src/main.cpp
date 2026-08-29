// KoffeeHelper.exe — entry point.
//
// Alpha1 responsibilities (this file):
//   1. Log a startup banner so tail-users know the exe reached main().
//   2. Bind the HTTP server on the fixed local port (27374).
//   3. Serve forever.
//
// Alpha2 additions (planned, not implemented here):
//   * Spawn KoffeeLoader.exe as a child, wait for "READY" on its stdout,
//     bail with a clear error if it prints "LOAD_FAIL: ..." instead.
//   * Open the koffee driver device (\\.\<koffee device>) via CreateFileW +
//     wrap DeviceIoControl in a thin r/w primitive.
//   * Silent aim + wallbang execution loop (raycast inline hook on Roblox's
//     RaycastBoundFn — semun-shape, koffee brand, koffee driver r/w).
//   * X-Koffee-Key auth on privileged routes (POST /config, POST /clear).

#include "http.h"
#include "log.h"

#include <cstdint>
#include <cstdlib>

namespace {

// Fixed, hardcoded. koffee.lua knows this too — do not change without
// bumping both sides in lock-step and noting it in the session log.
constexpr std::uint16_t kBridgePort = 27374;

}  // namespace

int main() {
    koffee::log("KoffeeHelper starting (v0.3.0-alpha1 skeleton)");
    koffee::log("alpha1 scope: /health responds; no driver, no silent aim yet");

    // Blocking. Returns only on unrecoverable bind/listen failure — accept()
    // loops forever in alpha1 (see the alpha2 note in http.cpp about shutdown).
    const int rc = koffee::http::serve(kBridgePort);

    if (rc != 0) {
        koffee::log_err("http server failed to start");
        return EXIT_FAILURE;
    }
    return EXIT_SUCCESS;
}
