#include "silentaim.h"

#include "hook.h"
#include "../game.h"
#include "../log.h"
#include "../mem.h"

#include <atomic>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <optional>
#include <thread>

namespace koffee::aim {

namespace {

// Tick rate. 60 Hz -- fast enough to keep target fresh for headshots, slow
// enough that a full DataModel walk each tick is fine even with 30 players.
// Alpha3+: split the DataModel walk (200-500ms cadence) from the target
// write (per-tick) so the hot path is memory reads on cached instance
// pointers instead of a full re-walk.
constexpr auto kTickPeriod = std::chrono::milliseconds(16);

// Keepalive window. If koffee.lua's last /config was more than this ago,
// treat the config as stale and disarm (protects against dangling silent
// aim if the game crashes or the script unloads without sending /clear).
constexpr auto kKeepaliveMax = std::chrono::seconds(5);

// v0.3.0-a2p6: target sticky window. When lua's picker briefly returns
// nil (target one frame off-screen, occlusion flicker, respawn race, or
// a POST landing between picker updates), has_target flaps to false and
// the naive path would call set_active(false), disarming the thunk mid-
// fire so the shot raycast slips through unrewritten. Cache the last
// lua-provided target for this window and keep the thunk armed; only
// truly disarm when the target has been absent for the full window.
// The v0.3.7 lua-side grace was 150ms; add a bit more slack here since
// the helper's 60Hz tick can consume up to ~16ms of it.
constexpr auto kTargetStickyMs = std::chrono::milliseconds(200);

std::atomic<bool>   g_running{false};
std::thread         g_thread;
std::atomic<std::chrono::steady_clock::time_point> g_last_config{};

silent_state g_state;

// v0.3.0-a2p6: sticky-target cache lives at namespace scope so the
// disarm paths above the sticky check can invalidate it. Otherwise a
// silent-disable (or keepalive expire) leaves a ghost target that the
// next tick would happily re-arm on inside the sticky window.
koffee::math::vector3                s_last_lua_target{};
bool                                 s_last_lua_wallbang = false;
bool                                 s_last_lua_valid    = false;
std::chrono::steady_clock::time_point s_last_lua_time{};

void invalidate_lua_sticky() {
    s_last_lua_valid    = false;
    s_last_lua_wallbang = false;
    s_last_lua_target   = {};
}

// Pick the "best" target from the world snapshot given the config.
// Alpha2 metric: closest player by 3D world distance from camera, gated by
// distance cap + team + health.
//
// Alpha3+: promote to angular-distance-from-crosshair-in-screen-space
// (semun's real metric). That needs the camera's view matrix + FOV read
// from RenderView -- offsets are available (imtheo VisualEngine chain) but
// not wired for alpha2.
std::optional<koffee::math::vector3>
pick_target(const koffee::game::world_snap& w, const silent_config& cfg) {
    const float max_dist_sq = cfg.distance * cfg.distance;
    float best_dist_sq = max_dist_sq;
    std::optional<koffee::math::vector3> best;

    for (const auto& p : w.players) {
        if (!p.hrp || p.hrp_position.length_squared() < 1e-6f) continue;

        // Health gate. Health is authoritative: even without health_check
        // we skip 0-hp targets (aim at a corpse is a bug, not a feature).
        if (p.health <= 0.f) continue;
        if (cfg.health_check && p.health <= 0.f) continue;

        // Team gate.
        if (cfg.team_check
            && w.local_team_brick_color != 0
            && p.team_brick_color == w.local_team_brick_color) {
            continue;
        }

        const auto delta = p.hrp_position - w.camera_position;
        const float d2 = delta.length_squared();
        if (d2 > best_dist_sq) continue;

        best = p.hrp_position;
        best_dist_sq = d2;
    }
    return best;
}

// Read the current config under lock. Cheap -- 40-byte struct copy.
silent_config current_cfg() {
    std::lock_guard lock{g_state.mtx};
    return g_state.cfg;
}

void tick() {
    // Cached DataModel between ticks; refresh_data_model is expensive
    // (walks static pointer chain). If DataModel rebuilds (join/leave),
    // subsequent snapshots return an all-zero world and we re-scan next
    // frame.
    static std::uint64_t s_cached_data_model = 0;

    if (!koffee::mem::attach()) {
        // No Roblox process; disarm any prior state and skip.
        invalidate_lua_sticky();
        koffee::aim::hook::set_active(false, {}, {}, false);
        koffee::aim::hook::ensure(false);
        return;
    }

    const auto cfg = current_cfg();

    // Keepalive check: no config touch in kKeepaliveMax = force disarm.
    const auto last = g_last_config.load(std::memory_order_relaxed);
    const auto age  = std::chrono::steady_clock::now() - last;
    const bool stale = (last.time_since_epoch().count() == 0) || (age > kKeepaliveMax);
    g_state.keepalive_recent.store(!stale, std::memory_order_relaxed);

    if (!cfg.enabled || stale) {
        invalidate_lua_sticky();
        koffee::aim::hook::set_active(false, {}, {}, false);
        koffee::aim::hook::ensure(false);
        return;
    }

    // Ensure the hook is installed (idempotent, has its own retry back-off).
    koffee::aim::hook::ensure(true);
    if (!koffee::aim::hook::installed()) return;

    // v0.3.0-a2p4: engaged gate. koffee.lua only sets engaged=true when
    // the user is actively firing under the silent-aim gates. If false,
    // disarm the thunk so unrelated raycasts (IK, occlusion, footsteps)
    // don't get rewritten. Fixes wallbang looking flaky on games that
    // raycast heavily outside of shot windows.
    if (!cfg.engaged) {
        invalidate_lua_sticky();
        koffee::aim::hook::set_active(false, {}, {}, false);
        return;
    }

    // Refresh DataModel every ~500ms.
    static auto s_last_dm_refresh = std::chrono::steady_clock::now();
    const auto now = std::chrono::steady_clock::now();
    if (!s_cached_data_model
        || now - s_last_dm_refresh > std::chrono::milliseconds(500)) {
        s_cached_data_model = koffee::game::refresh_data_model();
        s_last_dm_refresh = now;
    }

    // v0.3.0-a2p4: when koffee.lua sends a target, use it verbatim.
    // Lua-side picker is smarter than the helper native (FOV cone,
    // priority, sticky, sub-team check, target lock, prediction). Only
    // fall back to native picker if lua didn't send one this tick.
    //
    // v0.3.0-a2p6: TARGET STICKY. If has_target flaps false but was true
    // within kTargetStickyMs, keep the thunk armed on the cached target.
    // Prevents mid-fire disarm from single-POST nils. wallbang is also
    // cached so the sticky window uses the same flags the user last saw.
    // Cache is invalidated on silent-disable / keepalive-expire /
    // engaged=false / process detach so a stale ghost can't leak into
    // the next silent session.
    const bool use_lua_target = cfg.has_target
        || (s_last_lua_valid
            && (std::chrono::steady_clock::now() - s_last_lua_time) < kTargetStickyMs);

    if (use_lua_target) {
        // Refresh cache when we have a live target.
        if (cfg.has_target) {
            s_last_lua_target   = cfg.target;
            s_last_lua_wallbang = cfg.wallbang;
            s_last_lua_valid    = true;
            s_last_lua_time     = std::chrono::steady_clock::now();
        }
        // Still walk to get a fresh camera position -- thunk uses it for
        // its own short-range gate. Cheap: workspace -> camera -> pos, no
        // players walk needed.
        const auto snap = koffee::game::snapshot_world(s_cached_data_model);
        if (!snap.data_model) s_cached_data_model = 0;
        const auto cam_pos = snap.camera_position.length_squared() > 1e-6f
            ? snap.camera_position
            : koffee::math::vector3{};

        const auto& tgt      = cfg.has_target ? cfg.target   : s_last_lua_target;
        const bool  wallbang = cfg.has_target ? cfg.wallbang : s_last_lua_wallbang;
        koffee::aim::hook::set_active(true, tgt, cam_pos, wallbang);
        return;
    }

    // Cache expired -- release the sticky so the native picker path below
    // isn't holding a stale ghost.
    s_last_lua_valid = false;

    const auto snap = koffee::game::snapshot_world(s_cached_data_model);
    if (!snap.data_model || snap.camera_position.length_squared() < 1e-6f) {
        koffee::aim::hook::set_active(false, {}, {}, false);
        return;
    }

    // If DataModel returned all zeros this snapshot, invalidate the cache
    // so we re-scan next tick.
    if (snap.players.empty() && !snap.workspace) s_cached_data_model = 0;

    const auto target = pick_target(snap, cfg);
    if (!target) {
        koffee::aim::hook::set_active(false, {}, {}, false);
        return;
    }
    koffee::aim::hook::set_active(true, *target, snap.camera_position, cfg.wallbang);
}

void loop() {
    koffee::log("silentaim loop started");
    while (g_running.load(std::memory_order_relaxed)) {
        try {
            tick();
        } catch (...) {
            // Never let the loop die on an exception -- one bad Roblox
            // memory read shouldn't take the helper down. Alpha3+: log
            // once per hour instead of swallowing silently.
        }
        std::this_thread::sleep_for(kTickPeriod);
    }
    koffee::log("silentaim loop exiting");
}

}  // namespace

silent_state& state() { return g_state; }

void apply_config(const silent_config& cfg) {
    {
        std::lock_guard lock{g_state.mtx};
        g_state.cfg = cfg;
    }
    g_last_config.store(std::chrono::steady_clock::now(),
                        std::memory_order_release);
}

void force_disarm() {
    {
        std::lock_guard lock{g_state.mtx};
        g_state.cfg.enabled = false;
    }
    invalidate_lua_sticky();
    // Immediate hook set-inactive; the loop will pick it up next tick too.
    koffee::aim::hook::set_active(false, {}, {}, false);
}

void start() {
    if (g_running.exchange(true, std::memory_order_acq_rel)) return;
    g_thread = std::thread(&loop);
    g_thread.detach();  // alpha2: no clean shutdown, helper exits process-wide
}

void stop() {
    g_running.store(false, std::memory_order_release);
    // Thread is detached; the loop's own kTickPeriod-scale poll of
    // g_running lets it exit within one tick. No join.
}

}  // namespace koffee::aim
