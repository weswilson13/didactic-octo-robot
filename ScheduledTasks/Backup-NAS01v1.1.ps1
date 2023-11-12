$datetime = Get-Date -format yyyyMMddHHmmss
$transactionLog="\\192.168.1.4\NAS03\Logs\BackupLogFile_$datetime.log"
Start-Transcript -Path $transactionLog -ErrorAction SilentlyContinue

$whoami = whoami
Write-Output (-join "Run as ", $whoami, "`n")

$source="\\192.168.1.4\NAS01"
Write-Output (-join "Source ", $source)

$destination = "\\192.168.1.4\NAS03\Backup"
Write-Output (-join "Destination ", $destination)


$logfile="\\192.168.1.4\NAS03\Logs\BackupLogFile_$datetime.log"
Write-Output (-join "Logfile ", $logfile)

#Invoke-Command -ComputerName wiskyekosiera.mydomain.local -Authentication Negotiate -ScriptBlock {reg export HKEY_CURRENT_USER\SOFTWARE\SimonTatham \\192.168.1.4\NAS01\PuTTY\PuTTY_Profile.reg /Y}

Robocopy  $source $destination /MIR /XA:SH /XD ?RECYCLE.BIN .NET /R:5 /W:15 /MT:32 #/V /ETA /NP /LOG:$logfile

Stop-Transcript