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

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrWhiteSpace()]
    [string]$UserId,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrWhiteSpace()]
    [string]$PIN
)

begin{
    function Get-AppSettings {
        $configPath = "$PSScriptRoot\App.config"
        if (-not (Test-Path $configPath)) {
            Write-Error "Configuration file not found at path: $configPath"
            return
        }

        [xml]$config = Get-Content $configPath
        $appSettings = New-Object psobject
        $config.Configuration.appSettings.add | ForEach-Object {
            Add-Member -InputObject $appSettings -NotePropertyName $_.key.Trim() -NotePropertyValue $_.value.Trim()
        }

        return $appSettings
    }

    $appSettings = Get-AppSettings

    $rackMapping = $appSettings.RackMapping | ConvertFrom-Json
    $rackMapping | Out-String | Write-Verbose

    $apiKey = $appSettings.ApiKey
    Write-Verbose "Using API Key: $apiKey"
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
        Write-Verbose "Processing Rack: $($rack.Location) at IP: $($rack.IPAddress)"

        $uri = 'https://{0}/{1}/user/create/{2}/{3}' -f $rack.IPAddress, $apiKey, $UserId, $PIN
        Write-Host "Adding RFID card for UserId: $UserId to Lock on $($rack.Location) at IP: $($rack.IPAddress)"
        
        Write-Verbose "Command: Invoke-WebRequest -Uri $uri"
        try {
            $response = Invoke-WebRequest -Uri $uri -ErrorAction Stop
            Write-Host "Response: $($response.StatusCode) - $($response.StatusDescription)"
        }
        catch {
            Write-Error "Failed to add RFID card for UserId: $UserId on Rack: $($rack.Location). Error: $_"
        }
    }
}