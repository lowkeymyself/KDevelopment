// Silent-aim orchestrator: config + tick loop + target picker.
//
// koffee.lua tells this file the CONFIG via `POST /config` (enabled,
// wallbang, hit_part, gates). This file owns everything downstream:
//   * pick the best target from the current world snapshot
//   * ensure the raycast hook is installed if enabled
//   * push (target, camera, wallbang) to the hook every tick
//
// Runs on its own thread started at helper init. Reads shared config
// through a mutex-guarded singleton; the HTTP handler is the only writer.
#pragma once

#include <atomic>
#include <mutex>
#include <string>

#include "../vec.h"

namespace koffee::aim {

// Config schema (mirror of what koffee.lua sends). Keep field names in
// lock-step with the JSON keys in the /config route -- the JSON parser
// maps direct.
struct silent_config {
    bool         enabled       = false;
    bool         wallbang      = false;
    std::string  hit_part      = "Head";       // reserved for future part switching
    bool         team_check    = true;
    bool         health_check  = false;
    float        distance      = 1500.f;       // studs, world-space cap
    float        fov_radius    = 150.f;        // pixels around crosshair
    bool         fov_enabled   = false;
};

// Set once at helper startup; reads run lock-free.
struct silent_state {
    std::mutex     mtx;
    silent_config  cfg;                        // guarded by mtx
    std::atomic<bool> keepalive_recent{false};  // true if koffee.lua touched us < 5s ago
};

silent_state& state();

// Called from the HTTP /config handler. Replaces the whole config in one
// swap under the mutex.
void apply_config(const silent_config& cfg);

// Called from the HTTP /clear handler. Force disarm without changing the
// full config -- next /config tick from koffee.lua re-arms as needed.
void force_disarm();

// Called once at helper startup after koffee::mem::attach() (or attempt).
// Launches the internal tick thread. Idempotent.
void start();

// Called at helper shutdown (alpha3+). Currently the tick thread lives
// forever alongside the process.
void stop();

}  // namespace koffee::aim
