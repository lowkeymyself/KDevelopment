@echo off
set KOFE_DBGLOG=C:\Users\User\AppData\Local\Temp\koffee\koffee_dbg.log
cd /d C:\Users\User\AppData\Local\Temp\koffee
if exist koffee_dbg.log del /q koffee_dbg.log
KoffeeExternal.exe > liveout.txt 2> liveerr.txt
echo EXITCODE=%ERRORLEVEL% >> koffee_dbg.log