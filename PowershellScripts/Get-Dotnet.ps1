$html = New-Object -ComObject "HTMLFile"
[System.Collections.ArrayList]$latestReleases=@()

$baseUri = "https://versionsof.net"

$pageContent = Invoke-WebRequest -Uri $baseUri
$html.IHTMLDocument2_Write($pageContent.RawContent)

$htmlObjects = ($html.getElementsByTagName('td') | ? {$_.classname -eq 'title'})
$stubs = $htmlObjects.childnodes.pathname | ? {$_ -match 'core'} 
foreach ($s in $stubs) {
    $latestReleases.Add(((Invoke-WebRequest -Uri "$baseUri/$s").ParsedHtml.GetElementsByTagName('li') | ? {$_.innerHTML -match 'latest runtime'}).innerHTML) | Out-Null
}

foreach ($release in $latestReleases) {
    $LatestRuntimeVersion = (Select-String -InputObject $release -pattern '(?<=href=")/core/\d+\.\d+/\d+\.\d+\.\d+/(?=">)' -AllMatches).Matches.Value
    if ($LatestRuntimeVersion -eq $null) {continue}    
    Write-Host "$baseUri$LatestRuntimeVersion"
    
    $latestVersionContent = (Invoke-WebRequest -Uri "$baseUri/$LatestRuntimeVersion").Links

    $latestVersionContent | Where-Object {$_.innerHTML -in ('x86','x64', 'Hosting Bundle') -and $_.href -match 'win.*exe'} | 
        Select-Object href, @{Name='FileName';Expression={($_.href).split('/')[-1]}} |
        ForEach-Object {
            try {
                if (!(Get-Content "$env:USERPROFILE\downloads\dotnetVersions.log").Contains($_.FileName)) {
                    Write-Host $_.FileName
                    Invoke-WebRequest -Uri $_.href -OutFile "Z:\Microsoft\dotnet\installers\$($_.FileName)" -ErrorAction Stop
                    Out-File -InputObject $_.FileName -FilePath "$env:USERPROFILE\downloads\dotnetVersions.log" -Encoding ascii -Append
                }
            }
            catch {$_}
        }
}