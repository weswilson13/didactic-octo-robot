$cred = Import-Clixml \\192.168.1.4\NAS01\Scripts\Credentials\wes_admin_cred.xml
Start powershell -Credential $cred
New-PSSession -ComputerName SQ01.mydomain.local -Credential $cred -Authentication Negotiate -Name 'myPSSession'
Enter-PSSession -Name 'myPSSession' -Verbose
Invoke-Command -ScriptBlock {Start-Process powershell.exe -Verb runas -FilePath "\\192.168.1.4\nas01\Scripts\Export-GasReceiptPDFs.old.ps1"} 
Exit-PSSession
Remove-PSSession -Name 'myPSSession'

#Import-Module SqlServer
<#
Try {
    $server = 'SQ01.mydomain.local\MYSQLSERVER,1433'
    $database = 'gasreceipts'
    $query = "Select ID, PurchaseDate from dbo.receipts where receipt is not null"
    $cred = Import-Clixml \\192.168.1.4\NAS01\Scripts\Credentials\wes_local_cred.xml

    $receipts = Invoke-Sqlcmd -ServerInstance $server -Database $database -Query $query -Username $cred.Username -Password $cred.getnetworkCredential().password

    foreach($receipt in $receipts) {

        $date = Get-Date -Date $receipt.PurchaseDate -Format 'yyyyMMdd'
        $ID = $receipt.ID
        $filename = "RID$ID_$date.pdf"

        invoke-command -ScriptBlock {
            bcp.exe "SELECT receipt from gasreceipts.dbo.receipts where ID = $ID" queryout "\\192.168.1.4\NAS04\Gas Receipts\$filename" -T -f "\\192.168.1.4\NAS01\Scripts\bcp.fmt" -S "SQ01\MYSQLSERVER,1433"
        }

    }
} Catch {
    Write-Host "An error occurred:"
    Write-Host $_
} Finally {
    Exit-PSSession
    Remove-PSSession -Name 'myPSSession'
}
#>