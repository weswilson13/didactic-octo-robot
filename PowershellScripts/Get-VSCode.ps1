
Try {
    #$PSDefaultParameterValues = @{"Out-File:Encoding" = "Utf-8"}
    $logPath = "$PSScriptRoot\ScriptLogs\get-vscode.log"
    $logAttr = @{
        FilePath = $logPath
        Append = $true
        Encoding = "Utf-8"
    }
    $vsCodeRepo = Join-Path (Split-Path $PSScriptRoot -Parent) "Microsoft\VisualStudio\VSCode"

    Tee-Object -InputObject "$(Get-Date): Checking for VSCode updates..." @logAttr

    if ($fileContent -eq $null) {
        $fileContent = Invoke-WebRequest -Uri "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64" -UseBasicParsing
    }
    $contentDisposition = ConvertFrom-StringData -StringData ($fileContent.Headers.'Content-Disposition').split(';')[1].replace('"','') 
    $fileName = $contentDisposition.filename

    $version = (Select-String -InputObject $fileName -Pattern '\d+\.\d+\.\d+' -AllMatches).Matches[0].Value
    Tee-Object -InputObject "`t[INFO] Latest version from https://code.visualstudio.com/sha/download?build=stable&os=win32-x64 is: $version" @logAttr

    $latestVersionAvailable = (Get-ChildItem $vsCodeRepo | select Name -ExpandProperty Name) | Select @{Name='File';Expression={$_}}, @{Name='Version';Expression={(Select-String -InputObject $_ -Pattern '\d+\.\d+\.\d+' -AllMatches).Matches[0].Value}} | sort Version -Descending | select -First 1
    Tee-Object -InputObject "`t[INFO] Latest Version in repo is: $($latestVersionAvailable.Version)" @logAttr   

    if ($latestVersionAvailable.Version -lt $version) {
        Tee-Object -InputObject "`t[INFO] Downloading latest version..." @logAttr
        #$fileContent.RawContent | Out-File "$vsCodeRepo\$filename"
        wget -Uri "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64" -OutFile "$vsCodeRepo\$filename"
        Tee-Object -InputObject "`t[SUCCESS] Downloaded VSCode Version $version." @logAttr

        $creds = Import-Clixml -Path "$($PSScriptRoot)\Credentials\homelab@mydomain.local_cred.xml"
        $credentials = New-Object -TypeName pscredential($creds.username, $creds.Password)
        $messageAttr = @{
            SmtpServer = "awm17x.mydomain.local"
            From = "wes_admin@mydomain.local"
            To = "poweredge.t320.server@gmail.com"
            Subject = "VSCode Update"
            Body = "VSCode version $version is available."
            Credential = $credentials
            ErrorAction = "Stop"
        }
        Send-MailMessage @messageAttr
        Tee-Object -InputObject "`t[INFO]: Successfully sent notification e-mail." $logAttr
    } else {
        Tee-Object -InputObject "`t[INFO] No update available..." @logAttr
    }
}
Catch {
    Tee-Object -InputObject "`t[ERROR] An error occurred...`n`r`t`t$($error[0] | select *)" @logAttr
}