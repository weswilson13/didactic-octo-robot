$computers = get-adcomputer -Filter 'OperatingSystem -like "Win*"' 

foreach ($computer in $computers.DNSHostName) {
    if (Test-Connection -ComputerName $computer -Count 1 -Quiet) {
        Invoke-CommandAs -AsSystem -ComputerName $computer -ScriptBlock { Get-WindowsUpdate -Install -AutoReboot -AcceptAll } -Verbose
    }

}
