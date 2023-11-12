#Requires -Modules Invoke-CommandAs

param(
    [Parameter(Mandatory=$false)]
    [String[]] $ComputerName,
   
    [Parameter(Mandatory=$true)]
    [String] $Software
)

$Global:_software
$scriptBlock = {
    #$_software = $Software
    Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | 
    Get-ItemProperty | Where-Object {$_.DisplayName -match $_software } | Select-Object -Property DisplayName, DisplayVersion, Version, InstallDate, UninstallString
 }   


if ($ComputerName) {
    foreach ($computer in $ComputerName) {
        if (Test-Connection $computer -Count 1 -Quiet) {
            Invoke-CommandAs -AsSystem -ComputerName $computer -ScriptBlock {
                $a = $args[0]
                Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | 
                Get-ItemProperty | Where-Object {$_.DisplayName -match $a} | Select-Object -Property * #DisplayName, DisplayVersion, Version, InstallDate, UninstallString
            } -ArgumentList $_software
        }
    }
}
else {
    Invoke-Command $scriptBlock
}

