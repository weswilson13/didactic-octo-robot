[cmdletbinding()]
param()

function Get-MSIProperties ($FilePath) { # WILL NOT WORK ON PRIMENET DUE TO CONSTRAINED LANGUAGE MODE (CLM)
    $WindowsInstaller = New-Object -ComObject WindowsInstaller.Installer
    $WindowsInstallerDatabase = $WindowsInstaller.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $null, $WindowsInstaller, @(($FilePath), 0))
    # Open the Property-view
    $WindowsInstallerDatabaseView = $WindowsInstallerDatabase.GetType().InvokeMember("OpenView", "InvokeMethod", $null, $WindowsInstallerDatabase, "SELECT * FROM File")
    $WindowsInstallerDatabaseView.GetType().InvokeMember("Execute", "InvokeMethod", $null, $WindowsInstallerDatabaseView, $null)
}

function Import-FileTransferCSV {
    [cmdletbinding()]
    param()

    $ErrorActionPreference = 'SilentlyContinue'

    $result = @()
    $data = Import-Csv "$env:USERPROFILE\OneDrive\OneDrive - PrimeNet\SoftwareVersions\FileTransferLog.csv"

    foreach ($obj in $data) {
        #$versionInfo = $obj.VersionInfo.Split("`n").foreach({$key,$value=$_.split(':',2); @{$key.trim()=$value.trim()}})
        $null = Add-Member -InputObject $obj -NotePropertyMembers @{VersionInfo = $obj.VersionInfo.Split("`n").foreach({$key,$value=$_.split(':',2); @{$key.trim()=$value.trim()}})} -Force -PassThru
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
    }
    elseif ($FileInfo.VersionInfo.ProductVersion) { # check ProductVersion property
        $newVersion = $FileInfo.VersionInfo.ProductVersion
    }
    else { # try to get a version from the file name
        $newVersion = [regex]::Match($FileInfo.BaseName, '(\d+\.?)+').Value
    }

    if (($newVersion -eq "" -or $newVersion -eq $null -or ![version]::TryParse($newVersion,[ref]$null)) -and (Test-Path $FileInfo.FullName)) { # leverage applocker to try to pull out the version (SLOW!!!!)
        #Write-Host "Collecting AppLocker file information"
        $newVersion = (Get-AppLockerFileInformation -Path $FileInfo.FullName).Publisher.BinaryVersion.ToString()
    }

    return $newVersion
}

function Update-File {
    [cmdletbinding()]
    param(
        [string[]]$Collection,

        [ValidateSet('Software','Server','Switch')]
        [string]$Type
    )

    $csv, $csvPath = switch ($type) {
        'Software' { $softwareStatus, $softwareStatusPath; break }
        'Server' { $serverSoftwareStatus, $serverSoftwareStatusPath; break }
        'Switch' { $switchImageStatus, $switchImagesStatusPath; break }
    }
    
    foreach ($item in $collection) { # loop through each software pattern/server model/switch model

        $filesTransferWhereScriptBlock = {}
        $fileTransferWhereScriptBlock = switch ($Type) { # filter to identify the file in the transfer csv
            'Software' { {$_.BaseName -match $item}; break }
            'Server' { {$_.BaseName -match $item -and $_.BaseName -match $serverSoftwareTypes}; break }
            'Switch' { 
                $pattern = ""
                $pattern = ($csv | Where-Object {$_.SwitchModel -eq $item}).OS
                if ($pattern -eq "" -or $pattern -eq $null) { continue }
                {$_.BaseName -match $pattern -and $_.Extension -eq '.bin'}    
                break 
            }
        }

        if ($fileTransferWhereScriptBlock -eq $null) { continue }
        #AWrite-Host "`$fileTransferWhereScriptBlock: $($fileTransferWhereScriptBlock | Out-String)" -ForegroundColor White

        $newestFile = $filesTransferred | Where-Object $fileTransferWhereScriptBlock | Select-Object -First 1

        if ($newestFile) {
            $csvWhereScriptBlock = switch ($Type) {
                'Software' { {$_.FileMatch -eq $item}; break }
                'Server' { {$_.Id -match "${item}$([Regex]::Match($newestFile.BaseName,$serverSoftwareTypes, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase).Value)"} ;break }
                'Switch' { {$_.Id -match $item.Replace('+','\+')}; break }
            }
            
            #Write-Host "`$csvWhereScriptBlock: $($csvWhereScriptBlock | Out-String)" -ForegroundColor White

            $ErrorActionPreference = 'SilentlyContinue'

            $newVersion = $newestFile._FileVersion

            # update the csv
            $entry = $null
            $entry = $csv | Where-Object $csvWhereScriptBlock
            
            $product = switch ($Type) {
                'Software' { $entry.SoftwareName; break }
                'Server' { '{0} {1}' -f $entry.ServerModel, $entry.ProductType; break }
                'Switch' { $entry.SwitchModel; break }
            }
            
            #Write-Host $item
            $update = [ordered]@{Product = $product; Version = $newVersion; Date = $newestFile.CreationTime }
            $update | Out-String | Write-Host

            $entry.LatestVersion = $update.Version
            $entry.DateTime = $update.Date
            $ErrorActionPreference = 'Continue'
        }
    } # end foreach

    # write the csv
    $csv | Export-Csv -Path $csvPath -NoTypeInformation -Force
}

# get a list of all software patterns to search for from the SoftwareVersions csv
$softwareVersions = "$env:USERPROFILE\OneDrive\OneDrive - PrimeNet\SoftwareVersions"
$softwareStatusPath = Join-Path $softwareVersions SoftwareVersions.csv
$serverSoftwareStatusPath = Join-Path $softwareVersions ServerSoftware.csv
$switchImagesStatusPath = Join-Path $softwareVersions SwitchImages.csv

$softwareStatus = Import-Csv $softwareStatusPath
$serverSoftwareStatus = Import-Csv $serverSoftwareStatusPath
$switchImageStatus = Import-Csv $switchImagesStatusPath

# get all files transferred from the log
$filesTransferred = Import-FileTransferCsv | Sort-Object CreationTime, Name -Descending

# define the patterns to match
$softwareToUpdate = $softwareStatus.FileMatch | Where-Object {![string]::IsNullOrWhiteSpace($_)}
$serverSoftwareTypes = 'raid','idrac','bios'
$serverSoftwareTypes = $serverSoftwareTypes -join '|'
#$serverModelRegex = '(6[4,5]|7[4-6]|96)0'
$serverModels = '640','650','740','750','760','960'
$switchImages='IOS','IOS-XE' # this needs verification
$switchModels=$switchImageStatus.SwitchModel

# update software
Update-File -Type Software -Collection $softwareToUpdate

# update server software
Update-File -Type Server -Collection $serverModels

# update switch images
Update-File -Type Switch -Collection $switchModels
