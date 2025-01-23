<#
Encrypting a File
Generate a Key and IV: These are necessary for encryption and decryption.
Encrypt the File: Use the key and IV to encrypt the file.
#>
[CmdletBinding()]
Param(
    [System.IO.FileInfo]$ScriptPath,
    [System.IO.FileInfo]$SecureKeyPath
)

# Import the Key and Initialization Vector
$cipherParams = Import-Clixml $SecureKeyPath
$key = $cipherParams.Key    
$iv = $cipherParams.IV

# Define paths
$inputFilePath = $ScriptPath
$encryptedFilePath = "Z:\scripts\ScheduledTasksEncrypted\$($ScriptPath.BaseName).txt"

# Encrypt the file
$algorithm = [System.Security.Cryptography.Aes]::Create()
$algorithm.Key = $key
$algorithm.IV = $iv

$encryptor = $algorithm.CreateEncryptor($algorithm.Key, $algorithm.IV)
$inputFileStream = [System.IO.File]::OpenRead($inputFilePath)
$outputFileStream = [System.IO.File]::OpenWrite($encryptedFilePath)
$cryptoStream = New-Object System.Security.Cryptography.CryptoStream($outputFileStream, $encryptor, [System.Security.Cryptography.CryptoStreamMode]::Write)

$buffer = New-Object byte[] 1024
while (($read = $inputFileStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
    $cryptoStream.Write($buffer, 0, $read)
}

$cryptoStream.Close()
$inputFileStream.Close()
$outputFileStream.Close()


