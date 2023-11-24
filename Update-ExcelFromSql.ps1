using Module ImportExcel

# example
# Update-ExcelFromSql.ps1 -ServerInstance "SQ02,9999" -Database hmaildb -PathToExcel "\\raspberrypi4-1\nas04\testExcel.xlsx"

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [String]$ServerInstance
    ,
    [Parameter(Mandatory=$true)]
    [String]$Database
    ,
    [Parameter(Mandatory=$true)]
    [String]$Path
    # ,
    # [Parameter(Mandatory=$false, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    # [String]$WorksheetName
    # ,
    # [Parameter(Mandatory=$false)]
    # [String]$Query = "Select * from hm_accounts"
    # ,
    # [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    # [String]$Title
)

$PSBoundParameters.Remove("ServerInstance")
$PSBoundParameters.Add("Connection", $ServerInstance)
$PSboundParameters.Add("MsSqlServer", $true)
$PSboundParameters.Add("RangeName", "Data")
# $PSboundParameters.Add("SQL", $Query)

$PSBoundParameters | Out-String | Write-Verbose

$departments = (Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $Database -Query "Select distinct Name from [HumanResources].[Department]").Name
$departments | Out-String | Write-Verbose

foreach ($dept in $departments) {
    $PSBoundParameters["SQL"]="select * from [HumanResources].[vEmployeeDepartment] where department='$dept'"
    Send-SQLDataToExcel @PSBoundParameters -WorksheetName $dept -Title "Monthly Asset Inventory ($dept) $(Get-Date -Format 'MMMM yyyy')"
}