New-PSDrive -Name T -Root \\raspberrypi4-1\nas04 -PSProvider Filesystem -ErrorAction SilentlyContinue | Out-Null

$serverInstance = "SQ02\MYSQLSERVER,9999"
$database = "AdventureWorks2019"
$path = "T:\November2023.xlsx"

$parameters = @{
    ServerInstance = $serverInstance
    Database = $database
    Path = $path
}

$parameters | Out-String | Write-Verbose

$departments = (Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $Database -Query "Select distinct Name from [HumanResources].[Department]").Name
$departments | Out-String | Write-Verbose

$departments | .\Update-SqlFromExcel.ps1 -ServerInstance $serverInstance -Database $database -PathToExcel $path 