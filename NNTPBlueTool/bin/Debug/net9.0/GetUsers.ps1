[CmdletBinding()]
param([string]$Domain="dc03.mydomain.local")

Add-Type -AssemblyName System.DirectoryServices

$result = [adsisearcher]::new([adsi]::new("LDAP://$Domain"),"(&(objectCategory=person)(objectClass=user))").FindAll() | Out-GridView -PassThru
$entry = $result.GetDirectoryEntry()

return $entry.sAMAccountName