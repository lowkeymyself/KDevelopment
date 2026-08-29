// Minimum-viable vector types. Layout MUST match Roblox's internal Vector3
// (three tightly-packed floats, no padding) because we read/write straight
// bytes off game memory. Same for Vector2.
#pragma once

#include <cmath>
#include <cstdint>

namespace koffee::math {

struct vector2 {
    float x{0.f};
    float y{0.f};

    constexpr vector2() = default;
    constexpr vector2(float ax, float ay) : x(ax), y(ay) {}

    constexpr vector2 operator+(vector2 o) const { return {x + o.x, y + o.y}; }
    constexpr vector2 operator-(vector2 o) const { return {x - o.x, y - o.y}; }
    constexpr vector2 operator*(float s) const   { return {x * s, y * s}; }

    float length() const { return std::sqrt(x * x + y * y); }
};

struct vector3 {
    float x{0.f};
    float y{0.f};
    float z{0.f};

    constexpr vector3() = default;
    constexpr vector3(float ax, float ay, float az) : x(ax), y(ay), z(az) {}

    constexpr vector3 operator+(vector3 o) const { return {x + o.x, y + o.y, z + o.z}; }
    constexpr vector3 operator-(vector3 o) const { return {x - o.x, y - o.y, z - o.z}; }
    constexpr vector3 operator*(float s) const   { return {x * s, y * s, z * s}; }

    float length_squared() const { return x * x + y * y + z * z; }
    float length() const { return std::sqrt(length_squared()); }
    float dot(vector3 o) const   { return x * o.x + y * o.y + z * o.z; }

    // Safe unit -- returns zero vector on zero magnitude so callers don't NaN.
    vector3 unit_or_zero() const {
        const float l = length();
        if (l <= 1e-6f) return {};
        return {x / l, y / l, z / l};
    }
};

// Sanity: Roblox packs Vector3 as three floats. Any padding would break byte
// reads. This static_assert catches an ABI drift at compile time before it
// bricks the aim path at runtime.
static_assert(sizeof(vector3) == 12, "vector3 must be 12 bytes");
static_assert(sizeof(vector2) == 8,  "vector2 must be 8 bytes");

}  // namespace koffee::math
