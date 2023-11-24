using Module ImportExcel

New-PSDrive -Name T -Root \\raspberrypi4-1\nas04 -PSProvider Filesystem -ErrorAction SilentlyContinue | Out-Null

$serverInstance = "SQ02\MYSQLSERVER,9999"
$database = "AdventureWorks2019"
$path = "T:\November2023.xlsx"

$parameters = @{
    Connection = $serverInstance
    MsSqlServer = $true
    Database = $database
    Path = $path
    RangeName = "Data"
}

$parameters | Out-String | Write-Verbose

$departments = (Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $Database -Query "Select distinct Name from [HumanResources].[Department]").Name
$departments | Out-String | Write-Verbose

foreach ($dept in $departments) {
    Copy-ExcelWorksheet -SourceWorkbook \\raspberrypi4-1\nas04\template.xlsx -SourceWorksheet "Sheet1" -DestinationWorkbook $path -DestinationWorksheet $dept
    $parameters["SQL"] = "select * from [HumanResources].[vEmployeeDepartment] where department='$dept'"
    Send-SQLDataToExcel @parameters -WorksheetName $dept -Title "Monthly Asset Inventory ($dept) $(Get-Date -Format 'MMMM yyyy')" -KillExcel -AutoSize -
}