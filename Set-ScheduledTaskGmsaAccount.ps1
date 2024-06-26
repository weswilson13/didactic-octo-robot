﻿param (
    [Parameter(Mandatory=$true)]
    [string] $gMSAname,
    [Parameter(Mandatory=$true)]
    [string] $Taskname,
    [Parameter(Mandatory=$false)]
    [string] $Action,
    [Parameter(Mandatory=$false)]
    [string] $ActionArgument
)

Function Set-ScheduledTaskGmsaAccount () {

<#

.SYNOPSIS
Change account to Group Managed Service Account for scheduled task

.DESCRIPTION
Change account to Group Managed Service Account for scheduled task

.PARAMETER gMSAname
Name of group managed service account

.PARAMETER TaskName
Name of scheduled task

.EXAMPLE 
Set-ScheduledTaskGmsaAccount -gMSAname 'gmsa-server01' -Taskname 'My scheduled task'

.FUNCTIONALITY
    Change account to Group Managed Service Account for scheduled task

.NOTES
    Author:  Rickard Warfvinge <rickard.warfvinge@gmail.com>
    Purpose: Change scheduled task to use group managed service account instead of regular service account or user account
#>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string] $gMSAname,
        [Parameter(Mandatory=$true)]
        [string] $Taskname,
        [Parameter(Mandatory=$false)]
        [string] $Action,
        [Parameter(Mandatory=$false)]
        [string] $ActionArgument,
        [Parameter(Mandatory=$false)]
        [ValidateSet('Highest','Limited')]
        [string] $RunLevel='Limited'
        
    )

    If (-Not($gMSAname.EndsWith('$'))) {$gMSAname = $gMSAname + '$'} # If no trailing $ character in gMSA name, add $ sign
    Write-Host $gMSAname
    # Test gMSA account and get scheduled task
    Try {
        Test-ADServiceAccount -Identity $gMSAname -ErrorAction Stop
        $Task = Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop
    }

    Catch {Write-Warning $($_.Exception.Message);Break}

    # Change user account to gMSA for scheduled task
    $domain = $env:USERDNSDOMAIN -replace '\..+$'
    $Principal = New-ScheduledTaskPrincipal -UserID "$domain\$gMSAname" -LogonType Password -RunLevel $RunLevel
    Write-Host $Principal

    if ($Action) {
        $params = @{
            Execute=$Action
            Argument=$ActionArgument
        }
        [ciminstance]$Action = New-ScheduledTaskAction @params
        $Action.gettype()
    }

    Try {Set-ScheduledTask -TaskName $Task.TaskName -TaskPath $Task.TaskPath -Principal $Principal -Action $Action -ErrorAction Stop}
    Catch {Write-Warning $($error[0] | Out-String);Break}
}


Set-ScheduledTaskGmsaAccount @PSBoundParameters

# SIG # Begin signature block
# MIIbvwYJKoZIhvcNAQcCoIIbsDCCG6wCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBdUBnGW21Eny8W
# +ai3uFbZzUf8ZSeQSua/B8g4hqMDCKCCFhEwggMEMIIB7KADAgECAhAb7s/Dpqpu
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
# CisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCBE5lzu
# Ai8g+8DDmmjnupsCRT/EzYTQt5bFiSBMrUVy3TANBgkqhkiG9w0BAQEFAASCAQCL
# +3k37OX1uIsKe+HPSkkQhT4V8JcUAf+K4euS/zls0Zzxq5ptOj2RE0HpJgpOQtwm
# A2ny+LGE6VJt0qZrXwdfzd0JS1jiDavgpRs3iuwu3A40xWj556xM7iDi/0+/P4Zg
# FDhMDQBSbCuIVgmoMs8bIk1f0pE+U5GQOsikSv69+YxcZ7ADwG68hAcCUaqFRpWc
# SCLzXz14Bzt38YHxVRyEwTnn9RwR54JN0ao0SL4hFkY0NQYSxuvUUaZXKMaT+4m6
# diQcGZEKWcTNbO1Y3I2Mwis+suLiU/fxTZKCOWfI6h0vHcoDOnpdDrQtEorrCxJp
# f4cQhgTNvGQ6Junse4yCoYIDIDCCAxwGCSqGSIb3DQEJBjGCAw0wggMJAgEBMHcw
# YzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMTswOQYDVQQD
# EzJEaWdpQ2VydCBUcnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2IFRpbWVTdGFtcGlu
# ZyBDQQIQBUSv85SdCDmmv9s/X+VhFjANBglghkgBZQMEAgEFAKBpMBgGCSqGSIb3
# DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTI0MDUxMjEyMTM1NVow
# LwYJKoZIhvcNAQkEMSIEIOG0JNI0iJOsYUa/gcP/7NSk4ceLzNej6trEWYsvPo5b
# MA0GCSqGSIb3DQEBAQUABIICAJl2QjKwyHwswgF+GEwQBcwYybdITayMKUO98jCc
# ZarGpJSp+EFmenCQz2HBC4HOej1zgPdbiwj4xa/pXutpuYUBzQd9hUQK0EwgNHzp
# RK9/8nao1nMSs52Yf21JeLlbfb8xoD4W34d2pElTmDVvgH0gSN7/LdRmL+jUasvQ
# +y53+OIzBfk2E7JrCF2cKL3uCoaAr2x6mojXjI2uDsqBOmsL5698OjP/N/EytLKO
# YIoZ1Tepv5Y9MIe7hyylYeFf42ZSbMh5Fepkx/r4Dvkp6SlKHlIny19mq3hFW30c
# TFWuX5e4qR3NGLUPAfofZIk5BlXR8LoANOZNzyOSoeCW3d4PUh++a81JA//09A+/
# rM8SQh6klJdCdINfC/M/RoJ4ENmCazaWiAkAvPtJc9ybIJFheq473ph/gJ5xpTg/
# Pj7jZgz7qts4VMk5N6ReaoBhZdC04Elh4lgNSh8JwmesLeFzPfVk+4zX56i0nXqB
# a8aqV/lltZpTHmvhtDRXw7zDVtj58K2JYepP1JmMswXTUv0gk6yZGkF+xgKdsp6Z
# mIB+Gd+nkcRzWlkely/mtJ12WUDZwSL4pkvWF3kMHsYP9sizvJHtKqFoJQNndu5Q
# 01wHAds7CMKq6jh0mh00xeQGTWg0A8ouE6IE6yNN00Hw2H9jYMUn+++fPJwjqy3o
# 7N+K
# SIG # End signature block
