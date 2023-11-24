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
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [String]$PathToExcel
    ,
    [Parameter(Mandatory=$false)]
    [String]$WorksheetName
    ,
    [Parameter(Mandatory=$false)]
    [String]$Query = "Select * from hm_accounts"
)

$PSBoundParameters.Remove("ServerInstance")
$PSBoundParameters.Remove("PathToExcel")
$PSBoundParameters.Add("Connection", $ServerInstance)
$PSboundParameters.Add("MsSqlServer", $true)
$PSboundParameters.Add("SQL", $Query)
$PSboundParameters.Add("Path", $PathToExcel)
$PSboundParameters.Add("RangeName", "Data")

$PSBoundParameters | out-string | Write-Verbose

Send-SQLDataToExcel @PSBoundParameters