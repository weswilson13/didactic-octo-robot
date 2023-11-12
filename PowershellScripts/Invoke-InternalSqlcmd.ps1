function Invoke-InternalSqlcmd {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][string] $ServerInstance,
        [Parameter(Mandatory=$true)][string] $Query,
        [Parameter(Mandatory=$true)][string] $Database,
        [Parameter(Mandatory=$false)][System.Management.Automation.PSCredential] $Credential
    )

    if (-not $Credential) {
        return Invoke-SqlCmd -ServerInstance $ServerInstance -Query $Query -Database $Database
    }
    else {
        $ScriptBlock = {
            param($ServerInstance, $Query,$Database) 
            $ErrorActionPreference = 'Stop';

            return @{ Result = Invoke-SqlCmd -ServerInstance $ServerInstance -Query $Query -Database $Database }
        }

        $Job = Start-Job -Credential $Credential -ScriptBlock $ScriptBlock -ArgumentList $ServerInstance,$Query,$Database
        $JobResult = Wait-Job $Job;

        if ($JobResult.State -eq 'Completed') {
            return (Receive-Job $Job).Result
        }

        throw [Exception]::new("Error occurred while executing sql as $($Credential.UserName) $([System.Environment]::NewLine)$($JobResult.ChildJobs[0].JobStateInfo.Reason)", $JobResult.ChildJobs[0].JobStateInfo.Reason)
    }
}