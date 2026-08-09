@echo off
cd /d C:\Users\User\AppData\Local\Temp\koffee
KoffeeExternal.exe > step.log 2> step.err
echo EXIT=%ERRORLEVEL% > step.ec
echo DONE >> step.log