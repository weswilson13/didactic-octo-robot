using Module ImportExcel

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