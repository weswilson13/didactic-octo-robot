try{
    $checkFailed=$false
    $unapprovedUsers=@()

    $users = Get-LocalGroupMember -Group (Get-LocalGroup Administrators).Name 

    [Array]$approvedUsers='wes_admin'

    $users | ForEach-Object {
        if ($PSitem -notin $approvedUsers) {$checkFailed = $true; $unapprovedUsers += $PSitem}
    }

    if ($checkFailed) {
        return [PSCustomObject]@{
            Results="The Check Failed. The following users are not approved IAW system documentation:`n$($unapprovedUsers | Out-String)"
            Valid=$false
        }
    }

    return $true
}
Catch {
    $_.Exception
}
