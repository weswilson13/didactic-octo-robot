$Instance = "SQ02,9999"

#region From Scan-SqlServer2016Instance_Checks.psm1\Get-V213961 
    $ThisInst = $(Invoke-SqlCmd -ServerInstance $Instance -Query "
        SELECT CASE
                WHEN SERVERPROPERTY ('InstanceName') IS NULL THEN 'MSSQLSERVER'
                ELSE SERVERPROPERTY ('InstanceName')
            END Name
        ").Name

    #Set Remote Registry connection
    $RegSQLVal = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL" -Name $ThisInst

    # Get SQL connection settings
    $regprotocolNamed_Pipes = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$RegSQLVal\MSSQLServer\SuperSocketNetLib\Np" -Name "Enabled"
    $regprotocolShared_Memory = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$RegSQLVal\MSSQLServer\SuperSocketNetLib\Sm" -Name "Enabled"
    $regprotocolTCP = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$RegSQLVal\MSSQLServer\SuperSocketNetLib\Tcp" -Name "Enabled"
    $regprotocolVIA = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$RegSQLVal\MSSQLServer\SuperSocketNetLib\Via" -Name "Enabled"
#endregion

$FindingDetails = Get-Variable regprotocol* | Select @{Name='Protocol'; Expression={$_.Name -replace 'regprotocol'}}, Value
return $FindingDetails