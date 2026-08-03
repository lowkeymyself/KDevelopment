@echo off
setlocal enabledelayedexpansion
rem =====================================================================
rem Koffee External : one-shot build (driver + test target + host binary)
rem
rem Run from a "Developer Command Prompt for VS 2022" so msbuild + cargo
rem are on PATH. From plain cmd/PowerShell you'll get "msbuild not
rem recognized" -- use the VS prompt.
rem
rem Usage:
rem   build.bat           : build all three (driver Debug, testtarget release, host release with real-driver)
rem   build.bat driver    : build only the kernel driver
rem   build.bat user      : build only the Rust binaries
rem =====================================================================

set ROOT=%~dp0
set MODE=%1
if "%MODE%"=="" set MODE=all

echo === Koffee external build (%MODE%) ===

if /i "%MODE%"=="driver" goto :driver
if /i "%MODE%"=="user"   goto :user

:driver
echo.
echo [1/2] driver (msbuild, Debug^|x64)...
cd /d "%ROOT%driver"
msbuild KoffeeMem.vcxproj /p:Configuration=Debug /p:Platform=x64 /nologo /v:minimal
if errorlevel 1 (
    echo.
    echo [!] driver build FAILED. See errors above.
    exit /b 1
)
echo [+] driver ok : %ROOT%driver\x64\Debug\KoffeeMem\KoffeeMem.sys
if /i "%1"=="driver" goto :done

:user
echo.
echo [2/2] user (cargo, release + real-driver)...
cd /d "%ROOT%user"
cargo build --release --bin KoffeeTestTarget
if errorlevel 1 goto :cargofail
cargo build --release --bin KoffeeExternal --features real-driver
if errorlevel 1 goto :cargofail
echo [+] user ok :
echo     %ROOT%user\target\release\KoffeeTestTarget.exe
echo     %ROOT%user\target\release\KoffeeExternal.exe
goto :done

:cargofail
echo.
echo [!] cargo build FAILED. See errors above.
exit /b 1

:done
echo.
echo === done ===
endlocal
