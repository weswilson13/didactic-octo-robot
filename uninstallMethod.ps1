function Get-InstalledSoftware {
    param(
        [string]$ComputerName,
        [string]$Software
    )

    $Apps=@()

    $scriptblock = {
        $paths="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"

        Get-ItemProperty -Path $paths | Where-Object {$_.DisplayName -match $using:Software} | Select-Object *
    }
    
    $Apps = Invoke-Command -ScriptBlock $scriptblock -ComputerName $ComputerName

    return $Apps
}

$scriptblock = { 
    param(
        [string]$ComputerName,
        [string]$Software
    ) 
    
    Get-InstalledSoftware -ComputerName $ComputerName -Software $software | Foreach-Object {
        if ((Read-Host "Uninstall $($PSItem.DisplayName)? (y/n)") -eq 'y') {
            switch -Regex ($PSItem.UninstallString) {
                'msiexec' { 
                    # $guid = ($PSItem | Select-String -Pattern '{.*}').Matches.Value 
                    # $arg = "/X `"$guid`" /qn /norestart /v*l `"c:\tools\log.log`""
                    $arg = "$PSItem /qn /L*V `"c:\tools\log.log`""
                    write-host $arg
                    $proc = Start-Process -Filepath \\OptimusPrime\Z\Microsoft\SysInternals\PsExec.exe -ArgumentList "\\$ComputerName -s", $arg -PassThru -Wait
                    $proc.WaitForExit()  
                    break
                }
                'C:\\' {
                    # $exe = ($PSItem | Select-String -Pattern '".*"').Matches.Value.trim()
                    # write-host $exe
                    $arg = $PSItem.trim()
                    write-host $arg
                    # $arg += " --silent"
                    $arg | Out-String | Write-Host
                    $proc = Start-Process -Filepath \\OptimusPrime\Z\Microsoft\SysInternals\PsExec.exe -ArgumentList "\\$ComputerName -s", $arg -PassThru -Wait
                    $proc.WaitForExit()
                    break
                }
                {[string]::IsNullOrWhiteSpace($PSItem)} {Write-Host "No Uninstall String available."; break}
            }
        }
    }
}

[psobject]$test=@{Name='Test'}
$test | add-member -MemberType ScriptMethod -Name Uninstall -Value $scriptblock -PassThru
