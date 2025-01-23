<#
Decrypting a File
Use the Same Key and IV: Ensure you use the same key and IV used for encryption.
Decrypt the File: Use the key and IV to decrypt the file.
#>
[CmdletBinding()]
Param(
    [System.IO.FileInfo]$ScriptPath,
    [System.IO.FileInfo]$SecureKeyPath
)

# Use the same Key and IV
$cipherParams = Import-Clixml $SecureKeyPath
$key = $cipherParams.Key    
$iv = $cipherParams.IV

# Define paths
$encryptedFilePath = "Z:\scripts\ScheduledTasks\Encrypted\$($ScriptPath.BaseName).txt" #Encrypted\$($ScriptPath.BaseName).txt"
$guid = New-Guid
$decryptedFilePath = "$env:TEMP\$guid.ps1"

# Decrypt the file
$algorithm = [System.Security.Cryptography.Aes]::Create()
$algorithm.Key = $key
$algorithm.IV = $iv

$decryptor = $algorithm.CreateDecryptor($algorithm.Key, $algorithm.IV)
$inputFileStream = [System.IO.File]::OpenRead($encryptedFilePath)
$outputFileStream = [System.IO.File]::OpenWrite($decryptedFilePath)
$cryptoStream = New-Object System.Security.Cryptography.CryptoStream($inputFileStream, $decryptor, [System.Security.Cryptography.CryptoStreamMode]::Read)

$buffer = New-Object byte[] 1024
while (($read = $cryptoStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
    $outputFileStream.Write($buffer, 0, $read)
}

# close streams
$cryptoStream.Close()
$inputFileStream.Close()
$outputFileStream.Close()

try {
    $proc = Start-Process powershell.exe -ArgumentList "-NoProfile -NonInteractive -File `"$decryptedFilePath`"" -Wait -PassThru -NoNewWindow -ErrorAction Stop
}
catch {
    Write-Host "An error ocurred."
    Write-Host $error[0].Exception.Message
}
finally {
    # remove the temporary file
    Remove-Item $decryptedFilePath
}

return @{
    ExitCode = $proc.ExitCode
    Exception = $error[0].Exception.Message
}