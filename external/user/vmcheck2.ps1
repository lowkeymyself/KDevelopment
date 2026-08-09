$o = @()
Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'koffee|cmd|conhost' } | ForEach-Object { $o += ($_.Name + ' ' + $_.Id + ' cpu=' + [math]::Round($_.CPU,1)) }
$o += '=== step.log ==='
$o += (Get-Content 'C:\Users\User\AppData\Local\Temp\koffee\step.log' -ErrorAction SilentlyContinue)
$o += '=== step.err ==='
$o += (Get-Content 'C:\Users\User\AppData\Local\Temp\koffee\step.err' -ErrorAction SilentlyContinue)
$o += '=== step.ec ==='
$o += (Get-Content 'C:\Users\User\AppData\Local\Temp\koffee\step.ec' -ErrorAction SilentlyContinue)
$o += '=== loaded drivers with lnv/msr ==='
$o += (Get-CimInstance Win32_SystemDriver -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'lnv|SPrh|msri|winmsr' -or $_.PathName -match 'lnv|temp' } | ForEach-Object { $_.Name + ' state=' + $_.State + ' start=' + $_.StartMode + ' path=' + $_.PathName })
Write-Output ($o -join "`n")