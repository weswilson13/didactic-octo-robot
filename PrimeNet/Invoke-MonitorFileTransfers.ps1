$log = "$env:USERPROFILE\OneDrive\OneDrive - PrimeNet\SoftwareVersions\FileTransferLog.csv"

while ($true) { # loop indefinitely

    $transferredFiles = Import-Csv $log
    $files = Get-ChildItem "$env:USERPROFILE\OneDrive\OneDrive - PrimeNet\ToNNPP" 

    foreach ($file in $files) { # check each file against the log
        Write-Host "New file detected - $($file.Name)"

        if ($file.Name -in $transferredFiles.Name) { # if the file already exists in the log, skip it 
            Write-Host "$($file.Name) is already in the log."
            continue 
        }

        # wait for the file to finish downloading
        $lastSize = 0

        # Loop until the file size remains unchanged for 10 seconds
        while ($true) {
            Start-Sleep -Seconds 5
            $newSize = (Get-Item $file.FullName).Length
            if ($newSize -eq $lastSize) {
                Write-Host "File size is stable. Download complete."
                break
            }
            $lastSize = $newSize
        }

        Write-Host "$($file.Name) has finished downloading"

        # add file to log
        $file | Export-Csv $log -NoTypeInformation -Append 
        Write-Host "Added $($file.Name) to log."
    }

    # wait 30 seconds between polls
    Start-Sleep 30
}
