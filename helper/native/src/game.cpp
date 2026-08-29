#include "game.h"

#include "mem.h"
#include "offsets.h"

#include <cstdint>
#include <cstring>
#include <string>

namespace koffee::game {

namespace {

using namespace koffee::offsets;

// Read a Roblox-style small-string. Layout matches std::basic_string with
// SSO: at address+0x10 lives the length as int32; if length >= 16, the
// address stores a pointer to the heap buffer, else the string is embedded
// starting at address+0x00. Same shape semun's memory.cpp reads.
std::string read_rbx_string(std::uint64_t address) {
    if (!koffee::mem::addr_ok(address)) return {};
    const std::int32_t len = koffee::mem::read<std::int32_t>(address + 0x10);
    if (len <= 0 || len > 255) return {};

    std::uint64_t str_addr = address;
    if (len >= 16) {
        str_addr = koffee::mem::read<std::uint64_t>(address);
        if (!koffee::mem::addr_ok(str_addr)) return {};
    }

    std::string out;
    out.resize(static_cast<std::size_t>(len));
    const std::size_t got = koffee::mem::read_bytes(
        str_addr, out.data(), static_cast<std::size_t>(len));
    if (got != static_cast<std::size_t>(len)) return {};
    return out;
}

std::string read_class_name(std::uint64_t instance) {
    const std::uint64_t descriptor =
        koffee::mem::read<std::uint64_t>(instance + rbx_inst::class_descriptor);
    if (!koffee::mem::addr_ok(descriptor)) return {};
    return read_rbx_string(descriptor + rbx_inst::class_name);
}

std::string read_instance_name(std::uint64_t instance) {
    const std::uint64_t container =
        koffee::mem::read<std::uint64_t>(instance + rbx_inst::name_container);
    if (!koffee::mem::addr_ok(container)) return {};
    return read_rbx_string(container + rbx_inst::name);
}

// Iterate an Instance's children. Callback returns false to stop the walk
// early. Cap at 4096 iterations as a safety net against corrupted / stale
// pointers -- a real Instance never has that many children.
template <typename F>
void for_each_child(std::uint64_t instance, F&& fn) {
    if (!koffee::mem::addr_ok(instance)) return;
    const std::uint64_t start =
        koffee::mem::read<std::uint64_t>(instance + rbx_inst::children_start);
    const std::uint64_t end =
        koffee::mem::read<std::uint64_t>(instance + rbx_inst::children_start + rbx_inst::children_end);
    if (!koffee::mem::addr_ok(start) || end <= start) return;

    const std::uint64_t count = (end - start) / sizeof(std::uint64_t);
    if (count > 4096) return;  // sanity cap
    for (std::uint64_t i = 0; i < count; ++i) {
        const std::uint64_t child =
            koffee::mem::read<std::uint64_t>(start + i * sizeof(std::uint64_t));
        if (!koffee::mem::addr_ok(child)) continue;
        if (!fn(child)) return;
    }
}

// Locate a direct child by class name (case-sensitive -- Roblox class names
// are stable). Returns 0 if no child matches.
std::uint64_t find_child_by_class(std::uint64_t parent, std::string_view klass) {
    std::uint64_t match = 0;
    for_each_child(parent, [&](std::uint64_t child) {
        if (read_class_name(child) == klass) {
            match = child;
            return false;
        }
        return true;
    });
    return match;
}

// Locate a direct child by instance name. Roblox parts and Humanoid names
// are convention-based ("HumanoidRootPart", "Humanoid", ...).
std::uint64_t find_child_by_name(std::uint64_t parent, std::string_view name) {
    std::uint64_t match = 0;
    for_each_child(parent, [&](std::uint64_t child) {
        if (read_instance_name(child) == name) {
            match = child;
            return false;
        }
        return true;
    });
    return match;
}

// Read a BasePart position: BasePart+primitive -> Primitive+position (Vector3).
math::vector3 read_part_position(std::uint64_t part) {
    if (!koffee::mem::addr_ok(part)) return {};
    const std::uint64_t prim = koffee::mem::read<std::uint64_t>(part + base_part::primitive);
    if (!koffee::mem::addr_ok(prim)) return {};
    return koffee::mem::read<math::vector3>(prim + primitive::position);
}

}  // namespace

// Simple pointer-chain DataModel resolver. We rely on FakeDataModel.Pointer
// (RVA into RobloxPlayerBeta.exe pointing at the FakeDataModel pointer)
// and FakeDataModel.RealDataModel (offset from FakeDataModel to the real
// DataModel). Same walk semun uses, expressed against imtheo's naming.
//
// This will need a sig-scan fallback if imtheo's static offset drifts (the
// FakeDataModel pointer sometimes moves between builds). Alpha3+: add a
// scan that resolves the pointer heuristically instead of trusting the RVA
// forever.
std::uint64_t refresh_data_model() {
    // These come from imtheo (2026-08-27) but aren't in offsets.h yet because
    // they might live somewhere else in a build with different macros. Keep
    // literals here so a future refactor can move them to offsets.h once we
    // have a second build to confirm the shape holds across engine updates.
    constexpr std::uintptr_t k_fake_dm_ptr_rva     = 147496136;
    constexpr std::uintptr_t k_fake_dm_to_real_dm  = 504;

    const std::uint64_t base = koffee::mem::g_ctx.module_base;
    if (!base) return 0;

    const std::uint64_t fake_dm =
        koffee::mem::read<std::uint64_t>(base + k_fake_dm_ptr_rva);
    if (!koffee::mem::addr_ok(fake_dm)) return 0;

    const std::uint64_t real_dm =
        koffee::mem::read<std::uint64_t>(fake_dm + k_fake_dm_to_real_dm);
    if (!koffee::mem::addr_ok(real_dm)) return 0;
    return real_dm;
}

world_snap snapshot_world(std::uint64_t cached_data_model) {
    world_snap w{};
    w.data_model = cached_data_model ? cached_data_model : refresh_data_model();
    if (!w.data_model) return w;

    // Workspace -> CurrentCamera -> Position.
    w.workspace = koffee::mem::read<std::uint64_t>(w.data_model + data_model::workspace);
    if (koffee::mem::addr_ok(w.workspace)) {
        w.current_camera =
            koffee::mem::read<std::uint64_t>(w.workspace + workspace::current_camera);
        if (koffee::mem::addr_ok(w.current_camera)) {
            w.camera_position =
                koffee::mem::read<math::vector3>(w.current_camera + camera::position);
        }
    }

    // Players service. In DataModel's children, class name "Players".
    const std::uint64_t players_service = find_child_by_class(w.data_model, "Players");
    if (!players_service) return w;

    // LocalPlayer (Players service exposes it at offset 304).
    w.local_player = koffee::mem::read<std::uint64_t>(players_service + player::local_player);
    if (koffee::mem::addr_ok(w.local_player)) {
        const std::uint64_t local_team =
            koffee::mem::read<std::uint64_t>(w.local_player + player::team);
        if (koffee::mem::addr_ok(local_team)) {
            // Team.BrickColor lives at offset 184 (imtheo).
            w.local_team_brick_color =
                koffee::mem::read<std::uint32_t>(local_team + 184);
        }
    }

    // Enumerate Players service children -- each is a Player instance.
    for_each_child(players_service, [&](std::uint64_t plr) {
        if (plr == w.local_player) return true;  // skip self

        player_snap p{};
        p.player_inst = plr;

        // Character
        p.character = koffee::mem::read<std::uint64_t>(plr + player::model_instance);
        if (!koffee::mem::addr_ok(p.character)) {
            w.players.push_back(p);   // still push -- picker filters on hrp/health
            return true;
        }

        // HumanoidRootPart -- direct-name lookup in character's children.
        p.hrp = find_child_by_name(p.character, "HumanoidRootPart");
        if (koffee::mem::addr_ok(p.hrp)) {
            p.hrp_position = read_part_position(p.hrp);
        }

        // Humanoid -- direct-name lookup (class works too, name is faster).
        p.humanoid = find_child_by_name(p.character, "Humanoid");
        if (koffee::mem::addr_ok(p.humanoid)) {
            p.health     = koffee::mem::read<float>(p.humanoid + humanoid::health);
            p.max_health = koffee::mem::read<float>(p.humanoid + humanoid::max_health);
        }

        // Team colour
        const std::uint64_t team =
            koffee::mem::read<std::uint64_t>(plr + player::team);
        if (koffee::mem::addr_ok(team)) {
            p.team_brick_color = koffee::mem::read<std::uint32_t>(team + 184);
        }

        w.players.push_back(p);
        return true;
    });

    return w;
}

}  // namespace koffee::game
