<#
Decrypting a File
Use the Same Key and IV: Ensure you use the same key and IV used for encryption.
Decrypt the File: Use the key and IV to decrypt the file.
#>
[CmdletBinding(DefaultParameterSetName='KeyContainer')]
Param(
    # Path to encrypted data
    [string]$ScriptPath,

    # Thumbprint for certificate with private key
    [Parameter(Mandatory=$true, ParameterSetName='CertificateStore')]
    [string]$CertificateThumbprint,

    # Key container name with private key
    [Parameter(Mandatory=$true, ParameterSetName='KeyContainer')]
    [string]$KeyContainerName
)
function Get-CspKeyContainer {
    param(
        [string]$KeyContainerName
    )

    $keyContainerExists = $false

    # check user crypto keys for a container with the specified name
    $certUtil = certutil -user -key $KeyContainerName

    if (-not ($certUtil -match 'NTE_BAD_KEYSET')) { # the key exists
        $keyContainerExists = $true 
        [int]$keyNameIndex = $certUtil.Trim().IndexOf($KeyContainerName)
        $uniqueKeyId = $certUtil[$keyNameIndex + 1].Trim()
    }

    return @{
        Exists = $keyContainerExists
        UniqueKeyID = $uniqueKeyId
    }
}
function DecryptFile {
    <#
        .DESCRIPTION
        The Decrypt method does the following:

        1. Creates an Aes symmetric algorithm to decrypt the content.
        2. Reads the first eight bytes of the FileStream of the encrypted package into byte arrays to obtain the lengths of the encrypted key and the IV.
        3. Extracts the key and IV from the encryption package into byte arrays.
        4. Creates an RSACryptoServiceProvider object to decrypt the Aes key.
        5. Uses a CryptoStream object to read and decrypt the cipher text section of the FileStream encryption package, in blocks of bytes, into the FileStream object for the decrypted file. When this is finished, the decryption is completed.
    #>

    [CmdletBinding()]
    param(
        [System.IO.FileInfo]$File,
        [X509Certificate]$Cert
    )

    # Create instance of Aes for symmetric decryption of the data.
    $aes = [System.Security.Cryptography.Aes]::Create()

    # Create byte arrays to get the length of the encrypted key and IV.
    # These values were stored as 4 bytes each at the beginning of the encrypted package.
    [byte[]] $lenK = New-Object byte[] 4
    [byte[]] $lenIV = New-Object byte[] 4

    # Construct the file name for the decrypted file.
    $guid = New-Guid
    $script:outFile = [System.IO.Path]::Combine("$env:TEMP\$guid.ps1")

    # Use FileStream objects to read the encrypted file (inFs) and save the decrypted file (outFs).
    $inFs = [System.IO.FileStream]::new($File.FullName, [System.IO.FileMode]::Open)

    $inFs.Seek(0, [System.IO.SeekOrigin]::Begin)
    $inFs.Read($lenK, 0, 3)
    $inFs.Seek(4, [System.IO.SeekOrigin]::Begin)
    $inFs.Read($lenIV, 0, 3)

    # Convert the lengths to integer values.
    [int]$_lenK = [System.BitConverter]::ToInt32($lenK, 0)
    [int]$_lenIV = [System.BitConverter]::ToInt32($lenIV, 0)

    # Determine the start position of the cipher text (startC) and its length(lenC).
    [int]$startC = $_lenK + $_lenIV + 8
    $lenC = [int]$inFs.Length - $startC

    # Create the byte arrays for the encrypted Aes key, the IV, and the cipher text.
    [byte[]] $keyEncrypted = New-Object byte[] $_lenK
    [byte[]] $iv = New-Object byte[] $_lenIV

    # Extract the key and IV starting from index 8 after the length values.
    $inFs.Seek(8, [System.IO.SeekOrigin]::Begin)
    $inFs.Read($keyEncrypted, 0, $_lenK)
    $inFs.Seek(8 + $_lenK, [System.IO.SeekOrigin]::Begin)
    $inFs.Read($iv, 0, $_lenIV)

    [System.IO.Directory]::CreateDirectory($decrFolder)

    # Use RSACryptoServiceProvider to decrypt the AES key.
    if ($Cert) {
        [System.Security.Cryptography.RSA]$_rsa = $Cert.PrivateKey
        $_padding = [System.Security.Cryptography.RSAEncryptionPadding]::OaepSHA256 
        [byte[]]$keyDecrypted = $_rsa.Decrypt($keyEncrypted, $_padding)
    }
    else {
            $_cspp = [System.Security.Cryptography.CspParameters]::new()
            $_cspp.KeyContainerName = $KeyContainerName
            $_rsa = [System.Security.Cryptography.RSACryptoServiceProvider]::new($_cspp)
            $_rsa.PersistKeyInCsp = $true
            
            [byte[]]$keyDecrypted = $_rsa.Decrypt($keyEncrypted, $false)
    }

    # Decrypt the key.
    $transform = $aes.CreateDecryptor($keyDecrypted, $iv);

    # Decrypt the cipher text from from the FileSteam of the encrypted file (inFs) into the FileStream 
    # for the decrypted file (outFs).
    $outFs = [System.IO.FileStream]::new($script:outFile, [System.IO.FileMode]::Create)

    $count = 0
    $offset = 0

    # blockSizeBytes can be any arbitrary size.
    $blockSizeBytes = $aes.BlockSize / 8
    [byte[]]$data = New-Object byte[] $blockSizeBytes

    # By decrypting a chunk a time, you can save memory and accommodate large files.

    # Start at the beginning of the cipher text.
    $inFs.Seek($startC, [System.IO.SeekOrigin]::Begin);
    $outStreamDecrypted = [System.Security.Cryptography.CryptoStream]::new($outFs, $transform, [System.Security.Cryptography.CryptoStreamMode]::Write)
    
    Write-Host "Begin writing cleartext to $outFile..." -NoNewline

    do {
        $count = $inFs.Read($data, 0, $blockSizeBytes)
        $offset += $count
        $outStreamDecrypted.Write($data, 0, $count)
    } while ($count -gt 0)

    $outStreamDecrypted.FlushFinalBlock()

    Write-Host "Done"

    # clean up
    $inFs.Close()
    $outStreamDecrypted.Close()
    $outFs.Close()
}

