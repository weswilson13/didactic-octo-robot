
Try {
    $PSDefaultParameterValues = @{"Out-File:Encoding" = "Utf-8"}
    $logPath = "$PSScriptRoot\ScriptLogs\get-winscpupdate.log"
    $logAttr = @{
        FilePath = $logPath
        Append = $true
        Encoding = "Utf-8"
    }
    $WinScpRepo = Join-Path (Split-Path $PSScriptRoot -Parent) "WinSCP"

    Tee-Object -InputObject "$(Get-Date): Checking for WinSCP updates..." @logAttr

    $link = (Invoke-WebRequest -Uri https://winscp.net/eng/download.php -UseBasicParsing | select -ExpandProperty Links | Select-String -Pattern '/download/WinSCP-(\d+\.\d+\.(\d+)?)-Setup.exe').Matches[0].Value

    $version = (Select-String -InputObject $link -Pattern '\d+\.\d+\.\d+' -AllMatches).Matches[0].Value
    Tee-Object -InputObject "`t[INFO] Latest version from https://winscp.net/eng/download.php is: $version" @logAttr

    $latestVersionAvailable = (Get-ChildItem $WinScpRepo | select Name -ExpandProperty Name) | Select @{Name='File';Expression={$_}}, @{Name='Version';Expression={(Select-String -InputObject $_ -Pattern '\d+\.\d+\.\d+' -AllMatches).Matches[0].Value}} | sort Version -Descending | select -First 1
    Tee-Object -InputObject "`t[INFO] Latest version in repo is: $($latestVersionAvailable.Version)" @logAttr
    
    $fileName = $latestVersionAvailable.File -replace '\d+\.\d+\.\d+', $Version

    if ($latestVersionAvailable.Version -lt $version) {
        Tee-Object -InputObject "`t[INFO] Downloading latest version..." @logAttr
        wget -Uri (Invoke-WebRequest -Uri "https://winscp.net$link" -UseBasicParsing | Select -ExpandProperty Links | Select-String -Pattern 'https.*(?=" class="btn btn-primary btn-lg">Direct download)').Matches[0].Value -OutFile "$WinScpRepo\$filename"
        Tee-Object -InputObject "`t[SUCCESS] Downloaded WinSCP version $version." @logAttr

        $creds = Import-Clixml -Path "$($PSScriptRoot)\Credentials\homelab@mydomain.local_cred.xml"
        $credentials = New-Object -TypeName pscredential($creds.username, $creds.Password)
        $messageAttr = @{
            SmtpServer = "awm17x.mydomain.local"
            From = "wes_admin@mydomain.local"
            To = "poweredge.t320.server@gmail.com"
            Subject = "WinSCP Update"
            Body = "WinSCP version $version is available."
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
    Tee-Object -InputObject "`t[ERROR] An error occurred...`n`r`t`t$($error[0] | select *)" @logAttr
}