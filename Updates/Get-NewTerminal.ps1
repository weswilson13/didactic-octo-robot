<#
.DESCRIPTION
Script to check latest stable release of Windows Terminal. If a newer version is available, 
the .msi is downloaded, and tracking file may be updated. 

.EXAMPLE
Use -Verbose to see the values used for CurrentVersion and LatestVersion, as well as the Action determined by the script.

Console output will be similar to:

VERBOSE: Requested HTTP/1.1 GET with 0-byte payload
VERBOSE: Received HTTP/1.1 68071-byte response of content type application/json
VERBOSE: 
Name                           Value
----                           -----
Product                        Windows Terminal
CurrentVersion                 131.0.6778.140
LatestVersion                  131.0.6778.140
Action                         Ignore


Nothing new to pull down

SYNTAX:

.\Get-NewWindows Terminal.ps1 -Verbose
#>

[CmdletBinding()]
param()

# read our version control functions into the current session
. "$PSScriptRoot\VersionControl.ps1"

# turn off progress bar for *this Windows Terminal session* - this makes web request download exponentially faster
$ProgressPreference = 'SilentlyContinue' 
# $ProgressPreference = 'Continue' will turn on the progress bar 

[System.IO.FileInfo]$versionsTxt = "Z:\Scripts\versions.txt" # path to a text file containing the latest downloaded versions
$currentVersion,$latestVersion = [version]'0.0.0.0'

#region set product specific variables
$product = 'Windows Terminal'
$appRepo = "Z:\Microsoft\WindowsTerminal\Installers"

$url = 'https://github.com/microsoft/terminal/releases/latest'
$webrequest = Invoke-WebRequest -Uri $url -UseBasicParsing
$requestUri = $webrequest.BaseResponse.RequestMessage.RequestUri
$versionSegment = $requestUri.Segments[-1] # should return something like v7.4.6
$version = $versionSegment -replace '^v'

$releaseUri = Split-Path $url -Parent
$downloadURI = "$releaseUri\download\$versionSegment\Microsoft.WindowsTerminal_${version}_x64.zip".Replace("\","/")
$fileName = [System.IO.Path]::GetFileName($downloadURI)
$outputFile =  Join-Path $appRepo $fileName # path to downloaded file
#endregion set product specific variables

$latestVersion = [version]$version

# Get the latest downloaded version, store it in a variable called $currentVersion
$currentVersion = Get-CurrentVersion $product

$obj = [ordered]@{
    Product = $product
    CurrentVersion = $currentVersion
    LatestVersion = [version]$latestVersion
    Action = switch ($currentVersion.APIVersion -lt $latestVersion) {
        $true { 'Download'}
        $false { 'Ignore' }
        default { 'Error' }
    }
}

$obj | Out-String | Write-Verbose

# use a hashtable for readability
$webRequestParams = @{ # this is the URL for the .msi download and the download location defined above
    Uri = $downloadURI
    OutFile = $outputFile
}

$webRequestParams | Out-String | Write-Verbose

switch ($obj.Action) { # take appropriate action, write output to console
    'Download' { 
        try { 
            $webrequest = Invoke-WebRequest @webRequestParams -PassThru

            Write-Host "Downloaded a new version!" -ForegroundColor Green
            
            # update versions.txt
            Add-NewVersion -FilePath $outputFile -ProductName $product 

            # clean up old versions
            Remove-OldVersion -ProductName $product
        } 
        catch { throw $error[0] } 
    }
    'Ignore' { Write-Host "Nothing new to pull down" -ForegroundColor Yellow; break }
    'Error' { Write-Host "Something went wrong." }
}

# write additional attributes to returned object
$obj.Add("DownloadURI", $webRequestParams.Uri)
$obj.Add("DownloadFilepath",$webRequestParams.OutFile)
$obj.Add("SHA256Hash", (Get-FileHash $obj.DownloadFilepath -Algorithm SHA256).Hash)
$obj.Add("HttpStatusCode", $webrequest.StatusCode)

return $obj
