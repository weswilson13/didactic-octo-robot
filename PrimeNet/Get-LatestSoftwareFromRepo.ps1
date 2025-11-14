[cmdletbinding()]
param([switch]$Test)

function Import-FileTransferCSV {
    [cmdletbinding()]
    param()

    $ErrorActionPreference = 'SilentlyContinue'

    $result = @()
    $data = Import-Csv "$env:USERPROFILE\OneDrive\OneDrive - PrimeNet\SoftwareVersions\FileTransferLog.csv"

    foreach ($obj in $data) {
        #$versionInfo = $obj.VersionInfo.Split("`n").foreach({$key,$value=$_.split(':',2); @{$key.trim()=$value.trim()}})
        $null=Add-Member -InputObject $obj -NotePropertyMembers @{VersionInfo = $obj.VersionInfo.Split("`n").foreach({$key,$value=$_.split(':',2); @{$key.trim()=$value.trim()}})} -Force -PassThru
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

# get a list of all software patterns to search for from the SoftwareVersions csv
$softwareStatusPath = "$env:USERPROFILE\OneDrive\OneDrive - PrimeNet\SoftwareVersions\SoftwareVersions.csv"
$softwareStatus = Import-Csv $softwareStatusPath
$softwareToUpdate = $softwareStatus.FileMatch | Where-Object {![string]::IsNullOrWhiteSpace($_)}

$patternsToIgnore = 'WebView'
$patternsToIgnore = $patternsToIgnore -join '|'

# get our transferred file log
$filesTransferred = Import-FileTransferCSV

# loop through each directory, identify the executable
foreach ($software in $softwaretoUpdate) { 
    Write-Host "Checking for software matching " -NoNewLine
    Write-Host  "'$software'" -ForegroundColor Yellow

    $dir = Get-ChildItem 'Z:\Scripting\Automatic Downloads' -Directory | Where-Object {$_.Name -match $software} 

    if (!$dir) {
        Write-Host "  No matches in repo" -ForegroundColor Red
        Write-Host ""
        continue
    } else {
        $exe = Get-ChildItem $dir.FullName -Recurse -Depth 1 -File | Where-Object {$_.Extension -in '.exe','.msi' -and $_.FullName -match $software -and $_.BaseName -notmatch $patternsToIgnore} 
        
        if ($exe) {
            Write-Host "  Found the following installers:"
            $exe.Name.foreach({"`t> $_"}) | Out-String | Write-Host
        } 
        else {
            Write-Host "  Found no '.exe' files matching '$software'" -ForegroundColor Yellow
            Write-Host ""
            continue
        }
    }

    # if more than 1 installer returned, try to filter out x86 versions or target the x64 version
    if ($exe.Count -gt 1) { $exe = $exe | Where-Object { $_.FullName -notmatch '86' } }
    if ($exe.Count -gt 1) { $exe = $exe | Where-Object { $_.FullName -match '64' } }
    
    # if still more than 1 installer returned, try to filter out by latest version
    if ($exe.Count -gt 1) {
        foreach ($e in $exe) {
            $null = Add-Member -InputObject $e -NotePropertyMembers @{ Version = Get-FileVersion $e } -Force
        }

        $exe = $exe | Sort-Object Version -Descending | Select-Object -First 1
    }

    # if count is still more than 1, inform user and move to next software directory
    if ($exe.Count -gt 1) { 
        Write-Warning "Multiple installers were found. Unable to automatically determine correct action at this time. No action taken for $($dir.Name)"
        continue
    } 

    Write-Host "  Evaluating " -NoNewline
    Write-Host $exe.Name -ForegroundColor Cyan

    # get the file version of the installer in the repo
    if (!($version = $exe.Version)) {
        $version = Get-FileVersion $exe
    }
    if (!$version) { $version='0.0.0' }

    try {
        $_version = [version]$version
    }
    catch {
        if ($_.FullyQualifiedErrorId -eq 'InvalidCastParseTargetInvocation') {
            Write-Error "The value determined by the script to be the version - '$version' - could not be type cast as a [version] and may be invalid. No action will be taken for this software"
            continue
        }
        else { throw }
    }

    # check against log to see if we should bring over this file
    # get the latest entry for this software, if it exists
    $latestFileTransferred = $filesTransferred | Where-Object { $_.BaseName -match $software }

    # get the version
    $latestVersion = $latestFileTransferred._FileVersion | Sort-Object -Descending | Select-Object -First 1
    if (!$latestVersion) { $latestVersion = '0.0.0.0' }

    # if the version in the repo is newer, bring it over
    if (!$latestFileTransferred -or [version]$version -gt [version]$latestVersion) {
        Write-Host "  $($exe.Name) is new. Transferring to NNPP." -ForegroundColor Green
        Write-Host ""

        if (!$Test.IsPresent) { Copy-Item $exe.FullName "$env:USERPROFILE\OneDrive\OneDrive - PrimeNet\ToNNPP\_$($exe.Name)" }
    }
    else {
        Write-Host "  Software is already up to date." -ForegroundColor DarkGreen
        Write-Host ""
    }
}
