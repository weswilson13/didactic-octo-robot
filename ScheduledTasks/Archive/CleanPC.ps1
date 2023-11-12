# Silently opens and runs CCleaner, cleaning PC in accordance with the saved 
# Custom Clean configuration. Reboots client when finished.

Start-Transcript -Path "\\192.168.1.4\NAS01\Scripts\Scriptlogs\CleanPC_log_$env:COMPUTERNAME.txt"
#& "C:\Program Files\CCleaner\CCleaner64.exe" /auto /restart
Start-Process -FilePath "C:\Program Files\CCleaner\CCleaner64.exe" -ArgumentList "/auto /restart" -Wait
<#$date=Get-Date
Write-Output "Completed on $date"
Stop-Transcript #>
