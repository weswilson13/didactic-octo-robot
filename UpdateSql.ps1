#region requires modification
    #region create drive mappings
    New-PSDrive -Name T -Root "\\raspberrypi4-1\nas04" -PSProvider Filesystem -ErrorAction SilentlyContinue | Out-Null
    #endregion
    $serverInstance = "SQ02\MYSQLSERVER,9999"
    $database = "AdventureWorks2019"
    $path = "T:\November2023.xlsx"
    $query = "Select distinct Name from [HumanResources].[Department]"
#endregion

$parameters = @{
    ServerInstance = $serverInstance
    Database = $database
}

$parameters | Out-String | Write-Verbose

$departments = (Invoke-Sqlcmd @parameters -Query $query).Name
$departments | Out-String | Write-Verbose

# $departments | .\Update-SqlFromExcel.ps1 @parameters -PathToExcel $path 
.\Update-SqlFromExcel.ps1 @parameters -PathToExcel $path -WorksheetName $departments