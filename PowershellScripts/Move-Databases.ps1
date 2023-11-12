#requires -RunAsAdministrator 

$source = "\\192.168.1.4\NAS04\MSSQL\Data"
$destination = "\\192.168.1.10\E$\MSSQL\Data"

if(-not (Test-Path $destination)){
    New-Item -Path $destination -ItemType Directory
}

robocopy $source $destination /s /z /copyall /np #/L