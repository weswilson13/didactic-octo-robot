#region functions

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
    [byte[]]$keyEncrypted = $script:_rsa.Encrypt($aes.Key, $false)

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
    [byte[]]$keyDecrypted = $script:_rsa.Decrypt($keyEncrypted, $false)

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
    $script:_cspp.KeyContainerName = $textBoxKeyname.Text
    $script:_rsa = [System.Security.Cryptography.RSACryptoServiceProvider]::new($script:_cspp)
    $script:_rsa.PersistKeyInCsp = $true

    if ($script:_rsa.PublicOnly) {
        $label1.Text = "Key: $($script:_cspp.KeyContainerName) - Public Only"
    }
    else {
        $label1.Text = "Key: $($script:_cspp.KeyContainerName) - Full Key Pair"
    }
}
function buttonEncryptFile_Click([psobject]$sender, [System.EventArgs]$e) {
    <#
        .SYNOPSIS
        Click event handler for the Encrypt File button (buttonEncryptFile_Click)
    #>
    if ($script:_rsa -eq $null) {
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
    if ($script:_rsa -eq $null) {
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

        .DESCRIPTION
        Saves the key created by the Create Keys button to a file. It exports only the public parameters.

        This task simulates the scenario of Alice giving Bob her public key so that he can encrypt files for her. 
        He and others who have that public key will not be able to decrypt them because they do not have the full 
        key pair with private parameters.
    #>

    # Save the public key created by the RSA to a file. Caution, persisting the key to a file is a security risk.
    [System.IO.Directory]::CreateDirectory($encrFolder)
    $filebrowser = [System.Windows.Forms.SaveFileDialog]::new()
    $filebrowser.InitialDirectory = $encrFolder
    $filebrowser.FileName = $pubKeyFile
    
    if ($filebrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    
        try {
            $sw = [System.IO.StreamWriter]::new($filebrowser.FileName, $false)
            $sw.Write($script:_rsa.ToXmlString($false))
        }
        catch {
            throw "An error occurred writing public key"
        }
        finally {
            # clean up
            $sw.Close()
        }
    }
}
function buttonImportPublicKey_Click([psobject]$sender, [System.EventArgs]$e) {
    <#
        .SYNOPSIS
        Click event handler for the Import Public Key button (buttonImportPublicKey_Click)

        .DESCRIPTION
        Loads the key with only public parameters, as created by the Export Public Key button, and sets it as the key container name.

        This task simulates the scenario of Bob loading Alice's key with only public parameters so he can encrypt files for her.
    #>
    
    $filebrowser = [System.Windows.Forms.OpenFileDialog]::new()
    $filebrowser.InitialDirectory = $srcFolder

    if ($filebrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        try {
            $sr = [System.IO.StreamReader]::new($filebrowser.FileName)
            $script:_cspp.KeyContainerName = $textBoxKeyname.Text
            $script:_rsa = [System.Security.Cryptography.RSACryptoServiceProvider]::new($script:_cspp)

            $keytxt = $sr.ReadToEnd()
            $script:_rsa.FromXmlString($keytxt)
            $script:_rsa.PersistKeyInCsp = $true

            if ($script:_rsa.PublicOnly) {
                $label1.Text = "Key: $($script:_cspp.KeyContainerName) - Public Only"
            }
            else { 
                $label1.Text = "Key: $($script:_cspp.KeyContainerName) - Full Key Pair" 
            }
        }
        catch {
            throw "An error occurred importing public key"
        }
    }
}
function buttonGetPrivateKey_Click([psobject]$sender, [System.EventArgs]$e) {
    <#
        .SYNOPSIS
        Click event handler for the Get Private Key button (buttonGetPrivateKey_Click)

        .DESCRIPTION
        Sets the key container name to the name of the key created by using the Create Keys button. 
        The key container will contain the full key pair with private parameters.

        This task simulates the scenario of Alice using her private key to decrypt files encrypted by Bob.
    #>
    $script:_cspp.KeyContainerName = $textBoxKeyname.Text
    $script:_rsa = [System.Security.Cryptography.RSACryptoServiceProvider]::new($script:_cspp)
    $script:_rsa.PersistKeyInCsp = $true

    if ($script:_rsa.PublicOnly) {
        $label1.Text = "Key: $($script:_cspp.KeyContainerName) - Public Only"
    }
    else { 
         $label1.Text = "Key: $($script:_cspp.KeyContainerName) - Full Key Pair" 
    }
}

function Get-AppSettings {
    param ()
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
    
    return @{
        AppSettings = [System.Configuration.ConfigurationManager]::AppSettings
        ConnectionStrings = [System.Configuration.ConfigurationManager]::ConnectionStrings
    }
}
#endregion functions

#region    DECLARE GLOBAL OBJECTS

    # Path variables for source, encryption, and decryption folders.
    $AppSettings = (Get-AppSettings).AppSettings
    $srcFolder = $AppSettings["SourceFolder"]
    $encrFolder = $AppSettings["EncryptFolder"]
    $decrFolder = $AppSettings["DecryptFolder"]

    # Declare CspParameters and RsaCryptoServiceProvider objects with global scope of your Form class.
    New-Variable -Name _cspp -Value ([System.Security.Cryptography.CspParameters]::new()) -Option ReadOnly -Scope Script -Force
    [System.Security.Cryptography.RSACryptoServiceProvider]$script:_rsa = [System.Security.Cryptography.RSACryptoServiceProvider]::new($script:_cspp)
    
    # Public key file
    $pubKeyFile = "rsaPublicKey.txt"

    # Key container name for private/public key value pair.
    $keyName = "Key01"

#endregion DECLARE GLOBAL OBJECTS

<#
### controls
#>

#region textBoxKeyName
    $textBoxKeyname = New-Object System.Windows.Forms.TextBox
    $textBoxKeyname.Name = "textBoxKeyName"
    $textBoxKeyname.Text = $keyName
    # $textBoxKeyname.AutoSize = $true
#endregion textBoxKeyName

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
    $buttonDecryptFile = New-Object System.Windows.Forms.Button
    $buttonDecryptFile.Name = "buttonDecryptFile"
    $buttonDecryptFile.Text = "Decrypt File"
    $buttonDecryptFile.AutoSize = $true
    # $buttonDecryptFile.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom
    # $buttonDecryptFile.Dock = 'Bottom'
    $buttonDecryptFile.Add_Click({buttonDecryptFile_Click})
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
    $label1 = New-Object System.Windows.Forms.Label
    # $label.Dock = "Fill"
    $label1.Text = "Key Not Set"
    $label1.Font = New-Object System.Drawing.Font("Calibri",12,[Drawing.FontStyle]::Bold)
    $label1.AutoSize = $true
#endregion label1


$tableLayoutPanel = New-Object System.Windows.Forms.TableLayoutPanel
$tableLayoutPanel.RowCount = 5
$tableLayoutPanel.ColumnCount = 2
$tableLayoutPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 20))) | Out-Null
$tableLayoutPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 20))) | Out-Null
$tableLayoutPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 20))) | Out-Null
$tableLayoutPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 20))) | Out-Null
$tableLayoutPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 20))) | Out-Null

