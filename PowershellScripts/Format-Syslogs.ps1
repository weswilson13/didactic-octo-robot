$outputFilepath = '\\192.168.1.4\NAS01\Scripts\ScriptLogs\syslogOutput.csv'
if (Test-Path $outputFilepath) {
    Remove-Item $outputFilepath
}
$logFilePath = '\\192.168.1.10\c$\users\wes_admin\Documents\AX11000_Syslogs'

$logFiles = Get-ChildItem -Path "Microsoft.Powershell.Core\Filesystem::$logFilePath" | % {$_.Fullname}

Foreach($logFile in $logFiles) {
    $content = (Get-Content "Microsoft.Powershell.Core\Filesystem::$logFile") -replace '(?<=(\d{6,})) | (?=(\d{6,}))|(\[(\d+)\]): (?=<)|(?<=((\d{2}:){2}\d{2}))', "`t"
    $content | ConvertFrom-Csv -Delimiter "`t" -Header 'DateTime', 'Protocol\Port', 'AlertLevel', 'MsgID', 'Message' | Export-Csv -Path "Microsoft.Powershell.Core\Filesystem::$outputFilepath" -NoTypeInformation -Append
}