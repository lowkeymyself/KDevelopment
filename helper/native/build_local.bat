@echo off
setlocal
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvarsall.bat" x64 >NUL
if errorlevel 1 (
    echo VCVARSALL_FAILED
    exit /b 1
)
cd /d "%~dp0"
if not exist build_local mkdir build_local
cl /nologo /std:c++20 /O2 /EHsc /W4 /permissive- /Zc:__cplusplus /wd4127 ^
   /DWIN32_LEAN_AND_MEAN /DNOMINMAX /D_CRT_SECURE_NO_WARNINGS ^
   /Isrc /Ivendor ^
   /Fo:build_local\ ^
   src\main.cpp src\http.cpp src\log.cpp src\mem.cpp src\game.cpp ^
   src\aim\hook.cpp src\aim\silentaim.cpp ^
   ws2_32.lib psapi.lib advapi32.lib ^
   /link /OUT:build_local\KoffeeHelper_a2p5.exe
if errorlevel 1 (
    echo BUILD_FAILED
    exit /b 1
)
echo BUILD_OK
dir build_local\KoffeeHelper_a2p5.exe
