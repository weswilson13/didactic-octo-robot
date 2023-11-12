$years=@('2020','2019','2018')

foreach($year in $years){
    $path= "D:\Documents\Taxes\$year Taxes\Gas Receipts"
    $files=Get-ChildItem $path

    ForEach($file in $files) {
        $file=Rename-Item -Path "$path\$file" -NewName ($file -replace '-(\d*)','')
        write-host "UPDATE [dbo].[receipts]
       SET [Receipt] = (SELECT * FROM OPENROWSET(BULK '\\wiskyekosiera\d$\documents\taxes\$year taxes\gas receipts\"$file.name"', single_blob) AS receipt)
     WHERE FORMAT([PurchaseDate], 'yyyyMMdd') = '"(($file.Name -replace 'Scanned_','') -replace '.pdf','')"'
    GO"
    }
}