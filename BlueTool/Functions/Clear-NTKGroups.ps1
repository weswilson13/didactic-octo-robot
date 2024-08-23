function Remove-NTKGroups {
    Param(
        # AD User
        [Parameter(Mandatory=$true)]
        [Microsoft.ActiveDirectory.Management.ADAccount]
        $ADUser
    )
    try {
        Write-Host "Clearing NTK Groups"
        Get-ADGroup -Filter 'CN -like "NPTC*" -or CN -eq "NUCS" -or CN -eq "ISD"' | Remove-ADGroupMember -Members $ADUser -Confirm:$false
    }
    catch {
        throw $error[0]
    }
}