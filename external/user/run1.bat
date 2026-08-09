@echo off
cd /d C:\Users\User\AppData\Local\Temp\koffee
echo === RUN START ===
KoffeeExternal.exe > log1.txt 2>&1
echo === RUN END EXIT=%ERRORLEVEL% ===
type log1.txt