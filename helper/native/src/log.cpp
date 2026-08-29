#include "log.h"

#include <chrono>
#include <cstdio>
#include <ctime>
#include <mutex>

namespace koffee {

namespace {

// Serialise writes across worker threads (the HTTP accept loop spawns a
// thread per connection). Printf under lock is fine for the volume this
// helper produces.
std::mutex g_log_mtx;

void write_prefixed(std::FILE* out, std::string_view msg) {
    const auto now = std::chrono::system_clock::to_time_t(
        std::chrono::system_clock::now());
    std::tm tm{};
    localtime_s(&tm, &now);

    std::lock_guard lock{g_log_mtx};
    std::fprintf(out, "[%02d:%02d:%02d] %.*s\n",
                 tm.tm_hour, tm.tm_min, tm.tm_sec,
                 static_cast<int>(msg.size()), msg.data());
    std::fflush(out);
}

}  // namespace

void log(std::string_view msg) { write_prefixed(stdout, msg); }
void log_err(std::string_view msg) { write_prefixed(stderr, msg); }

}  // namespace koffee
