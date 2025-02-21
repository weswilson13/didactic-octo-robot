function New-HtmlTable {
    param(
        [Parameter(ValueFromPipeline=$true)]
        [object]$InputObject,

        [string]$TableTitle,

        [ValidateSet('good','bad')]
        [string]$TableClass
    )

    $htmlPreContent = "<div class=""table-container"">"
    $htmlPostContent = "</div>"

    $html = $InputObject | ConvertTo-Html -Fragment -PreContent $htmlPreContent -PostContent $htmlPostContent
    $columns = ($InputObject | gm -MemberType Properties).Count
    $tableTitle = New-TableTitle -Title $TableTitle -Columns $columns -Class bad
    
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

$csv = "Z:\Temp\PrinterStatus.csv"
$printerStatus = Import-Csv $csv

# establish the different groups
$badCertificateCN = @()
$bad8021xUserName = @()
$badNetworkIdHostName = @()
$badDnsPtrRecord = @()
$badDnsARecord = @()

# table titles
$badDnsPtrRecordTitle = "Incorrect DNS 'PTR' Records"
$badDnsARecordTitle = "Incorrect DNS 'A' Records"

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
}

$htmlOutput = @"
<html>
<head>
    <meta charset=""UTF-8"">
    <meta name=""viewport"" content=""width=device-width, initial-scale=1.0"">
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

        .table-container#GroupChanges {
            display: grid;
            grid-template-columns: repeat(1, auto);
            gap: 20px;
            /* width: 100%; */
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
"@

$badDnsPtrRecordHtml = New-HtmlTable -InputObject $badDnsPtrRecord -TableTitle $badDnsPtrRecordTitle -TableClass bad

$badDnsARecordHtml = New-HtmlTable -InputObject $badDnsARecord -TableTitle $badDnsARecordTitle -TableClass bad

$htmlOutput += $badDnsPtrRecordHtml
$htmlOutput += "</br>"
$htmlOutput += $badDnsARecordHtml 

$htmlOutput += @"
    </body>
</head>
</html>
"@

$htmlOutput | Out-File .\PrinterStatus.html