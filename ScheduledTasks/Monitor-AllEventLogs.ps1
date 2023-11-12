$config = Get-IniContent -FilePath (Join-Path -Path $scriptsRoot -ChildPath scriptconfig.ini)
$domain = $config.Values.strDomain
$scriptsRoot = Join-Path -Path $config.Values.strFileShare -ChildPath "Scripts"
$scriptsRoot

$computers = (Get-ADComputer -Server $domain -Filter {OperatingSystem -like "Windows*"}).DNSHostName
$email_cred = Import-Clixml -Path "$scriptsRoot\Credentials\homelab@mydomain.local_cred.xml"
$email_username = $email_cred.UserName;
$email_password = $email_cred.GetNetworkCredential().Password;


foreach($computer in $computers) {
    Write-Host $computer 
    if(Test-Connection -ComputerName $computer.ToString() -Count 1 -Quiet) {
        $scriptblock= {
            Start-Transcript (Join-Path -Path $Args[0] -ChildPath "ScriptLogs\Monitor_EventLogs_log_$env:COMPUTERNAME.txt") -Force
            powershell.exe -ExecutionPolicy bypass -File (Join-Path -Path $Args[0] -ChildPath "Monitor-EventLogs.ps1") $Args[1] $Args[2] "50"
            Stop-Transcript
       }
       Invoke-Command -ComputerName $computer -ScriptBlock $scriptblock -ArgumentList $scriptsRoot, $email_username, $email_password
    }
}