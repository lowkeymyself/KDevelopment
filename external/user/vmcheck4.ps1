$o = @()
# 1. sanity: plain redirect works?
Set-Content -Path 'C:\Users\User\AppData\Local\Temp\koffee\sanity.txt' -Value 'SANITY_WRITE_OK'
$o += 'sanity=' + (Get-Content 'C:\Users\User\AppData\Local\Temp\koffee\sanity.txt' -ErrorAction SilentlyContinue)
# 2. exe process state
$k = Get-Process KoffeeExternal -ErrorAction SilentlyContinue
if ($k) { $o += 'exe=RUNNING id=' + $k.Id } else { $o += 'exe=NOT_RUNNING' }
# 3. fresh Lnv temp syfiles (last 4 min)
$o += '=== recent lnv files ==='
$cut = (Get-Date).AddMinutes(-4)
Get-ChildItem 'C:\Users\User\AppData\Local\Temp\lnv*.sys' -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -gt $cut } | ForEach-Object { $o += ($_.Name + ' ' + $_.Length + 'B ' + $_.LastWriteTime.ToString('HH:mm:ss')) }
# 4. koffee_dbg.log size/timestamp on VM
$d = Get-Item 'C:\Users\User\AppData\Local\Temp\koffee\koffee_dbg.log' -ErrorAction SilentlyContinue
if ($d) { $o += 'dbg=' + $d.Length + 'B ' + $d.LastWriteTime.ToString('HH:mm:ss') }
# 5. task last result
$o += 'task=' + ((schtasks /query /tn KoffeeLiveRun /fo LIST /v 2>$null | Select-String 'Last Run Result') -join ' | ')
Write-Output ($o -join "`n")