$exe = 'C:\Users\joaol\AppData\Local\Temp\koffee\KoffeeExternal.exe'
& $exe --ram-dump 2>&1 | Out-String | Write-Host