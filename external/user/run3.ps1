$exe = 'C:\Users\User\AppData\Local\Temp\koffee\KoffeeExternal.exe'
$out = 'C:\Users\User\AppData\Local\Temp\koffee\full'
Remove-Item ($out + '.log') -ErrorAction SilentlyContinue
Remove-Item ($out + '.err') -ErrorAction SilentlyContinue
$p = Start-Process -FilePath $exe -WorkingDirectory 'C:\Users\User\AppData\Local\Temp\koffee' -RedirectStandardOutput ($out + '.log') -RedirectStandardError ($out + '.err') -PassThru
Set-Content -Path 'C:\Users\User\AppData\Local\Temp\koffee\pid.txt' -Value $p.Id