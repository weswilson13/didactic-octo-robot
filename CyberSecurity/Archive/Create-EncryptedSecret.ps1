<#
    .SYNOPSIS
    Creates or Imports an encrypted byte array for use in encryption and decryption operations.

    .DESCRIPTION
    The AES SYMMETRIC algorithm requires the same Key and Initialization Vector (IV) be used for encryption and subsequent
    decryption of data. This script allows creation of new encryption packages (key and IV) that can be saved to the local 
    machine and/or exported for later import onto another device. The encryption package is saved to the local machine 
    utilizing the Windows Data Protection API (DPAPI). This ensures the encryption key can only be retrieved by the current 
    user on the current machine.  

    When the encryption package is exported, it is saved in a file using the AES encryption standard. The user is asked
    for a password that will seed the key for this encryption. This password must be either 8, 12, or 16 characters long
    as it will be converted to an encryption key corresponding to 128, 192, or 256 bits, respectively. THIS PASSWORD MUST 
    BE REMEMBERED AS IT IS REQUIRED TO DECRYPT THE ENCRYPTED KEY.

    Access the encrypted XML content using Import-CliXml, the SecureString containing the encryption package is under the 
    Password element. 
    
    .PARAMETER Create
    Create a new encryption package (key and IV), save to an encrypted XML file

    .PARAMETER Export
    Exports the encryption package to an encrypted file. Use when the encryption package will be installed on additional machines.

    .PARAMETER Import
    Import an encryption package

    .PARAMETER Path
    Path where the encrypted XML should be created

    .EXAMPLE
    Create a new encryption package and encrypted export in the current users profile. Name the files EncryptionKey.

    Create-EncryptedSecret.ps1 -Create -Export -Path $env:USERPROFILE\EncryptionKey.xml 

    .EXAMPLE
    Import an encryption package. Create the encrypted XML containing the key in the current users profile.

    Create-EncryptedSecret.ps1 -Import C:\tools\EncryptedKey -Path $env:USERPROFILE\EncryptionKey.xml
#>

[CmdletBinding()]
param(
    # Create a new secret key
    [Parameter(Mandatory=$false)]
    [switch]$Create,

    # Exports a secret key
    [Parameter(Mandatory=$false)]
    [switch]$Export,

    # Exports a secret key
    [Parameter(Mandatory=$false)]
    [System.IO.FileInfo]$Import,

    # Output path
    [Parameter(Mandatory=$true)]
    [string]$Path
)

if ($create.IsPresent -and $Import) { # cannot create and import a key
    throw
}

