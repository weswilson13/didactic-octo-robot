$path = "$env:USERPROFILE\OneDrive\OneDrive - PrimeNet\SoftwareVersions\ScheduledTask\XML"
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
