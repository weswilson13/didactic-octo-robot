function Set-RegistryKeys {
    [cmdletbinding()]
    param([string]$DefaultPath = "$env:USERPROFILE\OneDrive\OneDrive - PrimeNet\ToNNPP")

    $onedrive = "$env:USERPROFILE\OneDrive\OneDrive - PrimeNet\"
    $paths = @{
        MonitoredFolder = $DefaultPath
        SoftwareVersions = Join-Path $onedrive SoftwareVersions
        TransferLog = Join-Path $onedrive SoftwareVersions\FileTransferLog.csv
        ActivityLog = Join-Path $onedrive Documents\FileTransferLogger.log
    }

    foreach ($item in $paths.GetEnumerator()) {
        try {
            $null = Get-ItemProperty HKCU:\Environment\FileTransfer -Name $item.Key -ErrorAction Stop #| Select-Object -ExpandProperty MonitoredFolder
        }
        catch {
            Write-Host "Adding $($item.Key) with value $($item.Value) to Registry Key HKCU:\Environment\FileTransfer" -ForegroundColor Yellow
            reg add 'HKCU\Environment\FileTransfer' /t REG_EXPAND_SZ /v $item.Key /d $item.Value
        }
    }

}

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

function Import-FileTransferCSV {
    [cmdletbinding()]
    param([string]$Log)

    $ErrorActionPreference = 'SilentlyContinue'

    $result = @()
    $data = Import-Csv (Get-RegistryValue TransferLog)

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

function Write-Log {
    [cmdletbinding()]
    param(
        [string]$Message,

        [validateset('Information','Warning','Error')]
        [string]$Severity = 'Information'
    )

    if ($VerbosePreference -eq [System.Management.Automation.ActionPreference]::Continue) { return }

    $logFile = Get-RegistryValue ActivityLog

    $notePropertyMembers = [ordered]@{
        FileTimeUTC = [datetime]::Now.ToFileTimeUtc()
        User = $env:USERNAME
        Severity = $Severity
        Message = $Message
    }
    $logger = New-Object psobject
    $null = Add-Member -InputObject $logger -NotePropertyMembers $notePropertyMembers -PassThru 

    $logger | Export-Csv $logFile -Append -NoTypeInformation
}
