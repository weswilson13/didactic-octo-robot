param(
    [Parameter(Mandatory=$false, Position=0)]
    [String]$WorkingDirectory = $PSScriptRoot
    ,
    [Parameter(Mandatory=$false, Position=1)]
    [String]$ComputerName
)

Import-Module -Name $WorkingDirectory\Modules\PsIni,$WorkingDirectory\Modules\SqlServer -Scope Local -Force

$serverInstance = (Get-IniContent -FilePath \\Optimusprime\Z\Scripts\scriptconfig.ini).Values["strSqlServer"]
$database = "Computers"
$table = "tblComputers"
$schema = "dbo"

if ($ComputerName) {
    $computerInfo = Invoke-Command -ComputerName $ComputerName -ScriptBlock { Get-ComputerInfo }
    $cpu = Get-CimInstance -Class Win32_Processor -ComputerName $computerName
}
Else {
    $computerInfo = Get-ComputerInfo
    $cpu = Get-CimInstance -Class Win32_Processor
}

$data = [PSCustomObject]@{
    SerialNumber = $computerInfo.BiosSeralNumber
    OS = $computerInfo.OsName
    ClientOrServer = $computerInfo.WindowsInstallationType
    BIOSVersion = $computerInfo.BiosBIOSVersion | Out-String
    BIOSManufacturer = $computerInfo.BiosManufacturer
    HostName = $computerInfo.CsName
    Domain = $computerInfo.CsDomain
    Manufacturer = $computerInfo.CsManufacturer
    Model = $computerInfo.CsModel
    TotalMemory = [Math]::Round($computerInfo.OsTotalVisibleMemorySize/1Mb,2)
    OSArchitecture = $computerInfo.OsArchitecture
    Processor = $cpu.Name | Out-String
} 

$data | Out-String | Write-Host

if ([String]::IsNullOrWhiteSpace((Invoke-Sqlcmd -ServerInstance $serverInstance -Database $database -Query "SELECT OBJECT_ID(N'$table', N'U') AS Value").Value)) {
    Write-SqlTableData -ServerInstance $serverInstance -DatabaseName $database -SchemaName $schema -TableName $table -InputData $data -Force
    Exit
}

$sql = [String]::Format("MERGE tblComputers T
        USING (SELECT 
             '{0}' AS SerialNumber
            ,'{1}' AS OS
            ,'{2}' AS ClientOrServer
            ,'{3}' AS BIOSVersion
            ,'{4}' AS BIOSManufacturer
            ,'{5}' AS HostName
            ,'{6}' AS Domain
            ,'{7}' AS Manufacturer
            ,'{8}' AS Model
            ,{9} AS TotalMemory
            ,'{10}' AS OSArchitecture
            ,'{11}' AS Processor ) S
        ON T.SerialNumber = S.SerialNumber
        WHEN MATCHED
            THEN UPDATE SET
                 T.OS = '{1}'
                ,T.ClientOrServer = '{2}'
                ,T.BIOSVersion = '{3}'
                ,T.BIOSManufacturer = '{4}'
                ,T.HostName = '{5}'
                ,T.Domain = '{6}'
                ,T.Manufacturer = '{7}'
                ,T.Model = '{8}'
                ,T.TotalMemory = {9}
                ,T.OSArchitecture = '{10}'
                ,T.Processor = '{11}'
        WHEN NOT MATCHED BY TARGET
            THEN INSERT
                (SerialNumber, OS, ClientOrServer, BIOSVersion, BIOSManufacturer, HostName, Domain, Manufacturer, Model, TotalMemory, OSArchitecture, Processor)
                VALUES ('{0}','{1}','{2}','{3}','{4}','{5}','{6}','{7}','{8}',{9},'{10}','{11}');",
                $data.SerialNumber,
                $data.OS,
                $data.ClientOrServer,
                $data.BIOSVersion,
                $data.BiosManufacturer,
                $data.HostName,
                $data.Domain,
                $data.Manufacturer,
                $data.Model,
                $data.TotalMemory,
                $data.OSArchitecture,
                $data.Processor)
    
    Invoke-Sqlcmd -ServerInstance $serverInstance -Database $database -Query $sql
    Pause

    
    