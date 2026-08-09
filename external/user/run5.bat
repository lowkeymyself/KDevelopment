@echo off
cd /d C:\Users\User\AppData\Local\Temp\koffee
set KOFE_DBGLOG=C:\Users\User\AppData\Local\Temp\koffee\dbg2.log
if exist dbg2.log del /q dbg2.log
KoffeeExternal.exe > merged.txt 2>&1
echo EXITCODE=%ERRORLEVEL% >> merged.txt