$Instance = "SQ02,9999"
[bool]$checkFailed = $false
$failedProtocols = @()
$protocols = @()

$approvedProtocols ='Shared Memory'

#region Adapted from Scan-SqlServer2016Instance_Checks.psm1\Get-V213961 
    $ThisInst = $(Invoke-SqlCmd -ServerInstance $Instance -Query "
        SELECT CASE
                WHEN SERVERPROPERTY ('InstanceName') IS NULL THEN 'MSSQLSERVER'
                ELSE SERVERPROPERTY ('InstanceName')
            END Name
        ").Name

    #Set Remote Registry connection
    $RegSQLVal = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL" -Name $ThisInst

    # Get SQL connection settings
    $protocols += [PSCustomObject]@{
        Protocol='Named Pipes'
        Value=Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$RegSQLVal\MSSQLServer\SuperSocketNetLib\Np" -Name "Enabled"
    }
    $protocols += [PSCustomObject]@{
        Protocol='Shared Memory'
        Value=Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$RegSQLVal\MSSQLServer\SuperSocketNetLib\Sm" -Name "Enabled"
    }
    $protocols += [PSCustomObject]@{
        Protocol='TCP/IP'
        Value=Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$RegSQLVal\MSSQLServer\SuperSocketNetLib\Tcp" -Name "Enabled"
    }
    $protocols += [PSCustomObject]@{
        Protocol='VIA'
        Value=Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$RegSQLVal\MSSQLServer\SuperSocketNetLib\Via" -Name "Enabled"
    }
#endregion

#$FindingDetails = Get-Variable regprotocol* | Select-Object @{Name='Protocol'; Expression={$_.Name -replace 'regprotocol'}},Value

$protocols.Where({$_.Value -eq 1}) | Foreach-Object {
    if ($_.Protocol -notin $approvedProtocols) {$checkFailed=$true; $failedProtocols+=$_.Protocol}
}

if ($checkFailed){"[CHECK FAILED]: The following protocol(s) are not documented: `n$($failedProtocols | Out-String)"; return $false}

return $true