# KoffeeHelper -- native (C++) helper for the Koffee suite.
#
# Alpha2 (this build): raycast inline hook + native target picker + HTTP
# bridge (/config, /clear, /health, /status). koffee.lua drives it via
# `POST /config` with a X-Koffee-Key header. Uses user-mode OpenProcess +
# ReadProcessMemory/WriteProcessMemory for now -- alpha3 swaps r/w for the
# koffee kernel driver via DeviceIoControl.
#
# Build:
#   cmake -S . -B build -G "Visual Studio 17 2022" -A x64
#   cmake --build build --config Release
# Output: build/Release/KoffeeHelper.exe

cmake_minimum_required(VERSION 3.20)
project(KoffeeHelper CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if(MSVC)
    add_compile_options(/W4 /permissive- /Zc:__cplusplus)
    # /wd4324 -- struct padded due to alignas (raycast_state_t is #pragma pack(push, 4)
    #            already, this suppresses false-positive warnings from vendored headers).
    # /wd4127 -- conditional expression is constant (cpp-httplib uses this pattern).
    add_compile_options(/wd4127)
    add_compile_definitions(
        _CRT_SECURE_NO_WARNINGS
        WIN32_LEAN_AND_MEAN
        NOMINMAX
        # cpp-httplib is header-only, but our translation unit that instantiates
        # its templates needs it to see the impl. Single-header library, no split.
    )
endif()

add_executable(KoffeeHelper
    src/main.cpp
    src/http.cpp
    src/log.cpp
    src/mem.cpp
    src/game.cpp
    src/aim/hook.cpp
    src/aim/silentaim.cpp
)

target_include_directories(KoffeeHelper PRIVATE src vendor)

# ws2_32   -- WinSock 2 (cpp-httplib backend on Windows).
# psapi    -- EnumProcessModulesEx, GetModuleBaseNameA (module walker in mem.cpp).
# advapi32 -- reserved for alpha3 (service control / driver device ACL).
target_link_libraries(KoffeeHelper PRIVATE
    ws2_32
    psapi
    advapi32
)

set_target_properties(KoffeeHelper PROPERTIES
    OUTPUT_NAME "KoffeeHelper"
    # Console subsystem during alpha for stdout logging. Flip to WIN32
    # subsystem + file log at first release build.
    WIN32_EXECUTABLE OFF
)
