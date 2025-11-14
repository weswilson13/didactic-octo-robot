function Import-FileTransferCSV {
    [cmdletbinding()]
    param([string]$Log)

    $ErrorActionPreference = 'SilentlyContinue'

    $result = @()
    $data = Import-Csv $Log

    foreach ($obj in $data) {
        #$versionInfo = $obj.VersionInfo.Split("`n").foreach({$key,$value=$_.split(':',2); @{$key.trim()=$value.trim()}})
        $notePropertyMembers = @{
            VersionInfo = $obj.VersionInfo.Split("`n").foreach({
                $key,$value=$_.split(':',2)
                [psobject]@{$key.trim()=$value.trim()}
            })
        }
        $null=Add-Member -InputObject $obj -NotePropertyMembers $notePropertyMembers -Force -PassThru
        $result += $obj
    }

    $ErrorActionPreference = 'Continue'

    return $result
}

function Get-FileVersion {
<#
    .SYNOPSIS
    Returns string containing the file version, derived preferentially from the object VersionInfo.

    We first check the FileVersion attribute. If this value is empty, then check the ProductVersion attribute. Next check filename for a valid version.
    If still no version returned, use AppLocker to try to pull version info - this method requires the file to be present.
#>

    [cmdletbinding()]
    param([object]$FileInfo)

    if ($FileInfo.VersionInfo.FileVersion -and $FileInfo.BaseName -notmatch 'idrac|bios') { # DELL seems to store the actual version in the ProductVersion attribute
        $newVersion = $FileInfo.VersionInfo.FileVersion

        if ([version]::TryParse($newVersion,[ref]$null)) {
            return $newVersion
        }
    }
    
    if ($FileInfo.VersionInfo.ProductVersion) { # check ProductVersion property
        $newVersion = $FileInfo.VersionInfo.ProductVersion

        if ([version]::TryParse($newVersion,[ref]$null)) {
            return $newVersion
        }
    } 
    else { # try to get a version from the file name
        $newVersion = [regex]::Match($FileInfo.BaseName, '(\d+\.?)+').Value

        if ([version]::TryParse($newVersion,[ref]$null)) {
            return $newVersion
        }
    }

    if (Test-Path $FileInfo.FullName) { # leverage applocker to try to pull out the version (SLOW!!!!)
        #Write-Host "Collecting AppLocker file information"
        $newVersion = (Get-AppLockerFileInformation -Path $FileInfo.FullName).Publisher.BinaryVersion.ToString()
        
        if ([version]::TryParse($newVersion,[ref]$null)) {
            return $newVersion
        }
    }

    throw "Unable to determine a valid file version"
}

$log = "$env:USERPROFILE\OneDrive\OneDrive - PrimeNet\SoftwareVersions\FileTransferLog.csv"

while ($true) { # loop indefinitely

    $transferredFiles = Import-FileTransferCSV $log
    $files = Get-ChildItem "$env:USERPROFILE\OneDrive\OneDrive - PrimeNet\ToNNPP" 

    foreach ($file in $files) { # check each file against the log
        Write-Host "New file detected - $($file.Name.TrimStart('_'))"

        # wait for the file to finish downloading
        Write-Host "`tWaiting for download to complete."
        $lastSize = 0
        $waiting = "`t."
        # Loop until the file size remains unchanged for 10 seconds

        do {
            while ($true) {
                Start-Sleep -Seconds 5
                $newSize = Get-ItemPropertyValue -Path $file.FullName -Name Length
               # ('"LastSize","NewSize"
               # "{0}","{1}"' -f $lastSize,$newSize) | ConvertFrom-Csv | format-table

                if ($newSize -eq $lastSize) {
                    Write-Host "`tFile size is stable. Download complete."
                    break
                }
                $lastSize = $newSize
            
                $waiting += "."
                Write-Host $waiting
            }

            try { 
                $_file = Rename-Item -Path $file.FullName -NewName $file.Name.TrimStart('_') -PassThru -ErrorAction Stop
                $file = $_file
            }
            catch {
                Write-Host "`t$($error[0].Exception.message)" -ForegroundColor Yellow
            }
        } while ($file.Name.StartsWith('_'))

        Write-Host "`t$($file.Name) has finished downloading"

        if ($logEntry = $transferredFiles | Where-Object {$_.Name -eq $file.Name}) { # if the file already exists in the log, skip it
            Write-Host "`tFound a matching filename in the log. Comparing file versions..." -NoNewline

            try {
                $fileVersion = ""
                [string]$fileVersion = Get-FileVersion (Get-Item $file.FullName)
                $fileVersion = $fileVersion.Trim()
            }
            catch {
                Write-Host "`t$($error[0].Exception.message)" -ForegroundColor Red
            }

            $logVersion = $logEntry._FileVersion

            #'"File Version","Log Version"
            # "{0}","{1}"' -f $fileVersion, (($logVersion | Sort-Object -Descending) -join ',') | ConvertFrom-Csv | Out-String | Write-Host -ForegroundColor Cyan
              
            if ($fileVersion.Trim() -in $logVersion) { 
                Write-Host "MATCH FOUND" -ForegroundColor Yellow
                Write-Host "`t$($file.Name) @ $($fileVersion) is already in the log."
                Write-Host ""
                continue 
            }
            Write-Host "NO MATCH" -ForegroundColor DarkGreen
        }

        # add file to log
        $null=Add-Member -InputObject $file -NotePropertyName '_FileVersion' -NotePropertyValue $fileVersion.Trim() -Force -PassThru
        $file | Export-Csv $log -NoTypeInformation -Append 
        Write-Host "`tAdded $($file.Name) to log." -ForegroundColor Green
        Write-Host ""
    }

    # wait 30 seconds between polls
    Start-Sleep 30
}
