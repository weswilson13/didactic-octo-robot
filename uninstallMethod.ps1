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
            $uninstallCommand=switch -Regex ($PSItem.UninstallString) {
                'msiexec' {$($PSItem -replace "/(I|X) *{","/X `"{" -replace "}$","}`""); break}
                'C:\\' {"$($PSItem) --silent"; break}
                {[string]::IsNullOrWhiteSpace($PSItem)} {Write-Host "No Uninstall String available."; break}
            }
            Write-Host $uninstallCommand
            Invoke-Command -ScriptBlock {cmd.exe /c "$uninstallCommand"} -ComputerName $ComputerName 
        }
    }
}

[psobject]$test=@{Name='Test'}
$test | add-member -MemberType ScriptMethod -Name Uninstall -Value $scriptblock -PassThru
