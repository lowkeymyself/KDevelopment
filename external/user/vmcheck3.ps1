Start-Sleep -Seconds 15
$o = @()
$o += '=== liveout ==='
$o += (Get-Content 'C:\Users\User\AppData\Local\Temp\koffee\liveout.txt' -ErrorAction SilentlyContinue)
$o += '=== liveerr ==='
$o += (Get-Content 'C:\Users\User\AppData\Local\Temp\koffee\liveerr.txt' -ErrorAction SilentlyContinue)
$o += '=== drivers ==='
$o += (Get-CimInstance Win32_SystemDriver -ErrorAction SilentlyContinue | Where-Object { $_.PathName -match 'Temp\\lnv|Temp\\rtc' } | ForEach-Object { $_.Name + ' state=' + $_.State + ' path=' + $_.PathName })
$o += ('=== koffee proc: ' + @(Get-Process KoffeeExternal -ErrorAction SilentlyContinue).Count + ' found ===')
Write-Output ($o -join "`n")