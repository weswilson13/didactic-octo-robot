function New-Html {
    $html = ""
    foreach ($software in $softwareVersions) {
        $aryLinks = @()
        $links = $software.Link.split(',') 
        $linkTexts = $software.LinkText.Split(',')
        
        for ($i=0; $i -lt $links.Count; $i++) {
        $aryLinks += "<a href=`"$($links[$i])`" target=`"_blank`">$($linkTexts[$i])</a>"
        }
        $strLinks = $aryLinks -join "<br>"
        $html += "<tr>
                    <td class=`"App`">{0}</td>
                    <td id=`"{1}`" class=`"Version`">[{1}]</td>
                    <td>
                        {2}
                    </td>
                </tr>" -f $software.SoftwareName, $software.Id, $strLinks
    }
    $formattedHtml = Format-HTML -Content $html

    return $formattedHtml -Replace '</?html>'
}
$folder = "$env:USERPROFILE\OneDrive\OneDrive - PrimeNet\SoftwareVersions"
$template = Join-Path $folder "SoftwareStatusTemplate.html"
$firmware = Join-Path $folder "firmware.txt"
$softwareVersionsCsv = Join-Path $folder "SoftwareVersions.csv"
$softwareVersions = Import-Csv $softwareVersionsCsv

# add more applications here as necessary. update html template accordingly.
$printerModels = "8500,609,551,577,578,652,506,612,6800,776,5700"
$printerModels = $printerModels.Split(',') | Sort-Object @{e={[int]$_}}

$htmlContent = Get-Content $template -Raw
$htmlContent = $htmlContent.Replace('[date]',(Get-Date -f 'MM/dd/yyyy HH:mm'))
$htmlContent = $htmlContent.Replace('[softwareHtml]', (New-Html))

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
$html = ""
foreach ($printer in $printerModels) { # loop through each printer model 
    
    $latestFirmware = $firmwares | Where-Object { $_ -match "M?$printer" } | Select-Object -Last 1
    $printer = [regex]::Match($latestFirmware, "M?$printer").Value
    $html += "<tr><td class=`"Printer`">$printer</td><td class=`"firmware`">$latestFirmware</td></tr>"

} # end foreach

$formattedHtml = Format-HTML -Content $html
$htmlContent = $htmlContent.Replace('[printerHtml]', $formattedHtml)

$htmlContent | Out-File "$folder\SoftwareStatus.html"