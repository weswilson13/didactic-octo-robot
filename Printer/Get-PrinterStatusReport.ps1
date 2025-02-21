function New-HtmlTable {
    param(
        [Parameter(ValueFromPipeline=$true)]
        [object]$InputObject,

        [string]$TableTitle,

        [ValidateSet('good','bad')]
        [string]$TableClass
    )

    # $htmlPreContent = "<div class=""table-container"">"
    # $htmlPostContent = "</div>"
    $params = @{}
    if ($TableClass -eq 'good') {
        $params = @{
            Property = 'PrinterName', 'PortName', 'CertificateSubject', 'Issuer', 'Expiry'
         }
    }
    $html = $InputObject | ConvertTo-Html @params -Fragment #-PreContent $htmlPreContent -PostContent $htmlPostContent
    $columns = $InputObject | Get-Member -MemberType Properties
    if ($columns) {
        $columns = $columns.Count
    }

    $tableTitle = New-TableTitle -Title $TableTitle -Columns $columns -Class $TableClass
    
    return $html.Replace('<table>', $tableTitle)
}
function New-TableTitle {
    param (
        [string]$Title,
        [int]$Columns,
        [string]$Class
    )

    if ($Class) {
        return "<table><tr><th class=""$Class"" colspan=""$Columns"">$Title</th></tr>"
    }
    else {
        return "<table><tr><th colspan=""$Columns"">$Title</th></tr>"
    }
}
function Get-PtrRecordName {
    param(
        [string]$IPAddress
    )

    $octets = $IPAddress.split('.')

    if ($octets.Count -eq 4) {
        return "{3}.{2}.{1}" -f $octets
    }
    else {
        throw "Could not parse $IPAddress. Make sure this is a valid IP Address."
    }
}
function Send-UpdateMessage {
    # configure and send a mail message
    $creds = switch -regex ($env:USERNAME) {
        'wes_admin' { Import-Clixml -Path "Z:\Scripts\Credentials\poweredge.t320.server@gmail.com_cred.xml" }
        'svc-SchTasks-RE' { Import-Clixml -Path "Z:\Scripts\Credentials\poweredge.t320.server@gmail.com_cred_svc-SchTasks_RE`$.xml" }
    }
    $credentials = New-Object -TypeName pscredential($creds.username, $creds.Password)
    
    $messageAttr = @{
        SmtpServer = 'smtp.gmail.com'
        Port = 587
        UseSsl = $true
        From = "poweredge.t320.server@gmail.com"
        To = "wesley.s.wilson.ctr@gmail.com"
        Subject = "Printer Config Errors"
        Body = $htmlOutput
        BodyAsHtml = $true
        Credential = $credentials
        ErrorAction = "Stop"
    }
    Send-MailMessage @messageAttr -
}

$csv = "Z:\Temp\PrinterStatus.csv"
$printerStatus = Import-Csv $csv

# establish the different groups
$badCertificateCN = @()
$bad8021xUserName = @()
$badNetworkIdHostName = @()
$badDnsPtrRecord = @()
$badDnsARecord = @()
$bad8021x =@()

# table titles
$badDnsPtrRecordTitle = "Incorrect DNS 'PTR' Records"
$badDnsARecordTitle = "Incorrect DNS 'A' Records"
$badNetworkIdHostNameTitle = "Incorrect Network ID HostName"
$bad8021xUserNameTitle = "Incorrect 802.1x UserName"
$badCertificateCNTitle = "Incorrect SSL Certificate"
$bad8021xTitle = "802.1x Not Enabled"

