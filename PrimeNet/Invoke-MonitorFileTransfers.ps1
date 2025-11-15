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

# set $VerbosePreference to 'Continue' for testing, 'SilentlyContinue' for normal operation
#$VerbosePreference = [System.Management.Automation.ActionPreference]::Continue
VerbosePreference = [System.Management.Automation.ActionPreference]::SilentlyContinue

$log = "$env:USERPROFILE\OneDrive\OneDrive - PrimeNet\SoftwareVersions\FileTransferLog.csv"
$toNNPP = "$env:USERPROFILE\OneDrive\OneDrive - PrimeNet\ToNNPP"

while ($true) { # loop indefinitely
    Clear-Host
    Write-Verbose "[$(Get-Date -f 'MM\\dd\\yyyy hh:mm:ss tt')] Checking $toNNPP"
    Write-Verbose "Cached File Version: $fileVersion"
    Write-Verbose "Cached Log Version: $logVersion"
    if ($fileVersion -or $logVersion) {
        # reset the versions for the next iteration
        $fileVersion = $null
        $logVersion = $null
        Write-Verbose "Reset version variables."
    }

    $transferredFiles = Import-FileTransferCSV $log
    $files = Get-ChildItem $toNNPP

    foreach ($file in $files) { # check each file against the log
        # reinitialize variables 
        $fileVersion = [string]::Empty
        $logVersion = [string]::Empty
        [bool]$failedToGetVersion = $false

        Write-Host "New file detected - $($file.Name.TrimStart('_'))"

        # wait for the file to finish downloading
        Write-Host "`tWaiting for download to complete."
        $lastSize = 0
        $waiting = "`t"
        # Loop until the file size remains unchanged for 10 seconds

        while ($true) {
            Start-Sleep -Seconds 5
            $newSize = Get-ItemPropertyValue -Path $file.FullName -Name Length
               
            # ('"LastSize","NewSize"
            # "{0}","{1}"' -f $lastSize,$newSize) | ConvertFrom-Csv | format-table

            if ($newSize -eq $lastSize) {
                Write-Host "" # ensures next console output is on a new line
                Write-Host "`tFile size is stable. Download complete."
                break
            }
            $lastSize = $newSize
            
            Write-Host "." -NoNewLine
        }

        Write-Verbose "[Program] Enter Do Loop."
        do {
            Write-Verbose "Attempt to update file name"
            try { 
                Start-Sleep 2 # short pause

                if($file.Name.StartsWith('_')) { # remove this artifact from the repository transfer
                    $_file = Rename-Item -Path $file.FullName -NewName $file.Name.TrimStart('_') -PassThru -ErrorAction Stop
                    $file = $_file
                    Write-Verbose "file name changed to: $($file.Name)"
                }
            }
            catch {
                Write-Host "`t$($error[0].Exception.message)" -ForegroundColor Yellow
            }
        } while ($file.Name.StartsWith('_')) # files beginning with _ are being transferred from the NNL repository. This transfer is programmatically different than a file download.
        Write-Verbose "[Program] Exit Do Loop."

        Write-Host "`t$($file.Name) has finished downloading"

        if ($logEntry = $transferredFiles | Where-Object {$_.Name -eq $file.Name}) { # if the file already exists in the log, skip it
            Write-Host "`tFound a matching filename in the log. Comparing file versions..." -NoNewline

            try {
                $fileVersion = $null
                [string]$fileVersion = Get-FileVersion (Get-Item $file.FullName)
                $fileVersion = $fileVersion.Trim()
                Write-Verbose "Set `$fileVersion to $fileVersion"
            }
            catch {
                Write-Host "`t$($error[0].Exception.message)" -ForegroundColor Red
                $failedToGetVersion = $true
            }

            $logVersion = $logEntry._FileVersion

            '"File Version","Log Version"
             "{0}","{1}"' -f $fileVersion, (($logVersion | Sort-Object -Descending) -join ',') | ConvertFrom-Csv | Out-String | Write-Verbose
              
            if ($fileVersion.Trim() -in $logVersion) { 
                Write-Host "MATCH FOUND" -ForegroundColor Yellow
                Write-Host "`t$($file.Name) @ $($fileVersion) is already in the log."
                Write-Host ""
                # reset the versions for the next iteration
                $fileVersion = $null
                $logVersion = $null
                Write-Verbose "Reset version variables."
                continue 
            }
            Write-Host "NO MATCH" -ForegroundColor DarkGreen
        }
        else {
            Write-Verbose "No corresponding entry in file transfer log"
        }

        # add file to log
        Write-Verbose "Lookup file version: $(($fileVersion -eq '' -or $fileVersion -eq $null) -and !$failedToGetVersion)"
        if (($fileVersion -eq "" -or $fileVersion -eq $null) -and !$failedToGetVersion) {
            Write-Verbose "Attempting to determine file version..."
            try {
                $fileVersion = $null
                [string]$fileVersion = Get-FileVersion (Get-Item $file.FullName)
                $fileVersion = $fileVersion.Trim()
                Write-Verbose "File Version: $fileVersion"
            }
            catch {
                Write-Host "`t$($error[0].Exception.message)" -ForegroundColor Red
            }
        }
        $null=Add-Member -InputObject $file -NotePropertyName '_FileVersion' -NotePropertyValue $fileVersion.Trim() -Force -PassThru
        $csvProperties = @{Property = '_FileVersion','VersionInfo','BaseName','Name','Length','DirectoryName','FullName','Extension','CreationTime','LastWriteTime'}

        $file | Export-Csv  $log -NoTypeInformation -Append 
        Write-Host "`tAdded $($file.Name) to log." -ForegroundColor Green
        Write-Host ""

        # reset the versions for the next iteration
        $fileVersion = $null
        $logVersion = $null
        Write-Verbose "Reset version variables."
    }

    # wait 30 seconds between polls
    Start-Sleep 30
}
