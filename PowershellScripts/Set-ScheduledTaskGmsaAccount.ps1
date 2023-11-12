param (
    [Parameter(Mandatory=$true)]
    [string] $gMSAname,
    [Parameter(Mandatory=$true)]
    [string] $Taskname
)

Function Set-ScheduledTaskGmsaAccount () {

<#

.SYNOPSIS
Change account to Group Managed Service Account for scheduled task

.DESCRIPTION
Change account to Group Managed Service Account for scheduled task

.PARAMETER gMSAname
Name of group managed service account

.PARAMETER TaskName
Name of scheduled task

.EXAMPLE 
Set-ScheduledTaskGmsaAccount -gMSAname 'gmsa-server01' -Taskname 'My scheduled task'

.FUNCTIONALITY
    Change account to Group Managed Service Account for scheduled task

.NOTES
    Author:  Rickard Warfvinge <rickard.warfvinge@gmail.com>
    Purpose: Change scheduled task to use group managed service account instead of regular service account or user account
#>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string] $gMSAname,
        [Parameter(Mandatory=$true)]
        [string] $Taskname
        
    )

    If (-Not($gMSAname.EndsWith('$'))) {$gMSAname = $gMSAname + '$'} # If no trailing $ character in gMSA name, add $ sign
    Write-Host $gMSAname
    # Test gMSA account and get scheduled task
    Try {

    Test-ADServiceAccount -Identity $gMSAname -ErrorAction Stop
    $Task = Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop

    }

    Catch {Write-Warning $($_.Exception.Message);Break}

    # Change user account to gMSA for scheduled task
    $domain = $env:USERDNSDOMAIN -replace '\..+$'
    $Principal = New-ScheduledTaskPrincipal -UserID "$domain\$gMSAname" -LogonType Password -RunLevel Highest
    Write-Host $Principal
    Try {Set-ScheduledTask - $Task -Principal $Principal -ErrorAction Stop}
    Catch {Write-Warning $($_.Exception.Message);Break}
}


Set-ScheduledTaskGmsaAccount -gMSAname $gMSAname -Taskname $Taskname