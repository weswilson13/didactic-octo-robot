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

    function Invoke-TrustAllCertificates { # This function is used to bypass SSL certificate validation

        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

        switch ($PSVersionTable.PSEdition) {
            'Core' {
                [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
            }
            'Desktop' {
                Add-Type -TypeDefinition ""
            }
        }
    }

    $appSettings = Get-AppSettings

    $rackMapping = $appSettings.RackMapping | ConvertFrom-Json
    $rackMapping | Out-String | Write-Verbose

    $apiKey = $appSettings.ApiKey
    Write-Verbose "Using API Key: $apiKey"
    
    Invoke-TrustAllCertificates
}

process {
    
}