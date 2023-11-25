using Module ImportExcel

$dateString = Get-Date -Format 'MMMM yyyy'

#region requires modification
    #region create drive mappings
        New-PSDrive -Name T -Root "\\raspberrypi4-1\nas04" -PSProvider Filesystem -Scope Global -ErrorAction SilentlyContinue | Out-Null
    #endregion
    $serverInstance = "SQ02\MYSQLSERVER,9999"
    $database = "AdventureWorks2019"
    $templateWorkbookName = "T:\template.xlsx"
    $templateSheetName = "Sheet1"

    # queries
    $departmentsQuery = "Select distinct Name from [HumanResources].[Department]" # return the departments/divisions
    
#endregion

$parameters = @{
    Connection = $serverInstance
    MsSqlServer = $true
    Database = $database
    Path = "T:\$dateString.xlsx"
    RangeName = "Data"
    KillExcel = $true
    AutoSize = $true
}

Write-Host "Core Parameters...`r`n$($parameters | Out-String)" -ForegroundColor Cyan

$departments = (Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $Database -Query $departmentsQuery).Name

Write-Host "Departments...`r`n`n$($departments | Out-String)" -ForegroundColor Yellow

foreach ($dept in $departments) {
    Write-Host "Creating the $dept Sheet..." 
    Copy-ExcelWorksheet -SourceWorkbook $templateWorkbookName -SourceWorksheet $templateSheetName -DestinationWorkbook $parameters.path -DestinationWorksheet $dept
    $parameters["SQL"] = "select * from [HumanResources].[vEmployeeDepartment] where department='$dept'" # return the data to be exported to each sheet
    $parameters["WorksheetName"] = $dept
    $parameters["Title"] = "Monthly Asset Inventory ($dept) $dateString"
    Send-SQLDataToExcel @parameters
    Write-Host "Done."
}

# ensure only the first tab is selected to prevent users from modifying all tabs
$pkg = Open-ExcelPackage -Path $parameters.path -KillExcel
Select-Worksheet -ExcelPackage $pkg -WorksheetName $departments[0]
Close-ExcelPackage -ExcelPackage $pkg 