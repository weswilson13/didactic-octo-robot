$wsusserver = (Get-IniContent -FilePath \\192.168.1.4\NAS01\Scripts\scriptconfig.ini).Values.strWsusServer 
Enter-PSSession $wsusserver

[reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration") | out-null
$wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer($wsusserver, $False,8530);
$wsus.GetSubscription().StartSynchronization();

Exit-PSSession

