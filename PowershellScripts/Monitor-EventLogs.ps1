# Title:   Monitor-EventLogs.ps1
# Version: 1.0.0, 05 MAR 2023
# Author:  Wes Wilson
# Purpose: Monitor the event logs and automatically archive and clear the log if it's over 100 MB in size.
# Set the archive location
<#
- If the xxxx event log is under 100 MB, an informational event is written to the Application event log
- If the log is over 100 MB
    - The log is archived to \\192.168.1.4\NAS03\EventLogs
    - If the archive operation fails, an error event is written to the Application event log and an e-mail is sent
    - If the archive operation succeeds, an informational event is written to the Application event log and an e-mail is sent

- Before using the script in your environment, configure the following variables:

    $ArchiveSize - Set to desired log size limit (MB)
    $ArchiveFolder - Set to an existing path where you want the log file archives to go
    $mailMsgServer - Set to a valid SMTP server
    $mailMsgFrom - Set to a valid FROM e-mail address
    $MailMsgTo - Set to a valid TO e-mail address
#>

[CmdletBinding()]
Param(
[Parameter(ValueFromPipeline=$true)] [string]$email_username,
[Parameter(ValueFromPipeline=$true)] [string]$email_password,
[Parameter(ValueFromPipeline=$true)] [int32]$maxLogSizeMB=100
)
     
$ArchiveFolder = "\\192.168.1.4\NAS03\EventLogs\$env:computername"

# How big can the security event log get in MB before we automatically archive?
$ArchiveSize = $maxLogSizeMB #250

# ------------------------------------------------------ 
# SMTP configuration: username, password, SSL and so on
# ------------------------------------------------------
if ($email_username -eq $null -and $email_password -eq $null) 
{ 
    $email_cred = Import-Clixml -Path \\192.168.1.4\NAS01\Scripts\Credentials\homelab@mydomain.local_cred.xml
    $email_username = $email_cred.UserName;
    $email_password = $email_cred.GetNetworkCredential().Password;
}
$email_smtp_host = "awm17x.mydomain.local";
$email_smtp_port = 587;
$email_smtp_SSL = 0;
$email_from_address = "eventLogMonitor@mydomain.local";
$email_to_addressArray = @("wes_admin@mydomain.local");

# ------------------------------------------------------ 
# E-Mail message configuration: from, to, subject, body
# ------------------------------------------------------ 
$message = new-object Net.Mail.MailMessage;
$message.From = $email_from_address;
foreach ($to in $email_to_addressArray) {
    $message.To.Add($to);
}

# ------------------------------------------------------ 
# Create SmtpClient object
# ------------------------------------------------------ 
$smtp = new-object Net.Mail.SmtpClient($email_smtp_host, $email_smtp_port);
$smtp.EnableSSL = $email_smtp_SSL;
$smtp.Credentials = New-Object System.Net.NetworkCredential($email_username, $email_password);

# Configure environment
$sysName        = $env:computername

# Check the event log
$Logs = Get-WmiObject Win32_NTEventLogFile #-Filter "logfilename = 'security'"
foreach ($Log in $Logs)
{
    # Configure log specific environment
    $logFileName = $Log.LogFileName
    $eventName      = "$logFileName Event Log Monitoring"

    # Add event source to application log if necessary 
    If (-NOT ([System.Diagnostics.EventLog]::SourceExists($eventName))) { 
        New-EventLog -LogName Application -Source $eventName
    } 

    $message.Subject = "$sysName $eventName"

    $SizeCurrentMB = [math]::Round($Log.FileSize / 1024 / 1024,2)
    $SizeMaximumMB = [math]::Round($Log.MaxFileSize / 1024 / 1024,2)
    Write-Host

    # Verify the archive folder exists
    If (!(Test-Path "$ArchiveFolder\$logFileName")) {
        Write-Host
        Write-Host "Archive folder $ArchiveFolder\$logFileName does not exist, adding directory ..." -ForegroundColor Red
        New-Item "$ArchiveFolder\$logFileName" -ItemType Directory
        #Exit
    }
    
    # Archive the event log if over the limit
    If ($SizeCurrentMB -gt $ArchiveSize) {
        $ArchiveFile = "$ArchiveFolder\$logFileName-" + (Get-Date -Format "yyyy-MM-dd@HHmm") + ".evt"
        $EventMessage = "The $logFileName event log size is currently " + $SizeCurrentMB + " MB.  The maximum allowable size is " + $SizeMaximumMB + " MB.  The security event log size has exceeded the threshold of $ArchiveSize MB."
        $Results = ($Log.BackupEventlog($ArchiveFile)).ReturnValue
        If ($Results -eq 0) {
        # Successful backup of security event log
        $Results = ($Log.ClearEventlog()).ReturnValue
        $EventMessage += "The $logFileName event log was successfully archived to $ArchiveFile and cleared."
        Write-Host $EventMessage
        Write-EventLog -LogName Application -Source $eventName -EventId 11 -EntryType Information -Message $eventMessage -Category 0
        
        # ------------------------------------------------------ 
        # Send the e-mail message
        # ------------------------------------------------------ 
        $message.Body = $EventMessage
        $smtp.send($message);
        $message.Dispose();
                }
        Else {
        $EventMessage += "The $logFileName event log could not be archived to $ArchiveFile and was not cleared.  Review and resolve security event log issues on $sysName ASAP!"
        Write-Host $EventMessage
        Write-EventLog -LogName Application -Source $eventName -EventId 11 -EntryType Error -Message $eventMessage -Category 0
        
        # ------------------------------------------------------ 
        # Send the e-mail message
        # ------------------------------------------------------ 
        $message.Body = $EventMessage
        $smtp.send($message);
        $message.Dispose();
        }
    }
    Else {
        # Write an informational event to the application event log
        $EventMessage = "The $logFileName event log size is currently " + $SizeCurrentMB + " MB.  The maximum allowable size is " + $SizeMaximumMB + " MB.  The security event log size is below the threshold of $ArchiveSize MB so no action was taken."
        Write-Host $EventMessage
        Write-EventLog -LogName Application -Source $eventName -EventId 11 -EntryType Information -Message $eventMessage -Category 0
    }
    # Close the log
    $Log.Dispose()
}
