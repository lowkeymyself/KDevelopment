// Roblox game-state walker.
//
// Everything here follows the offset table in `offsets.h`. If a walk starts
// returning zero addresses or garbage bytes, the first place to look is a
// Roblox engine update -- refresh offsets and rebuild.
//
// Scope for alpha2:
//   * find the DataModel (via TaskScheduler pointer chain -- future) OR the
//     Workspace via a well-known bootstrap pointer
//   * from Workspace, find CurrentCamera
//   * read camera world position
//   * enumerate Players service children (players list)
//   * per-player: character -> HumanoidRootPart -> position, humanoid health,
//     team colour comparison
//
// Alpha2 shortcut: instead of walking the TaskScheduler chain to reach
// DataModel (which needs a scan-for-string pattern to find TaskScheduler
// itself), we sig-scan for the DataModel pointer once at attach time and
// cache it. If the cache is stale (DataModel rebuilt on join/leave), the
// aim loop rediscovers.
#pragma once

#include <cstdint>
#include <vector>
#include <string>

#include "vec.h"

namespace koffee::game {

struct player_snap {
    std::uint64_t     player_inst{0};     // Players child Instance
    std::uint64_t     character{0};       // Player.ModelInstance (Character)
    std::uint64_t     hrp{0};             // HumanoidRootPart (BasePart)
    std::uint64_t     humanoid{0};        // Humanoid inside character
    math::vector3     hrp_position{};
    float             health{0.f};
    float             max_health{0.f};
    std::uint32_t     team_brick_color{0};
};

struct world_snap {
    std::uint64_t         data_model{0};
    std::uint64_t         workspace{0};
    std::uint64_t         current_camera{0};
    math::vector3         camera_position{};
    std::uint64_t         local_player{0};
    std::uint32_t         local_team_brick_color{0};
    std::vector<player_snap> players;    // excluding local player
};

// Rebind the DataModel pointer via a sig-scan. Called at attach + periodically
// while enabled to survive DataModel rebuilds (join/leave). Returns 0 on
// failure; caller should retry the next tick.
std::uint64_t refresh_data_model();

// Take a snapshot of the world in one pass. Best-effort -- individual reads
// that fail leave those fields zeroed and the surrounding fields intact.
// Callers should treat 0 addresses / 0 health as "skip this player" gates.
world_snap snapshot_world(std::uint64_t cached_data_model);

// Diagnostic: list an Instance's direct children with their class + name.
// Used by /debug/world to print the walker's raw view for offset triage.
// Cap on entries defends against corrupted children arrays.
struct child_info {
    std::uint64_t address{0};
    std::string   class_name;
    std::string   instance_name;
};
std::vector<child_info> list_children_diag(std::uint64_t instance,
                                           std::size_t cap = 64);

}  // namespace koffee::game
