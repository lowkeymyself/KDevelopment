$p = 'C:\Users\User\AppData\Local\Temp\koffee\full.log'
$proc = Get-Process KoffeeExternal -ErrorAction SilentlyContinue
if ($proc) { $alive = 'RUNNING' } else { $alive = 'NOT_RUNNING' }
$lines = @(Get-Content $p -ErrorAction SilentlyContinue)
$n = $lines.Count
$last = if ($n -gt 0) { $lines[$n-1] } else { '' }
Write-Output ("ALIVE=" + $alive + " LINES=" + $n + " LAST=" + $last)