$fileInfo = [System.IO.FileInfo]$ScriptPath
$params = @{ File = $fileInfo }

if ($KeyContainerName) { # check for the existence of the key container 
    $keyContainer = Get-CspKeyContainer -KeyContainerName $KeyContainerName
    if (!$keyContainer.Exists) { throw "$KeyContainerName does not exist" }

    DecryptFile -File $fileInfo -KeyContainerName $KeyContainerName
}
elseif ($CertificateThumbprint) {
    $cert = Get-ChildItem Cert:\ -Recurse | 
            Where-Object {$_.HasPrivateKey -and $_.Thumbprint -eq $CertificateThumbprint} | 
            Select-Object -First 1

    DecryptFile -File $fileInfo -Cert $cert
}
else {
    throw "Unable to resolve supplied parameters"
}

# if ($LASTEXITCODE -ne 0) {
#     throw "Unable to decrypt data"
# }

try {
    $proc = Start-Process pwsh.exe -ArgumentList "-NoProfile -NonInteractive -File `"$script:outFile`"" -Wait -PassThru -NoNewWindow -ErrorAction Stop
}
catch {
    Write-Host "An error ocurred."
    Write-Host $error[0].Exception.Message
}
finally {
    # remove the temporary file
    Remove-Item $script:outFile
}

return @{
    ExitCode = $proc.ExitCode
    Exception = $error[0].Exception.Message
}
# SIG # Begin signature block
# MIIb+QYJKoZIhvcNAQcCoIIb6jCCG+YCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCNVUlJVrQjd4ne
# ZQMTjZJcuiyjsYEczPp/STl50YT+cqCCFkIwggM7MIICI6ADAgECAhA2a84lByWj
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
# CQQxIgQgJYCyWoN78lbghqVy6Ny5LcriMCaN9CKSgtyuQLlV8DcwDQYJKoZIhvcN
# AQEBBQAEggEAwzS8bP9eZ/iUfMO5Y2/d28Gdl3jd5I883eTze12aWIDc+E+nXxVj
# oOqaGOlHIqpjngENGa2PvtHIS7DcLAbpn5jISA6sJHRuS5Re6I/xM8DBKfdorVup
# Q0xiVyAmZFKmGkeZTWJ0uS0fld20pM8tIJr3wd7lL+v7hK9H/wmAYniGHikhtxSJ
# lLBssvouMyGYdllg53uJSAShylfM5Z8LZs/mvz6JAxDaRKUzoq+O9z4vlsnsskub
# qoGWF/Lr0xt9nh+Vh69ULFYuAkGapa8HSI/R3Ja9HN0qcX8zecuY9cera7F82hJS
# tIf5dqQFlaCROSOTxZ8G69NzhGjpLBiID6GCAyAwggMcBgkqhkiG9w0BCQYxggMN
# MIIDCQIBATB3MGMxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5j
# LjE7MDkGA1UEAxMyRGlnaUNlcnQgVHJ1c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBU
# aW1lU3RhbXBpbmcgQ0ECEAuuZrxaun+Vh8b56QTjMwQwDQYJYIZIAWUDBAIBBQCg
# aTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNTAx
# MjYxNDEyMjdaMC8GCSqGSIb3DQEJBDEiBCC/46rNAa7FuPtPJlGRUCVNrF40VZhP
# ziioS8eyb+EPmjANBgkqhkiG9w0BAQEFAASCAgBPb+6z/3RmZ5GjHGpvtV37a/Qx
# uBrE7r5xPWdPLbSJFlnSnl/eecdu8xqQGsX/k4vzxh4CytNVw6W7iYDAhN02PV6k
# ZOjsegYNDiiPVrif6ZaYO8R5psSKVg2CUTrzqQs2ViFWXuo/vU43+LWkmtNPOVY0
# bVyMWBuZD69awt1OIPrjfzcsbVtGM24SG7SKuFsbbI/MKD0mZCI+Spdzy5Ezrctc
# R/jjWG0o3W9WqyWKnqVvPoa4V98FYjWgRb7k6xusn1QYg2i+HeLnKXrhGOEN/7Gp
# aLM4Bj+2yA6FW6NICmtyxkxLR7qeYxOhemgvXnpV1GzBvefahZYKXIOcxsbIh85U
# qqcfbVLCroNbcskZhQbdJI0FbmSzSUM1QilIXyeTanQ/1n7uh5FxtHie+IIaYGD4
# p9cxvv8Psy3l8UZj1TDtIL82ucBXNDUZapCckyFkA5s6Tls8fpLO03nzKXcY9Fgf
# Y5IWf2PORbxtRW7+wXGKTojjY9dWUI4jABcsU9AfbW97BwC9KNV9Yg6RgWPBDRjp
# J2K4cxeck7wCLPbY6ovBw+vKhDMvVbt7xzGZ3F1ldaPvpqDeaINFtfiGKbb+FTI5
# gf/JDZyxmJyUaQkv8/h+kPmSNT99IuTyv71+Agjc4b9ETm7PiOPe2RIVarmvGKx1
# rtmEjLNQxGFwyT8SnA==
# SIG # End signature block
