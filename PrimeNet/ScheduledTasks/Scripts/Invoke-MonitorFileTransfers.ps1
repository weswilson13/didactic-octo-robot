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

# load common functions into current session
$functions = Get-Content (Join-Path (Get-RegistryValue SoftwareVersions) Setup\FileTransferFunctions.ps1) -Raw
Invoke-Expression $functions

# set $VerbosePreference to 'Continue' for testing, 'SilentlyContinue' for normal operation
#$VerbosePreference = [System.Management.Automation.ActionPreference]::Continue
$VerbosePreference = [System.Management.Automation.ActionPreference]::SilentlyContinue

$tempIgnore = @{}
$waitTime = 20

$log = Get-RegistryValue TransferLog
$toNNPP = Get-RegistryValue MonitoredFolder

Write-Log "Begin Logging session. Monitoring '$toNNPP' and logging file data to '$log'"

while ($true) { # loop indefinitely
    Clear-Host
    Write-Verbose "`$tempIgnore:`n$($tempIgnore | Out-String)"
    if ($tempIgnore.Keys.Count -gt 0) {
        foreach ($key in $tempIgnore.Keys) {
            if ($tempIgnore.$key -le [datetime]::Now) {
                Write-Verbose "Timeout expired for $key. Removing from dictionary"
                $tempIgnore.Remove($key)
                Write-Log "Timeout expired for $key. Removing from dictionary"
            }
            else {
                $span = (New-TimeSpan -Start ([datetime]::Now) -End $tempIgnore.$key).TotalSeconds
                Write-Verbose "$key timeout is valid for $span seconds"
            }
        }
    }
    Write-Verbose "[$(Get-Date -f 'MM\\dd\\yyyy hh:mm:ss tt')] Checking $toNNPP"
    Write-Verbose "Cached File Version: $fileVersion"
    Write-Verbose "Cached Log Version: $logVersion"
    if ($fileVersion -or $logVersion) {
        # reset the versions for the next iteration
        $fileVersion = $null
        $logVersion = $null
        Write-Verbose "Reset version variables."
        Write-Log "File and/or log entry versions were cached. Cleared `$fileVersion and `$logVersion variables"
    }

    $transferredFiles = Import-FileTransferCSV $log
    $files = Get-ChildItem $toNNPP | Where-Object {$_.Name -notin $tempIgnore.Keys}
    $files | Out-String | Write-Verbose

    foreach ($file in $files) { # check each file against the log
        # reinitialize variables 
        $fileVersion = [string]::Empty
        $logVersion = [string]::Empty
        $fromNnlRepo = [string]::Empty
        [bool]$failedToGetVersion = $false
        if ($file.Name.StartsWith('_')) {
            $fromNnlRepo = " (from remote NNL repository)"
        }

        Write-Host "File detected - $($file.Name.TrimStart('_'))"
        Write-Log "Transferring $($file.Name.TrimStart('_'))$fromNnlRepo"

        # wait for the file to finish downloading
        Write-Host "`tWaiting for download to complete."
        [int]$lastSize = Get-ItemPropertyValue -Path $file.FullName -Name Length
        $waiting = "`t"
        # Loop until the file size remains unchanged for 5 seconds

        while ($true) {
            Start-Sleep -Seconds 3
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
        Write-Log "$($file.Name) finished downloading to $toNNPP"

        if ($logEntry = $transferredFiles | Where-Object {$_.Name -eq $file.Name}) { # if the file already exists in the log, skip it
            Write-Host "`tFound a matching filename in the log. Comparing file versions..." -NoNewline
            Write-Log "A file matching $($file.Name) was found in the transfer log"

            try {
                $fileVersion = $null
                [string]$fileVersion = Get-FileVersion (Get-Item $file.FullName)
                $fileVersion = $fileVersion.Trim()
                Write-Verbose "Set `$fileVersion to $fileVersion"
                Write-Log "Determined the version of the new file to be $fileVersion"
            }
            catch {
                Write-Host "`t$($error[0].Exception.message)" -ForegroundColor Red
                Write-Log "Failed to get file version of new file. The following error occurred: $($error[0].Exception.message)" -Severity Error
                $failedToGetVersion = $true
            }

            $logVersion = $logEntry._FileVersion
            Write-Log "The version of the matching log entry is $logVersion"

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
                Write-Log "New file and version exist in transfer log. Version variables cleared, moving to next file"
                # add the filename to the temporary hashtable. Ignore this filename for the next hour.
                $timeout = [datetime]::Now.AddHours(1) 
                $tempIgnore.Add($file.Name, $timeout)
                Write-Verbose "Added file to temp ignore dictionary:`n$($tempIgnore | Out-String)"
                Write-Log "$($file.name) will be ignored for further review until $timeout"
                continue 
            }
            Write-Host "NO MATCH" -ForegroundColor DarkGreen
            Write-Log "$($file.Name) @ $fileVersion does not exist in transfer log"
        }
        else {
            Write-Verbose "No corresponding entry in file transfer log"
            Write-Log "$($file.Name) does not exist in transfer log"
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
                Write-Log "Determined the version of the new file to be $fileVersion"
            }
            catch {
                Write-Host "`t$($error[0].Exception.message)" -ForegroundColor Red
                Write-Log "Failed to get file version of new file. The following error occurred: $($error[0].Exception.message)" -Severity Error
                $fileVersion = ""
            }
        }
        $null=Add-Member -InputObject $file -NotePropertyName '_FileVersion' -NotePropertyValue $fileVersion -Force -PassThru
        $csvProperties = @{Property = '_FileVersion','VersionInfo','BaseName','Name','Length','DirectoryName','FullName','Extension','CreationTime','LastWriteTime'}

        try {
            $file | Export-Csv $log -NoTypeInformation -Append -ErrorAction Stop
            Write-Host "`tAdded $($file.Name) to log." -ForegroundColor Green

            # add the filename to the temporary hashtable. Ignore this filename for the next hour.
            $timeout = [datetime]::Now.AddHours(1) 
            $tempIgnore.Add($file.Name, $timeout)
            Write-Verbose "Added file to temp ignore dictionary:`n$($tempIgnore | Out-String)"

            # reset the versions for the next iteration
            $fileVersion = $null
            $logVersion = $null
            Write-Verbose "Reset version variables."
            Write-Log "Added $($file.Name) to log. Reset version variables."
            Write-Log "$($file.name) will be ignored for further review until $timeout"
        }
        catch {
            Write-Host "Failed to add $($file.Name) to log. The following error occurred:`n$($error[0].Exception.Message)" -ForegroundColor Red
            Write-Log "Failed to add $($file.Name) to log. The following error occurred:`n$($error[0].Exception.Message)"
        }
        Write-Host ""
        
        #$softwareVersionsFolder = Split-Path $log -Parent
        #$scriptsFolder = Join-Path -Path $softwareVersionsFolder -ChildPath ScheduledTask\Scripts
        
        # run Update-SoftwareStatusCSV.ps1
        #Get-Content $scriptsFolder\Update-SoftwareStatusCSV.ps1 -Raw | Invoke-Expression | Out-Null
        #Write-Log "Updated CSV files"

        # run Update-SoftwareStatus.ps1
        #Get-Content $softwareVersionsFolder\Update-SoftwareStatus.ps1 -Raw | Invoke-Expression | Out-Null
        #Write-Log "Updated HTML Page"
    }

    # wait 30 seconds between polls
    Write-Verbose "Waiting $waitTime seconds"
    Start-Sleep $waitTime
}
