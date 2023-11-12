param(
    [Parameter(Mandatory=$true)]
    [string[]] $ComputerName,

    [Parameter(Mandatory=$true)]
    [string] $Version
)

if (Test-Connection $ComputerName -Count 1 -Quiet) {
    $session = New-PSSession $ComputerName

    # these commands will be executed on the remote machine
    $scriptBlock = {
        # temporarily map to the location of the VMTools installer on the NAS 
        Start-Process cmd -ArgumentList "/c net use t: \\raspberrypi4-1\nas01\VMWare\Tools" -Wait
        cd t:

        # get the name of the installation file using the $Version input variable
        $tools = (Get-ChildItem . -name "*$($Args[0])*")

        # if c:\tools does not exist, create the directory
        If (-not(Test-Path c:\tools)) {
            New-Item c:\Tools -ItemType Directory
        }

        # copy the installer to local drive. this is key, otherwise the UAC will hold up the installation
        Robocopy.exe t:\ c:\tools $tools /NP /NJH /NJS
        Start-Sleep -Seconds 10

        # start the silent installation. Log to vmtools.log
        Start-Process "c:\tools\$tools" -ArgumentList '/s /v "/qn" /L*v "c:\tools\vmtools.log"' -Wait
    
        # clean up - remove the mapped location; remove the installer
        Start-Process cmd -ArgumentList "/c net use t: /delete"
        Remove-Item c:\tools\$tools

        # get the status of the installation from the log. Provide the feedback to the console. 
        $result = (Get-ChildItem c:\tools\vmtools.log -Recurse | Select-String -Pattern '(?<=success or error status: )\d+' -AllMatches).Matches.Value 
        if ($result -eq '0') {
            Write-Host Installation Success -ForegroundColor Green
        }
        else {
            Write-Host Installation Failed. Check logs for more information. -ForegroundColor Red
        }
    }

    # execute the scriptblock on the remote computer
    Invoke-Command -Session $session -ScriptBlock $scriptBlock -ArgumentList $Version

    Remove-PSSession $session
}
else {
    Write-Error $ComputerName not online
}