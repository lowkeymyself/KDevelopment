$o = @()
$o += '=== procs ==='
Get-Process KoffeeExternal,cmd -ErrorAction SilentlyContinue | Select-Object Name,Id | ForEach-Object { $o += ($_.Name + ' ' + $_.Id) }
$o += '=== services ==='
$names = @('SPrhSMIiDvklGDvR')
foreach ($n in $names) {
  $k = "HKLM:\SYSTEM\CurrentControlSet\Services\$n"
  if (Test-Path $k) { $o += ("SVC " + $n + " EXISTS ImagePath=" + (Get-ItemProperty $k -Name ImagePath -ErrorAction SilentlyContinue).ImagePath) }
  else { $o += ("SVC " + $n + " ABSENT") }
}
$o += '=== device ==='
$d = Get-CimInstance Win32_PnPEntity -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'MSR|Lnv|Koffee|Mem' -or $_.DeviceID -match 'lnv|msr' }
foreach ($x in $d) { $o += ($x.Name + ' :: ' + $x.Status) }
$o += '=== memory integrity ==='
$mi = Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard -ErrorAction SilentlyContinue
if ($mi) { $o += ('VBS=' + $mi.VirtualizationBasedSecurityStatus + ' SecurityServicesRunning=' + ($mi.SecurityServicesRunning -join ',')) }
$wd = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity' -Name Enabled -ErrorAction SilentlyContinue).Enabled
$o += ('HVCI.Enabled=' + $wd)
Write-Output ($o -join "`n")