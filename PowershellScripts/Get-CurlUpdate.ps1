
Try {
    #$PSDefaultParameterValues = @{"Out-File:Encoding" = "Utf-8"}
    $logPath = "$PSScriptRoot\ScriptLogs\get-curlupdate.log"
    $logAttr = @{
        FilePath = $logPath
        Append = $true
        Encoding = "Utf-8"
    }
    $curlRepo = Join-Path (Split-Path $PSScriptRoot -Parent) "cURL"

    Tee-Object -InputObject "$(Get-Date): Checking for cURL updates..." @logAttr

    $pageContent = Invoke-WebRequest -Uri https://curl.se/windows/ -UseBasicParsing | select -ExpandProperty Content

    $build = (Select-String -InputObject $pageContent -Pattern '(?<=<b>Build</b>: )\d+\.\d+\.\d+_\d+' -AllMatches).Matches[0].Value
    Tee-Object -InputObject "`t[INFO] Latest build from https://curl.se/windows is: $build" @logAttr
    $version = $build.Replace('_','.')

    $latestBuildAvailable = (Get-ChildItem $curlRepo | select Name -ExpandProperty Name) | Select @{Name='File';Expression={$_}}, @{Name='Build';Expression={(Select-String -InputObject $_ -Pattern '\d+\.\d+\.\d+_\d+' -AllMatches).Matches[0].Value}} | sort Build -Descending | select -First 1
    Tee-Object -InputObject "`t[INFO] Latest build in repo is: $($latestBuildAvailable.Build)" @logAttr
    $latestVersionAvailable = $latestBuildAvailable.Build.Replace('_','.')

    $fileName = $latestBuildAvailable.File -replace '\d+\.\d+\.\d+_\d+', $build

    if ($latestVersionAvailable -lt $version) {
        Tee-Object -InputObject "`t[INFO] Downloading latest build..." @logAttr
        wget -Uri "https://curl.se/windows/latest.cgi?p=win64-mingw.zip" -OutFile "$curlRepo\$filename"
        Tee-Object -InputObject "`t[SUCCESS] Downloaded Curl Build $build." @logAttr

        $creds = Import-Clixml -Path "$($PSScriptRoot)\Credentials\homelab@mydomain.local_cred.xml"
        $credentials = New-Object -TypeName pscredential($creds.username, $creds.Password)
        $messageAttr = @{
            SmtpServer = "awm17x.mydomain.local"
            From = "wes_admin@mydomain.local"
            To = "poweredge.t320.server@gmail.com"
            Subject = "Curl Update"
            Body = "Curl build $build is available."
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