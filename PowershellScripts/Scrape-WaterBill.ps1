# Do your first request to obtain the login form and start maintaining one session
$baseUri = 'https://bill.charlestonwater.com'
$loginResponse = Invoke-WebRequest -Uri $baseUri -SessionVariable mySession

# Fill out your login form
$loginForm = $loginResponse.Forms[0]
$loginForm.Fields["UserName"] = "lpruitt87"
$loginForm.Fields["Password"] = "whatever"

# Use the URI defined in the action of your form to send your request to while maintaining your session
$summaryResponse = Invoke-WebRequest -Uri ($baseUri + $loginForm.Action) -Body $loginForm.Fields -WebSession $mySession -Method POST

#$billUri = "https://bill.charlestonwater.com/Bill/History"
#$billResponse = Invoke-WebRequest -Uri $billUri -WebSession $mySession

$html = New-Object -ComObject "HTMLFile"
$src = $summaryResponse.ParsedHtml.getElementById('accountdetailINCLUDE') | select -ExpandProperty outerHTML
#$src = $billResponse.Content
$src = [System.Text.Encoding]::Unicode.GetBytes($src)

$html.IHTMLDocument2_write($src)

#$keys = $html.getElementsByTagName('div') | ? {$_.classname -eq 'col-md-3'}
$values = ($html.getElementsByTagName('div') | ? {$_.classname -eq 'col-md-6'}).innerText

[PSCustomObject]@{
    AccountNumber = $values[0]
    ServiceAddress = $values[1]
    BillingAddress = $values[2]
    LastPaymentDue = $values[3]
    TotalAmountDue = $values[4]
    BillingPreference = $values[5]
}

$billingHistory = Invoke-WebRequest -Uri https://bill.charlestonwater.com/Bill/History -WebSession $mySession 
[System.Collections.ArrayList]$a = $billingHistory.ParsedHtml.getElementsByTagName('div') | ? {$_.classname -eq 'col-md-6'} | select innerText