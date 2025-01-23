# Script Methods
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
        [System.IO.FileInfo]$File
    )

    # Create instance of Aes for symmetric encryption of the data.
    $aes = [System.Security.Cryptography.Aes]::Create()
    $transform = $aes.CreateEncryptor()

    # Use RSACryptoServiceProvider to encrypt the AES key.
    # rsa is previously instantiated:
    #    $rsa = [RSACryptoServiceProvider]::new(cspp)
    [byte[]]$keyEncrypted = $_rsa.Encrypt($aes.Key, $false)

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
        [System.IO.FileInfo]$File
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
    $lenK = [System.BitConverter]::ToInt32($lenK, 0)
    $lenIV = [System.BitConverter]::ToInt32($lenIV, 0)

    # Determine the start position of the cipher text (startC) and its length(lenC).
    $startC = $lenK + $lenIV + 8;
    $lenC = [int]$inFs.Length - $startC

    # Create the byte arrays for the encrypted Aes key, the IV, and the cipher text.
    [byte[]] $keyEncrypted = New-Object byte[] $lenK
    [byte[]] $iv = New-Object byte[] $lenIV

    # Extract the key and IV starting from index 8 after the length values.
    $inFs.Seek(8, [System.IO.SeekOrigin]::Begin)
    $inFs.Read($keyEncrypted, 0, $lenK)
    $inFs.Seek(8 + $lenK, [System.IO.SeekOrigin]::Begin)
    $inFs.Read($iv, 0, $lenIV)

    [System.IO.Directory]::CreateDirectory($decrFolder)

    # Use RSACryptoServiceProvider to decrypt the AES key.
    [byte[]]$keyDecrypted = $_rsa.Decrypt($keyEncrypted, $false)

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

