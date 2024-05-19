$results = invoke-sqlcmd -ServerInstance "sq02,9999" -database Computers -query "Select * from tblComputers" | 
Select-Object SerialNumber,	OS,	ClientOrServer,	BIOSVersion,	BIOSManufacturer,	HostName,	Domain,	Manufacturer,	Model,	TotalMemory,	OSArchitecture 

$html = $results | ConvertTo-Html -Fragment | Out-String
$html = $html -replace '<table>', '
<style>
table, th, td {
  border: 1px solid black;
  border-collapse: collapse;
}

tr:hover {}

tr:nth-child(even) {
  background-color: #D6EEEE;
}
</style>
<table>'
$html = $html.replace('<table>', '<table style=width:100%>')

$creds = Import-Clixml -Path "\\Optimusprime\Z\scripts\Credentials\homelab@mydomain.local_cred.xml"
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