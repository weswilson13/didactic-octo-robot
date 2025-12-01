function Get-RegistryValue {
    [cmdletbinding()]
    param(
        [ValidateSet('MonitoredFolder','TransferLog','SoftwareVersions','ActivityLog')]
        [string]$Key
    )

    try { 
        $value = Get-ItemProperty HKCU:\Environment\FileTransfer -Name $Key -ErrorAction Stop | Select-Object -ExpandProperty $Key
    }
    catch {
        throw "$($error[0].Exception.Message). Please run Set-RegistryKeys.ps1 in SoftwareVersions\Setup to configure the necessary registry settings."
    }

    return $value
}

$path = Join-Path (Get-RegistryValue SoftwareVersions) ScheduledTask\XML
$xml = Get-ChildItem $path | Where-Object {$_.Extension -eq '.xml'}

foreach ($x in $xml) {
    $xmlRaw = Get-Content $x.FullName -Raw
    $xmlRaw = $xmLRaw -replace '%USERNAME%', $env:USERNAME

    $guid = [guid]::NewGuid().Guid
    $tempPath = "$env:TEMP\${guid}.xml"
    $xmlRaw | Out-File $tempPath

    # Create the scheduled task
    schtasks.exe /Create /XML $tempPath /tn $x.BaseName.Replace('_Headless','')

    Remove-Item $tempPath -Force
}
