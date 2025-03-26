$folder = "$env:USERPROFILE\OneDrive\OneDrive - PrimeNet\SoftwareVersions"
$template = Join-Path $folder "SoftwareStatusTemplate.html"
$firmware = Join-Path $folder "firmware.txt"

# add more applications here as necessary. update html template accordingly.
$printerModels = "8500,609,551,577,578,652,506,612,6800,776,5700"
$applications = 'adobe','edge','chrome','firefox','git','linqpad','nodejs','npp','powershell','vmware','defender','terminal','vscode','winscp'
$vmwareProducts = 'esxi','vcenter','tools','horizon','vsan'

$content = Get-Content $template

$content = $content.Replace('[date]',(Get-Date -f 'MM/dd/yyyy HH:mm'))

# get all text files files
$files = Get-ChildItem $folder | Where-Object {$_.Extension -eq '.txt'}

foreach ($app in $applications) {
    $version,$fileDate = $null

    # get the associated text file
    $file = $files | Where-Object {$_.basename -match $app}

    if (!$file) { # update html and move to next
        Write-Host "No file for $app" -ForegroundColor Yellow
        $content = $content.Replace("[$app]","")
        continue 
    } # end if

    # add the file date to the output so it is easier to see the last time the software was pulled
    $fileDate = $file.LastWriteTime
    
    Write-Host "$file, $fileDate"
    if ([datetime]$fileDate -gt [datetime]::Now.AddHours(-24)) { $fileDate = "<span class=`"new`">$fileDate<span>" }

    if ($app -ne 'vmware') { # vmware file needs to be handled differently

        $version = Get-Content $file.FullName
        $newContent = "<b>$version</b>  ($fileDate)"
        $content = $content.Replace("[$app]",$newContent)

    } # end if

    else { # parse each VMWare line separately
        $versions = Get-Content $file.FullName


        foreach ($product in $vmwareProducts) { # loop through each VMWare product

            $ver = $versions.Where({$_ -match $product})

            $version,$_app = switch($product) {
                'esxi'{ @([regex]::Match($ver, '\d Update \d\w' ).Value, 'vmware_esxi'); break }
                'vcenter' { @([regex]::Match($ver, '\d Update \d\w' ).Value, 'vmware_vcenter'); break }
                'horizon' { @([regex]::Match($ver, '\d+\.\d+' ).Value, 'vmware_horizon'); break }
                'tools' { @([regex]::Match($ver, '(\d+\.?)+' ).Value, 'vmware_tools'); break }
                'vsan' { @([regex]::Match($ver, '(\d+\.?)+' ).Value, 'vmware_vsan'); break }
                default { @("", "vmware_$product") }
            }# end switch

            $_fileDate = $fileDate
            $newContent = "<b>$version</b>  ($_fileDate)"
            if ($version -eq "") { $newContent = "" }
            $content = $content.Replace("[$_app]",$newContent)

        } # end foreach

    }# end else

} # end foreach

# review printer firmware
$firmwareFileInfo = Get-ItemProperty $firmware
$firmwares = Get-Content $firmware

$content = $content.Replace('[printer-date]',$firmwareFileInfo.LastWriteTime)

foreach ($printer in $printerModels.Split(',')) { # loop through each printer model 

    $latestFirmware = $firmwares | Where-Object { $_ -match "M?$printer" } | Select-Object -Last 1
    $content = $content -replace "\[M?$printer\]",$latestFirmware

} # end foreach

$content | Out-File "$folder\SoftwareStatus.html"
