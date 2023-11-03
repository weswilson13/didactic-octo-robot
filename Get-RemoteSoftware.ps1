#Requires -Modules Invoke-CommandAs

param(
    [Parameter(Mandatory=$false)]
    [String[]] $ComputerName = $env:COMPUTERNAME,
   
    [Parameter(Mandatory=$true)]
    [String] $Software
)

$command = "Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | 
            Get-ItemProperty | Where-Object {`$_.DisplayName -match '$Software' } | Select-Object -Property DisplayName, DisplayVersion, Version, InstallDate, UninstallString"

if ($ComputerName -ne $env:COMPUTERNAME) {
    foreach ($computer in $ComputerName) {
        if (Test-Connection $computer -Count 1 -Quiet) {
            Invoke-Command -ComputerName $computer -ScriptBlock {Invoke-Expression $Args[0].ToString()} -ArgumentList $command
        }
    }
}
else {
    Invoke-Expression $command
}

