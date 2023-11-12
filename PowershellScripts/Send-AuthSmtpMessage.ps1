    param(
        [CmdletBinding()]
        [Parameter(Mandatory=$true,
                  ValueFromPipeline = $true)]
                  [string]$username,

        [securestring]$password,

        [string]$smtpServer = "awm17x.mydomain.local",

        [int]$smtpPort = 587,

        [int]$smtpSSL = 0,

        [Parameter(Mandatory=$true,
                  ValueFromPipeline = $true)]
                  [string]$subject,

        [string]$from = "wes_admin@mydomain.local",

        [string]$to = "poweredge.t320.server@gmail.com",

        [Parameter(Mandatory=$true,
                  ValueFromPipeline = $true)]
                  [string]$body,

        [string]$attachment
    )

    # ------------------------------------------------------ 
    # E-Mail message configuration: from, to, subject, body
    # ------------------------------------------------------ 
    $message = [System.Net.Mail.MailMessage]::new() #New-Object System.Net.Mail.MailMessage;
    $message.From = $from;
    foreach ($recipient in $to) {
        $message.To.Add($recipient);
    }
    $message.Subject = $subject;
    $message.Body = $body;
    if ($attachment -ne '') {$message.Attachments.Add($attachment);}

    # ------------------------------------------------------ 
    # Create SmtpClient object and send the e-mail message
    # ------------------------------------------------------ 
    $smtp = new-object System.Net.Mail.SmtpClient($smtpServer, $smtpPort);
    $smtp.EnableSSL = $smtpSSL;
    $smtp.Credentials = New-Object -TypeName pscredential($username, $password)
    $smtp.send($message.From, $message.To, $message.Subject, $message.Body)
    #$smtp.Send($message);
    $message.Dispose();

   -join ($message.From, $message.To, $message.Subject, $message.Body, $message.Attachments.Count, $smtpServer, $smtpPort, $smtpSSL), ', ' | Out-File \\192.168.1.4\nas01\Scripts\ScriptLogs\email_attr.txt -Encoding ascii
