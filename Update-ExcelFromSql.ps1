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
    [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [String]$Path
    ,
    [Parameter(Mandatory=$false)]
    [String]$WorksheetName
    ,
    [Parameter(Mandatory=$false)]
    [String]$SQL = "Select * from hm_accounts"
    ,
    [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [String]$Title
)

$PSBoundParameters.Remove("ServerInstance")
$PSBoundParameters.Add("Connection", $ServerInstance)
$PSboundParameters.Add("MsSqlServer", $true)
$PSboundParameters.Add("RangeName", "Data")

$PSBoundParameters | out-string | Write-Verbose

Send-SQLDataToExcel @PSBoundParameters