if ($Create.IsPresent) { # create a new cryptographic key and IV
    
    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.GenerateIV()
    $aes.GenerateKey()

    $byteArrayString = ($aes.IV + $aes.Key) -join ','
}
elseif ($Import) { # import an encrypted byte string
    $content = Get-Content $Import.FullName -raw
    $exportSecureKey = Read-Host "Enter the password to decrypt the imported key" -AsSecureString
    $encryptedSecureKey = ConvertTo-SecureString -String $content -SecureKey $exportSecureKey
    $byteArrayString = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(`
    [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($encryptedSecureKey))
}

# create an encrypted XML file to store the key. Uses DPAPI. Only retrievable by specific user on specific machine.
$secureString = ConvertTo-SecureString -String $byteArrayString -AsPlainText -Force
[pscredential]::new("EncryptionKeyandIV", $secureString) | Export-Clixml $Path

if ($Export) { # export the byte string to an encrypted file
    $pathInfo = [System.IO.FileInfo]$Path
    $pathFullName = $pathInfo.FullName
    $extension = $pathInfo.Extension
    $exportPath = $pathFullName.Replace($extension,"")
    $exportSecureKey = Read-Host "Enter a password to encrypt the exported key. Passwords must be 8, 12, or 16 characters." -AsSecureString
    ConvertFrom-SecureString -SecureString $secureString -SecureKey $exportSecureKey | Out-File $exportPath
}

return @{IV = $aes.IV; Key = $aes.key; ByteString = $byteArrayString}


# SIG # Begin signature block
# MIIb+QYJKoZIhvcNAQcCoIIb6jCCG+YCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCkWkD/GsdFe3oP
# AA8722V3kyAhIIw4OEcOpcxt/vJJJKCCFkIwggM7MIICI6ADAgECAhA2a84lByWj
# mkYPfn9MTwxLMA0GCSqGSIb3DQEBCwUAMCMxITAfBgNVBAMMGHdlc19hZG1pbkBt
# eWRvbWFpbi5sb2NhbDAeFw0yNDExMjQxNTE4NDFaFw0yNTExMjQxNTM4NDFaMCMx
# ITAfBgNVBAMMGHdlc19hZG1pbkBteWRvbWFpbi5sb2NhbDCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBAM8CN/dDl5ke/jDl/zWjZ86fzh2Cg6+fxF073Snu
# kQCwz9QTNKFOFksmlVL/OD5Aqsyt5PJk3LAgTT0rypEL4DwVoNNcjK+H2JVaSzD0
# S6OQYOfIJTYrGhFbwhvjkNHzyhx6u43F9eVchqtKY+uO30IQjXEi+05HgdU07+nl
# lqcnkmxn6hyVsRqynSz6dMZcDJhtEfNw0Cq4PlbjxAYomS/OjnXjkd0L5WDeJHx1
# wwunZBxRk/tAFRFmJvjejp13OtOYooywruB3OBfrETSl7e91VE6INRTxGMomVb0e
# 6CBqVwkDVa2KWAiNbOevmUSvPM0y2q8jMtaIr7A4+TVPfhUCAwEAAaNrMGkwDgYD
# VR0PAQH/BAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMCMGA1UdEQQcMBqCGHdl
# c19hZG1pbkBteWRvbWFpbi5sb2NhbDAdBgNVHQ4EFgQU66n1ytkczGZ1PZnl6wKm
# 736Ax2kwDQYJKoZIhvcNAQELBQADggEBAC6Qq+qq8XhlcWGDfI1HJx5gMoBjW4UO
# pUkP4u9O4zSnLKe6jYR4gXl1m0c4+0ToQLfYszwUCfm2DBLE5ceYJhsG1AFjLk+6
# HPZ8ZZoF0p+MgYzhVm/irv7gVnt4zOf0ZuFlfdeqcl/4mYdumpfQ0jmWJQlVGFOA
# K/RiAoc3MdJZ1T/4iRTNdB68AWcPftlZKv5FofHVm0gNPsydALkITbTKKfaEUKCq
# 7H9mf7Z+XiQCFnBW6tfx6ijlLn4UMl/2w7xnJgJ0rxxgajfIqSk5uA0vMZAdp6cZ
# Y4nNGMaEhFzyU/t4w/pjpGUoEyD/v0oH63t3y2ReqPKAtvSJQkN7FBgwggWNMIIE
# daADAgECAhAOmxiO+dAt5+/bUOIIQBhaMA0GCSqGSIb3DQEBDAUAMGUxCzAJBgNV
# BAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdp
# Y2VydC5jb20xJDAiBgNVBAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAe
# Fw0yMjA4MDEwMDAwMDBaFw0zMTExMDkyMzU5NTlaMGIxCzAJBgNVBAYTAlVTMRUw
# EwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20x
# ITAfBgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBHNDCCAiIwDQYJKoZIhvcN
# AQEBBQADggIPADCCAgoCggIBAL/mkHNo3rvkXUo8MCIwaTPswqclLskhPfKK2FnC
# 4SmnPVirdprNrnsbhA3EMB/zG6Q4FutWxpdtHauyefLKEdLkX9YFPFIPUh/GnhWl
# fr6fqVcWWVVyr2iTcMKyunWZanMylNEQRBAu34LzB4TmdDttceItDBvuINXJIB1j
# KS3O7F5OyJP4IWGbNOsFxl7sWxq868nPzaw0QF+xembud8hIqGZXV59UWI4MK7dP
# pzDZVu7Ke13jrclPXuU15zHL2pNe3I6PgNq2kZhAkHnDeMe2scS1ahg4AxCN2NQ3
# pC4FfYj1gj4QkXCrVYJBMtfbBHMqbpEBfCFM1LyuGwN1XXhm2ToxRJozQL8I11pJ
# pMLmqaBn3aQnvKFPObURWBf3JFxGj2T3wWmIdph2PVldQnaHiZdpekjw4KISG2aa
# dMreSx7nDmOu5tTvkpI6nj3cAORFJYm2mkQZK37AlLTSYW3rM9nF30sEAMx9HJXD
# j/chsrIRt7t/8tWMcCxBYKqxYxhElRp2Yn72gLD76GSmM9GJB+G9t+ZDpBi4pncB
# 4Q+UDCEdslQpJYls5Q5SUUd0viastkF13nqsX40/ybzTQRESW+UQUOsxxcpyFiIJ
# 33xMdT9j7CFfxCBRa2+xq4aLT8LWRV+dIPyhHsXAj6KxfgommfXkaS+YHS312amy
# HeUbAgMBAAGjggE6MIIBNjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBTs1+OC
# 0nFdZEzfLmc/57qYrhwPTzAfBgNVHSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823I
# DzAOBgNVHQ8BAf8EBAMCAYYweQYIKwYBBQUHAQEEbTBrMCQGCCsGAQUFBzABhhho
# dHRwOi8vb2NzcC5kaWdpY2VydC5jb20wQwYIKwYBBQUHMAKGN2h0dHA6Ly9jYWNl
# cnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcnQwRQYD
# VR0fBD4wPDA6oDigNoY0aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0
# QXNzdXJlZElEUm9vdENBLmNybDARBgNVHSAECjAIMAYGBFUdIAAwDQYJKoZIhvcN
# AQEMBQADggEBAHCgv0NcVec4X6CjdBs9thbX979XB72arKGHLOyFXqkauyL4hxpp
# VCLtpIh3bb0aFPQTSnovLbc47/T/gLn4offyct4kvFIDyE7QKt76LVbP+fT3rDB6
# mouyXtTP0UNEm0Mh65ZyoUi0mcudT6cGAxN3J0TU53/oWajwvy8LpunyNDzs9wPH
# h6jSTEAZNUZqaVSwuKFWjuyk1T3osdz9HNj0d1pcVIxv76FQPfx2CWiEn2/K2yCN
# NWAcAgPLILCsWKAOQGPFmCLBsln1VWvPJ6tsds5vIy30fnFqI2si/xK4VC0nftg6
# 2fC2h5b9W9FcrBjDTZ9ztwGpn1eqXijiuZQwggauMIIElqADAgECAhAHNje3JFR8
# 2Ees/ShmKl5bMA0GCSqGSIb3DQEBCwUAMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNV
# BAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBHNDAeFw0yMjAzMjMwMDAwMDBaFw0z
# NzAzMjIyMzU5NTlaMGMxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwg
# SW5jLjE7MDkGA1UEAxMyRGlnaUNlcnQgVHJ1c3RlZCBHNCBSU0E0MDk2IFNIQTI1
# NiBUaW1lU3RhbXBpbmcgQ0EwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoIC
# AQDGhjUGSbPBPXJJUVXHJQPE8pE3qZdRodbSg9GeTKJtoLDMg/la9hGhRBVCX6SI
# 82j6ffOciQt/nR+eDzMfUBMLJnOWbfhXqAJ9/UO0hNoR8XOxs+4rgISKIhjf69o9
# xBd/qxkrPkLcZ47qUT3w1lbU5ygt69OxtXXnHwZljZQp09nsad/ZkIdGAHvbREGJ
# 3HxqV3rwN3mfXazL6IRktFLydkf3YYMZ3V+0VAshaG43IbtArF+y3kp9zvU5Emfv
# DqVjbOSmxR3NNg1c1eYbqMFkdECnwHLFuk4fsbVYTXn+149zk6wsOeKlSNbwsDET
# qVcplicu9Yemj052FVUmcJgmf6AaRyBD40NjgHt1biclkJg6OBGz9vae5jtb7IHe
# IhTZgirHkr+g3uM+onP65x9abJTyUpURK1h0QCirc0PO30qhHGs4xSnzyqqWc0Jo
# n7ZGs506o9UD4L/wojzKQtwYSH8UNM/STKvvmz3+DrhkKvp1KCRB7UK/BZxmSVJQ
# 9FHzNklNiyDSLFc1eSuo80VgvCONWPfcYd6T/jnA+bIwpUzX6ZhKWD7TA4j+s4/T
# Xkt2ElGTyYwMO1uKIqjBJgj5FBASA31fI7tk42PgpuE+9sJ0sj8eCXbsq11GdeJg
# o1gJASgADoRU7s7pXcheMBK9Rp6103a50g5rmQzSM7TNsQIDAQABo4IBXTCCAVkw
# EgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4EFgQUuhbZbU2FL3MpdpovdYxqII+e
# yG8wHwYDVR0jBBgwFoAU7NfjgtJxXWRM3y5nP+e6mK4cD08wDgYDVR0PAQH/BAQD
# AgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMIMHcGCCsGAQUFBwEBBGswaTAkBggrBgEF
# BQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEEGCCsGAQUFBzAChjVodHRw
# Oi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNy
# dDBDBgNVHR8EPDA6MDigNqA0hjJodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGln
# aUNlcnRUcnVzdGVkUm9vdEc0LmNybDAgBgNVHSAEGTAXMAgGBmeBDAEEAjALBglg
# hkgBhv1sBwEwDQYJKoZIhvcNAQELBQADggIBAH1ZjsCTtm+YqUQiAX5m1tghQuGw
# GC4QTRPPMFPOvxj7x1Bd4ksp+3CKDaopafxpwc8dB+k+YMjYC+VcW9dth/qEICU0
# MWfNthKWb8RQTGIdDAiCqBa9qVbPFXONASIlzpVpP0d3+3J0FNf/q0+KLHqrhc1D
# X+1gtqpPkWaeLJ7giqzl/Yy8ZCaHbJK9nXzQcAp876i8dU+6WvepELJd6f8oVInw
# 1YpxdmXazPByoyP6wCeCRK6ZJxurJB4mwbfeKuv2nrF5mYGjVoarCkXJ38SNoOeY
# +/umnXKvxMfBwWpx2cYTgAnEtp/Nh4cku0+jSbl3ZpHxcpzpSwJSpzd+k1OsOx0I
# SQ+UzTl63f8lY5knLD0/a6fxZsNBzU+2QJshIUDQtxMkzdwdeDrknq3lNHGS1yZr
# 5Dhzq6YBT70/O3itTK37xJV77QpfMzmHQXh6OOmc4d0j/R0o08f56PGYX/sr2H7y
# Rp11LB4nLCbbbxV7HhmLNriT1ObyF5lZynDwN7+YAN8gFk8n+2BnFqFmut1VwDop
# hrCYoCvtlUG3OtUVmDG0YgkPCr2B2RP+v6TR81fZvAT6gt4y3wSJ8ADNXcL50CN/
# AAvkdgIm2fBldkKmKYcJRyvmfxqkhQ/8mJb2VVQrH4D6wPIOK+XW+6kvRBVK5xMO
# Hds3OBqhK/bt1nz8MIIGvDCCBKSgAwIBAgIQC65mvFq6f5WHxvnpBOMzBDANBgkq
# hkiG9w0BAQsFADBjMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIElu
# Yy4xOzA5BgNVBAMTMkRpZ2lDZXJ0IFRydXN0ZWQgRzQgUlNBNDA5NiBTSEEyNTYg
# VGltZVN0YW1waW5nIENBMB4XDTI0MDkyNjAwMDAwMFoXDTM1MTEyNTIzNTk1OVow
# QjELMAkGA1UEBhMCVVMxETAPBgNVBAoTCERpZ2lDZXJ0MSAwHgYDVQQDExdEaWdp
# Q2VydCBUaW1lc3RhbXAgMjAyNDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoC
# ggIBAL5qc5/2lSGrljC6W23mWaO16P2RHxjEiDtqmeOlwf0KMCBDEr4IxHRGd7+L
# 660x5XltSVhhK64zi9CeC9B6lUdXM0s71EOcRe8+CEJp+3R2O8oo76EO7o5tLusl
# xdr9Qq82aKcpA9O//X6QE+AcaU/byaCagLD/GLoUb35SfWHh43rOH3bpLEx7pZ7a
# vVnpUVmPvkxT8c2a2yC0WMp8hMu60tZR0ChaV76Nhnj37DEYTX9ReNZ8hIOYe4jl
# 7/r419CvEYVIrH6sN00yx49boUuumF9i2T8UuKGn9966fR5X6kgXj3o5WHhHVO+N
# BikDO0mlUh902wS/Eeh8F/UFaRp1z5SnROHwSJ+QQRZ1fisD8UTVDSupWJNstVki
# qLq+ISTdEjJKGjVfIcsgA4l9cbk8Smlzddh4EfvFrpVNnes4c16Jidj5XiPVdsn5
# n10jxmGpxoMc6iPkoaDhi6JjHd5ibfdp5uzIXp4P0wXkgNs+CO/CacBqU0R4k+8h
# 6gYldp4FCMgrXdKWfM4N0u25OEAuEa3JyidxW48jwBqIJqImd93NRxvd1aepSeNe
# REXAu2xUDEW8aqzFQDYmr9ZONuc2MhTMizchNULpUEoA6Vva7b1XCB+1rxvbKmLq
# fY/M/SdV6mwWTyeVy5Z/JkvMFpnQy5wR14GJcv6dQ4aEKOX5AgMBAAGjggGLMIIB
# hzAOBgNVHQ8BAf8EBAMCB4AwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggr
# BgEFBQcDCDAgBgNVHSAEGTAXMAgGBmeBDAEEAjALBglghkgBhv1sBwEwHwYDVR0j
# BBgwFoAUuhbZbU2FL3MpdpovdYxqII+eyG8wHQYDVR0OBBYEFJ9XLAN3DigVkGal
# Y17uT5IfdqBbMFoGA1UdHwRTMFEwT6BNoEuGSWh0dHA6Ly9jcmwzLmRpZ2ljZXJ0
# LmNvbS9EaWdpQ2VydFRydXN0ZWRHNFJTQTQwOTZTSEEyNTZUaW1lU3RhbXBpbmdD
# QS5jcmwwgZAGCCsGAQUFBwEBBIGDMIGAMCQGCCsGAQUFBzABhhhodHRwOi8vb2Nz
# cC5kaWdpY2VydC5jb20wWAYIKwYBBQUHMAKGTGh0dHA6Ly9jYWNlcnRzLmRpZ2lj
# ZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNFJTQTQwOTZTSEEyNTZUaW1lU3RhbXBp
# bmdDQS5jcnQwDQYJKoZIhvcNAQELBQADggIBAD2tHh92mVvjOIQSR9lDkfYR25tO
# CB3RKE/P09x7gUsmXqt40ouRl3lj+8QioVYq3igpwrPvBmZdrlWBb0HvqT00nFSX
# gmUrDKNSQqGTdpjHsPy+LaalTW0qVjvUBhcHzBMutB6HzeledbDCzFzUy34VarPn
# vIWrqVogK0qM8gJhh/+qDEAIdO/KkYesLyTVOoJ4eTq7gj9UFAL1UruJKlTnCVaM
# 2UeUUW/8z3fvjxhN6hdT98Vr2FYlCS7Mbb4Hv5swO+aAXxWUm3WpByXtgVQxiBlT
# VYzqfLDbe9PpBKDBfk+rabTFDZXoUke7zPgtd7/fvWTlCs30VAGEsshJmLbJ6ZbQ
# /xll/HjO9JbNVekBv2Tgem+mLptR7yIrpaidRJXrI+UzB6vAlk/8a1u7cIqV0yef
# 4uaZFORNekUgQHTqddmsPCEIYQP7xGxZBIhdmm4bhYsVA6G2WgNFYagLDBzpmk91
# 04WQzYuVNsxyoVLObhx3RugaEGru+SojW4dHPoWrUhftNpFC5H7QEY7MhKRyrBe7
# ucykW7eaCuWBsBb4HOKRFVDcrZgdwaSIqMDiCLg4D+TPVgKx2EgEdeoHNHT9l3ZD
# BD+XgbF+23/zBjeCtxz+dL/9NWR6P2eZRi7zcEO1xwcdcqJsyz/JceENc2Sg8h3K
# eFUCS7tpFk7CrDqkMYIFDTCCBQkCAQEwNzAjMSEwHwYDVQQDDBh3ZXNfYWRtaW5A
# bXlkb21haW4ubG9jYWwCEDZrziUHJaOaRg9+f0xPDEswDQYJYIZIAWUDBAIBBQCg
# gYQwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYB
# BAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0B
# CQQxIgQg075L7EDD/WYStB3I2PPfpcyYH1iILWujoRVtZ6GKb1AwDQYJKoZIhvcN
# AQEBBQAEggEATLmkdkjNWdl0Q7vEJpH2sE072yLIMHwUsDmkUlH+hAgCJ7nkn19v
# DMlhQaXTf8eyHsI7ch7kuQTnKQmKApNob+JZv+QW6c6zJ09k1jqixYwUroNbWuzs
# D3iK4YRmvMdg+3+XL6cqFHOGJOTnAwiHNn1k1SAhk9oquf51cS1s0tEUI0Jxtyxt
# pQ87JXY8DPV+c3PTkRW5T9BPUX25cBHr/TgYCsj/q7hS3aayFcIOxBoTHwaj9Ngz
# 5wRPwMNKvm+o2C8vEX9mUdT6aBd3kNoBz/S+YDh01wlbuclkE6Ah/oYKC0Hqqrke
# v+o/SlVHH9/uIRWYZ4ZYwmuG55a2EUpybKGCAyAwggMcBgkqhkiG9w0BCQYxggMN
# MIIDCQIBATB3MGMxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5j
# LjE7MDkGA1UEAxMyRGlnaUNlcnQgVHJ1c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBU
# aW1lU3RhbXBpbmcgQ0ECEAuuZrxaun+Vh8b56QTjMwQwDQYJYIZIAWUDBAIBBQCg
# aTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNTAx
# MjMxNDM2MDVaMC8GCSqGSIb3DQEJBDEiBCBDGEpmFXAYJGm72gVzOts9cYK3yvJm
# K/RQg6Ljg7Dg+zANBgkqhkiG9w0BAQEFAASCAgBt4OB4FsTY/ajca9S9U4Ft2f9h
# V8sdTGkCxCpqEjwvy63/lKvCSTFaLDnMu5QUOVkCZMsilgFCP8j83oF/Z9u90guF
# mV+htea7eyaIfpSXAUHhF5Tnk7gW1uVBduGDNa6p0CJhXuY9fzNW9JjG4mpDUUhf
# G35MHthnT45uNZb/BORI+a6WU/WpQp6jMDtYTixfpscvelwwK1K67Bk4RU172WAa
# XbxHzx/Xyyw1JECa8N6CjosGlLJAbtQU7BX3SMgg+i8Dsqcvu3ySC5z975PdMKWO
# WWxNGGV9R9LiDqQDbQo0aNoHP3dhiblmRIdnvF4V81Mtp109tOJgk7o4RQ1p0opR
# 0yn5nCTTicjbMwO+z143CARejo2AQLhH9IxaEcYLnZn0aMEOXDtma8BRSyQrTxfG
# 7i06dzILWeUvBgvBpB0wUj3Qq99pAQcYu1x9VWb8V+r08NAVrOwZ0x67iXi0S5h3
# bmAPWbVvS1CzMn8NTMrNCardl5uAcdjF8ilgPUum5EqfW7fau8lQCM7EN43449xr
# ob/DYOodjx9QR3lH3HI8nSIXlKJhqhVPqWwKcU/7PJvi0j51NyGRvencDrIp9+aZ
# xRwzfGG3wRBbCx9P0ciGSC+pAYIPXkSIHigoXrMtNQiG+BEbvZyrFu3IIfAopEUe
# Drxo9xR4dpwmY2393w==
# SIG # End signature block
