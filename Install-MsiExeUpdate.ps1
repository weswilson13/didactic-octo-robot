param(
    [Parameter(Mandatory=$false)]
    [string[]] $ComputerName=$env:COMPUTERNAME
   ,
    [Parameter(Mandatory=$true)]
    [ValidateSet('msodbc','msoledb','Edge','Vmware','Npp', 'Defender', 'WinSCP', 'Powershell', 'Dotnet', 'VSCode', 'PuTTY')]
    [string] $Type
   ,
    [Parameter(Mandatory=$false)] 
    [ValidateSet('17','18','19')]
    [string] $SQLVersion
   ,
    [Parameter(Mandatory=$false)] 
    [string] $DefenderVersion
   ,
    [Parameter(Mandatory=$false)]
    [ValidateSet('Hosting', 'AspNet', 'Desktop', 'Runtime', 'UninstallTool')]
    [string] $DotnetType
   ,
    [Parameter(Mandatory=$false)]
    [string] $DotnetVersion

)

foreach ($computer in $ComputerName) {
    if (Test-Connection $ComputerName -Count 1 -Quiet) {

        $filePath = switch -Regex ($Type) {
            '^mso' {'\\raspberrypi4-1\nas01\Microsoft\SQL Server\Providers-Drivers'}
            'Edge' {'\\raspberrypi4-1\nas01\Microsoft\MicrosoftEdge'}
            'Vmware' {'\\raspberrypi4-1\nas01\VMware\Tools'}
            'Npp' {'\\raspberrypi4-1\nas01\Notepad++'} 
            'Defender' {'\\raspberrypi4-1\nas05\Updates\Defender'}
            'WinSCP' {'\\raspberrypi4-1\nas01\WinSCP'}
            'Powershell' {'\\raspberrypi4-1\nas01\WindowsPowershell\Installers'}
            'PuTTY' {'\\raspberrypi4-1\nas01\PuTTY'}
            'dotnet' {'\\raspberrypi4-1\nas01\Microsoft\dotnet'}
            'VSCode' {'\\raspberrypi4-1\nas01\Microsoft\VisualStudio\VSCode'}  
        }

        if ($DotnetType -eq 'UninstallTool') {$PSBoundParameters.DotnetType = 'Uninstall'}

        $software = switch -Regex ($Type) {
            '^mso' {'odbc|oledb'}
            'Edge' {'^Microsoft.*Edge$'} 
            'VMware' {'VMware.*tools'}
            'Npp' {'Npp|Notepad\+\+'}
            'Defender' {'mpam|Defender'} 
            'WinSCP' {'WinSCP'}
            'Powershell' {'Powershell( 7)?'} 
            'PuTTY' {'PuTTY'}
            'dotnet' {"(net)?.*$($PSBoundParameters.DotnetType).*$DotnetVersion"}
            'VSCode' {'V.*S.*Code'} 
        }

        # get latest update
        $msi = Get-ChildItem $filePath | 
            Where-Object {$_.Name -match $software -and $_.Name -like "*$SQLVersion*" -and $_.Extension -in ('.exe','.msi')} | 
            Select-Object FullName, @{Name = 'FileVersion'; Expression = {& "$PSScriptRoot\Get-MsiExeInstallerVersion.ps1" -Path $_.FullName}}, Extension |
            Sort-Object FileVersion -Descending | Select-Object -First 1
        Write-Host msi filepath: $msi.FullName
        
        Write-Host "Installer Version: $($msi.FileVersion)" -ForegroundColor Magenta

        $installedVersion = switch ($DefenderVersion -ne '') {
            true { $DefenderVersion | Select-Object @{Name='DisplayVersion';Expression={$_}}}
            false { & "$PSScriptRoot\Get-RemoteSoftware.ps1" -ComputerName $Computer -Software $software }
        }
        Write-Host "Installed Version: $($installedVersion.DisplayName) v.$($installedVersion.DisplayVersion)" -ForegroundColor Cyan

        if ($msi.FileVersion -le $installedVersion.DisplayVersion) {Write-Warning "Software is up to date. Exiting..."; Exit}

        if (-not (Test-Path \\$Computer\c$\Tools)) { 
           New-Item -Path \\$Computer\c$\Tools -ItemType Directory
           Write-Host Created Directory C:\Tools -ForegroundColor DarkYellow
        }

        $update = "update$($msi.extension)"
        Copy-Item $msi.FullName "\\$Computer\c$\Tools\$update"
        Write-Host "Copied $($msi.FullName) to \\$Computer\c$\Tools\$update" -ForegroundColor Green

        $execPath = switch ($msi.extension) {
            '.exe' {"C:\Tools\$update"}
            default {"msiexec.exe"}
        }

        $command = switch -Regex ($Type) {
            <#TO DO
                Generalize the commands/logging based on extension
            #>
            '^mso' {"/i c:\tools\update.msi /qn /L*v c:\tools\sqlDriverUpdate.log IACCEPTMSODBCSQLLICENSETERMS=YES"}
            'Edge' {"/i c:\tools\update.msi /qn /L*v c:\tools\msEdgeUpdate.log"}
            'VMware' {"/S /v `"/qn REBOOT=R ADDLOCAL=ALL REMOVE=Hgfs /L*v c:\tools\VmwareToolsUpdate.log`""}
            'Npp' {"/S /v `"/qn /L*v c:\tools\NppUpdate.log`""}
            'Defender' {"/S /v `"/qn /L*v c:\tools\DefinitionsUpdate.log`""}
            'WinSCP' {"/i c:\tools\update.msi /qn /L*v c:\tools\winScpUpdate.log"}
            'Powershell' {"/i c:\tools\update.msi /qn /L*v c:\tools\psupdate.log"}
            'PuTTY' {"/i c:\tools\update.msi /qn /L*v c:\tools\puttyUpdate.log"}
            'dotnet' {switch ($DotnetType) {
                    UninstallTool {"/i c:\tools\update.msi /qn /L*v c:\tools\dotnetUninstallToolUpdate.log"}
                    Default {"/S /v `"/qn /L*v c:\tools\dotnetUpdate.log`""}
                } 
            }
            'VSCode' {"/SP /VERYSILENT /MERGETASKS=!runcode,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath"}
        }
        #Invoke-CommandAs -ComputerName $Computer -ScriptBlock { Start-Process -FilePath msiexec.exe -ArgumentList $args -Wait } -ArgumentList $command -AsSystem
        if ($computer -notmatch $env:COMPUTERNAME) {
            Invoke-CommandAs -ComputerName $Computer -ScriptBlock { Start-Process -FilePath $args[0] -ArgumentList $args[1] -Wait } -ArgumentList $execPath,$command -AsSystem
        } else {
            Invoke-Command -ScriptBlock { Start-Process -FilePath $args[0] -ArgumentList $args[1] -Verb RunAs -Wait } -ArgumentList $execPath,$command
        }

        Remove-Item "\\$Computer\c$\Tools\$update"
        Write-Host "Removed \\$Computer\c$\Tools\$update" -ForegroundColor Green
    } else {
        Write-Warning "$Computer is not online."
    }
}