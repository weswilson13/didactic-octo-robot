$xmlRaw = Get-Content UpdateSoftwareStatusCSV_Headless.xml -Raw
$xmlRaw = $xmLRaw -replace '%USERNAME%', $env:USERNAME

$guid = [guid]::NewGuid().Guid
$tempPath = "$env:TEMP\${guid}.xml"
$xmlRaw | Out-File $tempPath

schtasks.exe /Create /XML $tempPath /tn UpdateSoftwareStatusCSV

Remove-Item $tempPath -Force
