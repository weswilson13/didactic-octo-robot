<#
.DESCRIPTION
Script to check latest stable release of Visual Studio Code. If a newer version is available, 
the .exe is downloaded, and tracking file may be updated. 

.EXAMPLE
Use -Verbose to see the values used for CurrentVersion and LatestVersion, as well as the Action determined by the script.

Console output will be similar to:

VERBOSE: Requested HTTP/1.1 GET with 0-byte payload
VERBOSE: Received HTTP/1.1 68071-byte response of content type application/json
VERBOSE: 
Name                           Value
----                           -----
Product                        Google Chrome
CurrentVersion                 131.0.6778.140
LatestVersion                  131.0.6778.140
Action                         Ignore


Nothing new to pull down

SYNTAX:

.\Get-NewVSCode.ps1 -Verbose
#>

[CmdletBinding()]
param()

. "$PSScriptRoot\VersionControl.ps1"

# turn off progress bar for *this powershell session* - this makes web request download exponentially faster
$ProgressPreference = 'SilentlyContinue' 
# $ProgressPreference = 'Continue' will turn on the progress bar 

[System.IO.FileInfo]$versionsTxt = "Z:\Scripts\versions.txt" # path to a text file containing the latest downloaded versions
$appRepo = "Z:\Microsoft\VisualStudio\VSCode" # path to downloaded file
$currentVersion,$latestVersion = '0.0.0.0'
$url = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64"

# Get the latest stable version
$fileContent = Invoke-WebRequest -Uri $url -UseBasicParsing
$contentDisposition = ($fileContent.Headers.'Content-Disposition')
Clear-Variable -Name fileContent

$filenameStringData = $contentDisposition.split(';')[1].replace('"','')
$fileName = (ConvertFrom-StringData -StringData $filenameStringData).filename 

$outputFile = Join-Path $appRepo $fileName

$architecture,[version]$latestVersion = [regex]::Match($fileName, 'VSCodeSetup-(?<arch>x(64|86))-(?<version>(\d+\.?)+).exe').Groups["arch","version"].Value

# Get the latest downloaded version, store it in a variable called $currentVersion
if (!(Test-Path $versionsTxt)) {
   $null = New-Item -Path $versionsTxt -ItemType File
}

try { 
    $currentVersionJSON = (Get-Content $versionsTxt).split('\n',[System.StringSplitOptions]::RemoveEmptyEntries) |
    ConvertFrom-Json | Where-Object {$_.Product -eq 'VSCode'} | Select-Object -Last 1
    
    $currentVersion = @{
        APIVersion = [version]$currentVersionJSON.APIVersion
        FileVersion = [version]$currentVersionJSON.FileVersion
    }
} 
catch {}

$code = [ordered]@{
    Product = 'VSCode'
    CurrentVersion = $currentVersion
    LatestVersion = [version]$latestVersion
    Action = switch ($currentVersion.APIVersion -lt $latestVersion) {
        $true { 'Download'}
        $false { 'Ignore' }
        default { 'Error' }
    }
}

$code | Out-String | Write-Verbose

# use a hashtable for readability
$webRequestParams = @{ # this is the URL for the .msi download and the download location defined above
    Uri = $url
    OutFile = $outputFile
}

switch ($code.Action) { # take appropriate action, write output to console
    'Download' { 
        try { 
            $webrequest = Invoke-WebRequest @webRequestParams -PassThru

            Write-Host "Downloaded a new version!" -ForegroundColor Green
            
            # update versions.txt
            Add-NewVersion -FilePath $outputFile -ProductName 'VSCode' 

            # clean up old versions
            Remove-OldVersion -ProductName 'VSCode'
        } 
        catch { throw $error[0] } 
    }
    'Ignore' { Write-Host "Nothing new to pull down" -ForegroundColor Yellow; break }
    'Error' { Write-Host "Something went wrong." }
}

$code.Add("DownloadURI", $webRequestParams.Uri)
$code.Add("DownloadFilepath",$webRequestParams.OutFile)
$code.Add("SHA256Hash", (Get-FileHash $code.DownloadFilepath -Algorithm SHA256).Hash)
$code.Add("HttpStatusCode", $webrequest.StatusCode)

return $code
