Start-Transcript -Path \\192.168.1.4\NAS01\Scripts\ScriptLogs\RemoveTempFilesLog_$env:COMPUTERNAME.Log
    @($env:TEMP, 'C:\Windows\Temp', 'C:\Windows\Prefetch').Foreach({Write-Output "Clearing $_"; Remove-Item -Path $_ -Recurse -ErrorAction Continue <#SilentlyContinue#>})
Stop-Transcript