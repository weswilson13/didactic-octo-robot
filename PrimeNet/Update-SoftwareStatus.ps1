function New-Html {
    param([switch]$Server)
     
    $html = ""
    if ($Server.IsPresent) {
        $collection = $serverSoftware
    }
    else {
        $collection = $softwareVersions
    }
    foreach ($software in $collection) {
        $aryLinks = @()
        $img, $checked = $null
        $softwareName = $software.SoftwareName
        if ($software.LogoOnly -eq 1) { $softwareName = $null }

        if ($software.LoginRequired -eq 1) { $checked = " checked" }

        $links = $software.Link.split(',') 
        $linkTexts = $software.LinkText.Split(';')
        $src = Get-ChildItem .\images | Where-Object { $_.Name -match $software.Id } | Select-Object -ExpandProperty Name
        if ($src) { $img = "<img height=`"30px`" src=`".\images\$src`">" }
        <#switch($software.Id) {
            'teradici' { "<img style=`"background-color:blue`" height=`"30px`" src=`".\images\teradici.svg`">"; break }
            'hpwja' { "<img height=`"30px`" src=`".\images\hpwja.jpg`">"; break }
            'servicepro' { "<img height=`"30px`" src=`".\images\servicepro.png`">"; break }
            'ssms' { "<img height=`"30px`" src=`".\images\ssms.png`">"; break }
            'vscode' { "<img height=`"30px`" src=`".\images\vscode.png`">"; break }
            default { $null }
        }#>

        for ($i=0; $i -lt $links.Count; $i++) {
            $aryLinks += "<a href=`"$($links[$i])`" target=`"_blank`">$($linkTexts[$i])</a>"
        }
        $strLinks = $aryLinks -join "<br>`r"

        if ($Server.IsPresent) {
            $html += "<tr class=`"$($software.ServerModel.Replace(' ',''))`">
                        <td class=`"ServerApp`">{0}</td>
                        <td>{1}</td>
                        <td id=`"{2}`" class=`"Version`">[{2}]</td>
                        <td>
                            {3}
                        </td>
                    </tr>" -f $software.ServerModel, $software.ProductType, $software.Id, $strLinks
        }
        else {
            $html += "<tr>
                        <td class=`"{3} App`">$img{0}</td>
                        <td id=`"{1}`" class=`"Version`">[{1}]</td>
                        <td>
                            {2}
                        </td>
                        <td class=`"checkbox text-center align-middle`"><input type=`"checkbox`"$checked></td>
                    </tr>" -f $softwareName, $software.Id, $strLinks, $software.Bin
        }
    }
    
    foreach ($obj in $collection) {
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
                $_date = "<span class=`"nodate`">???<span>" 
            }
    
            $newContent = "<b>$version</b>  ($_date)"
        }
        $html = $html.Replace("[$app]",$newContent)
    
    } # end foreach

    return $html
}

$folder = "$env:USERPROFILE\OneDrive\OneDrive - PrimeNet\SoftwareVersions"
$template = Join-Path $folder "SoftwareStatusTemplate.html"
$firmware = Join-Path $folder "firmware.txt"
$softwareVersionsCsv = Join-Path $folder "SoftwareVersions.csv"
$serverVersionsCsv = Join-Path $folder "ServerSoftware.csv"
$softwareVersions = Import-Csv $softwareVersionsCsv
$serverSoftware = Import-Csv $serverVersionsCsv

# add more applications here as necessary. update html template accordingly.
$printerModels = "8500,609,551,577,578,652,506,612,6800,776,5700"
$printerModels = $printerModels.Split(',') | Sort-Object @{e={[int]$_}}

$htmlContent = Get-Content $template -Raw
$htmlContent = $htmlContent.Replace('[date]',(Get-Date -f 'MM/dd/yyyy HH:mm'))
$htmlContent = $htmlContent.Replace('[softwareHtml]', (New-Html))
$htmlContent = $htmlContent.Replace('[serverHtml]', (New-Html -Server))

# create button group
$buttonHtml = @("<button class=`"btn btn-primary All`" type=`"button`">All</button>")
$buttons = $softwareVersions | Select-Object @{n='Name';e={$_.Bin}}, @{n='Label';e={'Software'}} -Unique
$buttons += $serverSoftware | Select-Object @{n='Name';e={$_.ServerModel}}, @{n='Label';e={'Server'}} -Unique

# review printer firmware
$firmwareFileInfo = Get-ItemProperty $firmware
$firmwares = Get-Content $firmware

$htmlContent = $htmlContent.Replace('[printer-date]',$firmwareFileInfo.LastWriteTime)
$html = ""
foreach ($printer in $printerModels) { # loop through each printer model 
    
    $latestFirmware = $firmwares | Where-Object { $_ -match "M?$printer" } | Select-Object -Last 1
    $printer = [regex]::Match($latestFirmware, "M?$printer").Value
    $html += "<tr><td class=`"Printer $printer`">$printer</td><td class=`"firmware`">$latestFirmware</td></tr>"
    $buttons += $printer | Select-Object  @{n='Name';e={$_}}, @{n='Label';e={'Printer'}} -Unique

} # end foreach

$htmlContent = $htmlContent.Replace('[printerHtml]', $html)

foreach ($button in $buttons) {
    $buttonHtml += "<button class=`"btn btn-primary $($button.Label)`" type=`"button`">$($button.Name)</button>"
}
$buttonHtml = $buttonHtml -join "`n"
$htmlContent = $htmlContent.Replace('[buttonHtml]', $buttonHtml)

$htmlContent | Out-File "$folder\SoftwareStatus.html"
