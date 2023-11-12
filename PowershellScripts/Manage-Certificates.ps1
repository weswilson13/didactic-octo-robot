## Create a Self-Signed Certificate (SSL)

#$certname = "{certificateName}"    ## Replace {certificateName}
$certname = "TestCert"
#$cert = New-SelfSignedCertificate -Subject "CN=$certname" -CertStoreLocation "Cert:\CurrentUser\My" -KeyExportPolicy Exportable -KeySpec Signature -KeyLength 2048 -KeyAlgorithm RSA -HashAlgorithm SHA256
New-SelfSignedCertificate -DnsName mydomain.local, localhost -Subject "CN=$certname" -CertStoreLocation "Cert:\LocalMachine\My" -KeyExportPolicy Exportable -KeySpec Signature -KeyLength 2048 -KeyAlgorithm RSA -HashAlgorithm SHA256

## Export the certificate
Export-Certificate -Cert $cert -FilePath "C:\Users\admin\Desktop\$certname.cer"   ## Specify your preferred location

## (Optional): Append private key to existing cert (required for IIS binding)
$thumbprint = (Get-ChildItem -Path "Cert:\CurrentUser\My" | Where-Object {$_.Subject -Match "$certname"} | Select-Object Thumbprint).Thumbprint
certutil -repairstore my $thumbprint

## (Optional): Export your public certificate with its private key
$mypwd = ConvertTo-SecureString -String "{myPassword}" -Force -AsPlainText  ## Replace {myPassword}
Export-PfxCertificate -Cert $cert -FilePath "C:\$certname.pfx" -Password $mypwd   ## Specify your preferred location

## Import Certificate to Certificate Store
Import-Certificate -FilePath "\\WS01\C$\SelfCert.pfx" -CertStoreLocation 'Cert:\LocalMachine\My' -Verbose
Import-PfxCertificate -FilePath "C:\Cert1.pfx" -CertStoreLocation 'Cert:\LocalMachine\Root' -Password $mypwd -Verbose

## Optional task: Delete the certificate from the keystore.
Get-ChildItem -Path "Cert:\CurrentUser\My" | Where-Object {$_.Subject -Match "$certname"} | Select-Object Thumbprint, FriendlyName
Remove-Item -Path Cert:\CurrentUser\My\{pasteTheCertificateThumbprintHere} -DeleteKey