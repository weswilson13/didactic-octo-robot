function Get-RegistryValue {
    [cmdletbinding()]
    param(
        [ValidateSet('MonitoredFolder','TransferLog','SoftwareVersions','ActivityLog')]
        [string]$Key
    )

    $value = Get-ItemProperty HKCU:\Environment\FileTransfer -Name $Key -ErrorAction Stop | Select-Object -ExpandProperty $Key

    return $value
}

$path = Join-Path (Get-RegistryValue SoftwareVersions) ScheduledTask\XML

$xmlRaw = Get-Content $path\CheckSoftwareRepo.xml -Raw
$xmlRaw = $xmLRaw -replace '%USERNAME%', $env:USERNAME

$guid = [guid]::NewGuid().Guid
$tempPath = "$env:TEMP\${guid}.xml"
$xmlRaw | Out-File $tempPath

schtasks.exe /Create /XML $tempPath /tn CheckSoftwareRepo

Remove-Item $tempPath -Force
