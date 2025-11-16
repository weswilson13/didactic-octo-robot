$path = "$env:USERPROFILE\OneDrive\OneDrive - PrimeNet\SoftwareVersions\ScheduledTask\XML"

$xmlRaw = Get-Content $path\MonitorFileTransfers_Headless.xml -Raw
$xmlRaw = $xmLRaw -replace '%USERNAME%', $env:USERNAME

$guid = [guid]::NewGuid().Guid
$tempPath = "$env:TEMP\${guid}.xml"
$xmlRaw | Out-File $tempPath

schtasks.exe /Create /XML $tempPath /tn MonitorFileTransfers

Remove-Item $tempPath -Force
