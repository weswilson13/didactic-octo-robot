$Configuration=(Get-WSUSServer).GetConfiguration()
$Configuration.BitsDownloadPriorityForeground=$True
$Configuration.Save()
(get-wsusserver).GetConfiguration()