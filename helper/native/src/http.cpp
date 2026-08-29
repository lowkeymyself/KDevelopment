// HTTP server rewritten over cpp-httplib for alpha2.
//
// Routes:
//   * GET  /health   -- unchanged from alpha1, no auth. Cheapest liveness
//                       probe from koffee.lua on Silent Aim enable.
//   * GET  /status   -- richer than /health: attach state + current config +
//                       hook state. Diagnostic use.
//   * POST /config   -- koffee.lua pushes the silent-aim config blob (JSON).
//                       Auth: X-Koffee-Key header must equal the shared key.
//   * POST /clear    -- force disarm the aim path. Auth: same.
//
// Auth: dev key `KoffeeBetaDevelopmentTesting`, matches Koffee.md's
// "Round-1 auth (dev)" section. Alpha3+ swaps in a real key provider.

#include "http.h"
#include "log.h"
#include "mem.h"
#include "game.h"
#include "aim/hook.h"
#include "aim/silentaim.h"

// vendored
#include "../vendor/httplib.h"
#include "../vendor/json.hpp"

#include <atomic>
#include <string>

namespace koffee::http {

namespace {

using nlohmann::json;

constexpr const char* kAuthHeader = "X-Koffee-Key";
constexpr const char* kDevKey     = "KoffeeBetaDevelopmentTesting";

constexpr const char* kVersion = "0.3.0-a2p2";

std::atomic<httplib::Server*> g_server{nullptr};

bool has_valid_key(const httplib::Request& req) {
    const auto it = req.headers.find(kAuthHeader);
    if (it == req.headers.end()) return false;
    return it->second == kDevKey;
}

void set_json(httplib::Response& res, int status, const json& j) {
    res.status = status;
    res.set_content(j.dump(), "application/json");
}

json health_body() {
    return json{
        {"status",  "ok"},
        {"version", kVersion},
        {"stage",   "alpha2"},
    };
}

json status_body() {
    const bool attached      = koffee::mem::g_ctx.attached.load(std::memory_order_relaxed);
    const bool hook_up       = koffee::aim::hook::installed();
    const bool hook_aiming   = koffee::aim::hook::aiming();
    const bool keepalive     = koffee::aim::state().keepalive_recent.load(std::memory_order_relaxed);

    // Copy config under lock so we don't race with /config writes.
    koffee::aim::silent_config cfg;
    {
        std::lock_guard lock{koffee::aim::state().mtx};
        cfg = koffee::aim::state().cfg;
    }

    return json{
        {"version",  kVersion},
        {"attached", attached},
        {"pid",      koffee::mem::g_ctx.pid},
        {"hook", {
            {"installed", hook_up},
            {"aiming",    hook_aiming},
        }},
        {"silent", {
            {"keepalive_recent", keepalive},
            {"enabled",          cfg.enabled},
            {"wallbang",         cfg.wallbang},
            {"hit_part",         cfg.hit_part},
            {"team_check",       cfg.team_check},
            {"health_check",     cfg.health_check},
            {"distance",         cfg.distance},
        }},
    };
}

// Best-effort JSON -> silent_config. Missing / wrong-typed fields fall back
// to defaults from a fresh config, so a partial payload from koffee.lua
// (e.g. old script version) still parses cleanly. Never throws.
koffee::aim::silent_config parse_config(const json& j) {
    koffee::aim::silent_config out;   // defaults

    auto load_bool = [&](const char* key, bool& dst) {
        if (auto it = j.find(key); it != j.end() && it->is_boolean()) dst = it->get<bool>();
    };
    auto load_float = [&](const char* key, float& dst) {
        if (auto it = j.find(key); it != j.end() && it->is_number()) dst = it->get<float>();
    };
    auto load_string = [&](const char* key, std::string& dst) {
        if (auto it = j.find(key); it != j.end() && it->is_string()) dst = it->get<std::string>();
    };

    load_bool("enabled",       out.enabled);
    load_bool("wallbang",      out.wallbang);
    load_string("hit_part",    out.hit_part);
    load_bool("team_check",    out.team_check);
    load_bool("health_check",  out.health_check);
    load_float("distance",     out.distance);
    load_float("fov_radius",   out.fov_radius);
    load_bool("fov_enabled",   out.fov_enabled);

    // Clamp obvious garbage. koffee.lua's distance slider can push huge
    // numbers if the user unbounds it; we cap here to avoid float weirdness
    // in the picker's `d*d` comparisons.
    if (out.distance < 1.f)     out.distance = 1.f;
    if (out.distance > 100000.f) out.distance = 100000.f;
    return out;
}

void install_routes(httplib::Server& srv) {
    // /health -- no auth, cheap. Called on Silent Aim enable in koffee.lua.
    srv.Get("/health", [](const httplib::Request&, httplib::Response& res) {
        set_json(res, 200, health_body());
    });

    // /status -- no auth, diagnostic.
    srv.Get("/status", [](const httplib::Request&, httplib::Response& res) {
        set_json(res, 200, status_body());
    });

    // /config -- POST, JSON, X-Koffee-Key required.
    srv.Post("/config", [](const httplib::Request& req, httplib::Response& res) {
        if (!has_valid_key(req)) {
            set_json(res, 401, json{{"error", "bad_or_missing_key"}});
            return;
        }
        json j;
        try {
            j = json::parse(req.body);
        } catch (...) {
            set_json(res, 400, json{{"error", "bad_json"}});
            return;
        }
        if (!j.is_object()) {
            set_json(res, 400, json{{"error", "expected_object"}});
            return;
        }
        // koffee.lua sends {"silent": {...}} to leave room for future
        // config groups (aim, esp, etc). Fall back to top-level for
        // convenience during manual testing.
        const json* silent_obj = &j;
        if (auto it = j.find("silent"); it != j.end() && it->is_object()) {
            silent_obj = &(*it);
        }
        koffee::aim::apply_config(parse_config(*silent_obj));
        set_json(res, 200, json{{"status", "ok"}});
    });

    // /debug/world -- no auth, diagnostic. Forces a fresh DataModel scan +
    // snapshot and returns the walker's view of the world so we can pin
    // down which layer a picker fails at (dm/workspace/camera/players).
    // Added 2026-08-29 while chasing "hook.installed:true but aiming:false"
    // on the first live-Roblox test.
    srv.Get("/debug/world", [](const httplib::Request&, httplib::Response& res) {
        if (!koffee::mem::g_ctx.attached.load(std::memory_order_relaxed)) {
            set_json(res, 200, json{{"error", "not_attached"}});
            return;
        }
        const std::uint64_t dm = koffee::game::refresh_data_model();
        const auto w = koffee::game::snapshot_world(dm);

        json players_arr = json::array();
        for (const auto& p : w.players) {
            players_arr.push_back({
                {"player_inst",      p.player_inst},
                {"character",        p.character},
                {"hrp",              p.hrp},
                {"humanoid",         p.humanoid},
                {"hrp_pos", {
                    {"x", p.hrp_position.x},
                    {"y", p.hrp_position.y},
                    {"z", p.hrp_position.z},
                }},
                {"health",           p.health},
                {"max_health",       p.max_health},
                {"team_brick_color", p.team_brick_color},
            });
        }

        // v0.3.0-a2p2: also dump the raw child walk of DataModel with
        // class + name strings. This is the smoking-gun view when
        // players is empty -- either the walker returns nothing (walk
        // broken) or the class-name reads produce garbage (offsets
        // wrong for ClassDescriptor/ClassName), and the JSON tells us
        // which. Capped at 64 entries so a bad walker can't dump MB
        // of garbage into the response.
        json dm_children_arr = json::array();
        if (dm) {
            const auto kids = koffee::game::list_children_diag(dm, 64);
            for (const auto& c : kids) {
                dm_children_arr.push_back({
                    {"addr",  c.address},
                    {"class", c.class_name},
                    {"name",  c.instance_name},
                });
            }
        }

        set_json(res, 200, json{
            {"data_model",       w.data_model},
            {"workspace",        w.workspace},
            {"current_camera",   w.current_camera},
            {"camera_pos", {
                {"x", w.camera_position.x},
                {"y", w.camera_position.y},
                {"z", w.camera_position.z},
            }},
            {"local_player",         w.local_player},
            {"local_team_brick",     w.local_team_brick_color},
            {"players_count",        w.players.size()},
            {"players",              players_arr},
            {"dm_children_count",    dm_children_arr.size()},
            {"dm_children",          dm_children_arr},
        });
    });

    // /clear -- POST, no body needed, X-Koffee-Key required.
    srv.Post("/clear", [](const httplib::Request& req, httplib::Response& res) {
        if (!has_valid_key(req)) {
            set_json(res, 401, json{{"error", "bad_or_missing_key"}});
            return;
        }
        koffee::aim::force_disarm();
        set_json(res, 200, json{{"status", "cleared"}});
    });
}

}  // namespace

int serve(std::uint16_t port) {
    httplib::Server srv;
    srv.set_read_timeout(2, 0);
    srv.set_write_timeout(2, 0);
    // Payload cap -- config JSON is at most a few hundred bytes; anything
    // bigger is garbage or an attack surface. Reject early.
    srv.set_payload_max_length(64 * 1024);

    install_routes(srv);

    g_server.store(&srv, std::memory_order_release);

    koffee::log(std::string("http listening on 127.0.0.1:") + std::to_string(port));
    const bool ok = srv.listen("127.0.0.1", port);
    g_server.store(nullptr, std::memory_order_release);

    if (!ok) {
        koffee::log_err("http listen() failed -- port likely in use");
        return 2;
    }
    return 0;
}

}  // namespace koffee::http
