function Get-NewID {

    [int]$lastID = Get-Content $versionsTxt | ConvertFrom-Json | Sort-Object -Property @{e={[int]$_.ID}} -Descending | Select-Object -First 1 -ExpandProperty ID

    return [string]($lastID + 1)
}
function Add-NewVersion {
    param(
        [System.IO.FileInfo]$FilePath,
        [string]$ProductName
    )

    $fileVersion = switch ($FilePath.Extension) {
        '.exe' { [version](Get-ItemProperty -Path $FilePath -Name VersionInfo).VersionInfo.FileVersion.Trim() }
        '.msi' { [version](Get-MSIProperty -Path $FilePath -Property ProductVersion).Value }
        '.zip' { 
            $archive = Get-ZipFiles -FilePath $FilePath | Where-Object {$_ -match 'WindowsTerminal.exe'} | Split-Path -Parent
            [regex]::Match($archive,'(\d+\.?)+').Value
        }
    }

    Write-Verbose "Adding new version - $($fileVersion | Out-String)"

    if (!$fileVersion) { throw "Could not determine version of the new file."}

    $id = Get-NewID
    Write-Verbose "New ID is '$id'"

    [ordered]@{ID=$id;Product=$ProductName;APIVersion=$latestVersion.ToString();FileVersion=$fileVersion.ToString()} | 
        ConvertTo-Json -Compress |
        Out-File $versionsTxt -Append -Encoding ascii
}
function Remove-OldVersion {
    param(
        [string]$ProductName
    )

    begin {
        [System.Collections.ArrayList]$content = Get-Content $versionsTxt | ConvertFrom-Json

        if (!$ProductName) {
            $ProductName = $content | Select-Object -Unique -ExpandProperty Product
            $ProductName | Out-String | Write-Verbose 
        }
    }

    process {
        foreach ($product in $ProductName) {
            
            Write-Verbose "Removing old versions of $product"
            $versionsToRemove = $content | Where-Object { $_.Product -eq $product } | 
                Sort-Object -Property ID -Descending | 
                Select-Object -ExpandProperty ID -Skip 1
            
            Write-Verbose "Found the following line ID's to remove: $($versionsToRemove | Out-String)"
            foreach ($id in $versionsToRemove) {
                $lineToRemove = $content | Where-Object {$_.ID -eq $id}

                Write-Verbose "Removing $($lineToRemove | Out-String)"

                $content.Remove($lineToRemove)
            }

            $null = New-Item $versionsTxt -ItemType File -Force
            $content | Foreach-Object {
                $null = $PSItem | ConvertTo-Json -Compress | Out-File -FilePath $versionsTxt -Append -Encoding ascii
            }
            
            Start-Sleep 1
        }
    }
}
function Get-CurrentVersion {
    param(
        [ValidateSet('Microsoft Edge','Google Chrome','VSCode','Powershell','Git','SSMS','Notepad++','7zip','Windows Terminal','Tortoise Git','VMWare Tools','WinSCP')]
        [string]$ProductName
    )
  
    if (!(Test-Path $versionsTxt)) {
        New-Item -Path $versionsTxt -ItemType File
    }

    try { 
        $currentVersionJSON = Get-Content $versionsTxt |
        ConvertFrom-Json | Where-Object {$_.Product -eq $ProductName} | Select-Object -Last 1
        
        $currentVersion = [ordered]@{
            APIVersion = [version]$currentVersionJSON.APIVersion
            FileVersion = [version]$currentVersionJSON.FileVersion
        }

        return $currentVersion
    } 
    catch {
        throw $Error[0]
    }
}
function Get-ZipFiles {
    param(
        [System.IO.FileInfo]$FilePath
    )

    # Open the ZIP archive
    $zip = [System.IO.Compression.ZipFile]::OpenRead($FilePath)

    $files = @()

    # Enumerate and list the files in the ZIP archive
    foreach ($entry in $zip.Entries) {
        $files += $entry.FullName
    }

    # Close the ZIP archive
    $zip.Dispose()

    return $files
}