$tableLayoutPanel.ColumnStyles.Add((new-object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 50))) | Out-Null
$tableLayoutPanel.ColumnStyles.Add((new-object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 50))) | Out-Null

$tableLayoutPanel.Dock = "Fill"
# $tableLayoutPanel.CellBorderStyle = "outset"
$tableLayoutPanel.Controls.Add($textBoxKeyname,0,0)
$tableLayoutPanel.SetColumnSpan($textBoxKeyname,2)
$tableLayoutPanel.Controls.Add($buttonEncryptFile,0,1)
$tableLayoutPanel.Controls.Add($buttonDecryptFile,1,1)
$tableLayoutPanel.Controls.Add($buttonImportPublicKey,0,2)
$tableLayoutPanel.Controls.Add($buttonExportPublicKey,1,2)
$tableLayoutPanel.Controls.Add($buttonCreateAsmKeys,0,3)
$tableLayoutPanel.Controls.Add($buttonGetPrivateKey,1,3)
$tableLayoutPanel.Controls.Add($label1,0,4)
$tableLayoutPanel.SetColumnSpan($label1,2)


$form = New-Object System.Windows.Forms.Form
$form.Text = "Crypto Tool"
$form.ClientSize = New-Object System.Drawing.Size(300,300)
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$form.Add_FormClosed({
    $form.Close()
    $form.Dispose()
})

