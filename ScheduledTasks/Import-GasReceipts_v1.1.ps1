Try{
	Start-Transcript -Path \\192.168.1.4\NAS01\Scripts\ScriptLogs\GasReceipt_log.txt
    
    $config = Get-IniContent -FilePath \\192.168.1.4\NAS01\Scripts\scriptconfig.ini
	$destinationPath = $config.Values.strGasReceipts
    $strSqlServer = $config.Values.strSqlServer
    $dbGasReceipts = $config.Values.dbGasReceipts

    Import-Module SqlServer

	$currentYear = (Get-Date).Year

	$sourcePath = "G:\My Drive\Gas Receipts\$currentYear Gas Receipts"
    $sourcePath

    $destinationPath
	<#$destinationPath = "\\wiskyEkoSiera\d$\Documents\Taxes\$currentYear Taxes\Gas Receipts"#>

	if (-not (Test-Path $destinationPath)) {
		New-Item -Path $destinationPath -ItemType Directory
	}

	$files = Get-ChildItem $sourcePath -Name '*.pdf' -File 

	foreach($file in $files) {
        $source = Join-Path -Path $sourcePath -ChildPath $file
        $source
        $destination = (Join-Path -Path $destinationPath -ChildPath $file) -replace '-(\d*)'
        $destination

        if (-not (Test-Path -Path $destination)) { 
		    $file = Move-Item -Path $source -Destination $destination -ErrorAction SilentlyContinue -Verbose -PassThru

            $date = Select-String -InputObject $file.Name -Pattern '\d{8}'
		    $year = $date.Matches[0].ToString().Substring(0,4)
		    $month=$date.Matches[0].ToString().Substring(4,2)
		    $day=$date.Matches[0].ToString().Substring(6,2)
		    [String]$dateNeat = Get-Date -Month $month -Day $day -Year $year

            if($file -like '*h.pdf') {
                $vehicle='2014 Honda Accord'
                $licensePlate='SRL514'
            } elseif($file -like '*f.pdf') {
                $vehicle='2013 Ford F-150'
                $licensePlate='NAR198'
            }

		    $sql = "USE [gasreceipts]
				    GO

				    DECLARE @results as varbinary(max);
                    DECLARE @sql as nvarchar(max);
                    DECLARE @purchaseDate as varchar(10)=FORMAT(CAST('$dateNeat' AS DATE), 'yyy-MM-dd')
                    DECLARE @vehicle as varchar(50) = '$vehicle'
                    DECLARE @licensePlate as varchar(10) = '$licensePlate'

                    select @results = receipt from dbo.receipts where PurchaseDate = @purchaseDate and Vehicle=@vehicle
                
                    IF @results is not null
	                    BEGIN
		                    SET @sql = 'UPDATE [dbo].[receipts] 
                                        SET [Receipt] = (SELECT * FROM OPENROWSET(BULK ''$file'', single_blob) AS receipt) 
                                        WHERE PurchaseDate=''' + @purchaseDate + ''' 
                                            AND Vehicle=''' + @vehicle + ''''
                                    
	                    END
                    ELSE
	                    BEGIN
		                    SET @sql = 'INSERT INTO [dbo].[receipts]
						                       ([PurchaseDate]
						                       ,[Receipt]
						                       ,[TaxYear]
                                               ,[Vehicle]
                                               ,[LicensePlate])
					                     VALUES
						                       (''' + @purchaseDate + '''
						                       ,(SELECT * FROM OPENROWSET(BULK ''$file'', single_blob) AS receipt)
						                       ,$year
                                               ,''' + @vehicle + '''
                                               ,''' + @licensePlate + ''')'
				                
		                    END
                
                    PRINT @sql;        
                    EXEC sp_executesql @sql;"
		    #Write-Output $sql

		    $sqlConnection = Invoke-Sqlcmd -ServerInstance $strSqlServer -Database $dbGasReceipts -Query $sql -Verbose
        }
        else {
            Write-Output "$destination already exists. This file was ignored."
        }
	}
} catch {
  Write-Output "An error occurred:"
  Write-Output $error[0] | select *
}

Stop-Transcript