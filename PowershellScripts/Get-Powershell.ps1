
Try {
    #region initialization
    #$PSDefaultParameterValues = @{"Out-File:Encoding" = "Utf-8"}
    $logPath = "$PSScriptRoot\ScriptLogs\get-PSupdate.log"
    $logAttr = @{
        FilePath = $logPath
        Append = $true
        Encoding = "Utf-8"
    }
    $PSRepo = Join-Path (Split-Path $PSScriptRoot -Parent) "WindowsPowershell\Installers"
    #endregion

    Tee-Object -InputObject "$(Get-Date): Checking for PowerShell updates..." @logAttr

    $pageContent = Invoke-WebRequest -Uri https://github.com/PowerShell/PowerShell/releases/latest | Select-Object -ExpandProperty Content
    $version = (Select-String -InputObject $pageContent -Pattern '\d+\.\d+\.\d+' -AllMatches).Matches[0].Value
    Tee-Object -InputObject "`t[INFO] Latest version from https://github.com/PowerShell/PowerShell/releases/latest is: $version" @logAttr
    
    $latestVersionAvailable = (Get-ChildItem $PSRepo | Select-Object Name -ExpandProperty Name) | Select-Object @{Name='File';Expression={$_}}, @{Name='version';Expression={(Select-String -InputObject $_ -Pattern '\d+\.\d+\.\d+' -AllMatches).Matches[0].Value}} | Sort-Object version -Descending | Select-Object -First 1
    Tee-Object -InputObject "`t[INFO] Latest version in repo is: $($latestversionAvailable.version)" @logAttr

    $fileName = $latestversionAvailable.File -replace '\d+\.\d+\.\d+', $version

    if ($latestVersionAvailable.version -lt $version) {
        Tee-Object -InputObject "`t[INFO] Downloading latest version..." @logAttr
        Invoke-WebRequest -Uri "https://github.com/PowerShell/PowerShell/releases/download/v$version/PowerShell-$version-win-x64.msi" -OutFile "$PSRepo\$filename"
        Tee-Object -InputObject "`t[SUCCESS] Downloaded Powershell version $version." @logAttr

        $creds = Import-Clixml -Path "$($PSScriptRoot)\Credentials\homelab@mydomain.local_cred.xml"
        $credentials = New-Object -TypeName pscredential($creds.username, $creds.Password)
        $messageAttr = @{
            SmtpServer = "awm17x.mydomain.local"
            From = "wes_admin@mydomain.local"
            To = "poweredge.t320.server@gmail.com"
            Subject = "Powershell Update"
            Body = "Powershell version $version is available."
            Credential = $credentials
            ErrorAction = "Stop"
        }
        Send-MailMessage @messageAttr
        Tee-Object -InputObject "`t[INFO]: Successfully sent notification e-mail." @logAttr
    } else {
        Tee-Object -InputObject "`t[INFO] No update available..." @logAttr
    }
}
Catch {
    Tee-Object -InputObject "`t[ERROR] An error occurred...`n`r`t`t$($error[0] | Select-Object *)" @logAttr
}