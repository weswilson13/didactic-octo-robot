[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet(
        'Rack1',
        'Rack2',
        'Rack3',
        'Rack4',
        'Rack5',
        'Rack6',
        'Rack7',
        'Rack8',
        'Rack9',
        'Rack10',
        'Rack11',
        'Rack12',
        'Rack13',
        'Rack14'
    )]
    [string[]]$Location,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrWhiteSpace()]
    [string[]]$UserId,

    [Parameter(Mandatory = $false)]
    [switch]$All
)

begin{
    
    if (!$All.IsPresent -and !$UserId) {
        throw "You must specify either -All to clear all users or -UserId to specify specific users to remove."
    }
    if ($All.IsPresent -and $UserId) {
        throw "You cannot use -All and -UserId together. Please choose one option."
    }
    Write-Verbose "Retrieving application settings from App.config"
    $appSettings = Get-AppSettings

    $rackMapping = $appSettings.RackMapping | ConvertFrom-Json
    $rackMapping | Out-String | Write-Verbose

    $apiKey = $appSettings.ApiKey
    Write-Verbose "Using API Key: $apiKey"
    
    Invoke-TrustAllCertificates
}

process {
    if ($Location) {
        Write-Verbose "Filtering racks for specified locations: $($Location -join ', ')"
        $racksToUpdate = $rackMapping | Where-Object {$_.Location -in $Location}
    }
    else {
        Write-Verbose "No specific locations provided, updating all racks."
        $racksToUpdate = $rackMapping
    }

    foreach ($rack in $racksToUpdate)
    {
        if ($All.IsPresent) {
            Write-Verbose "Clearing all users from Rack: $($rack.Location)"
            $uri = 'https://{0}/{1}/user/clear' -f $rack.IPAddress, $apiKey
            try {
                Invoke-TANLockWebRequest -Uri $uri
            }
            catch {
                Write-Error "Failed to clear users from Rack: $($rack.Location). Error: $_"
            }
        }
        else {
            foreach ($user in $UserId) {
                Write-Verbose "Removing User: $user from Rack: $($rack.Location)"
                $uri = 'https://{0}/{1}/user/delete/{2}' -f $rack.IPAddress, $apiKey, $user
                try {
                    Invoke-TANLockWebRequest -Uri $uri
                }
                catch {
                    Write-Error "Failed to remove User: $user from Rack: $($rack.Location). Error: $_"
                }
            }
        }
    }  
}