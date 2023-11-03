param(
    [Parameter(Mandatory=$false)]
    [string[]] $ComputerName='DC02',

    [Parameter(Mandatory=$false)]
    [string] $Version
)

if (Test-Connection $ComputerName -Count 1 -Quiet) {
    $session = New-PSSession $ComputerName

    # these commands will be executed on the remote machine
    $scriptBlock = {
        # temporarily map to the location of the VMTools installer on the NAS 
        Start-Process cmd -ArgumentList "/c net use t: \\raspberrypi4-1\nas01\cURL" -Wait
        cd t:

        # get the name of the installation file using the $Version input variable
        $tools = switch($Version -eq $null) {
            true {(Get-ChildItem . | select Name -ExpandProperty Name) | Select @{Name='File';Expression={$_.Name}}, @{Name='Build';Expression={(Select-String -InputObject $_ -Pattern '\d+\.\d+\.\d+_\d+' -AllMatches).Matches[0].Value}} | sort Build -Descending | select -ExpandProperty File -First 1
    }
            false {(Get-ChildItem . -name "*$($Args[0])*")}
        }

        # if c:\tools does not exist, create the directory
        If (-not(Test-Path c:\tools)) {
            New-Item c:\Tools -ItemType Directory
        }

        # copy the installer to local drive. this is key, otherwise the UAC will hold up the installation
        $test = Expand-Archive -Path t:\$tools -DestinationPath c:\tools -Force
        write-host $test
        $curl = Get-ChildItem c:\tools -Name 'curl.exe' -File -Recurse
        $curl = "c:\tools\$curl"
        Write-Host $curl

        $sysCurl = 'C:\Windows\System32\curl.exe'
        takeown /F $sysCurl /A
        ICACLS $sysCurl /grant administrators:F
        Copy-Item -Path $curl -Destination $sysCurl -Force
        
        $sysCurl = 'C:\Windows\SysWOW64\curl.exe'
        takeown /F $sysCurl /A
        ICACLS $sysCurl /grant administrators:F
        Copy-Item -Path $curl -Destination $sysCurl -Force

        # clean up - remove the mapped location; remove the installer
        Start-Process cmd -ArgumentList "/c net use t: /delete"
        Remove-Item -Path (Join-Path -Path 'c:\tools' -ChildPath (Get-ChildItem 'c:\tools' -name '*curl*' -Directory)) -Recurse -Force
    }

    # execute the scriptblock on the remote computer
    Invoke-Command -Session $session -ScriptBlock $scriptBlock -ArgumentList $Version

    Remove-PSSession $session
}
else {
    Write-Error $ComputerName not online
}