try{
    $checkFailed=$false
    $unapprovedUsers=@()

    $users = ( Get-ChildItem "C:\program files\Microsoft SQL Server\*\setup bootstrap\log" -Recurse -Include *.log | 
        Select-String -Pattern 'LogonUser = ' ) -replace '^.*LogonUser = ' -replace 'SYSTEM','SYSTEM (Windows Update)' | 
        Sort-Object -Unique 

    #$users | Out-String | Write-Host 

    [Array]$approvedUsers='wes_admin'

    $users | ForEach-Object {
        if ($PSitem -notin $approvedUsers) {$checkFailed = $true; $unapprovedUsers += $PSitem}
    }

    if ($checkFailed) {
        "The Check Failed. The following users are not approved IAW system documentation:`n$($unapprovedUsers | Out-String)"
        return $false
    }
}
Catch {
    $_.Exception
}
