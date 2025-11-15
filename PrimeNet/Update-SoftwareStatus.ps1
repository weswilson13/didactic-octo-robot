function New-Html {
    param(
        [switch]$Server,
        [switch]$Switch
    )
    
    function Get-Links {
        $links = $software.Link.split(',') 
        $linkTexts = $software.LinkText.Split(';')

        for ($i=0; $i -lt $links.Count; $i++) {
            $aryLinks += "<a href=`"$($links[$i])`" target=`"_blank`">$($linkTexts[$i])</a>"
        }

        return $aryLinks -join "<br>`r"
    }
    
    $html = ""

    if ($Server.IsPresent) { # use data from ServerSoftware.csv
        $collection = $serverSoftware
    }
    elseif ($switch.IsPresent) { # use data from SwitchImages.csv
        $collection = $switchImages
    }
    else { # use date from SoftwareVersions.csv
        $collection = $softwareVersions
    }

    foreach ($software in $collection) { # loop over each line in the .csv
        $aryLinks = @()
        $img, $checked, $tss = $null

        # get software title
        $softwareName = $software.SoftwareName
        if ($software.LogoOnly -eq 1) { # software logo contains the name, so don't add text
            $softwareName = $null 
        }

        # get login required checkbox
        if ($software.LoginRequired -eq 1) { # login required to get to downloads. Show this displayed as a checked checkbox
            $checked = " checked" 
        }

        # get TSS credential ID
        if ($software.TSS_ID) {
            $tss = '<img height="25px" src="./images/tss.png" onclick="javascript:alert(''Get login credentials using Secret Server ID: {0}'');">' -f $software.TSS_ID
        }

        # set up img element
        $imgScriptBlock = {$_.Name -match '^' + $software.Id.Replace('+','\+')}
        $src = Get-ChildItem $folder\images | Where-Object $imgScriptBlock | Select-Object -ExpandProperty Name
        if ($src) { $img = "<img height=`"30px`" src=`".\images\$src`">" }

        # get the software link(s)
        $strLinks = Get-Links

        # create the HTML
        if ($Server.IsPresent) { # server software table format
            $html += "<tr class=`"$($software.ServerModel.Replace(' ',''))`">
                        <td class=`"ServerApp`">{0}</td>
                        <td class=`"$($software.ServerModel.Replace(' ',''))`">{1}</td>
                        <td id=`"{2}`" class=`"Version`">[{2}]</td>
                        <td>
                            {3}
                        </td>
                    </tr>" -f $software.ServerModel, $software.ProductType, $software.Id, $strLinks
        }
        elseif ($Switch.IsPresent) { # switch images table format
            $html += "<tr class=`"$($software.SwitchModel)`">
                        <td>{0}</td>
                        <td class=`"$($software.SwitchModel)`">{0}</td>
                        <td id=`"{1}`" class=`"Version`">[{1}]</td>
                        <td>
                            {2}
                        </td>
                    </tr>" -f $software.SwitchModel, $software.Id, $strLinks
        }
        else { # software versions table format
            $html += "<tr>
                        <td class=`"order`">$($software.SoftwareName)</td>
                        <td class=`"{3} App align-middle`">$img{0}</td>
                        <td id=`"{1}`" class=`"Version align-middle`">[{1}]</td>
                        <td class=`"align-middle`">
                            {2}
                        </td>
                        <td class=`"checkbox text-center align-middle`"><input type=`"checkbox`"$checked>$tss</td>
                    </tr>" -f $softwareName, $software.Id, $strLinks, $software.Bin
        }
    }
    
    # update the datetime the software was updated
    foreach ($obj in $collection) { # loop through each line of the .csv
        $version,$fileDate,$newContent = $null
    
        # add the updated date to the output so it is easier to see the last time the software was pulled
        $app = $obj.id
        $version = $obj.LatestVersion
        if ($version) {
            $_date = $obj.DateTime
            if ($_date) {
                Write-Host "$app, $_date"
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

$folder = switch -Regex ($env:USERDNSDOMAIN) {
    'UNRPNET.GOV' { Get-ChildItem "$env:USERPROFILE\OneDrive\OneDrive - PrimeNet" -Directory | 
                    Where-Object {$_.Name -match 'SoftwareVersions'} | Select-Object -ExpandProperty FullName
    }
    default { $PSScriptRoot }
}
$template = Join-Path $folder "Templates\SoftwareStatusTemplate.html"
$firmware = Join-Path $folder "firmware.txt"

# CSV filepaths
$softwareVersionsCsv = Join-Path $folder "SoftwareVersions.csv"
$serverVersionsCsv = Join-Path $folder "ServerSoftware.csv"
$switchImagesCsv = Join-Path $folder "SwitchImages.csv"

$softwareVersions = Import-Csv $softwareVersionsCsv
$serverSoftware = Import-Csv $serverVersionsCsv
$switchImages = Import-Csv $switchImagesCsv

# add more applications here as necessary. update html template accordingly.
$printerModels = "8500,609,551,577,578,652,506,612,6800,776,5700"
$printerModels = $printerModels.Split(',') | Sort-Object @{e={[int]$_}}

$htmlContent = Get-Content $template -Raw -Encoding UTF8
$htmlContent = $htmlContent.Replace('[date]',(Get-Date -f 'MM/dd/yyyy HH:mm'))
$htmlContent = $htmlContent.Replace('[softwareHtml]', (New-Html))
$htmlContent = $htmlContent.Replace('[serverHtml]', (New-Html -Server))
$htmlContent = $htmlContent.Replace('[switchHtml]', (New-Html -Switch))

# create button group
$buttonHtml = @("<button class=`"btn btn-primary All`" type=`"button`">All</button>")
$buttons = $softwareVersions | Select-Object @{n='Name';e={$_.Bin}}, @{n='Label';e={'Software'}} -Unique
$buttons += $serverSoftware | Select-Object @{n='Name';e={$_.ServerModel}}, @{n='Label';e={'Server'}} -Unique
$buttons += $switchImages | Select-Object @{n='Name';e={$_.SwitchModel}}, @{n='Label';e={'Switch'}} -Unique

# review printer firmware
$firmwareFileInfo = Get-ItemProperty $firmware
$firmwares = Get-Content $firmware

$htmlContent = $htmlContent.Replace('[printer-date]',$firmwareFileInfo.LastWriteTime)
$html = ""

foreach ($printer in $printerModels) { # loop through each printer model 
    
    $latestFirmware = $firmwares | Where-Object { $_ -match "M?$printer" } | Select-Object -Last 1
    $printer = [regex]::Match($latestFirmware, "M?$printer").Value
    if ($printer[0] -match '\d') { $printer = "_$printer" }

    $html += "<tr><td class=`"Printer $printer`">$($printer.replace('_',''))</td><td class=`"firmware`">$latestFirmware</td></tr>"
    $buttons += $printer | Select-Object  @{n='Name';e={$_.replace('_','')}}, @{n='Label';e={'Printer'}} -Unique

} # end foreach

$htmlContent = $htmlContent.Replace('[printerHtml]', $html)

foreach ($button in $buttons) {
    $buttonHtml += "<button class=`"btn btn-primary $($button.Label)`" type=`"button`">$($button.Name)</button>"
}
$buttonHtml = $buttonHtml -join "`n"
$htmlContent = $htmlContent.Replace('[buttonHtml]', $buttonHtml)

$htmlContent | Out-File "$folder\SoftwareStatus.html" -Encoding utf8
