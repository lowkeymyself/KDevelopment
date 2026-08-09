$o = @()
$f = Get-Item 'C:\Users\User\AppData\Local\Temp\koffee\KoffeeExternal.exe' -ErrorAction SilentlyContinue
if ($f) { $o += ('exe=' + $f.Length + 'B ' + $f.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')) }
$o += ('koffee_procs=' + @(Get-Process KoffeeExternal -ErrorAction SilentlyContinue).Count)
$o += ('all_exes=' + ((Get-Process | Where-Object { $_.Name -match 'Koffee|koffee' }).Count))
Write-Output ($o -join "`n")