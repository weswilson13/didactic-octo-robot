[cmdletbinding(DefaultParameterSetName = 'All')]
param(
    [Parameter(Mandatory = $false)]
    [Parameter(ParameterSetName = 'All')]
    [string[]] $ComputerName = $env:COMPUTERNAME
    ,
    [Parameter(Mandatory = $true)]
    [Parameter(ParameterSetName = 'All')]
    [ValidateSet('msodbc', 'msoledb', 'Edge', 'Git', 'TortoiseGit', 'Vmware', 'Npp', 'Defender', 'WinSCP', 'Powershell', 'Dotnet', 'VSCode', 'PuTTY', 'SSMS', 'WindowsTerminal')]
    [string[]] $Type
    ,
    [Parameter(Mandatory = $false, ParameterSetName = 'All')]
    [Parameter(ParameterSetName = 'SQL')] 
    [ValidateSet('17', '18', '19')]
    [string] $SQLVersion
    ,
    [Parameter(Mandatory = $false, ParameterSetName = 'All')]
    [Parameter(Mandatory = $true, ParameterSetName = 'Defender')] 
    [string] $DefenderVersion
    ,
    [Parameter(Mandatory = $false, ParameterSetName = 'All')]
    [Parameter(Mandatory = $true, ParameterSetName = 'Dotnet')]
    [ValidateSet('Hosting', 'AspNet', 'Desktop', 'Runtime', 'UninstallTool')]
    [string] $DotnetType
    ,
    [Parameter(Mandatory = $false, ParameterSetName = 'All')]
    [Parameter(Mandatory = $true, ParameterSetName = 'Dotnet')]
    [string] $DotnetVersion
    ,
    [Parameter(Mandatory = $false, ParameterSetName = 'All')]
    [Switch] $Force
    ,
    [Parameter(Mandatory = $false, ParameterSetName = 'All')]
    [Switch] $Log

)
function Use-RunAs 
{    
    # Check if script is running as Administrator and if not elevate it
    # Use Check Switch to check if admin 
     
    param([Switch]$Check) 
     
    $IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()` 
        ).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator") 
         
    if ($Check) { return $IsAdmin }   
      
    if ($MyInvocation.ScriptName -ne "") 
    {  
        if (-not $IsAdmin)  
          {  
            try 
            {   $paramString = @()
                foreach ($param in $_psBoundParameters.GetEnumerator()) {
                    $paramString += "-{0} {1}" -f $param.Key,($param.Value -join ',')
                }
                
                $params = $paramString -join " "

                $arg = "-file `"$($MyInvocation.ScriptName)`" $params" 
                Start-Process "powershell.exe" -Verb Runas -ArgumentList $arg -ErrorAction 'stop'  
            } 
            catch 
            { 
                Write-Warning "Error - Failed to restart script elevated"  
                break               
            } 
            exit 
        }  
    }  
} 

$_psBoundParameters = $PSBoundParameters

Use-RunAs 

function Use-RunAs 
{    
    # Check if script is running as Administrator and if not elevate it
    # Use Check Switch to check if admin 
     
    param([Switch]$Check) 
     
    $IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()` 
        ).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator") 
         
    if ($Check) { return $IsAdmin }   
      
    if ($MyInvocation.ScriptName -ne "") 
    {  
        if (-not $IsAdmin)  
          {  
            try 
            {  
                $arg = "-file `"$($MyInvocation.ScriptName)`"" 
                Start-Process "$psHome\powershell.exe" -Verb Runas -ArgumentList $arg -ErrorAction 'stop'  
            } 
            catch 
            { 
                Write-Warning "Error - Failed to restart script elevated"  
                break               
            } 
            exit 
        }  
    }  
} 

Use-RunAs 

$logpath = "$env:TEMP\Install-MsiExeUpdate_Log.log"
$PSDefaultParameterValues["Out-File:FilePath"]=$logPath
$PSDefaultParameterValues["Out-File:Append"]=$true

$softwareRepo = '\\Optimusprime\Z'
$updates = '\\mydomain\dfs\Updates'

if (Test-Path $logPath) { Remove-item $logPath -Force }

