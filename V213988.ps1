try{
    $checkFailed=$false
    $unapprovedUsers=@()
    Out-File -FilePath c:\tools\v213988.log -Force

    $users = Get-LocalGroupMember -Group (Get-LocalGroup Administrators).Name 
    Out-File -FilePath c:\tools\v213988.log -Append -InputObject "Administrators: `n $($users | out-string)"

    [Array]$approvedUsers='wes_admin'
    Out-File -FilePath c:\tools\v213988.log -Append -InputObject "approvedUsers: `n $($approvedUsers | out-string)"

    $users | ForEach-Object {
        if ($PSitem.Name -notin $approvedUsers) {$checkFailed = $true; $unapprovedUsers += $PSitem.Name}
    }

    Out-File -FilePath c:\tools\v213988.log -Append -InputObject "unapprovedUsers: `n $($unapprovedUsers | out-string)"

    if ($checkFailed) {
        # $obj = [PSCustomObject]@{
        #     Results="The Check Failed. The following users are not approved IAW system documentation:`n$($unapprovedUsers | Out-String)"
        #     Valid=$false
        # }
        # Out-File -FilePath c:\tools\v213988.log -Append -InputObject $($obj | fl)

        return [PSCustomObject]@{
            Results=$("The Check Failed. The following users are not approved IAW system documentation:`n$($unapprovedUsers | Out-String)")
            Valid=$false
        }
    }

    return $true
}
Catch {
    $_.Exception
}
