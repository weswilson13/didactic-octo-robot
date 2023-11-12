#Requires -RunAsAdministrator

$config = Get-IniContent -FilePath "$PSScriptRoot\scriptconfig.ini"
$primaryDns = $config.Values.strPrimaryDns
$secondayDns = $config.Values.strSecondaryDns

Set-DnsClientServerAddress -InterfaceAlias Wi-Fi -ServerAddresses ($primaryDns, $secondayDns)