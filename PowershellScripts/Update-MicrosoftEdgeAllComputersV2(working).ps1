Function Update-MicrosoftEdge {
    [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromPipeline=$True)]
            [ValidateNotNullOrEmpty()]
            [String] $ComputerName
        )

    if (Test-Connection $ComputerName -Count 2 -Quiet) {
    try {
        $ComputerName | Out-String | Write-Verbose
        .\Install-MsiExeUpdate.ps1 -ComputerName $ComputerName -Type Edge -Verbose
    }
    catch {$_}
    }

}

$computers = Get-ADComputer -Filter 'OperatingSystem -like "*Windows*"' | select -ExpandProperty DNSHostName

Update-MicrosoftEdge -ComputerName $($computers -join ',') -Verbose

 