[cmdletbinding()]
param()

function Get-MSIProperties ($FilePath) { # WILL NOT WORK ON PRIMENET DUE TO CONSTRAINED LANGUAGE MODE (CLM)
    $WindowsInstaller = [WindowsInstaller]::Installer
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
    $data = Import-Csv "$env:USERPROFILE\OneDrive\OneDrive - PrimeNet\Documents\FileTransferLog.csv"

    foreach ($obj in $data) {
        #$versionInfo = $obj.VersionInfo.Split("`n").foreach({$key,$value=$_.split(':',2); @{$key.trim()=$value.trim()}})
        Add-Member -InputObject $obj -NotePropertyMembers @{VersionInfo = $obj.VersionInfo.Split("`n").foreach({$key,$value=$_.split(':',2); @{$key.trim()=$value.trim()}})} -Force -PassThru
        $result += $obj
    }

    $ErrorActionPreference = 'Continue'

    return $result
}

# get a list of all software patterns to search for from the SoftwareVersions csv
$softwareStatusPath = "$env:USERPROFILE\OneDrive\OneDrive - PrimeNet\SoftwareVersions\SoftwareVersions.csv"
$softwareStatus = Import-Csv $softwareStatusPath

# get all files transferred from the log
$filesTransferred = Import-FileTransferCsv | Sort-Object CreationTime, Name -Descending

$softwareToUpdate = $softwareStatus.FileMatch | Where-Object {![string]::IsNullOrWhiteSpace($_)}
foreach ($software in $softwareToUpdate) {
    $newestFile = $filesTransferred | Where-Object {$_.BaseName -match $software} | Select-Object -First 1
    if ($newestFile) {
        $ErrorActionPreference = 'SilentlyContinue'
        $versionInfo = $newestFile.VersionInfo

        if ($versionInfo.FileVersion) {
            $newVersion = $versionInfo.FileVersion
        }
        elseif ($versionInfo.ProductVersion) { # check ProductVersion property
            $newVersion = $versionInfo.ProductVersion
        }
        else { # try to get a version from the file name
            $newVersion = [regex]::Match($newestFile.BaseName, '(\d+\.?)+').Value
        }

        $update = [ordered]@{Product = $software; Version = $newVersion; Date = $newestFile.CreationTime }
        $update | Out-String | Write-Host

        # update the csv
        $entry = $softwareStatus | Where-Object {$_.FileMatch -eq $software}
        $entry.LatestVersion = $update.Version
        $entry.DateTime = $update.Date
        $ErrorActionPreference = 'Continue'
    }
} # end foreach

# write the csv
$softwareStatus | Export-Csv -Path $softwareStatusPath -NoTypeInformation -Force
