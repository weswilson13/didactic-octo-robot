$config = (Get-IniContent "$PSScriptRoot\scriptconfig.ini").Values
$sqlServer = $config.strSqlServer
$gasReceiptsDb = $config.strGasReceiptsDb
$gasReceiptsTb = $config.strGasReceiptsTable

$username = $config.strGasReceiptsUsername
$password = $config.strGasReceiptsPassword

Invoke-Sqlcmd -Username $username -Password $password -ServerInstance $sqlServer -Database $gasReceiptsDb -Query "Select * From $gasReceiptsTb Order by ID desc" | Out-GridView

While ($true) {
    Clear-Host
    Do {[int]$id = Read-Host "Enter the ID of the record to modify" } While (-not $id)
    $totalCost = Read-Host "Enter the total cost of the transaction"
    $numberGallons = Read-Host "Enter the number of gallons from the transaction"

    $query = "UPDATE $gasReceiptsTb
              SET [TotalCost] = $totalCost
                 ,[NumberGallons] = $numberGallons
     
              WHERE [ID]=$id"

    try{
        Invoke-Sqlcmd -Username $username -Password $password -ServerInstance $sqlServer -Database $gasReceiptsDb -Query $query -Verbose
    } 
    catch {
        Write-Error $Error[0]
        break
    }
    if ((Read-Host "Enter more receipt data? (y/n)").ToLower() -eq "n") {break}
}