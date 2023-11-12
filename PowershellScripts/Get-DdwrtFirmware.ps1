##########################################################################################
# Script: Get-DdwrtFirmware.ps1
# Script Date: 10/7/2023
# 
# Description: Monitors the dd-wrt firmware release web page for updates.   
#              Automatically downloads the latest release and sends a notification e-mail.
#
##########################################################################################
Set-Location $PSScriptRoot
$PSScriptRoot

try {
    #$PSDefaultParameterValues = @{"Out-File:Encoding" = "Utf-8"}
    $logPath = "$PSScriptRoot\ScriptLogs\get-ddwrtFirmware.log"
    $logAttr = @{
        FilePath = $logPath
        Append = $true
        Encoding = "ascii"
    }
    Tee-Object -InputObject "$(Get-Date): Checking for Firmware Updates...(running as $env:USERNAME)" @logAttr
    $iniContent = (Get-IniContent $PSScriptRoot\scriptconfig.ini -ErrorAction Stop).Values
    #net use z: $iniContent.strFileShare

    
    # get the URI of the latest firmware version available on the dd-wrt downloads page
    $ddwrtFwUri = "https://ftp.dd-wrt.com/dd-wrtv2/downloads/betas/$((Get-Date).Year)"
    $latestRelease = Invoke-WebRequest -Uri $ddwrtFwUri -UseBasicParsing | 
        Select-Object -ExpandProperty Links | 
        Sort-Object href -Descending | 
        Select-Object -First 1
    $latestRelease = $latestRelease.href.TrimEnd('/')
    $router = "netgear-r7000"
    $bin = "netgear-r7000-webflash.bin"
    $fullUri = ($ddwrtFwUri,$latestRelease, $router, $bin -join '/')
    Tee-Object -InputObject "`tLatest Firmware: $fullUri" @logAttr
    
    # build the output filepath string. Make sure it is accessible before downloading anything. Exit the program if the repo is not accessible. 
    $firmwareRepo = "$($iniContent.strFileShare)\Firmware\Router FW"
    if (-not (Test-Path $firmwareRepo)) {
        Tee-Object -InputObject "`t[FATAL ERROR] Could Not Access Firmware Repo. Exiting..." @logAttr
        Throw [System.IO.FileNotFoundException] "Could Not Access Firmware Repo"
    }
    $fwDate = (Select-String -InputObject $latestRelease -Pattern '(\d{1,2})-(\d{2})-(\d{4})' -AllMatches).Matches.Value.Replace('-','.')
    $outputFilepath = "$firmwareRepo\$($bin.replace('.bin',"_$fwDate.bin"))"

    # if the latest version is not already in the repo, download it and send notification
    if (Test-Path $outputFilepath) {
        Tee-Object -InputObject "`tNo updates available." @logAttr
    }
    else {
        # download the new file
        Invoke-WebRequest -Uri $fullUri -OutFile $outputFilepath
        
        # check file size and hashes to make sure this is an update
        $currentVersionSizeAndHash = Get-ChildItem $firmwareRepo -Filter netgear* | 
            Sort-Object CreationTime -Descending | 
            Select-Object -Skip 1 -First 1 -Property 
                @{Name='FileSize';Expression={$_.Length/1KB}},
                @{Name='FileHash';Expression={(Get-FileHash $_.FullName).Hash}}
        Tee-Object -InputObject "`t$currentVersionSizeAndHash" @logAttr

        $newVersionSizeAndHash = Get-ItemProperty $outputFilepath | 
            Select-Object -Property 
                @{Name='FileSize';Expression={$_.Length/1KB}},
                @{Name='FileHash';Expression={(Get-FileHash $_.FullName).Hash}}
        Tee-Object -InputObject "`t$newVersionSizeAndHash" @logAttr
        
        if ($currentVersionSizeAndHash.FileSize -eq $newVersionSizeAndHash.FileSize) {
            Remove-Item $outputFilepath -Force
            Tee-Object -InputObject "`tNo updates available." @logAttr
        }
        else {
            # build an alert e-mail to notify of the available file 
            $creds = Import-Clixml -Path "$PSScriptRoot\Credentials\homelab@mydomain.local_cred.xml"
            $credentials = New-Object -TypeName pscredential($creds.UserName, $creds.Password)
            
            $mailMessage = @{
                Credential = $credentials
                SmtpServer = $($iniContent.strMailServer)
                From = "wes_admin@mydomain.local"
                To = "poweredge.t320.server@gmail.com"
                Subject = "Firmware Update"
                Body = "New DD-WRT Firmware is Available`n`r`t`t$outputFilepath"
                ErrorAction = "Stop"
            }

            Send-MailMessage @mailMessage
            Tee-Object -InputObject "`t$($mailMessage.Body | Out-String)" @logAttr
            
        }
    }
}
catch {
    Tee-Object -InputObject $error[0] @logAttr
}

