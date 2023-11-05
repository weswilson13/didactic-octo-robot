[cmdletbinding()]
param()

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Try {
    $applications = 'Curl', 'Powershell', 'WinSCP', 'VSCode', 'Notepad++', 'PuTTY'
    $numberOfVersionsToKeep = 3
    $PSDefaultParameterValues.Clear()
    $PSDefaultParameterValues.Add("Tee-Object:FilePath", $logPath)
    $PSDefaultParameterValues.Add("Tee-Object:Append", $true)
    $PSDefaultParameterValues.Add("Tee-Object:Encoding", "ASCII")
    
    foreach($application in $applications) {
        $logPath = Join-Path "$PSScriptRoot\ScriptLogs" $(Switch ($application) {
            'Curl' {"get-curlupdate.log"}
            'Notepad++' {'get-nppupdate.log'}
            'Powershell' {"get-PSupdate.log"}
            'WinSCP' {"get-winscpupdate.log"}
            'VSCode' {"get-vscode.log"}
            'PuTTY' {"get-putty.log"}
        })
        
        $PSDefaultParameterValues["Tee-Object:FilePath"] = $logPath

        $z = Split-Path $PSScriptRoot -Parent
        $appRepo = Join-Path $z $(Switch ($application) {
            'Curl' {"cURL"}
            'Notepad++' {"Notepad++"}
            'Powershell' {"WindowsPowershell\Installers"}
            'WinSCP' {"WinSCP"}
            'VSCode' {"Microsoft\VisualStudio\VSCode"}
            'PuTTY' {'PuTTY'}
        }) 

        $pageContentUri = Switch ($application) {
            'Curl' {"https://curl.se/windows/"}
            'Notepad++' {"https://notepad-plus-plus.org/downloads/"}
            'Powershell' {"https://github.com/PowerShell/PowerShell/releases/latest"}
            'PuTTY' {"https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html"}
            'WinSCP' {"https://winscp.net/eng/download.php"}
            'VSCode' {"https://code.visualstudio.com/updates/"}
        } 

        $regex = Switch ($application) {
            'Curl' {'\d+\.\d+\.\d+_\d+'}
            'Notepad++' {'(?<=Current Version )\d\.\d\.\d'}
            'PuTTY' {'(?<=latest release \()\d+\.\d+(\.\d+)?'}
            'WinSCP' {'\d\.\d\.\d'}
            default {'\d+\.\d+\.\d+'}    
        }

        Tee-Object -InputObject "$(Get-Date): Checking for $application updates..." 

        $pageContent = Invoke-WebRequest -Uri $pageContentUri -UseBasicParsing | Select-Object -ExpandProperty Content
        $version = (Select-String -InputObject $pageContent -Pattern $regex -AllMatches).Matches[0].Value
        Tee-Object -InputObject "`t[INFO] Latest version from $pageContentUri is: $version" 
        
        $fileUri = Switch ($application) {
            'Curl' {"https://curl.se/windows/latest.cgi?p=win64-mingw.zip"}
            'Notepad++' {"https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/$version/npp.$version.Installer.x64.exe"}
            'Powershell' {"https://github.com/PowerShell/PowerShell/releases/download/v$version/PowerShell-$version-win-x64.msi"}
            'PuTTY' {"https://the.earth.li/~sgtatham/putty/latest/w64/putty-64bit-$version-installer.msi"}
            'WinSCP' {"https://winscp.net/download/WinSCP-$version.msi"}
            'VSCode' {"https://code.visualstudio.com/sha/download?build=stable&os=win32-x64"}
        }
        Write-Debug $fileUri

        $repoRegex = $regex -replace '\(\?<=(.*) (\\\()?\)'
        Write-Debug $repoRegex 

        $availableVersions = (Get-ChildItem $appRepo | Select-Object Name -ExpandProperty Name) | 
            Select-Object @{Name='File';Expression={$_}}, @{Name='version';Expression={(Select-String -InputObject $_ -Pattern ($repoRegex) -AllMatches).Matches[0].Value}}
        $latestVersionAvailable = $availableVersions | Sort-Object version -Descending | Select-Object -First 1
        Tee-Object -InputObject "`t[INFO] Latest version in repo is: $($latestversionAvailable.version)" 

        $fileName = $latestversionAvailable.File -replace $repoRegex, $version
        Write-Debug $fileName

        if ($latestVersionAvailable.version -lt $version) {
            Tee-Object -InputObject "`t[INFO] Downloading latest version..." 
            Invoke-WebRequest -Uri $fileUri -OutFile (Join-Path $appRepo $filename)
            Tee-Object -InputObject "`t[SUCCESS] Downloaded $application version $version." 

            $creds = Import-Clixml -Path "$($PSScriptRoot)\Credentials\homelab@mydomain.local_cred.xml"
            $credentials = New-Object -TypeName pscredential($creds.username, $creds.Password)
            $messageAttr = @{
                SmtpServer = "awm17x.mydomain.local"
                From = "wes_admin@mydomain.local"
                To = "poweredge.t320.server@gmail.com"
                Subject = "$application Update"
                Body = "$application version $version is available."
                Credential = $credentials
                ErrorAction = "Stop"
            }
            Send-MailMessage @messageAttr
            Tee-Object -InputObject "`t[INFO]: Successfully sent notification e-mail." 
        } else {
            Tee-Object -InputObject "`t[INFO] No update available..." 
        }

        # Clean-up older versions
        [String]$versionToKeep = ($version -replace '\D','') - $numberOfVersionsToKeep
        $files = Get-ChildItem $appRepo -File | Where-Object {$_.Name -match $repoRegex} 
        $files | Out-String | Write-Debug
        $files | ForEach-Object {
            if ([Int]((Select-String -InputObject $_.Name -pattern $repoRegex).Matches.Value -replace '\D') -lt $versionToKeep -and $files.Count -gt $numberOfVersionsToKeep ) {
                Tee-Object -InputObject "Removing $($_.Name)"
                Remove-Item $_ -Force
            } 
        }
    }
}
Catch {
    Tee-Object -InputObject "`t[ERROR] An error occurred...`n`r`t`t$($error[0] | Select-Object *)" 
}