$form.Controls.AddRange(@($tableLayoutPanel))
$form.ShowDialog()

# SIG # Begin signature block
# MIIb+QYJKoZIhvcNAQcCoIIb6jCCG+YCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDA9E0lVgtps0oL
# Gkvt6Wk/ykBlW8xjflQOcLMqhZn6ZaCCFkIwggM7MIICI6ADAgECAhA2a84lByWj
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
# CQQxIgQgzJcdQu2OESrjRwvPloOPRI4JUbZGWofPxZIUnfbuf1wwDQYJKoZIhvcN
# AQEBBQAEggEAYQuqSz/m+sm7JAm1qzBdzbntdbytPqfRS/mkpjiKmwDbm1RHRY8w
# sYH0b5ARIa/yCxhK9F6x0GI89keydQRXD5EQjxbr2yGW6I2ew4Fj3HkGFEyRJ8gj
# /O/jBZkmDR1fOihlFovkUY8ZhBaSRl4zs78JokXBbGovB4yOxFXoggdH4SJbpqkG
# r/JekRzItstiSScN2E9BHIvi7pco4olzpIXEuuo/wJfXO9TQV2S7ZSF8QHH8fukc
# wBzvq4/e88XsxjwDozGyVLUfQTobfYSDgvmfRoGyygwHfsSOeTXpQzc4RjF0rBxV
# DPyl2WMMsdMVCUx4fw3fL6c6aomLW/k9W6GCAyAwggMcBgkqhkiG9w0BCQYxggMN
# MIIDCQIBATB3MGMxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5j
# LjE7MDkGA1UEAxMyRGlnaUNlcnQgVHJ1c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBU
# aW1lU3RhbXBpbmcgQ0ECEAuuZrxaun+Vh8b56QTjMwQwDQYJYIZIAWUDBAIBBQCg
# aTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNTAx
# MjUxNDI1NDZaMC8GCSqGSIb3DQEJBDEiBCDTzbDJQfkJ7v4sFyu7Dj9LrCib+jGh
# lSXnVCAT3U3XATANBgkqhkiG9w0BAQEFAASCAgBBBhF2ZrLXuFYBmoVZybVlXYrn
# oxVw9myZH/Ayq2YgxVSq9Fnj1JH9KxbS7ybWFzAsSw7S/E4XzuutYqiXMhGZTMiB
# MhoNlZcqPM3gcMXYejoh/KEVhT/q45diEsrhI2ssDzN4mBDA/8OvmK427rUUjlT4
# f0w2DUaPxBw9xWJNkQq0TlSvJQsDdsqF4Wz/55CwmvRE8Ev6vQEW/7I9naqe3wZ8
# 9VQ2mdgFVlxiRLaevQ2vccOzZcL4D+PgqOJxPiO3lRVROwXjX4vDAFdp2CNhWD/4
# nWonzLMIcJLjuDe4MYDHEXiv2L6eC05GxnUHMLa+aKh12bUsJnxWy5upcW+poY4P
# 9+Xb05Kj6g1NBetjV60jMEWzZ/BG6K/G1LUX1bkEUlh75w7EZ8j9gjIULlMKr5OV
# buZQ9V4MQA6FQuk9gMAhHLtF8SlfTFrbUI/iztZ6fLMTiV+1aCvauveQRZD1caAw
# z3rabyzZ00cGYmj77RMxG9jk0Z3N1DobIKy3dzJY+pFp6DU7HPnwAvLSf9O1fE3K
# HzKks8TOdB0dRpX9/8TagSANEB6wbP/uOSbGfKHKNMNtWwfNs4lI4S9IbbYEOQmq
# AfcywD8dMbHuFRNT1yhAtzYNeDihOc8imlJViSV/bSlX8fwkFJDizbR8GYhM/3y7
# rpRhn+6724Ca29UX6w==
# SIG # End signature block
