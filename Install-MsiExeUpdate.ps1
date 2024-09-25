#Requires -RunAsAdministrator 
#Requires -PSEdition Desktop

[cmdletbinding(DefaultParameterSetName = 'All')]
param(
    [Parameter(Mandatory = $false)]
    [Parameter(ParameterSetName = 'All')]
    [string[]] $ComputerName = $env:COMPUTERNAME
    ,
    [Parameter(Mandatory = $true)]
    [Parameter(ParameterSetName = 'All')]
    [ValidateSet('msodbc', 'msoledb', 'Edge', 'Vmware', 'Npp', 'Defender', 'WinSCP', 'Powershell', 'Dotnet', 'VSCode', 'PuTTY', 'SSMS', 'WindowsTerminal')]
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

$logpath = "$env:TEMP\Install-MsiExeUpdate_Log.log"
$PSDefaultParameterValues["Out-File:FilePath"]=$logPath
$PSDefaultParameterValues["Out-File:Append"]=$true

$softwareRepo = '\\Optimusprime\Z'
$updates = '\\raspberrypi4-1\nas05'

if (Test-Path $logPath) { Remove-item $logPath -Force }

try {
foreach ($computer in $ComputerName) {
    foreach ($T in $Type) {
        if (Test-Connection $ComputerName -Count 1 -Quiet) {

            $filePath = switch -Regex ($T) {
                '^mso' { "$softwareRepo\Microsoft\SQL Server\Providers-Drivers" }
                'Edge' { "$softwareRepo\Microsoft\MicrosoftEdge" }
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
                'VMware' { "/S /v `"/qn /L*v ""c:\tools\VmwareToolsUpdate.log"" REBOOT=R ADDLOCAL=ALL REMOVE=Hgfs,VmwTimeProvider`"" }
                'Npp' { "/S /v `"/qn /L*v c:\tools\NppUpdate.log`"" }
                'Defender' { "/S /v `"/qn /L*v c:\tools\DefinitionsUpdate.log`"" }
                'WinSCP' { "/a c:\tools\update.exe /qn /L*v c:\tools\winScpUpdate.log" }
                'Powershell' { "/i c:\tools\update.msi /qn /L*v c:\tools\psupdate.log ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1 ENABLE_PSREMOTING=1 REGISTER_MANIFEST=1 ADD_PATH=1 ENABLE_MU=1" }
                'PuTTY' { "/i c:\tools\update.msi /qn /L*v c:\tools\puttyUpdate.log" }
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
                    Invoke-Command -ComputerName $Computer -ScriptBlock { Start-Process $args[0] -ArgumentList $args[1] -Verb RunAs -Wait } -ArgumentList $execPath, $command
                }
                else {
                    if ($Log.IsPresent) { Out-File -InputObject "Executing: Start-Process -FilePath $execPath -ArgumentList $command -Verb RunAs -Wait" }
                    Invoke-Command -ScriptBlock { Start-Process -FilePath $args[0] -ArgumentList $args[1] -Wait } -ArgumentList $execPath, $command
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
# MIIbvwYJKoZIhvcNAQcCoIIbsDCCG6wCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBhSe1bCWBOSaiJ
# gz+DGSYYBADDtz3RrxHpfJO/psoCUKCCFhEwggMEMIIB7KADAgECAhAb7s/Dpqpu
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
# 9u3WfPwwggbCMIIEqqADAgECAhAFRK/zlJ0IOaa/2z9f5WEWMA0GCSqGSIb3DQEB
# CwUAMGMxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkG
# A1UEAxMyRGlnaUNlcnQgVHJ1c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3Rh
# bXBpbmcgQ0EwHhcNMjMwNzE0MDAwMDAwWhcNMzQxMDEzMjM1OTU5WjBIMQswCQYD
# VQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xIDAeBgNVBAMTF0RpZ2lD
# ZXJ0IFRpbWVzdGFtcCAyMDIzMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKC
# AgEAo1NFhx2DjlusPlSzI+DPn9fl0uddoQ4J3C9Io5d6OyqcZ9xiFVjBqZMRp82q
# smrdECmKHmJjadNYnDVxvzqX65RQjxwg6seaOy+WZuNp52n+W8PWKyAcwZeUtKVQ
# gfLPywemMGjKg0La/H8JJJSkghraarrYO8pd3hkYhftF6g1hbJ3+cV7EBpo88MUu
# eQ8bZlLjyNY+X9pD04T10Mf2SC1eRXWWdf7dEKEbg8G45lKVtUfXeCk5a+B4WZfj
# RCtK1ZXO7wgX6oJkTf8j48qG7rSkIWRw69XloNpjsy7pBe6q9iT1HbybHLK3X9/w
# 7nZ9MZllR1WdSiQvrCuXvp/k/XtzPjLuUjT71Lvr1KAsNJvj3m5kGQc3AZEPHLVR
# zapMZoOIaGK7vEEbeBlt5NkP4FhB+9ixLOFRr7StFQYU6mIIE9NpHnxkTZ0P387R
# Xoyqq1AVybPKvNfEO2hEo6U7Qv1zfe7dCv95NBB+plwKWEwAPoVpdceDZNZ1zY8S
# dlalJPrXxGshuugfNJgvOuprAbD3+yqG7HtSOKmYCaFxsmxxrz64b5bV4RAT/mFH
# Coz+8LbH1cfebCTwv0KCyqBxPZySkwS0aXAnDU+3tTbRyV8IpHCj7ArxES5k4Msi
# K8rxKBMhSVF+BmbTO77665E42FEHypS34lCh8zrTioPLQHsCAwEAAaOCAYswggGH
# MA4GA1UdDwEB/wQEAwIHgDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsG
# AQUFBwMIMCAGA1UdIAQZMBcwCAYGZ4EMAQQCMAsGCWCGSAGG/WwHATAfBgNVHSME
# GDAWgBS6FtltTYUvcyl2mi91jGogj57IbzAdBgNVHQ4EFgQUpbbvE+fvzdBkodVW
# qWUxo97V40kwWgYDVR0fBFMwUTBPoE2gS4ZJaHR0cDovL2NybDMuZGlnaWNlcnQu
# Y29tL0RpZ2lDZXJ0VHJ1c3RlZEc0UlNBNDA5NlNIQTI1NlRpbWVTdGFtcGluZ0NB
# LmNybDCBkAYIKwYBBQUHAQEEgYMwgYAwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3Nw
# LmRpZ2ljZXJ0LmNvbTBYBggrBgEFBQcwAoZMaHR0cDovL2NhY2VydHMuZGlnaWNl
# cnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZEc0UlNBNDA5NlNIQTI1NlRpbWVTdGFtcGlu
# Z0NBLmNydDANBgkqhkiG9w0BAQsFAAOCAgEAgRrW3qCptZgXvHCNT4o8aJzYJf/L
# LOTN6l0ikuyMIgKpuM+AqNnn48XtJoKKcS8Y3U623mzX4WCcK+3tPUiOuGu6fF29
# wmE3aEl3o+uQqhLXJ4Xzjh6S2sJAOJ9dyKAuJXglnSoFeoQpmLZXeY/bJlYrsPOn
# vTcM2Jh2T1a5UsK2nTipgedtQVyMadG5K8TGe8+c+njikxp2oml101DkRBK+IA2e
# qUTQ+OVJdwhaIcW0z5iVGlS6ubzBaRm6zxbygzc0brBBJt3eWpdPM43UjXd9dUWh
# pVgmagNF3tlQtVCMr1a9TMXhRsUo063nQwBw3syYnhmJA+rUkTfvTVLzyWAhxFZH
# 7doRS4wyw4jmWOK22z75X7BC1o/jF5HRqsBV44a/rCcsQdCaM0qoNtS5cpZ+l3k4
# SF/Kwtw9Mt911jZnWon49qfH5U81PAC9vpwqbHkB3NpE5jreODsHXjlY9HxzMVWg
# gBHLFAx+rrz+pOt5Zapo1iLKO+uagjVXKBbLafIymrLS2Dq4sUaGa7oX/cR3bBVs
# rquvczroSUa31X/MtjjA2Owc9bahuEMs305MfR5ocMB3CtQC4Fxguyj/OOVSWtas
# FyIjTvTs0xf7UGv/B3cfcZdEQcm4RtNsMnxYL2dHZeUbc7aZ+WssBkbvQR7w8F/g
# 29mtkIBEr4AQQYoxggUEMIIFAAIBATAuMBoxGDAWBgNVBAMMD0NvZGVTaWduaW5n
# Q2VydAIQG+7Pw6aqbrlDNQEy35ls1TANBglghkgBZQMEAgEFAKCBhDAYBgorBgEE
# AYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwG
# CisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCBYeFvo
# hhmgJHRhYI2cKGt7HP8nmnBUIG+78VyDv5sCGjANBgkqhkiG9w0BAQEFAASCAQCh
# YDmarBlcluua+v2Yf5EBmvOa2j+2ueFyZ4UDnse2icdgzgCpKr4x6BKHRV2cxSfY
# 60WLpgr+NvMyuUCeVZ6PF4EB1hghM2XYRmkeqo8dclZCMxmDxFVc1W8Y70Awzfl1
# 4kd1F7/Sgb+wuF39OZueTCB4H4KSzVU5YUd/M1ynYzz0D/26bs2ODD3cfs3N4mIj
# zOjQMQrndGbRzSgJbNT3M9AUunJgair/65549x1xrVjZZfXJSDEH6aoXparHBHUb
# /UAfhPqROZ7Oz2Gm18c4OOxLeChWxaHoRWxgzoEc5P4T595KECC4tFbxIGhyKCmP
# tXOpLCtljWb4DGXtLqMLoYIDIDCCAxwGCSqGSIb3DQEJBjGCAw0wggMJAgEBMHcw
# YzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMTswOQYDVQQD
# EzJEaWdpQ2VydCBUcnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2IFRpbWVTdGFtcGlu
# ZyBDQQIQBUSv85SdCDmmv9s/X+VhFjANBglghkgBZQMEAgEFAKBpMBgGCSqGSIb3
# DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTI0MDIwNDE2MTgxN1ow
# LwYJKoZIhvcNAQkEMSIEIETBdArK8gOnFJlH9eoTB6BSada5tWvakSdu4QfkCXqx
# MA0GCSqGSIb3DQEBAQUABIICAJkNSzf1uWQAF+MRRalik+O/rM5h/h5kHmgKCGqP
# Gd4WBGZ83HOr2wfP3Sqz2VrAOyhKHXBSNCnJnJBKR9MVxRMHjZv1jrJhXP5mpzPz
# ExrCQ8euGdO8wPcjDcCyvQR6ubMMeK83MTbRCG6cIHt79+yqfveSDI80qe6mPPdM
# jw4v7BrSnuR/kdnGWERw6deS7bNfwglpBEtmcH+2x8j6w6bJyZ82tC/LZGBdfCqs
# n1AEMnKqnmr6iOQRtLiIf9QIE0CeKJgj+m9FWMbq05jdreGVma6gIXhnVhXiUfBG
# plt3MGfQb2CyPOVxOVcj8bM9vYtINp7gXpLw39QeUAyDa7T8AnLPUWFLggsbjDgE
# DeeiwYdj9LYU5XDAU3+KXtasSB+6PhcaiePkkcHHbhuwssTzfJz1oE+yKaqX15SC
# 6lXyvmYOrSnFZmDnn3lgyaCeu2Xx2ZL+nO3hbpfYF+jUaleqJCV9nKoywS2lGuuZ
# iJac3/iImRpoxhncZpRGkOBRfcC43rCoqByHxiI2iAq+ML8nplVgvWvYiVYKzPZY
# IRDbv6oh4F98MCKX2BOrmHX/XBJ78rcvv9SAdn/ldIFsjbx88O6HMZNToOAAaNph
# jq/xXezPKNFMO2dBmhHwWP6Y5hK4m1rGgGPlk7PjY9C3US12O/x1PPR3KIauL6VV
# TfKU
# SIG # End signature block
