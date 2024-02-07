$results = invoke-sqlcmd -ServerInstance "sq02,9999" -database Computers -query "Select * from tblComputers" | 
Select-Object SerialNumber,	OS,	ClientOrServer,	BIOSVersion,	BIOSManufacturer,	HostName,	Domain,	Manufacturer,	Model,	TotalMemory,	OSArchitecture 

$html = $results | ConvertTo-Html | Out-String
$html = $html -replace '</head>', '</head>
<style>
table, th, td {
  border: 1px solid black;
  border-collapse: collapse;
}

tr:hover {}

tr:nth-child(even) {
  background-color: #D6EEEE;
}
</style>'
$html = $html.replace('<table>', '<table style=width:100%>')

$creds = Import-Clixml -Path "\\raspberrypi4-1\nas01\scripts\Credentials\homelab@mydomain.local_cred.xml"
$credentials = New-Object -TypeName pscredential($creds.username, $creds.Password)
$messageAttr = @{
    SmtpServer = "awm17x.mydomain.local"
    From = "wes_admin@mydomain.local"
    To = "poweredge.t320.server@gmail.com"
    Subject = "Test HTML Message"
    Body = $html
    BodyAsHtml = $true
    Credential=$credentials
    ErrorAction = "Stop"
}
Send-MailMessage @messageAttr