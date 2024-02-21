Param(
    [Parameter(Mandatory=$false, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [System.IO.FileInfo]$BackupRepository = "C:\tools\test"
    ,
    [Parameter(Mandatory=$false, ValueFromPipeline=$false, ValueFromPipelineByPropertyName=$true)]
    [string]$Format = "MMyyddHHmmss"
)

$files = Get-Childitem $BackupRepository -File -Recurse 
$files | Foreach-Object {
    $split=[System.IO.Path]::GetFileNameWithoutExtension($PSitem.Name) -split '_'
    $arrayLength = $split.Length-1
    Add-Member -InputObject $PSItem -NotePropertyMembers @{SwitchName=$split[0];BackupDate=[datetime]::ParseExact("$(-join $split[1..$arrayLength])",$Format,$null)}
}

$newestFiles = $files | Group-Object -Property SwitchName | Foreach-Object { $_.Group | Sort-Object BackupDate -Descending | Select-Object -First 1 }
$newestFiles