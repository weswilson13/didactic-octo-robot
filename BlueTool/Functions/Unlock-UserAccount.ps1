function Unlock-UserAccount {
    <#
    .SYNOPSIS
    Unlocks a users account.
    
    .DESCRIPTION
    Unlocks a users account.
    #>
    [System.ComponentModel.DisplayName("Unlock Account")]
    param(
        # user principal
        [Parameter(Mandatory=$true)]
        [Microsoft.ActiveDirectory.Management.ADAccount]
        $Identity
    )
    
    try {
        $Identity | Unlock-ADAccount
    }
    catch {
        throw $error[0]
    }
}