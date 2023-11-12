
#Start-Transcript -Path "\\192.168.1.4\NAS01\Scripts\ScriptLogs\Check-Thunderbird_log.txt" -UseMinimalHeader -Append
$path = "\\192.168.1.4\NAS01\Scripts\ScriptLogs\Check-Thunderbird_log.txt"

if ((Get-Process -Name thunderbird -ErrorAction SilentlyContinue) -eq $null) {
    Out-File -FilePath $path -InputObject ((Get-Date -Format "MM-dd-yyyy HH:mm:ss")," thunderbird is not running. Attempting to start." -join "`t") -Append -Encoding ascii
    Start-Process -WindowStyle Minimized thunderbird    
} else {
    Out-File -FilePath $path -InputObject ((Get-Date -Format "MM-dd-yyyy HH:mm:ss")," thunderbird is running" -join "`t") -Append -Encoding ascii
}

if ((Get-Service -Name hmailserver).Status -eq 'Stopped') {
    Out-File -FilePath $path -InputObject ((Get-Date -Format "MM-dd-yyyy HH:mm:ss")," hmail server is stopped. Attempting to start." -join "`t") -Append -Encoding ascii
    Start-Service hmailserver
    #Start-Sleep -Seconds 5
    #Get-Service hmailserver
} elseif (-not (Get-ChildItem -Path "C:\Program Files (x86)\hMailServer\Logs" -Name ("*",(get-date -Format 'yyyy-MM-dd').ToString(),"*" -join ""))) {
    Restart-Service hmailserver -Force
    Start-Sleep -Seconds 5
} else {
    Out-File -FilePath $path -InputObject ((Get-Date -Format "MM-dd-yyyy HH:mm:ss")," hmail server is running" -join "`t") -Append -Encoding ascii
}