Try{
	Start-Transcript -Path \\192.168.1.4\NAS01\Scripts\ScriptLogs\GasReceipt_log.txt -Force

	Import-Module SqlServer

	$currentYear = (Get-Date).Year

	$sourcePath = "G:\My Drive\Gas Receipts\$currentYear Gas Receipts"
	$destinationPath = "\\192.168.1.4\NAS02\Gas Receipts"
	<#$destinationPath = "\\wiskyEkoSiera\d$\Documents\Taxes\$currentYear Taxes\Gas Receipts"#>

	<#if (-not (Test-Path $destinationPath)) {
		New-Item -Path $destinationPath -ItemType Directory
	}#>

	$files = Get-ChildItem $sourcePath 

	foreach($file in $files) {
		Move-Item -Path $sourcePath\$file -Destination ("$destinationPath\$file" -replace '-(\d*)','') -Verbose
		$date = Select-String -InputObject $file.name -Pattern '\d{8}'
		$year = $date.Matches[0].ToString().Substring(0,4)
		$month=$date.Matches[0].ToString().Substring(4,2)
		$day=$date.Matches[0].ToString().Substring(6,2)
		[String]$dateNeat = Get-Date -Month $month -Day $day -Year $year
		Write-Host $dateNeat

		$sql = "USE [gasreceipts]
				GO

				INSERT INTO [dbo].[receipts]
						   ([PurchaseDate]
						   --,[Receipt]
						   ,[TaxYear])
					 VALUES
						   (FORMAT(CAST('$dateNeat' AS DATE),'yyyy-MM-dd')
						   --,(SELECT * FROM OPENROWSET(BULK '$destinationPath`\$file', single_blob) AS receipt)
						   ,$year)
				GO"
		Write-Output $sql

		$sqlConnection = Invoke-Sqlcmd -ServerInstance 'SQ01.mydomain.local\MYSQLSERVER,1433' -Database 'gasreceipts' -Query $sql -Verbose
	}
} catch {
  Write-Output "An error occurred:"
  Write-Output $_
}
