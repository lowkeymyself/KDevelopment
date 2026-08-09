@echo off
cd /d C:\Users\User\AppData\Local\Temp\koffee
echo BATCH_START_BEGIN > marker.txt
copy /y marker2.txt marker.txt >nul 2>&1
KoffeeExternal.exe --ram-dump > rdump.txt 2>&1
echo RAN_EXIT=%ERRORLEVEL% >> marker.txt
copy /y rdump.txt nm.txt >nul 2>&1
echo BATCH_DONE >> marker.txt