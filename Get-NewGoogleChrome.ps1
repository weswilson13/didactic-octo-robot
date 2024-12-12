[CmdletBinding()]
param()

# turn off progress bar for this powershell session - this makes web request download exponentially faster
$ProgressPreference = 'SilentlyContinue'

$outputFile = "$env:USERPROFILE\Downloads\googlechromestandaloneenterprise64.msi" 

# Get the latest stable Chrome version
# This URL lists every? Google Chrome version in the stable channel, in a JSON format
$versionsUrl = "https://versionhistory.googleapis.com/v1/chrome/platforms/win/channels/stable/versions"
$versionsJson = Invoke-WebRequest -Uri $versionsUrl | Select-Object -ExpandProperty Content
$versions = ConvertFrom-Json $versionsJson # convert the JSON to an array of objects
$latestVersion = $versions.versions[0].version # select the first object, which should be the latest version
                                               # we could sort descending on Version to ensure we get the latest


# Get the latest downloaded version, store it in a variable called $currentVersion

#region replace this with whatever method supplies latest downloaded version ($currentVersion)

# Example - if we are using a .txt file where the last line is the latest version
# $currentVersion = (Get-Content versions.txt).split('\n')[-1]

$installers = Get-ChildItem Z:\Chrome -File | ? { $_.Extension -eq '.msi' }
$installers | ForEach-Object {
    $productCode = Get-MSIProperty -Property ProductCode -Path $PSItem
    $null = Add-Member -InputObject $PSItem -PassThru -NotePropertyMembers @{ChromeVersion = [version](Get-MSIProductInfo $ProductCode.Value).ProductVersion}
}
$currentInstaller = $installers | Sort-Object -Property ChromeVersion -Descending | Select-Object -First 1
$currentVersion = $currentInstaller.ChromeVersion
#endregion replace this code

$chrome = @{
    CurrentVersion = [version]$currentVersion
    LatestVersion = [version]$latestVersion
    Action = switch ([version]$currentVersion -lt [version]$latestVersion) {
        $true { 'Download '}
        $false { 'Ignore' }
        default { 'Error' }
    }
}

$chrome | Out-String | Write-Verbose

$webRequestParams = @{
    Uri = "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi"
    OutFile = $outputFile
}
switch ($chrome.Action) {
    'Download' { 
        try { Invoke-WebRequest @webRequestParams; Write-Host "Downloaded a new version!" -ForegroundColor Green } 
        catch { $error[0] }
        end { break } 
    }
    'Ignore' { Write-Host "Nothing new to pull down"; break }
    'Error' { Write-Host "Something went wrong." }
}

