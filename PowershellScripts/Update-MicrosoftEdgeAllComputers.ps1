$computers = Get-ADComputer -Filter 'OperatingSystem -like "*Windows*"' | select -ExpandProperty DNSHostName

foreach ($c in $computers) {
    if (Test-Connection $c -Count 2 -Quiet) {
        try {
            Start-Job -ScriptBlock { Z:\Scripts\Install-MsiExeUpdate.ps1 -ComputerName $Args[0] -Type Edge -Verbose } -ArgumentList $c
        }
        catch {$_}
    }
}