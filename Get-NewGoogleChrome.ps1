<#
.DESCRIPTION
Script to check latest stable release of Google Chrome. If a newer version is available, 
the enterprise .msi is downloaded, and tracking file may be updated. 

.EXAMPLE
Use -Verbose to see the values used for CurrentVersion and LatestVersion, as well as the Action determined by the script.

Console output will be similar to:

VERBOSE: Requested HTTP/1.1 GET with 0-byte payload
VERBOSE: Received HTTP/1.1 68071-byte response of content type application/json
VERBOSE: 
Name                           Value
----                           -----
CurrentVersion                 131.0.6778.140
LatestVersion                  131.0.6778.140
Action                         Ignore


Nothing new to pull down

SYNTAX:

.\Get-NewGoogleChrome.ps1 -Verbose
#>

[CmdletBinding()]
param()

# load Forms Namespace to access the Messagebox classes
Add-Type -AssemblyName System.Windows.Forms

# turn off progress bar for *this powershell session* - this makes web request download exponentially faster
$ProgressPreference = 'SilentlyContinue' 
# $ProgressPreference = 'Continue' will turn on the progress bar 

$versionsTxt = ".\versions.txt" # path to a text file containing the latest downloaded versions
$outputFile = "$env:USERPROFILE\Downloads\googlechromestandaloneenterprise64.msi" # path to downloaded file

# Get the latest stable Chrome version
# This URL lists every? Google Chrome version in the stable channel, in a JSON format
# Reference: https://developer.chrome.com/docs/versionhistory/guide/
$versionsUrl = "https://versionhistory.googleapis.com/v1/chrome/platforms/win/channels/stable/versions"
$versionsJson = Invoke-WebRequest -Uri $versionsUrl | Select-Object -ExpandProperty Content
$versions = ConvertFrom-Json $versionsJson # convert the JSON to an array of objects
$latestVersion = $versions.versions[0].version # select the first object, which should be the latest version
                                               # we could sort descending on Version to ensure we get the latest

# Get the latest downloaded version, store it in a variable called $currentVersion
if (!(Test-Path $versionsTxt)) {
    New-Item -Path $versionsTxt -ItemType File
}
try { $currentVersion = (Get-Content $versionsTxt).split('\n')[-1] } # [-1] returns the last index in the array
catch {}

$chrome = [ordered]@{
    CurrentVersion = [version]$currentVersion
    LatestVersion = [version]$latestVersion
    Action = switch ([version]$currentVersion -lt [version]$latestVersion) {
        $true { 'Download'}
        $false { 'Ignore' }
        default { 'Error' }
    }
}

$chrome | Out-String | Write-Verbose

# use a hashtable for readability
$webRequestParams = @{ # this is the URL for the .msi download and the download location defined above
    Uri = "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi"
    OutFile = $outputFile
}

switch ($chrome.Action) { # take appropriate action, write output to console
    'Download' { 
        try { 
            Invoke-WebRequest @webRequestParams; 
            Write-Host "Downloaded a new version!" -ForegroundColor Green
            $ans=[System.Windows.Forms.MessageBox]::Show("Append this version to 'versions.txt'?", "Update File?",`
                [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
            if ($ans -eq 'Yes') { $latestVersion.ToString() | Out-File $versionsTxt -Append}
            break } 
        catch { throw $error[0] } 
    }
    'Ignore' { Write-Host "Nothing new to pull down" -ForegroundColor Yellow; break }
    'Error' { Write-Host "Something went wrong." }
}

