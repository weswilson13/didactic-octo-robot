function Set-AccountPassword {
    <#
    .SYNOPSIS
    Resets a users password.
    
    .DESCRIPTION
    Resets a users password.
    #>
    [System.ComponentModel.DisplayName("Reset User Password")]
    param(
        # user principal
        [Parameter(Mandatory=$true)]
        [Microsoft.ActiveDirectory.Management.ADAccount]
        $Identity
        ,
        # new password
        [Parameter(Mandatory=$true)]
        [securestring]
        $NewPassword
    )
    
    try {
        $Identity | Set-ADAccountPassword -Reset -NewPassword $NewPassword
    }
    catch {
        throw $error[0]
    }
}