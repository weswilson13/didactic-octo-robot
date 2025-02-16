# skip SSL-Validation for websocket communication:
Add-Type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# Define the URL for the login page and the URL to the secure area
$loginUrl = "https://192.168.0.141/home/status.html"
$secureUrl = "https://192.168.0.141/net/security/certificate/certificate.html"

# Define the credentials
$username = "wesley.wilson@unnpp.gov"
$password = 'Ud3my12e$'

# Create a session variable to maintain the login session
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession

# Prepare the login form data
$formData = @{
    loginurl = '/home/status.html'
    B1887 = 'ced8fwr-HDX*ycm4zbu'
}

# Send the login request
$response = Invoke-WebRequest -Uri $loginUrl -Method Post -Body $formData -WebSession $session

# Check if login was successful (e.g., by looking for a specific element in the response)
if ($response.StatusCode -eq "200") {
    Write-Host "Login successful!"

    # Access the secure area
    $secureResponse = Invoke-WebRequest -Uri $secureUrl -WebSession $session
    $secureResponse.Links

    Write-Host "Secure area content:"
    Write-Output $secureResponse.Content
} else {
    Write-Host "Login failed!"
}
