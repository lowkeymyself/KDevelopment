// Alpha1 HTTP server. Minimal WinSock-based, thread-per-connection.
// Handles ONE route: GET /health -> 200 JSON. Everything else -> 404.
//
// Alpha2 will replace this with cpp-httplib (or equivalent) and add:
//   * POST /config (koffee.lua pushes silent-aim config)
//   * POST /clear  (koffee.lua releases the target lock)
//   * GET  /status (helper self-report: driver attached? Roblox attached?)
//   * X-Koffee-Key header enforcement on all POSTs.
//
// The reason alpha1 is hand-rolled instead of pulling cpp-httplib is size --
// this file is ~150 LOC and audits at a glance, versus vendoring an 8K-line
// header before we've even proved the wire. Once we need real routing +
// JSON parsing, cpp-httplib lands and this file goes away.
#pragma once

#include <cstdint>

namespace koffee::http {

// Bind + accept-loop on `port` (bound to 127.0.0.1 -- localhost only). Blocks
// the calling thread until shutdown or unrecoverable bind failure. Returns 0
// on clean shutdown, non-zero on bind/listen failure.
int serve(std::uint16_t port);

}  // namespace koffee::http