foreach ($obj in $printerStatus) {
    # Check Printer Name against DNS Records
    if ($obj.ReverseLookupByPortName -ne $obj.PrinterName) { # PTR for the PortName is incorrect 
        $badDnsPtrRecord += [pscustomobject]@{
            PrinterName = $obj.PrinterName
            IP = $obj.PortName
            PtrRecordName = Get-PtrRecordName $obj.PortName
            PtrRecordData = $obj.ReverseLookupByPortName
        } 
    }

    if ($obj.ReverseLookupByIPAddress -ne $obj.PrinterName) { 
        $badDnsPtrRecord += [pscustomobject]@{
            PrinterName = $obj.PrinterName
            IP = $obj.IPAddress
            PtrRecordName = Get-PtrRecordName $obj.IPAddress
            PtrRecordData = $obj.ReverseLookupByIPAddress
        } 
     }

    # Check printer Port Name against DNS
    if ($obj.IPAddress -ne $obj.PortName) {
        $badDnsARecord += [pscustomobject]@{
            PrinterName = $obj.PrinterName
            PortName = $obj.PortName
            IP = $obj.IPAddress
        }
    }

    # Check 802.1x username against PrinterName
    if ($obj.'802.1x_UserName' -ne $obj.PrinterName) {
        $bad8021xUserName += [pscustomobject]@{
            PrinterName = $obj.PrinterName
            '802.1xUserName' = $obj.'802.1x_UserName'
        }
    }

    # Check network hostname against PrinterName
    if ($obj.NetworkID_HostName -ne $obj.PrinterName) {
        $badNetworkIdHostName += [pscustomobject]@{
            PrinterName = $obj.PrinterName
            NetworkIDHostName = $obj.NetworkID_HostName
        }
    }

    # check if 802.1x is enabled
    if ($obj.'802.1x_Enabled'.Trim() -eq 'FALSE') {
        $bad8021x += [pscustomobject]@{
            PrinterName = $obj.PrinterName
            '802.1x_Enabled' = $obj.'802.1x_Enabled'
        }
    }
}

$htmlOutput = @"
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Printer Status</title>
    <style>
        header {
            background-color: darkblue;
            color: white;
            padding: 0px;
            text-align: center;
			border: 1px solid white;
            width: 95%;
        }

        body {
			font-family: Arial, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            flex-direction: column;
            margin: 0;
            /* width: 95%; */
        }

        .table-container {
            display: grid;
            grid-template-columns: repeat(2, auto);
            gap: 20px;
            width: 95%
        }

        .table-container#satPrinters {
            display: grid;
            grid-template-columns: repeat(1, auto);
            gap: 20px;
            width: 95%
        }

        table, th, td {
            border: 1px solid black;
        }

        th {
            height: 40px;
			font-size: 20px;
            background-color: darkblue; 
            color:aliceblue;
        }
		
        th.bad {
            background-color: crimson
        }

        th.good {
            background-color: green
        }

		td.eventId {
			width: 100px;
		}
    </style>
</head>
<body>
    <header>
        <h1>Printer Status</h1>
    </header>
    <div class="table-container">
"@

$badDnsPtrRecordHtml = New-HtmlTable -InputObject $badDnsPtrRecord -TableTitle $badDnsPtrRecordTitle -TableClass bad
$badDnsARecordHtml = New-HtmlTable -InputObject $badDnsARecord -TableTitle $badDnsARecordTitle -TableClass bad
$badNetworkIdHostNameHtml = New-HtmlTable -InputObject $badNetworkIdHostName -TableTitle $badNetworkIdHostNameTitle -TableClass bad
$bad8021xUserNameHtml = New-HtmlTable -InputObject $bad8021xUserName -TableTitle $bad8021xUserNameTitle -TableClass bad
$badCertificateCNHtml = New-HtmlTable -InputObject $badCertificateCN -TableTitle $badCertificateCNTitle -TableClass bad
$bad8021xHtml = New-HtmlTable -InputObject $bad8021x -TableTitle $bad8021xTitle -TableClass bad

$badPrinters = @()

foreach ($var in (Get-Variable -Name bad*)) {
    if ($var.Name -notmatch 'Html|Title') {
        $badPrinters += ($var.Value).PrinterName
        if ($var.Value) { 
            $_var = "$($var.Name)Html"
            $htmlOutput += (Get-Variable -Name $_var).Value
        }
    }
}

$goodPrinters = $printerStatus | Where-Object {$_.PrinterName -notin $badPrinters} | Sort-Object PrinterName -Unique
$goodPrintersHtml = New-HtmlTable -InputObject $goodPrinters -TableTitle "SAT Printers" -TableClass good

$htmlOutput += 
@"
        </div>
"@

if ($htmlOutput) { Send-UpdateMessage }

$htmlOutput += 
@"
        </br>
        <div class="table-container" id="satPrinters">
"@
$htmlOutput += $goodPrintersHtml

$htmlOutput += @"
        </div>
    </body>
</head>
</html>
"@

$htmlOutput | Out-File .\PrinterStatus.html