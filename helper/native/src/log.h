// Tiny logger. Alpha1: stdout only, prefixed with wall-clock HH:MM:SS. Alpha2
// gates on a build flag to also mirror to a file next to the exe so the release
// binary (which will run WIN32 subsystem = no stdout) is still debuggable.
#pragma once
#include <string_view>

namespace koffee {

void log(std::string_view msg);
void log_err(std::string_view msg);

}  // namespace koffee
