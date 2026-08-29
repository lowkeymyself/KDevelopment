# KoffeeHelper — native (C++) helper for the Koffee suite.
#
# What this builds (alpha1): a headless service that binds a local HTTP port
# and answers GET /health. Alpha2 adds subprocess management for the Rust
# loader (external/user, produces KoffeeLoader.exe + the driver device),
# a DeviceIoControl wrapper for r/w against the driver, and the silent-aim +
# wallbang execution loop the koffee.lua script drives via /config.
#
# Build (from this directory):
#   cmake -S . -B build -G "Visual Studio 17 2022" -A x64
#   cmake --build build --config Release
#
# Output: build/Release/KoffeeHelper.exe

cmake_minimum_required(VERSION 3.20)
project(KoffeeHelper CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if(MSVC)
    # /W4 — high warning level; /permissive- — strict conformance;
    # /Zc:__cplusplus — accurate __cplusplus macro (MSVC lies by default).
    add_compile_options(/W4 /permissive- /Zc:__cplusplus)
    add_compile_definitions(
        _CRT_SECURE_NO_WARNINGS
        WIN32_LEAN_AND_MEAN
        NOMINMAX
    )
endif()

add_executable(KoffeeHelper
    src/main.cpp
    src/http.cpp
    src/log.cpp
)

target_include_directories(KoffeeHelper PRIVATE src)

# ws2_32 — WinSock 2 (bind/listen/accept/recv/send for the HTTP server).
# Alpha2 will add: Advapi32 (service control), Shell32 (tray icon), and
# the C++ shim linking against DeviceIoControl (already in kernel32).
target_link_libraries(KoffeeHelper PRIVATE ws2_32)

set_target_properties(KoffeeHelper PROPERTIES
    OUTPUT_NAME "KoffeeHelper"
    # Console subsystem during dev/alpha so log() reaches stdout when the
    # user launches from a terminal. Alpha2 (or first release build) flips
    # this to WIN32 subsystem + logs to file so the exe runs headless.
    WIN32_EXECUTABLE OFF
)
