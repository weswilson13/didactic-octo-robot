function EncryptFile {
    <#
        .DESCRIPTION
        The EncryptFile method does the following:

        1. Creates a Aes symmetric algorithm to encrypt the content.
        2. Creates an RSACryptoServiceProvider object to encrypt the Aes key.
        3. Uses a CryptoStream object to read and encrypt the FileStream of the source file, in blocks of bytes, into a destination FileStream object for the encrypted file.
        4. Determines the lengths of the encrypted key and IV, and creates byte arrays of their length values.
        5. Writes the Key, IV, and their length values to the encrypted package.

        The encryption package uses the following format:

            - Key length, bytes 0 - 3
            - IV length, bytes 4 - 7
            - Encrypted key
            - IV
            - Cipher text
            
        You can use the lengths of the key and IV to determine the starting points and lengths of all parts of the encryption package, which can then be used to decrypt the file.
    #>
    [CmdletBinding()]
    param(
        [System.IO.FileInfo]$File,
        [X509Certificate]$Cert
    )

    # Create instance of Aes for symmetric encryption of the data.
    $aes = [System.Security.Cryptography.Aes]::Create()
    $transform = $aes.CreateEncryptor()

    # Use RSACryptoServiceProvider to encrypt the AES key.
    [System.Security.Cryptography.RSA]$_rsa = $Cert.PublicKey.GetRSAPublicKey()
    $_padding = [System.Security.Cryptography.RSAEncryptionPadding]::Pkcs1
    [byte[]]$keyEncrypted = $_rsa.Encrypt([byte[]]$aes.Key, $_padding)

    # Create byte arrays to contain the length values of the key and IV.
    $lKey = $keyEncrypted.Length
    [byte[]] $lenK = [System.BitConverter]::GetBytes($lKey)
    $lIV = $aes.IV.Length
    [byte[]]$lenIV = [System.BitConverter]::GetBytes($lIV)

    # Write the following to the FileStream
    # for the encrypted file (outFs):
    # - length of the key
    # - length of the IV
    # - encrypted key
    # - the IV
    # - the encrypted cipher content

    # Change the file's extension to ".enc"
    $outFile = [System.IO.Path]::Combine($encrFolder, [System.IO.Path]::ChangeExtension($File.Name, ".enc"))
    $outFs = [System.IO.FileStream]::new($outFile, [System.IO.FileMode]::Create)
    
    $outFs.Write($lenK, 0, 4)
    $outFs.Write($lenIV, 0, 4)
    $outFs.Write($keyEncrypted, 0, $lKey)
    $outFs.Write($aes.IV, 0, $lIV)

    # Now write the cipher text using a CryptoStream for encrypting.
    $outStreamEncrypted = [System.Security.Cryptography.CryptoStream]::new($outFs, $transform, [System.Security.Cryptography.CryptoStreamMode]::Write)
    
    # By encrypting a chunk at a time, you can save memory and accommodate large files.
    $count = 0
    $offset = 0

    # blockSizeBytes can be any arbitrary size.
    $blockSizeBytes = $aes.BlockSize / 8
    [byte[]]$data = New-Object byte[] $blockSizeBytes
    $bytesRead = 0

    $inFs = [System.IO.FileStream]::new($file.FullName, [System.IO.FileMode]::Open)
    
    do {
        $count = $inFs.Read($data, 0, $blockSizeBytes)
        $offset += $count
        $outStreamEncrypted.Write($data, 0, $count)
        $bytesRead += $blockSizeBytes
    } while ($count -gt 0)

    $outStreamEncrypted.FlushFinalBlock()

    # clean up
    $inFs.Close()
    $outStreamEncrypted.Close()
    $outFs.Close()
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
    $outFile = [System.IO.Path]::ChangeExtension($File.FullName.Replace("Encrypt", "Decrypt"), ".txt")

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
    [System.Security.Cryptography.RSA]$_rsa = $Cert.PrivateKey
    $_padding = [System.Security.Cryptography.RSAEncryptionPadding]::Pkcs1   
    [byte[]]$keyDecrypted = $_rsa.Decrypt($keyEncrypted, $_padding)

    # Decrypt the key.
    $transform = $aes.CreateDecryptor($keyDecrypted, $iv);

    # Decrypt the cipher text from from the FileSteam of the encrypted file (inFs) into the FileStream 
    # for the decrypted file (outFs).
    $outFs = [System.IO.FileStream]::new($outFile, [System.IO.FileMode]::Create)

    $count = 0
    $offset = 0

    # blockSizeBytes can be any arbitrary size.
    $blockSizeBytes = $aes.BlockSize / 8
    [byte[]]$data = New-Object byte[] $blockSizeBytes

    # By decrypting a chunk a time, you can save memory and accommodate large files.

    # Start at the beginning of the cipher text.
    $inFs.Seek($startC, [System.IO.SeekOrigin]::Begin);
    $outStreamDecrypted = [System.Security.Cryptography.CryptoStream]::new($outFs, $transform, [System.Security.Cryptography.CryptoStreamMode]::Write)
    do {
        $count = $inFs.Read($data, 0, $blockSizeBytes)
        $offset += $count
        $outStreamDecrypted.Write($data, 0, $count)
    } while ($count -gt 0)

    $outStreamDecrypted.FlushFinalBlock()

    # clean up
    $inFs.Close()
    $outStreamDecrypted.Close()
    $outFs.Close()
}

# $cert = Get-ChildItem Cert:\CurrentUser\My | ? {$_.FriendlyName -eq 'Scripting'}
# EncryptFile -File Z:\Scripts\ScheduledTasks\Get-Updates.ps1 -Cert $cert

# DecryptFile -File C:\Tools\Encrypt\Get-Updates.enc -Cert $cert