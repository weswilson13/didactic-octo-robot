Try{
	Start-Transcript -Path \\192.168.1.4\NAS01\Scripts\ScriptLogs\GasReceipt_log.txt
    
    $config = Get-IniContent -FilePath \\192.168.1.4\NAS01\Scripts\scriptconfig.ini
	$destinationPath = $config.Values.strGasReceiptsPdfs
    $strSqlServer = $config.Values.strSqlServer
    $dbGasReceipts = $config.Values.strGasReceiptsDb
    $username = $config.Values.strGasReceiptsUsername
    $password = $config.Values.strGasReceiptsPassword

    $dateRegex = '((\b\d{1,2}\D{0,3})?\b(?:Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|Oct(?:ober)?|(Nov|Dec)(?:ember)?)\D?)(\d{1,2}(st|nd|rd|th)?)?((\s*[,.\-\/]\s*)\D?)?\s*((19[0-9]\d|20\d{2})|\d{2})*'
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

            $date = Select-String -InputObject $file.Name -Pattern "\d{8}|$dateRegex"
		    $year = Get-Date $date.Matches[0].Value -Format "yyyy"
		    $month=Get-Date $date.Matches[0].Value -Format "MM"
		    $day=Get-Date $date.Matches[0].Value -Format "dd"
		    [String]$dateNeat = Get-Date -Month $month -Day $day -Year $year
            $dateNeat

            if($file -like '*h.pdf') {
                $vehicle='2014 Honda Accord'
                $licensePlate='SRL514'
            } elseif($file -like '*f.pdf') {
                $vehicle='2013 Ford F-150'
                $licensePlate='NAR198'
            }

            $vehicle
            $licensePlate

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

		    $sqlConnection = Invoke-Sqlcmd -Username $username -Password $password -ServerInstance $strSqlServer -Database $dbGasReceipts -Query $sql -Verbose
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