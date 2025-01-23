[CmdletBinding()]
param(
    # Secure string
    [Parameter(Mandatory=$true)]
    [string]$Password,

    # Output path
    [Parameter(Mandatory=$true)]
    [string]$Path
)
   
# generate a random salt 
$length = 32 # bytes (256 bit key)
$salt = New-Object byte[] $length
$rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::Create()
$rng.GetBytes($salt)

$iterations = 1000
$rfc = [System.Security.Cryptography.Rfc2898DeriveBytes]::new($Password,$salt,$iterations)
$key = $rfc.GetBytes(32)

# generate a random initialization vector 
$length = 16
$iv = New-Object byte[] $length
$rng.GetBytes($iv)

@{
    Key = $key
    IV = $iv
} | Export-Clixml $Path