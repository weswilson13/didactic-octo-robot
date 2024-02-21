$backupRepository = "C:\tools\test"

$files = Get-Childitem $backupRepository -File -Recurse
$files | Foreach-Object {
    $split=[System.IO.Path]::GetFileNameWithoutExtension($PSitem.Name) -split '_'
    Add-Member -InputObject $PSItem -NotePropertyMembers @{SwitchName=$split[0];BackupDate=[datetime]::ParseExact("$($split[1]+$split[2])",'MMddyyHHmmss',$null)}
}

$newestFiles = $files | Group-Object -Property SwitchName | Foreach-Object { $_.Group | Sort-Object BackupDate -Descending | Select-Object -First 1 }
$newestFiles