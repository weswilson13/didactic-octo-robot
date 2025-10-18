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
        Add-Member -InputObject $obj -NotePropertyMembers @{VersionInfo = $obj.VersionInfo.Split("`n").foreach({$key,$value=$_.split(':',2); @{$key.trim()=$value.trim()}})} -Force -PassThru
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

        $newVersion = Get-FileVersion $newestFile

        # update the csv
        $entry = $softwareStatus | Where-Object {$_.FileMatch -eq $software}
        
        $update = [ordered]@{Product = $entry.SoftwareName; Version = $newVersion; Date = $newestFile.CreationTime }
        $update | Out-String | Write-Host

        $entry.LatestVersion = $update.Version
        $entry.DateTime = $update.Date
        $ErrorActionPreference = 'Continue'
    }
} # end foreach

# write the csv
$softwareStatus | Export-Csv -Path $softwareStatusPath -NoTypeInformation -Force
