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
function Check-Module {
    param (
        [string]$ComputerName
    )
    if ($ComputerName) { Enter-PSSession $ComputerName }
    $Z="\\OptimusPrime\Z\WindowsPowershell"
    if (!(Get-Module -Name Invoke-CommandAs)) { Import-Module -Name $Z\Modules\Invoke-CommandAs }
    if ($ComputerName) { Exit-PSSession $ComputerName }
}

$scriptblock = {   
    $this | out-string | Write-Host  
    Get-InstalledSoftware -ComputerName $this.ComputerName -Software $this.BaseProduct | Foreach-Object {
        if ((Read-Host "Uninstall $($PSItem.DisplayName)? (y/n)") -eq 'y') {
            switch -Regex ($PSItem.UninstallString) {
                'msiexec' { 
                    $arg = "$($PSItem -replace 'msiexec.exe /(I|X) *{', '/X {') /qn /L*V `"c:\tools\log.log`""
                    Write-Host $arg
                    Invoke-CommandAs -AsSystem -ScriptBlock { Start-Process msiexec -ArgumentList $Args[0] -Wait } -ArgumentList $arg -ComputerName $this.ComputerName 
                    break
                }
                'C:\\' {
                    $exe = ($PSItem | Select-String -Pattern '".*"').Matches.Value.trim()
                    write-host $exe
                    $arg = "$($PSItem.Replace($exe,'').trim()) --force-uninstall"
                    Write-Host $arg 
                    Invoke-CommandAs -AsSystem -ScriptBlock { Start-Process $Args[0] -ArgumentList $Args[1] -Wait } -ArgumentList $exe,$arg -ComputerName $this.ComputerName
                    break
                }
                {[string]::IsNullOrWhiteSpace($PSItem)} {Write-Host "No Uninstall String available."; break}
            }
        }
    }
}

[psobject]$test=@{
    ComputerName='LindsPC'
    BaseProduct='Microsoft Edge'}
$test | add-member -MemberType ScriptMethod -Name Uninstall -Value $scriptblock -PassThru