try {
foreach ($computer in $ComputerName) {
    foreach ($T in $Type) {
        if (Test-Connection $ComputerName -Count 1 -Quiet) {

            $filePath = switch -Regex ($T) {
                '^mso' { "$softwareRepo\Microsoft\SQL Server\Providers-Drivers" }
                'Edge' { "$softwareRepo\Microsoft\MicrosoftEdge" }
                'Git' { "$softwareRepo\Git"}
                'TortoiseGit' { "$softwareRepo\TortoiseGit"}
                'Vmware' { "$softwareRepo\VMware\Tools" }
                'Npp' { "$softwareRepo\Notepad++" } 
                'Defender' { "$updates\Updates\Defender" }
                'WinSCP' { "$softwareRepo\WinSCP" }
                'Powershell' { "$softwareRepo\WindowsPowershell\Installers" }
                'PuTTY' { "$softwareRepo\PuTTY" }
                'dotnet' { "$softwareRepo\Microsoft\dotnet" }
                'VSCode' { "$softwareRepo\Microsoft\VisualStudio\VSCode" }  
                'SSMS' { "$softwareRepo\Microsoft\SQL Server" }
                'WindowsTerminal' { "$softwareRepo\Microsoft\WindowsTerminal\Installers" }
            }

            if ($T -eq 'WindowsTerminal') {
                $files = Get-ChildItem $filePath -File 
                foreach ($file in $files) {
                    Add-Member -InputObject $file -NotePropertyMembers @{Version = (Select-String -InputObject $file.Name -Pattern '\d+\.\d+\.\d+\.\d+').Matches.Value -replace '\D' }
                }
                $latestVersion = ($files.Version | Measure-Object -Maximum).Maximum
                $exePath = Split-Path $filePath -Parent
                if (((Get-ItemProperty "$exePath\WindowsTerminal.exe").VersionInfo.ProductVersion -replace '\D') -lt $latestVersion) {
                
                    Get-Process WindowsTerminal | Stop-Process -Force
                
                    $zipFile = $files | Where-Object { $_.Version -eq $latestVersion }
                    Write-Host zip filepath: $zipFile.Name
                    if ($Log.IsPresent) { Out-File -InputObject "zip filepath: $($zipFile.Name)" }

                    Expand-Archive -Path $zipFile.FullName -DestinationPath $exePath -Force
                    $newFolder = Get-ChildItem $exePath -Directory | Where-Object { $_.Name -match 'terminal-\d+' } 
                    Get-ChildItem $newFolder.FullName | Copy-Item -Destination $exePath -Recurse -Force
                    Write-Host "Copied all files to $exePath" 
                    if ($Log.IsPresent) { Out-File -InputObject "Copied all files to $exePath" }  
                    Remove-Item $newFolder.FullName -Recurse
                }
                exit    
            }

            if ($DotnetType -eq 'UninstallTool') { $PSBoundParameters.DotnetType = 'Uninstall' }
            if ($DotnetVersion) { $PSBoundParameters.DotnetVersion = $DotnetVersion.Substring(0, 3) }
        
            [string]$software = switch -Regex ($T) {
                '^mso' { 'odbc|oledb' }
                'Edge' { '^Microsoft.*Edge' } 
                '^Git' { '^Git' }
                'TortoiseGit' { 'Tortoise' }
                'VMware' { 'VMware.*tools' }
                'Npp' { '(Npp|Notepad\+\+)' }
                'Defender' { 'mpam|Defender' } 
                'WinSCP' { 'WinSCP' }
                'Powershell' { 'Powershell( 7)?' } 
                'PuTTY' { 'PuTTY' }
                'dotnet' { "(net)?.*$($PSBoundParameters.DotnetType).*$($PSBoundParameters.DotnetVersion)" }
                'VSCode' { '(V.*S.*)?Code' }
                'SSMS' { '(SSMS)-Setup|^SQL Server Management Studio$' } 
            }

            Write-Verbose $software
            
            # get latest update
            $files = Get-ChildItem $filePath -Recurse -ErrorAction SilentlyContinue | 
                Where-Object { $_.Name -match $software -and $_.Name -like "*$SQLVersion*" -and $_.Name -like "*$DotnetVersion*" -and $_.Extension -in ('.exe', '.msi') }
                
            $files = $files | ForEach-Object {
                $splat = @{
                    InputObject         = $PSItem
                    NotePropertyMembers = @{ FileVersion = $(& "$softwareRepo\Scripts\Get-MsiExeInstallerVersion.ps1" $_.FullName) }
                }
                Add-Member @splat -PassThru -Force
            }

            $msi = $files | Sort-Object FileVersion -Descending | 
                Select-Object @{Name="InstallerName";Expression={$_.Name}}, `
                            @{Name="InstallerPath";Expression={$_.FullName}}, `
                            @{Name="InstallerVersion";Expression={$_.FileVersion}}, `
                            @{Name="InstallerExtension";Expression={$_.Extension}} -First 1
            
            $msi | Format-List | Out-String | Write-Host -ForegroundColor Magenta

            $installedVersion = switch ($T) {
                'Defender' { 
                    [PSCustomObject]@{DisplayName='Defender';DisplayVersion=Get-MpComputerStatus -CimSession $Computer | 
                    Select-Object -ExpandProperty AntispywareSignatureVersion} 
                }
                default { & "$PSScriptRoot\Get-RemoteSoftware.ps1" -ComputerName $Computer -Software $software }
            }
            Write-Host "Installed Version: $($installedVersion.DisplayName) v.$($installedVersion.DisplayVersion)" -ForegroundColor Cyan
            if ($Log.IsPresent) {
                [PSCustomObject]@{
                    TargetComputer=$Computer
                    InstalledSoftware = $installedVersion.DisplayName
                    InstalledVersion = $installedVersion.DisplayVersion
                    InstallerVersion = $msi.InstallerVersion
                    InstallerName = $msi.InstallerName
                    InstallerPath = $msi.InstallerPath
                    InstallerExtension = $msi.InstallerExtension
                    PaddedInstalledVersion = ($installedVersion.DisplayVersion -replace '\D').PadRight(10,'0')
                    PaddedInstallerVersion = ($msi.InstallerVersion -replace '\D').PadRight(10,'0')
                    ForceIsPresent = $Force.IsPresent 
                    InstallingUpdate = $($msi.InstallerVersion -replace '\D').PadRight(10,'0') -gt $($installedVersion.DisplayVersion -replace '\D').PadRight(10,'0') -or $Force.IsPresent
                    SoftwareRegexPattern = $software
                } | Format-List | Out-String | Out-File
            }

            if ([version]$msi.InstallerVersion -le [version]$installedVersion.DisplayVersion -and !$Force.IsPresent) { 
                Write-Warning "Software is up to date. Exiting..."
                if ($Log.IsPresent) { Out-File -InputObject "Software is up to date. Exiting..." }
                Continue 
            }

            if (-not (Test-Path \\$Computer\c$\Tools)) { 
                New-Item -Path \\$Computer\c$\Tools -ItemType Directory -Verbose
                if ($Log.IsPresent) { Out-File -InputObject "Created Directory C:\Tools" }
            }

            $update = "update$($msi.InstallerExtension)"
            Copy-Item $msi.InstallerPath "\\$Computer\c$\Tools\$update"
            Write-Host "Copied $($msi.InstallerPath) to \\$Computer\c$\Tools\$update" -ForegroundColor Green
            if ($Log.IsPresent) { Out-File -InputObject "Copied $($msi.InstallerPath) to \\$Computer\c$\Tools\$update" }

            $execPath = switch ($msi.InstallerExtension) {
                '.exe' { "C:\Tools\$update" }
                default { "msiexec.exe" }
            }

            $command = switch -Regex ($T) {
            <# TO DO
                Generalize the commands/logging based on extension
            #>
                '^mso' { "/i c:\tools\update.msi /qn /L*v c:\tools\sqlDriverUpdate.log IACCEPTMSODBCSQLLICENSETERMS=YES" }
                'Edge' { "/i c:\tools\update.msi /qn /L*v c:\tools\msEdgeUpdate.log" }
                '^Git' { "c:\tools\update.exe /verysilent /log=c:\tools\gitUpdate.log" }
                'TortoiseGit' { "/i c:\tools\update.msi /quiet /L*v c:\tools\tortoiseGitUpdate.log" }
                'VMware' { "/S /v `"/qn /L*v ""c:\tools\VmwareToolsUpdate.log"" REBOOT=R ADDLOCAL=ALL REMOVE=Hgfs,VmwTimeProvider`"" }
                'Npp' { "/S /v `"/qn /L*v c:\tools\NppUpdate.log`"" }
                'Defender' { "/S /v `"/qn /L*v c:\tools\DefinitionsUpdate.log`"" }
                'WinSCP' { "/a c:\tools\update.exe /forcecloseapplications /sp- /verysilent /log=c:\tools\winScpUpdate.log" }
                'Powershell' { "/i c:\tools\update.msi /qn /L*v c:\tools\psupdate.log ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1 ENABLE_PSREMOTING=1 REGISTER_MANIFEST=1 ADD_PATH=1 ENABLE_MU=1" }
                'PuTTY' { "/a c:\tools\update.msi /qn /L*v c:\tools\puttyUpdate.log" }
                'dotnet' {
                    switch ($DotnetType) {
                        UninstallTool { "/i c:\tools\update.msi /qn /L*v c:\tools\dotnetUninstallToolUpdate.log" }
                        Default { "/S /v `"/qn /L*v c:\tools\dotnetUpdate.log`"" }
                    } 
                }
                'VSCode' { "/SP /VERYSILENT /MERGETASKS=!runcode,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath" }
                'SSMS' { "/install /quiet /norestart /log c:\tools\ssms.log" }
            }

            if ($T -in ('SSMS', 'Npp', 'VSCode')) { 
                Get-Process | Where-Object { $_.Name -match $software } | Stop-Process -Force -ErrorAction Stop -Verbose
            }

            Write-Verbose $command

            #Invoke-CommandAs -ComputerName $Computer -ScriptBlock { Start-Process -FilePath msiexec.exe -ArgumentList $args -Wait } -ArgumentList $command -AsSystem
            try {
                if ($computer -notmatch $env:COMPUTERNAME) {
                    if ($Log.IsPresent) { Out-File -InputObject "Executing: Invoke-Command -ComputerName $Computer -ScriptBlock { Start-Process $execPath -ArgumentList $command -Verb RunAs -Wait }" }
                    $proc = Invoke-Command -ComputerName $Computer -ScriptBlock { Start-Process $args[0] -ArgumentList $args[1] -Verb RunAs -Wait -PassThru } -ArgumentList $execPath, $command
                    $proc.ExitCode
                }
                else {
                    if ($Log.IsPresent) { Out-File -InputObject "Executing: Start-Process -FilePath $execPath -ArgumentList $command -Verb RunAs -Wait" }
                    $proc = Invoke-Command -ScriptBlock { Start-Process -FilePath $args[0] -ArgumentList $args[1] -Wait -PassThru } -ArgumentList $execPath, $command
                    $proc.ExitCode
                }

                Remove-Item "\\$Computer\c$\Tools\$update" -Verbose
                if ($Log.IsPresent) { Out-File -InputObject "Removed \\$Computer\c$\Tools\$update" }
            }
            catch { $_ }
        }
        else {
            Write-Warning "$Computer is not online."
            if ($Log.IsPresent) { Out-File -InputObject "$Computer is not online." }
        }
    }
}
}
catch {
    $Error[0]
    if ($Log.IsPresent) { Out-File -InputObject $($Error[0]) }
}

# SIG # Begin signature block
# MIIbuQYJKoZIhvcNAQcCoIIbqjCCG6YCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBsbzNxoisH2Vp+
# NnTEU3TEC4xVaf540mOIkizpr3/Z6qCCFgswggMEMIIB7KADAgECAhAb7s/Dpqpu
# uUM1ATLfmWzVMA0GCSqGSIb3DQEBCwUAMBoxGDAWBgNVBAMMD0NvZGVTaWduaW5n
# Q2VydDAeFw0yMzExMTYyMjAxNDRaFw0yNDExMTYyMjIxNDRaMBoxGDAWBgNVBAMM
# D0NvZGVTaWduaW5nQ2VydDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
# ALfhMVcOd/NUwngr/o8cy8+qOXJwcDdvSeq4cD/HhHmngt5hshFqPGjb1aq4RApu
# YSl/veqGB5L+RzzpmV17lEWr91jy5hke+iEra5rXPoyz2oVNx5wfzeiHfDTb+NJy
# B6TX+l1ZpbuvQOB2JvutpshJUAx8B0wA9P69OrW5W7uOHPfUQA8tN3c//fCSM7c/
# T+61TOaaNXkychjqCCdfWNEZfwczPGdXBTHHjnpOTEHtHif8LTR4fygfE9GrDS/l
# CTCnmEd/V/4DSxrdRPcrB+M0lZtcrOTJFZvV80SF2vNEbsvD9aZ5LB58PNXTPO26
# lVWDnss6Mli3ice0HJwCQIUCAwEAAaNGMEQwDgYDVR0PAQH/BAQDAgeAMBMGA1Ud
# JQQMMAoGCCsGAQUFBwMDMB0GA1UdDgQWBBRGPwmJM1n90kd98y4H2PGBQQCtYzAN
# BgkqhkiG9w0BAQsFAAOCAQEAeayj5nmwYsBN6XuAg0u1V6eUErFYmxRxbRl1oUZB
# IKa+cXgLJ0mTgT96XFggcsy5YYAjQEtVc00HgY6B5DMQ+KoLJWc8ROC5YAcmHDAR
# RMZngyT+oRnbgQd7KHmLf65p5QdroCmP89whRbEE0rdVLj9VEyYFJaCTx/H5kc+N
# l/oxqatLV6wdbMtNt0Q+4AIJzZc/4JFcm2LkXPWpaG+/cSmt3emwNFybQPbNiG+X
# 420Nk+ZlSU0vnfR3cxwK8cQeKG/qsZjOSIZ0s6Z0X1W30x+Yc7b81ZbaquByhe2X
# HD12AqY3PcWwYEVkMuxxGh+EpBAdmiE60gdAyPNhL6OgvTCCBY0wggR1oAMCAQIC
# EA6bGI750C3n79tQ4ghAGFowDQYJKoZIhvcNAQEMBQAwZTELMAkGA1UEBhMCVVMx
# FTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNv
# bTEkMCIGA1UEAxMbRGlnaUNlcnQgQXNzdXJlZCBJRCBSb290IENBMB4XDTIyMDgw
# MTAwMDAwMFoXDTMxMTEwOTIzNTk1OVowYjELMAkGA1UEBhMCVVMxFTATBgNVBAoT
# DERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEhMB8GA1UE
# AxMYRGlnaUNlcnQgVHJ1c3RlZCBSb290IEc0MIICIjANBgkqhkiG9w0BAQEFAAOC
# Ag8AMIICCgKCAgEAv+aQc2jeu+RdSjwwIjBpM+zCpyUuySE98orYWcLhKac9WKt2
# ms2uexuEDcQwH/MbpDgW61bGl20dq7J58soR0uRf1gU8Ug9SH8aeFaV+vp+pVxZZ
# VXKvaJNwwrK6dZlqczKU0RBEEC7fgvMHhOZ0O21x4i0MG+4g1ckgHWMpLc7sXk7I
# k/ghYZs06wXGXuxbGrzryc/NrDRAX7F6Zu53yEioZldXn1RYjgwrt0+nMNlW7sp7
# XeOtyU9e5TXnMcvak17cjo+A2raRmECQecN4x7axxLVqGDgDEI3Y1DekLgV9iPWC
# PhCRcKtVgkEy19sEcypukQF8IUzUvK4bA3VdeGbZOjFEmjNAvwjXWkmkwuapoGfd
# pCe8oU85tRFYF/ckXEaPZPfBaYh2mHY9WV1CdoeJl2l6SPDgohIbZpp0yt5LHucO
# Y67m1O+SkjqePdwA5EUlibaaRBkrfsCUtNJhbesz2cXfSwQAzH0clcOP9yGyshG3
# u3/y1YxwLEFgqrFjGESVGnZifvaAsPvoZKYz0YkH4b235kOkGLimdwHhD5QMIR2y
# VCkliWzlDlJRR3S+Jqy2QXXeeqxfjT/JvNNBERJb5RBQ6zHFynIWIgnffEx1P2Ps
# IV/EIFFrb7GrhotPwtZFX50g/KEexcCPorF+CiaZ9eRpL5gdLfXZqbId5RsCAwEA
# AaOCATowggE2MA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFOzX44LScV1kTN8u
# Zz/nupiuHA9PMB8GA1UdIwQYMBaAFEXroq/0ksuCMS1Ri6enIZ3zbcgPMA4GA1Ud
# DwEB/wQEAwIBhjB5BggrBgEFBQcBAQRtMGswJAYIKwYBBQUHMAGGGGh0dHA6Ly9v
# Y3NwLmRpZ2ljZXJ0LmNvbTBDBggrBgEFBQcwAoY3aHR0cDovL2NhY2VydHMuZGln
# aWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNydDBFBgNVHR8EPjA8
# MDqgOKA2hjRodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVk
# SURSb290Q0EuY3JsMBEGA1UdIAQKMAgwBgYEVR0gADANBgkqhkiG9w0BAQwFAAOC
# AQEAcKC/Q1xV5zhfoKN0Gz22Ftf3v1cHvZqsoYcs7IVeqRq7IviHGmlUIu2kiHdt
# vRoU9BNKei8ttzjv9P+Aufih9/Jy3iS8UgPITtAq3votVs/59PesMHqai7Je1M/R
# Q0SbQyHrlnKhSLSZy51PpwYDE3cnRNTnf+hZqPC/Lwum6fI0POz3A8eHqNJMQBk1
# RmppVLC4oVaO7KTVPeix3P0c2PR3WlxUjG/voVA9/HYJaISfb8rbII01YBwCA8sg
# sKxYoA5AY8WYIsGyWfVVa88nq2x2zm8jLfR+cWojayL/ErhULSd+2DrZ8LaHlv1b
# 0VysGMNNn3O3AamfV6peKOK5lDCCBq4wggSWoAMCAQICEAc2N7ckVHzYR6z9KGYq
# XlswDQYJKoZIhvcNAQELBQAwYjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lD
# ZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEhMB8GA1UEAxMYRGln
# aUNlcnQgVHJ1c3RlZCBSb290IEc0MB4XDTIyMDMyMzAwMDAwMFoXDTM3MDMyMjIz
# NTk1OVowYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMTsw
# OQYDVQQDEzJEaWdpQ2VydCBUcnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2IFRpbWVT
# dGFtcGluZyBDQTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAMaGNQZJ
# s8E9cklRVcclA8TykTepl1Gh1tKD0Z5Mom2gsMyD+Vr2EaFEFUJfpIjzaPp985yJ
# C3+dH54PMx9QEwsmc5Zt+FeoAn39Q7SE2hHxc7Gz7iuAhIoiGN/r2j3EF3+rGSs+
# QtxnjupRPfDWVtTnKC3r07G1decfBmWNlCnT2exp39mQh0YAe9tEQYncfGpXevA3
# eZ9drMvohGS0UvJ2R/dhgxndX7RUCyFobjchu0CsX7LeSn3O9TkSZ+8OpWNs5KbF
# Hc02DVzV5huowWR0QKfAcsW6Th+xtVhNef7Xj3OTrCw54qVI1vCwMROpVymWJy71
# h6aPTnYVVSZwmCZ/oBpHIEPjQ2OAe3VuJyWQmDo4EbP29p7mO1vsgd4iFNmCKseS
# v6De4z6ic/rnH1pslPJSlRErWHRAKKtzQ87fSqEcazjFKfPKqpZzQmiftkaznTqj
# 1QPgv/CiPMpC3BhIfxQ0z9JMq++bPf4OuGQq+nUoJEHtQr8FnGZJUlD0UfM2SU2L
# INIsVzV5K6jzRWC8I41Y99xh3pP+OcD5sjClTNfpmEpYPtMDiP6zj9NeS3YSUZPJ
# jAw7W4oiqMEmCPkUEBIDfV8ju2TjY+Cm4T72wnSyPx4JduyrXUZ14mCjWAkBKAAO
# hFTuzuldyF4wEr1GnrXTdrnSDmuZDNIztM2xAgMBAAGjggFdMIIBWTASBgNVHRMB
# Af8ECDAGAQH/AgEAMB0GA1UdDgQWBBS6FtltTYUvcyl2mi91jGogj57IbzAfBgNV
# HSMEGDAWgBTs1+OC0nFdZEzfLmc/57qYrhwPTzAOBgNVHQ8BAf8EBAMCAYYwEwYD
# VR0lBAwwCgYIKwYBBQUHAwgwdwYIKwYBBQUHAQEEazBpMCQGCCsGAQUFBzABhhho
# dHRwOi8vb2NzcC5kaWdpY2VydC5jb20wQQYIKwYBBQUHMAKGNWh0dHA6Ly9jYWNl
# cnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRSb290RzQuY3J0MEMGA1Ud
# HwQ8MDowOKA2oDSGMmh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRy
# dXN0ZWRSb290RzQuY3JsMCAGA1UdIAQZMBcwCAYGZ4EMAQQCMAsGCWCGSAGG/WwH
# ATANBgkqhkiG9w0BAQsFAAOCAgEAfVmOwJO2b5ipRCIBfmbW2CFC4bAYLhBNE88w
# U86/GPvHUF3iSyn7cIoNqilp/GnBzx0H6T5gyNgL5Vxb122H+oQgJTQxZ822EpZv
# xFBMYh0MCIKoFr2pVs8Vc40BIiXOlWk/R3f7cnQU1/+rT4osequFzUNf7WC2qk+R
# Zp4snuCKrOX9jLxkJodskr2dfNBwCnzvqLx1T7pa96kQsl3p/yhUifDVinF2ZdrM
# 8HKjI/rAJ4JErpknG6skHibBt94q6/aesXmZgaNWhqsKRcnfxI2g55j7+6adcq/E
# x8HBanHZxhOACcS2n82HhyS7T6NJuXdmkfFynOlLAlKnN36TU6w7HQhJD5TNOXrd
# /yVjmScsPT9rp/Fmw0HNT7ZAmyEhQNC3EyTN3B14OuSereU0cZLXJmvkOHOrpgFP
# vT87eK1MrfvElXvtCl8zOYdBeHo46Zzh3SP9HSjTx/no8Zhf+yvYfvJGnXUsHics
# JttvFXseGYs2uJPU5vIXmVnKcPA3v5gA3yAWTyf7YGcWoWa63VXAOimGsJigK+2V
# Qbc61RWYMbRiCQ8KvYHZE/6/pNHzV9m8BPqC3jLfBInwAM1dwvnQI38AC+R2AibZ
# 8GV2QqYphwlHK+Z/GqSFD/yYlvZVVCsfgPrA8g4r5db7qS9EFUrnEw4d2zc4GqEr
# 9u3WfPwwgga8MIIEpKADAgECAhALrma8Wrp/lYfG+ekE4zMEMA0GCSqGSIb3DQEB
# CwUAMGMxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkG
# A1UEAxMyRGlnaUNlcnQgVHJ1c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3Rh
# bXBpbmcgQ0EwHhcNMjQwOTI2MDAwMDAwWhcNMzUxMTI1MjM1OTU5WjBCMQswCQYD
# VQQGEwJVUzERMA8GA1UEChMIRGlnaUNlcnQxIDAeBgNVBAMTF0RpZ2lDZXJ0IFRp
# bWVzdGFtcCAyMDI0MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAvmpz
# n/aVIauWMLpbbeZZo7Xo/ZEfGMSIO2qZ46XB/QowIEMSvgjEdEZ3v4vrrTHleW1J
# WGErrjOL0J4L0HqVR1czSzvUQ5xF7z4IQmn7dHY7yijvoQ7ujm0u6yXF2v1CrzZo
# pykD07/9fpAT4BxpT9vJoJqAsP8YuhRvflJ9YeHjes4fduksTHulntq9WelRWY++
# TFPxzZrbILRYynyEy7rS1lHQKFpXvo2GePfsMRhNf1F41nyEg5h7iOXv+vjX0K8R
# hUisfqw3TTLHj1uhS66YX2LZPxS4oaf33rp9HlfqSBePejlYeEdU740GKQM7SaVS
# H3TbBL8R6HwX9QVpGnXPlKdE4fBIn5BBFnV+KwPxRNUNK6lYk2y1WSKour4hJN0S
# MkoaNV8hyyADiX1xuTxKaXN12HgR+8WulU2d6zhzXomJ2PleI9V2yfmfXSPGYanG
# gxzqI+ShoOGLomMd3mJt92nm7Mheng/TBeSA2z4I78JpwGpTRHiT7yHqBiV2ngUI
# yCtd0pZ8zg3S7bk4QC4RrcnKJ3FbjyPAGogmoiZ33c1HG93Vp6lJ415ERcC7bFQM
# RbxqrMVANiav1k425zYyFMyLNyE1QulQSgDpW9rtvVcIH7WvG9sqYup9j8z9J1Xq
# bBZPJ5XLln8mS8wWmdDLnBHXgYly/p1DhoQo5fkCAwEAAaOCAYswggGHMA4GA1Ud
# DwEB/wQEAwIHgDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMI
# MCAGA1UdIAQZMBcwCAYGZ4EMAQQCMAsGCWCGSAGG/WwHATAfBgNVHSMEGDAWgBS6
# FtltTYUvcyl2mi91jGogj57IbzAdBgNVHQ4EFgQUn1csA3cOKBWQZqVjXu5Pkh92
# oFswWgYDVR0fBFMwUTBPoE2gS4ZJaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0Rp
# Z2lDZXJ0VHJ1c3RlZEc0UlNBNDA5NlNIQTI1NlRpbWVTdGFtcGluZ0NBLmNybDCB
# kAYIKwYBBQUHAQEEgYMwgYAwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2lj
# ZXJ0LmNvbTBYBggrBgEFBQcwAoZMaHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29t
# L0RpZ2lDZXJ0VHJ1c3RlZEc0UlNBNDA5NlNIQTI1NlRpbWVTdGFtcGluZ0NBLmNy
# dDANBgkqhkiG9w0BAQsFAAOCAgEAPa0eH3aZW+M4hBJH2UOR9hHbm04IHdEoT8/T
# 3HuBSyZeq3jSi5GXeWP7xCKhVireKCnCs+8GZl2uVYFvQe+pPTScVJeCZSsMo1JC
# oZN2mMew/L4tpqVNbSpWO9QGFwfMEy60HofN6V51sMLMXNTLfhVqs+e8haupWiAr
# SozyAmGH/6oMQAh078qRh6wvJNU6gnh5OruCP1QUAvVSu4kqVOcJVozZR5RRb/zP
# d++PGE3qF1P3xWvYViUJLsxtvge/mzA75oBfFZSbdakHJe2BVDGIGVNVjOp8sNt7
# 0+kEoMF+T6tptMUNlehSR7vM+C13v9+9ZOUKzfRUAYSyyEmYtsnpltD/GWX8eM70
# ls1V6QG/ZOB6b6Yum1HvIiulqJ1Elesj5TMHq8CWT/xrW7twipXTJ5/i5pkU5E16
# RSBAdOp12aw8IQhhA/vEbFkEiF2abhuFixUDobZaA0VhqAsMHOmaT3XThZDNi5U2
# zHKhUs5uHHdG6BoQau75KiNbh0c+hatSF+02kULkftARjsyEpHKsF7u5zKRbt5oK
# 5YGwFvgc4pEVUNytmB3BpIiowOIIuDgP5M9WArHYSAR16gc0dP2XdkMEP5eBsX7b
# f/MGN4K3HP50v/01ZHo/Z5lGLvNwQ7XHBx1yomzLP8lx4Q1zZKDyHcp4VQJLu2kW
# TsKsOqQxggUEMIIFAAIBATAuMBoxGDAWBgNVBAMMD0NvZGVTaWduaW5nQ2VydAIQ
# G+7Pw6aqbrlDNQEy35ls1TANBglghkgBZQMEAgEFAKCBhDAYBgorBgEEAYI3AgEM
# MQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQB
# gjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCA7r6Dy6tGNoYbt
# uYIy85X159U+FZTWk2BiaEwaHcbVyDANBgkqhkiG9w0BAQEFAASCAQBJqlDi5Msf
# 5/WtHA4hmfq6VXcBTEL76Qdo9LMnglS96hVIyl3hmFORDmChldCL7cuKmdHysi27
# r5FHpel8yLeNPepTJDMbuKgcUbdYTFTDsiMQ4ZVTqzObR5mw1ZZHYeSaRS4nQ1Kr
# L6LXkS/e39elKj2Vi+UKA2jEKHTy31uQd1YwTQ+C+ew77ZPjKsP6hLEvGc+qErJR
# tskNZ2so7N3ed0XLzL26+t0V7d0VLEw2Zp6IGwsTL11U93zvH6dqXm039Ua+uVau
# nw5nTGnmIiHBDy6YqukZJTRJD0NgurRUxgozJuNOKgm4/j2Ce3M+kA65XofkNY95
# 31Vu3cz898mRoYIDIDCCAxwGCSqGSIb3DQEJBjGCAw0wggMJAgEBMHcwYzELMAkG
# A1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMTswOQYDVQQDEzJEaWdp
# Q2VydCBUcnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2IFRpbWVTdGFtcGluZyBDQQIQ
# C65mvFq6f5WHxvnpBOMzBDANBglghkgBZQMEAgEFAKBpMBgGCSqGSIb3DQEJAzEL
# BgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTI0MTAyMTE2MTYxOFowLwYJKoZI
# hvcNAQkEMSIEIALKmKzTIOmti0Baaw+YyGaaufoNuDT6W16TfcktjSmXMA0GCSqG
# SIb3DQEBAQUABIICAGnkVoA/JiRzeKCUzxNm0PhQys7efS8iZFqXaPkQZzZ9K8ke
# a7M4rxZoCpbZXJRJ/QoVnrr8p4tXkqrTCig+sQlyP0ZMS6qyoy1w2Liek/E/n6OM
# 7+k5vUde8qykBFBYZDfmsc9/2hndxOmt5NZM/C3rYi+OJ3fLwDy8RYoQWs8jIe6J
# QcjHQnivXCFpSpeojHY78sO0o0T6vFxny+WYlqLwsTWw5Vfmw8VmaceMRqh8Jf3A
# AQeaV8kvhIxGNgmL1IrJNNX+Cjot/SGcK4pOoZRqdbfFjl38v6mLmbY1uNjiycjB
# lNazXRNtZ+Xdk4b0funcis/yuSZX974EE58h3FHCqgcY3eAfdxJTSk1Ke0vdyxNA
# 48KHzPv9zgFQAGwEgLDYF+njTD3xozLD3LoTD1RklWOycZ1z+azLBIbU2beU12o3
# YMxzRuOkNh3FEqSJFVuPxcQf69/Lc6cVDy0pdHfW1/5A5zVf7MJfSZGrnJWAt088
# MCCO/oNJDFPtebWXGEFqM3yoq+b/9CX2+5ZQzmOE/BunFfjpDrO/neVLzrnUuVaD
# hyzIP4ayhlz07s6zJWD4XMJpgObXcLSQgGRWviOnZu9TodBG0G9pXXZfkaTOJ2Jq
# Fe19U2cN9qJtnIERmtZv/v+AXHkb3Q1+BS5C5Hv9W06SwY+H5ptoCtL/bC3k
# SIG # End signature block
