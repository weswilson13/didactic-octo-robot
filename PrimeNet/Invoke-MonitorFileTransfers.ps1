function Import-FileTransferCSV {
    [cmdletbinding()]
    param([string]$Log)

    $ErrorActionPreference = 'SilentlyContinue'

    $result = @()
    $data = Import-Csv $Log

    foreach ($obj in $data) {
        #$versionInfo = $obj.VersionInfo.Split("`n").foreach({$key,$value=$_.split(':',2); @{$key.trim()=$value.trim()}})
        $null=Add-Member -InputObject $obj -NotePropertyMembers @{VersionInfo = $obj.VersionInfo.Split("`n").foreach({$key,$value=$_.split(':',2); @{$key.trim()=$value.trim()}})} -Force -PassThru
        $result += $obj
    }

    $ErrorActionPreference = 'Continue'

    return $result
}

function Get-FileVersion {
    [cmdletbinding()]
    param([object]$FileInfo)

    if ($FileInfo.VersionInfo.FileVersion) {
        $newVersion = $FileInfo.VersionInfo.FileVersion
    }
    elseif ($FileInfo.VersionInfo.ProductVersion) { # check ProductVersion property
        $newVersion = $FileInfo.VersionInfo.ProductVersion
    }
    else { # try to get a version from the file name
        $newVersion = [regex]::Match($FileInfo.BaseName, '(\d+\.?)+').Value
    }

    return $newVersion
}

$log = "$env:USERPROFILE\OneDrive\OneDrive - PrimeNet\SoftwareVersions\FileTransferLog.csv"

while ($true) { # loop indefinitely

    $transferredFiles = Import-FileTransferCSV $log
    $files = Get-ChildItem "$env:USERPROFILE\OneDrive\OneDrive - PrimeNet\ToNNPP" 

    foreach ($file in $files) { # check each file against the log
        Write-Host "New file detected - $($file.Name)"

        if ($file.Name -in $transferredFiles.Name) { # if the file already exists in the log, skip it
            Write-Host "`tFound a matching filename in the log. Comparing file versions..." -NoNewline
            $logEntry = $transferredFiles | Where-Object {$_.Name -eq $file.Name}
            [string]$fileVersion = $file.VersionInfo.FileVersion
            $logVersion = $logEntry.VersionInfo.FileVersion.Trim()

            if ($fileVersion -in $logVersion) { 
                Write-Host "MATCH FOUND" -ForegroundColor Yellow
                Write-Host "`t$($file.Name) @ $($file.VersionInfo.FileVersion) is already in the log."
                continue 
            }
            Write-Host "NO MATCH" -ForegroundColor DarkGreen
        }

        # wait for the file to finish downloading
        $lastSize = 0

        # Loop until the file size remains unchanged for 10 seconds
        while ($true) {
            Start-Sleep -Seconds 5
            $newSize = (Get-Item $file.FullName).Length
            if ($newSize -eq $lastSize) {
                Write-Host "`tFile size is stable. Download complete."
                break
            }
            $lastSize = $newSize
        }

        Write-Host "`t$($file.Name) has finished downloading"

        # add file to log
        if ([string]$file.VersionInfo.FileVersion -eq "") { # try to add the file version using our function
            $file.VersionInfo.FileVersion = Get-FileVersion $file
        }
        $file | Export-Csv $log -NoTypeInformation -Append 
        Write-Host "`tAdded $($file.Name) to log."
    }

    # wait 30 seconds between polls
    Start-Sleep 30
}
