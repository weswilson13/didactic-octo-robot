#Requires -RunAsAdministrator
$transcriptPath = Join-Path -Path (Split-Path $PSScriptRoot) -ChildPath "ScriptLogs\Restart-SQLServices_log.txt"
Start-Transcript -Path $transcriptPath -Force

$config = Get-IniContent (Join-Path -Path (Split-Path $PSScriptRoot) -ChildPath scriptconfig.ini)
$fileShare = $config.Values.strFileShare
Write-Host $fileshare
$sqlServer = $config.Values.strSqlServer
Write-Host $sqlServer

$computer = $sqlServer -replace '\\.*|,.*'
Write-Host $computer

try {
    $services = Get-Service -ComputerName $computer -Name '*SQLSERVER*' #'MSSQL$MYSQLSERVER' # @('MSSQL$MYSQLSERVER','SQLAgent$MYSQLSERVER')
    $services | Restart-Service -Force -Verbose
}
catch {
    Write-Error $Error[0]
    throw $Error[0]
}
finally {
    Get-Service -ComputerName $computer -Name '*SQLSERVER*' -Verbose
    Stop-Transcript
}