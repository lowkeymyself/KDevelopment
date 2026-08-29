// Raycast inline hook — ported from semun's `raycast_silent.cpp`, renamed
// into the koffee namespace, memory primitive routed through `koffee::mem`.
//
// Design (unchanged from source):
//   1. `install()` reads the raycast bound function pointer at
//      `RobloxPlayerBeta + bound_desc_rva + bound_fn`, generates a ~300B
//      x64 thunk in a code cave (or a fresh VirtualAllocEx page), writes
//      the thunk, then swaps the function pointer to point at the thunk.
//   2. Inside Roblox, whenever the raycast bound function is called, the
//      thunk reads a shared `raycast_state_t` living at an address the
//      helper allocated inside Roblox's address space. If the state's
//      `active` flag is set, the thunk rewrites the raycast direction (and
//      optionally origin under wallbang) to hit the target world position,
//      then jumps to the original function.
//   3. `set_active(true, target_world, wallbang)` fills the state page.
//      `set_active(false, ...)` clears the active flag -- no need to
//      uninstall the hook to disarm.
//
// The literal thunk byte pattern is inherited verbatim from semun for
// alpha2 -- swapping the pattern (to break trivial signature matches) is
// alpha4+ work. The wire behaviour is unchanged: same registers, same
// jumps, same scale/wallbang flag interpretations.
//
// Callers must pass the current Roblox camera position on every
// `set_active(true, ...)` -- the thunk uses it to gate rays whose origin
// is far from the camera (probe/IK rays).
#pragma once

#include "../vec.h"

namespace koffee::aim::hook {

// Install/uninstall based on `want`. Called every tick from the aim loop.
// Cheap when already in the desired state.
void ensure(bool want);

// Arm or disarm the shared state. When `on == true`, `world_target` is
// written into the state page and the thunk's `active` flag flips on.
// `wallbang == true` sets an extra flag that widens the thunk's rewrite
// path (raycast origin also gets translated in front of the target).
// `camera_position` is snapped into the state so the thunk's own gates
// (short-range probe rejection) get honest inputs.
void set_active(bool on,
                const koffee::math::vector3& world_target,
                const koffee::math::vector3& camera_position,
                bool wallbang);

// Scale factor for the thunk's rewrite math -- alpha2 leaves it at the
// default (1.15) since semun's thunk assembly assumes that constant range.
// Wired for future tuning (e.g. distance-based scaling).
void set_scale(float scale);

// Query.
bool installed();
bool aiming();

}  // namespace koffee::aim::hook
