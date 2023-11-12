<#  
    The computer running this script must have all of the hosts added to its Trusted Hosts File.
#>

$computers = @()
$computers += (Get-ADComputer -Server mydomain.local -Filter {OperatingSystem -like "Windows 10*"}).DNSHostName

$mailServerLog="\\192.168.1.4\NAS01\Scripts\ScriptLogs\Check-Thunderbird_log.txt"
$mailServerScript = "\\192.168.1.4\NAS01\Scripts\ScheduledTasks\Check-Thunderbird.ps1"
$logHeader = "**********************`nHomelab Mail Server Status Log`nScript: $mailServerScript`nMachine: $env:COMPUTERNAME`nUsername: $env:USERDOMAIN\$env:USERNAME`n**********************"
Set-Content -Path $mailServerLog -Value $logHeader

foreach($computer in $computers) {
    Write-Host "Machine Name: $computer"
    if(Test-Connection -ComputerName $computer.ToString() -Count 1 -Quiet) {
        Write-Host "$computer is available"
        if ($computer -match '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}') {
            $cred = Import-Clixml -Path \\192.168.1.4\NAS01\Scripts\Credentials\Linds_cred.xml
            Invoke-Command -ComputerName $computer -Credential $cred -ScriptBlock {
                    Start-Transcript -Path "\\192.168.1.4\NAS01\Scripts\Scriptlogs\CleanPC_log_$env:COMPUTERNAME.txt"
                    Start-Process -FilePath "C:\Program Files\CCleaner\CCleaner64.exe" -ArgumentList "/auto /restart" -Wait
                    Stop-Transcript
                } -ErrorAction SilentlyContinue -Verbose
        } else {
            Invoke-Command -ComputerName $computer -ScriptBlock {
                        Start-Transcript -Path "\\192.168.1.4\NAS01\Scripts\Scriptlogs\CleanPC_log_$env:COMPUTERNAME.txt"
                        Start-Process -FilePath "C:\Program Files\CCleaner\CCleaner64.exe" -ArgumentList "/auto /restart" -Wait
                        Stop-Transcript
                    } -ErrorAction SilentlyContinue -Verbose
        }
    }
}