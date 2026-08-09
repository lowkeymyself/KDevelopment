schtasks /create /tn KoffeeLiveRun /tr "cmd /c C:\Users\User\AppData\Local\Temp\koffee\live.bat >> C:\Users\User\AppData\Local\Temp\koffee\livewrap.log 2>&1" /sc once /st 23:59 /ru User /rl HIGHEST /f
schtasks /run /tn KoffeeLiveRun
echo SCHTASKS_RUN_DONE