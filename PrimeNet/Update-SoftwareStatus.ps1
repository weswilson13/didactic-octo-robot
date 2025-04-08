$folder = "$env:USERPROFILE\OneDrive\OneDrive - PrimeNet\SoftwareVersions"
$template = Join-Path $folder "SoftwareStatusTemplate.html"
$firmware = Join-Path $folder "firmware.txt"
$softwareVersionsCsv = Join-Path $folder "SoftwareVersions.csv"
$softwareVersions = Import-Csv $softwareVersionsCsv

# add more applications here as necessary. update html template accordingly.
$printerModels = "8500,609,551,577,578,652,506,612,6800,776,5700"

$htmlContent = Get-Content $template
$htmlContent = $htmlContent.Replace('[date]',(Get-Date -f 'MM/dd/yyyy HH:mm'))

foreach ($obj in $softwareVersions) {
    $version,$fileDate,$newContent = $null

    # add the updated date to the output so it is easier to see the last time the software was pulled
    $app = $obj.id
    $version = $obj.LatestVersion
    if ($version) {
        $_date = $obj.DateTime
        if ($_date) {
            #Write-Host "$app, $_date"
            if ([datetime]$_date -gt [datetime]::Now.AddHours(-24)) { $_date = "<span class=`"new`">$_date<span>" }
        }
        else {
            $_date = "???" 
        }

        $newContent = "<b>$version</b>  ($_date)"
    }
    $htmlContent = $htmlContent.Replace("[$app]",$newContent)

} # end foreach

# review printer firmware
$firmwareFileInfo = Get-ItemProperty $firmware
$firmwares = Get-Content $firmware

$htmlContent = $htmlContent.Replace('[printer-date]',$firmwareFileInfo.LastWriteTime)

foreach ($printer in $printerModels.Split(',')) { # loop through each printer model 

    $latestFirmware = $firmwares | Where-Object { $_ -match "M?$printer" } | Select-Object -Last 1
    $htmlContent = $htmlContent -replace "\[M?$printer\]",$latestFirmware

} # end foreach

$htmlContent | Out-File "$folder\SoftwareStatus.html"
