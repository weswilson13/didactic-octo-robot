﻿function Get-InactiveUsers {
    <#
    .SYNOPSIS
    Gets a list of inactive users.
    
    .DESCRIPTION
    Gets a list of inactive users.
    #>
    [System.ComponentModel.DisplayName("Inactive Users")]
    param()
    $When = ((Get-Date).AddDays(-30)).Date
    Get-ADUser -Filter { LastLogonDate -lt $When } -Properties * | 
        Select-Object SamAccountName, DistinguishedName, LastLogonDate
}