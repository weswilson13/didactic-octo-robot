Function Get-AllInstances {
    # Generate list of valid instances.  Exclude SQL Server 2014 Express edition.
    $ValidInstances = New-Object System.Collections.Generic.List[System.Object]
    $KeysToCheck = @("HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server", "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Microsoft SQL Server")
    ForEach ($Key in $KeysToCheck) {
        $Instances = (Get-ItemProperty $Key).InstalledInstances
        ForEach ($Instance in $Instances) {
            $p = (Get-ItemProperty "$($Key)\Instance Names\SQL").$Instance
            $Edition = (Get-ItemProperty "$($Key)\$($p)\Setup").Edition
            $Version = [Version](Get-ItemProperty "$($Key)\$($p)\Setup").Version
            If (-Not($Version -like "12.0*" -and $Edition -like "*Express*")) {
                $NewObj = [PSCustomObject]@{
                    InstanceName = $Instance
                    Edition      = $Edition
                    Version      = $Version
                }
                $ValidInstances.Add($NewObj)
            }
        }
    }

    # Get instance names and service status
    $allInstances = New-Object System.Collections.Generic.List[System.Object]
    $KeysToCheck = @("HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL", "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Microsoft SQL Server\Instance Names\SQL")
    ForEach ($Key in $KeysToCheck) {
        If (Test-Path $Key) {
            (Get-Item $Key).GetValuenames() | Where-Object { $_ -notlike '*#*' } | ForEach-Object {
                If ($_ -in $ValidInstances.InstanceName) {
                    # Grab the version from the array built earlier...
                    $tmpVersion = ($ValidInstances | Where-Object InstanceName -EQ $_).Version

                    # Determine the server Name
                    $tsname = (Get-Item $Key).GetValue($_)
                    If ($Key -like "*WOW6432Node*") {
                        If (Test-Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Microsoft SQL Server\$tsname\cluster") {
                            $cname = (Get-Item "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Microsoft SQL Server\$tsname\cluster").GetValue('ClusterName')
                        }
                        Else {
                            $cname = $env:computername
                        }
                    }
                    Else {
                        If (Test-Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$tsname\cluster") {
                            $cname = (Get-Item "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$tsname\cluster").GetValue('ClusterName')
                        }
                        Else {
                            $cname = $env:computername
                        }
                    }

                    # Determine the Windows Service Name and Status...
                    If ($_ -eq 'MSSQLSERVER') {
                        $tmpServiceName = 'MSSQLSERVER'
                        $tmpInstanceName = $cname
                    }
                    else {
                        $tmpServiceName = "mssql`$$_"
                        $tmpInstanceName = "$cname\$_"
                    }
                    $oService = Get-Service $tmpServiceName -ErrorAction SilentlyContinue
                    if ($oService) {
                        $tmpStatus = $oService.Status
                    }
                    else {
                        $tmpServiceName = "NotFound"
                        $tmpStatus = 'NA'
                    }

                    $NewObj = [PSCustomObject]@{
                        Name    = $tmpInstanceName
                        Service = $tmpServiceName
                        Status  = $tmpStatus
                        Version = $tmpVersion
                    }
                    $allInstances.Add($NewObj)
                }
            }
        }
    }
    Return $allInstances
}