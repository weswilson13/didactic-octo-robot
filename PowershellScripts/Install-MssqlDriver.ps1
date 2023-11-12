param(
    [Parameter(Mandatory=$true)]
    [string] $ComputerName
   ,
    [Parameter(Mandatory=$true)]
    [ValidateSet('ODBC','OLEDB')]
    [string] $DriverType
)

# get latest driver
$msi = Get-FileMetaData '\\raspberrypi4-1\nas01\Microsoft\SQL Server\Providers-Drivers' | ? {$_.Filename -match $DriverType} | Sort-Object -Property 'Content Created' -Descending | select -First 1
Write-Host msi filepath: $msi.Path

$pssession = New-PSSession $ComputerName

if (-not (Test-Path \\$ComputerName\c$\Tools)) { 
   New-Item -Path \\$ComputerName\c$\Tools -ItemType Directory
   Write-Host Created Directory C:\Tools
}

Copy-Item $msi.Path \\$ComputerName\c$\Tools\newSqlDriver.msi
Write-Host Copied $msi.Path

Invoke-Command -Session $pssession -ScriptBlock { Start-Process -FilePath msiexec.exe -ArgumentList "/i c:\tools\newSqlDriver.msi /qn /L*v c:\tools\sqlDriverUpdate.log IACCEPTMSODBCSQLLICENSETERMS=YES" -Wait }

Remove-Item \\$ComputerName\c$\Tools\newSqlDriver.msi

Remove-PSSession $pssession