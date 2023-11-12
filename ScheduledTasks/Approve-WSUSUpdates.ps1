#Email address where you want to send the notification after the script completes
[string[]]$recipients = admins@contoso.com 

#WSUS server name
$wsusserver = (Get-IniContent -FilePath \\192.168.1.4\NAS01\Scripts\scriptconfig.ini).Values.strWsusServer 

#Log file name
$log = "\\192.168.1.4\NAS01\Scripts\ScriptLogs\Approved_Updates_{0:MMddyyyy_HHmm}.log" -f (Get-Date) 

#Creating log file
new-item -path $log -type file -force 

#Loading the WSUS .NET classes
[void][reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration") 

#Storing the object into the variable
$wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer($wsusserver, $False,8530) 

#Loading WSUS Update scope object into variable
$UpdateScope = New-Object Microsoft.UpdateServices.Administration.UpdateScope 

#Setting up groups for updates approval
$groups = "All Computers" 

#Setting up update classifications for approval
$Classification = $wsus.GetUpdateClassifications() | ? {$_.Title -ne 'Service Packs' ‑and $_.Title -ne 'Drivers' -and $_.Title -ne 'Upgrades'} 

#Setting up update categories for approval
$Categories = $wsus.GetUpdateCategories() | ? {$_.Title -notmatch "SQL" -and $_.Title -notmatch "Skype"} 

$UpdateScope.FromCreationDate = (get-date).AddMonths(-1) #Configuring starting date for UpdateScope interval

$UpdateScope.ToCreationDate = (get-date) #Configuring ending date for UpdateScope interval

$UpdateScope.Classifications.Clear() #Clearing classification object before assigning new value to it

$UpdateScope.Classifications.AddRange($Classification) #Assigning previously prepared classifications to the classification object

$UpdateScope.Categories.Clear() #Clearing the categories object before assigning a new value to it

$UpdateScope.Categories.AddRange($Categories) #Assigning previously prepared categories to the classification object

$updates = $wsus.GetUpdates($UpdateScope) | ? {($_.Title -notmatch "LanguageInterfacePack" -and $_.Title -notmatch "LanguagePack" -and $_.Title -notmatch "FeatureOnDemand" -and $_.Title -notmatch "Skype" -and $_.Title -notmatch "SQL" -and $_.Title -notmatch "Itanium" -and $_.PublicationState -ne "Expired" -and $_.IsDeclined -eq $False )} #Storing all updates in the previously defined UpdateScope interval to the $updates variable and filtering out those not required

foreach ($group in $groups) #Looping through groups
  {
   $wgroup = $wsus.GetComputerTargetGroups() | where {$_.Name -eq $group} #Storing the current group into the $wgroup variable
   foreach ($update in $updates) #Looping through updates
     {
      $update.Approve(“Install”,$wgroup) #Approving each update for the current group
     }
  }

$date = Get-Date #Storing the current date into the $date variable

"Aproved updates (on " + $date + "): " | Out-File $log -append #Updating the log file

"Updates have been approved for following groups: (" + $groups + ")" | Out-File $log ‑append #Updating log file

"Folowing updates have been approved:" | Out-File $log -append #Updating the log file

$updates | Select Title,ProductTitles,KnowledgebaseArticles,CreationDate | ft -Wrap | Out-File $log -append #Updating log file

Send-MailMessage -From "WSUS@contoso.com" -To $recipients -Subject "New updates have been approved" -Body "Please find the list of approved updates enclosed" -Attachments $log -SmtpServer "smtp-server" -DeliveryNotificationOption OnFailure #Sending the log file by email.