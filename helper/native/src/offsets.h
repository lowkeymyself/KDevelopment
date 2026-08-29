// Roblox engine offsets baked into the helper for the current build.
//
// Sources for this snapshot (2026-08-28):
//   * Raycast + FastCluster: dump1.txt (Unified Engine Offset Dumper,
//     build ad341c61967d68a8) — user hand-verified against a live Roblox
//     process before this commit.
//   * All others: imtheo primary — https://offsets.imtheo.lol/offsets.json
//     Roblox Version: version-f5a60436d48947d3, dumped 27/08/2026 19:36,
//     388 offsets total, dumper 2.1.7 / RbxDumperV2.
//
// Update rhythm: Roblox ships engine updates roughly weekly-to-biweekly.
// When the raycast hook stops installing or the DataModel walk starts
// returning garbage, refresh from both sources. Keep the header timestamp
// and version tag current so a future session knows what build these
// numbers match.
#pragma once

#include <cstdint>

namespace koffee::offsets {

// -- Raycast (dump1.txt, build ad341c61967d68a8) ------------------------------
namespace raycast {
    // RVA into RobloxPlayerBeta.exe of the WorldRoot method-table descriptor
    // whose slot at RaycastBoundFn holds the raycast bound function pointer.
    // The hook rewrites the pointer at (module_base + BoundDesc + BoundFn).
    inline constexpr std::uintptr_t bound_desc_rva = 0x8089F20;
    inline constexpr std::uintptr_t bound_fn       = 0x80;
}  // namespace raycast

// -- DataModel / Workspace / Camera (imtheo, version-f5a60436d48947d3) --------
namespace data_model {
    inline constexpr std::uintptr_t workspace = 344;
}
namespace workspace {
    inline constexpr std::uintptr_t current_camera = 1176;
}
namespace camera {
    inline constexpr std::uintptr_t position = 252;
}

// -- Player / Character walk ---------------------------------------------------
namespace player {
    inline constexpr std::uintptr_t local_player   = 304;
    inline constexpr std::uintptr_t user_id        = 208;
    inline constexpr std::uintptr_t display_name   = 312;
    inline constexpr std::uintptr_t model_instance = 664;   // Character
    inline constexpr std::uintptr_t team           = 728;
}
namespace humanoid {
    inline constexpr std::uintptr_t health              = 400;
    inline constexpr std::uintptr_t max_health          = 424;
    inline constexpr std::uintptr_t humanoid_root_part  = 1144;
}
namespace base_part {
    inline constexpr std::uintptr_t primitive = 392;
}
namespace primitive {
    inline constexpr std::uintptr_t position = 236;
    // Alpha3+: velocity for prediction.
    inline constexpr std::uintptr_t assembly_linear_velocity  = 248;
    inline constexpr std::uintptr_t assembly_angular_velocity = 260;
}

// -- Instance tree (Players service, children walk) ---------------------------
// Named `rbx_inst` (not `instance`) to avoid shadowing local variables named
// `instance` in the game walker functions.
namespace rbx_inst {
    inline constexpr std::uintptr_t children_start = 120;
    inline constexpr std::uintptr_t children_end   = 8;    // stride from start
    inline constexpr std::uintptr_t name_container = 112;
    inline constexpr std::uintptr_t name           = 8;
    inline constexpr std::uintptr_t class_descriptor = 24;
    inline constexpr std::uintptr_t class_name     = 8;
}

}  // namespace koffee::offsets
