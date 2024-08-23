function Set-NTKGroups {
    Param(
        # AD User
        [Parameter(Mandatory=$true)]
        [Microsoft.ActiveDirectory.Management.ADAccount]
        $ADUser
        ,
        # NTK Group
        [Parameter(Mandatory=$false)]
        [ValidateSet('None','NonNuclearTrained','NuclearTrained','InformationSecurityDepartment','PhysicalSecurity','SeniorStaff')]
        [string[]]$NTKAssignment = 'None'
        ,
        # Helper User
        [Parameter(Mandatory=$false)]
        [switch]
        $StudentHelper
        ,
        # Exam User
        [Parameter(Mandatory = $false)]
        [switch]
        $ExamUser
    )

    begin {
        $allUsersGroups = @("NPTC-GEN","NNPTC-Users","Users.NNPTC.All")
    }

    process {
        try {
            $NTKAssignment | ForEach-Object {
                $groups = switch ($PSItem) {
                    {$PSItem -in @('None','NonNuclearTrained','PhysicalSecurity')} { $allUsersGroups }
                    {$PSItem -in @('NuclearTrained','SeniorStaff')} { $allUsersGroups + @("NPTC-REC","NPTC-REP","NPTC-SEP","NPTC-TRA","NUCS") }
                    'InformationSecurityDepartment' { $allUsersGroups + @("ISD") }
                    default { throw }
                }

                if ($StudentHelper) { $groups += "Helpers"}
                if ($ExamUser) { $groups += "Exam Writers"}

                foreach ($group in $groups) {
                    Write-Host "Adding $($ADUser.SamAccountName) to $group"
                    Get-ADGroup $group | Add-ADGroupMember -Members $ADUser -Confirm:$false
                    Write-Log -Message "Added $($ADUser.SamAccountName) to $group" -Severity Information
                }
            }
        }
        catch {
            throw $error[0]
        }
    }
}