# Event Handlers
function buttonCreateAsmKeys_Click([psobject]$sender, [System.EventArgs]$e) {
    <#
        .SYNOPSIS
        Click event handler for the Create Keys button (buttonCreateAsmKeys_Click)
    #>

    # Stores a key pair in the key container.
    $_cspp.KeyContainerName = $keyName;
    $_rsa = [System.Security.Cryptography.RSACryptoServiceProvider]::new($_cspp)
    $_rsa.PersistKeyInCsp = $true

    if ($_rsa.PublicOnly) {
        $label1.Text = "Key: $($_cspp.KeyContainerName) - Public Only"
    }
    else {
        $label1.Text = "Key: $($_cspp.KeyContainerName) - Full Key Pair"
    }
}
function buttonEncryptFile_Click([psobject]$sender, [System.EventArgs]$e) {
    <#
        .SYNOPSIS
        Click event handler for the Encrypt File button (buttonEncryptFile_Click)
    #>
    if ($_rsa -eq $null) {
        [System.Windows.Forms.MessageBox]::Show("Key not set.")
    } 
    else {
        # Display a dialog box to select a file to encrypt.
        $_encryptOpenFileDialog = [System.Windows.Forms.OpenFileDialog]::new()
        $_encryptOpenFileDialog.InitialDirectory = $srcFolder
        if ($_encryptOpenFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK)
        {
            $fName = $_encryptOpenFileDialog.FileName
            if (![string]::IsNullOrWhiteSpace($fName)) { # Pass the file name without the path.
                $fileInfo = [System.IO.FileInfo]$fName
                EncryptFile($fileInfo)
            }
        }
    }
}
function buttonDecryptFile_Click([psobject]$sender, [System.EventArgs]$e) {
    <#
        .SYNOPSIS
        Click event handler for the Decrypt File button
    #>
    if ($_rsa -eq $null) {
        [System.Windows.Forms.MessageBox]::Show("Key not set.")
    }
    else {
        # Display a dialog box to select the encrypted file.
        $_decryptOpenFileDialog = [System.Windows.Forms.OpenFileDialog]::new()
        $_decryptOpenFileDialog.InitialDirectory = $encrFolder
        if ($_decryptOpenFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $fName = $_decryptOpenFileDialog.FileName
            if (![string]::IsNullOrWhiteSpace($fName)) {
                $fileInfo = [System.IO.FileInfo]$fName
                DecryptFile($fileInfo)
            }
        }
    }
}
function buttonExportPublicKey_Click([psobject]$sender, [System.EventArgs]$e) {
    <#
        .SYNOPSIS
        Click event handler for the Export Public Key button (buttonExportPublicKey_Click)
    #>

    # Save the public key created by the RSA to a file. Caution, persisting the key to a file is a security risk.
    [System.IO.Directory]::CreateDirectory($encrFolder)
    $sw = [System.IO.StreamWriter]::new($pubKeyFile, $false)
    $sw.Write($_rsa.ToXmlString($false))

    # clean up
    $sw.Close()
}
function buttonImportPublicKey_Click([psobject]$sender, [System.EventArgs]$e) {
    $sr = [System.IO.StreamReader]::new($pubKeyFile)
    $_cspp.KeyContainerName = $keyName
    $_rsa = [System.Security.Cryptography.RSACryptoServiceProvider]::new($_cspp)

    $keytxt = $sr.ReadToEnd()
    $_rsa.FromXmlString($keytxt)
    $_rsa.PersistKeyInCsp = $true

    if ($_rsa.PublicOnly) {
        $label1.Text = "Key: $($_cspp.KeyContainerName) - Public Only"
    }
    else { 
        "Key: $($_cspp.KeyContainerName) - Full Key Pair" 
    }
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Configuration

# Set this to the full path of your App.config
$configPath = "$PSScriptRoot\App.config"

[System.AppDomain]::CurrentDomain.SetData("APP_CONFIG_FILE", $configPath)
[Configuration.ConfigurationManager].GetField("s_initState", "NonPublic, Static").SetValue($null, 0)
[Configuration.ConfigurationManager].GetField("s_configSystem", "NonPublic, Static").SetValue($null, $null)
([Configuration.ConfigurationManager].Assembly.GetTypes() | 
    Where-Object {$_.FullName -eq "System.Configuration.ClientConfigPaths"})[0].GetField("s_current", "NonPublic, Static").SetValue($null, $null)

$AppSettings=[System.Configuration.ConfigurationManager]::AppSettings


#region    DECLARE GLOBAL OBJECTS

    # Path variables for source, encryption, and decryption folders.
    $srcFolder = $AppSettings["SourceFolder"]
    $encrFolder = $AppSettings["EncryptFolder"]
    $decrFolder = $AppSettings["DecryptFolder"]

    # Declare CspParameters and RsaCryptoServiceProvider objects with global scope of your Form class.
    $_cspp = [System.Security.Cryptography.CspParameters]::new()
    [System.Security.Cryptography.RSACryptoServiceProvider]$_rsa = $null

    # Public key file
    $pubKeyFile = "$encrFolder\rsaPublicKey.txt";

    # Key container name for private/public key value pair.
    $keyName = "Key01";

#endregion DECLARE GLOBAL OBJECTS

<#
### controls
#>

#region buttonEncryptFile
    $buttonEncryptFile = New-Object System.Windows.Forms.Button
    $buttonEncryptFile.Name = "buttonEncryptFile"
    $buttonEncryptFile.Text = "Encrypt File"
    $buttonEncryptFile.AutoSize = $true
    # $buttonEncryptFile.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom
    # $buttonEncryptFile.Dock = 'Bottom'
    $buttonEncryptFile.Add_Click({buttonEncryptFile_Click})
#endregion buttonEncryptFile

#region buttonDecryptFile
    $buttonEncryptFile = New-Object System.Windows.Forms.Button
    $buttonEncryptFile.Name = "buttonDecryptFile"
    $buttonEncryptFile.Text = "Decrypt File"
    $buttonEncryptFile.AutoSize = $true
    # $buttonEncryptFile.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom
    # $buttonEncryptFile.Dock = 'Bottom'
    $buttonEncryptFile.Add_Click({buttonDecryptFile_Click})
#endregion buttonDecryptFile

#region buttonCreateAsmKeys
    $buttonCreateAsmKeys = New-Object System.Windows.Forms.Button
    $buttonCreateAsmKeys.Name = "buttonCreateAsmKeys"
    $buttonCreateAsmKeys.Text = "Create Keys"
    $buttonCreateAsmKeys.AutoSize = $true
    # $buttonCreateAsmKeys.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom
    # $buttonCreateAsmKeys.Dock = 'Bottom'
    $buttonCreateAsmKeys.Add_Click({buttonCreateAsmKeys_Click})
#endregion buttonCreateAsmKeys

#region buttonExportPublicKey
    $buttonExportPublicKey = New-Object System.Windows.Forms.Button
    $buttonExportPublicKey.Name = "buttonExportPublicKey"
    $buttonExportPublicKey.Text = "Export Public Key"
    $buttonExportPublicKey.AutoSize = $true
    # $buttonExportPublicKey.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom
    # $buttonExportPublicKey.Dock = 'Bottom'
    $buttonExportPublicKey.Add_Click({buttonExportPublicKey_Click})
#endregion buttonExportPublicKey

#region buttonImportPublicKey
    $buttonImportPublicKey = New-Object System.Windows.Forms.Button
    $buttonImportPublicKey.Name = "buttonImportPublicKey"
    $buttonImportPublicKey.Text = "Import Public Key"
    $buttonImportPublicKey.AutoSize = $true
    # $buttonImportPublicKey.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom
    # $buttonImportPublicKey.Dock = 'Bottom'
    $buttonImportPublicKey.Add_Click({buttonImportPublicKey_Click})
#endregion buttonImportPublicKey

#region buttonGetPrivateKey
    $buttonGetPrivateKey = New-Object System.Windows.Forms.Button
    $buttonGetPrivateKey.Name = "buttonGetPrivateKey"
    $buttonGetPrivateKey.Text = "Get Private Key"
    $buttonGetPrivateKey.AutoSize = $true
    # $buttonGetPrivateKey.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom
    # $buttonGetPrivateKey.Dock = 'Bottom'
    $buttonGetPrivateKey.Add_Click({buttonGetPrivateKey_Click})
#endregion buttonGetPrivateKey

#region label1
    $label = New-Object System.Windows.Forms.Label
    # $label.Dock = "Fill"
    $label.Text = "Key Not Set"
    $label.Font = New-Object System.Drawing.Font("Calibri",12,[Drawing.FontStyle]::Bold)
    $label.AutoSize = $true
#endregion label1


$defaultText = "Enter one or more DoD IDs separated by commas..."
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Text = $defaultText
$textbox.Multiline = $true
$textbox.Dock = "Fill"
$textBox.Add_Click({
    if ($this.Text -eq $defaultText) {
        $this.ResetText()
    }
})



$tableLayoutPanel = New-Object System.Windows.Forms.TableLayoutPanel
$tableLayoutPanel.RowCount = 3
$tableLayoutPanel.ColumnCount = 1
$tableLayoutPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 5))) | Out-Null
$tableLayoutPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 85))) | Out-Null
$tableLayoutPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 10))) | Out-Null
$tableLayoutPanel.Dock = "Fill"
# $tableLayoutPanel.CellBorderStyle = "outset"
$tableLayoutPanel.Controls.Add($label,0,0)
$tableLayoutPanel.Controls.Add($textBox,0,1)
$tableLayoutPanel.Controls.Add($button,0,2)

$form = New-Object System.Windows.Forms.Form
$form.Text = "Enter DoD IDs"
$form.ClientSize = New-Object System.Drawing.Size(400,400)
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$form.Add_FormClosed({
    $form.Close()
    $form.Dispose()
})

$form.Controls.AddRange(@($tableLayoutPanel))
$form.ShowDialog()
