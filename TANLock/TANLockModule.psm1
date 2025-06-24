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
function Invoke-TANLockWebRequest {
    param (
        [string]$Uri,
        [string]$Method = 'GET',
        [hashtable]$Body
    )

    $webRequestParams = @{
        Uri         = $Uri
        Method      = $Method
        ContentType = 'application/json'
        ErrorAction = 'Stop'
    }
    if ($Body) {
        $webRequestParams['Body'] = $Body | ConvertTo-Json -Depth 10
    }

    Write-Verbose "Sending request to $Uri"
    try {
        $response = Invoke-WebRequest @webRequestParams
        Write-Host "Response: $($response.StatusCode) - $($response.StatusDescription)"
    }
    catch {
        throw "Failed to send request to $Uri. Error: $_"
    }
}
function Get-TANLockInfo {
    <#
        .SYNOPSIS
        Retrieves information about TANLock devices.

        .DESCRIPTION
        This function retrieves information about TANLock devices based on the provided location.
        It uses the API key and rack mapping from the application settings.

        .PARAMETER Location
        Specifies the location of the TANLock devices to retrieve information for.
        Valid values are 'Rack1', 'Rack2', ..., 'Rack14'.

        .EXAMPLE
        Get-TANLockInfo -Location 'Rack1', 'Rack2'
    #>
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
        [string]$Location
    )

    begin{
        try { $appSettings = Get-AppSettings }
        catch { $PSCmdlet.ThrowTerminatingError($_) }

        $rackMapping = $appSettings.RackMapping | Where-Object { $_.Location -eq $Location } | ConvertFrom-Json
        Write-Verbose "Rack Mapping for Location '$Location':"
        $rackMapping | Out-String | Write-Verbose

        $apiKey = $appSettings.ApiKey
        Write-Verbose "Using API Key: $apiKey"
        
        Invoke-TrustAllCertificates
    }

    process {
        $uri = 'https://{0}/{1}/info' -f $rackMapping.IPAddress, $apiKey
        try { Invoke-TANLockWebRequest -Uri $uri }
        catch {
            throw "Failed to retrieve TANLock information for location '$Location'. Error: $_"
        }
    }
}
function Get-TANLockHelp {
    <#
        .SYNOPSIS

    #>
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
        [string]$Location
    )

    begin{
        try { $appSettings = Get-AppSettings }
        catch { $PSCmdlet.ThrowTerminatingError($_) }

        $rackMapping = $appSettings.RackMapping | Where-Object { $_.Location -eq $Location } | ConvertFrom-Json
        Write-Verbose "Rack Mapping for Location '$Location':"
        $rackMapping | Out-String | Write-Verbose
        
        Invoke-TrustAllCertificates
    }

    process {
        $uri = 'https://{0}/help' -f $rackMapping.IPAddress
        try { Invoke-TANLockWebRequest -Uri $uri }
        catch {
            throw "Failed to retrieve TANLock help for location '$Location'. Error: $_"
        }
    }
}
function Get-TANLockLog {
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
        [string]$Location
    )

    begin{
        try { $appSettings = Get-AppSettings }
        catch { $PSCmdlet.ThrowTerminatingError($_) }

        $rackMapping = $appSettings.RackMapping | Where-Object { $_.Location -eq $Location } | ConvertFrom-Json
        Write-Verbose "Rack Mapping for Location '$Location':"
        $rackMapping | Out-String | Write-Verbose

        $apiKey = $appSettings.ApiKey
        Write-Verbose "Using API Key: $apiKey"
        
        Invoke-TrustAllCertificates
    }

    process {
        $uri = 'https://{0}/{1}/log/read' -f $rackMapping.IPAddress, $apiKey
        try { Invoke-TANLockWebRequest -Uri $uri }
        catch {
            throw "Failed to retrieve TANLock log for location '$Location'. Error: $_"
        }
    }
}
function Get-TANLockState {
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
        [string[]]$Location
    )

    begin{
        try { $appSettings = Get-AppSettings }
        catch { $PSCmdlet.ThrowTerminatingError($_) }

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
            Write-Verbose "Processing Rack: $($rack.Location) at IP: $($rack.IPAddress)"

            $uri = 'https://{0}/{1}/status' -f $rack.IPAddress, $apiKey
            Write-Host "Getting state for Lock on $($rack.Location) at IP: $($rack.IPAddress)"
            
            try {
                Invoke-TANLockWebRequest -Uri $uri -Method 'GET'
                Write-Host "State retrieved successfully for Rack: $($rack.Location)"
            }
            catch {
                Write-Error "Failed to get state on Rack: $($rack.Location). Error: $_"
            }
        }
    }
}
function Set-TANLockState {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
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
        [ValidateSet(
            'locked',
            'unlocked',
            'open'
        )]
        [string]$State
    )

    begin{
        try { $appSettings = Get-AppSettings }
        catch { $PSCmdlet.ThrowTerminatingError($_) }

        $rackMapping = $appSettings.RackMapping | ConvertFrom-Json
        $rackMapping | Out-String | Write-Verbose

        $apiKey = $appSettings.ApiKey
        Write-Verbose "Using API Key: $apiKey"
        
        Invoke-TrustAllCertificates

        $body = @{state=$State}
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

            $uri = 'https://{0}/{1}/status' -f $rack.IPAddress, $apiKey
            Write-Host "Setting state to $State for Lock on $($rack.Location) at IP: $($rack.IPAddress)"
            
            Write-Verbose "Command: Invoke-WebRequest -Uri $uri -Method Post -Body $($body | Out-String) -ContentType 'application/json'"
            try {
                $response = Invoke-WebRequest -Uri $uri -Method Post -Body $body -ContentType 'application/json' -ErrorAction Stop
                Write-Host "Response: $($response.StatusCode) - $($response.StatusDescription)"
            }
            catch {
                Write-Error "Failed to set state on Rack: $($rack.Location). Error: $_"
            }
        }
    }
}
function Get-TANLockUser {
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
        [string[]]$Location
    )

    begin{
        try { $appSettings = Get-AppSettings }
        catch { $PSCmdlet.ThrowTerminatingError($_) }

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
            Write-Verbose "No specific locations provided, returning users for all racks."
            $racksToUpdate = $rackMapping
        }

        foreach ($rack in $racksToUpdate)
        {
            Write-Verbose "Processing Rack: $($rack.Location) at IP: $($rack.IPAddress)"

            $uri = 'https://{0}/{1}/user/list' -f $rack.IPAddress, $apiKey
            Write-Host "Getting users registered for Lock on $($rack.Location) at IP: $($rack.IPAddress)"
            
            try {
                Invoke-TANLockWebRequest -Uri $uri -Method 'GET'
                Write-Host "Users retrieved successfully for Rack: $($rack.Location)"
            }
            catch {
                Write-Error "Failed to get users on Rack: $($rack.Location). Error: $_"
            }
        }
    }
}
function New-TANLockUser {
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
        try { $appSettings = Get-AppSettings }
        catch { $PSCmdlet.ThrowTerminatingError($_) }

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
            Write-Verbose "Processing Rack: $($rack.Location) at IP: $($rack.IPAddress)"

            $uri = 'https://{0}/{1}/user/create/{2}/{3}' -f $rack.IPAddress, $apiKey, $UserId, $PIN
            Write-Host "Creating user for Lock on $($rack.Location) at IP: $($rack.IPAddress)"

            try {
                Invoke-TANLockWebRequest -Uri $uri -Method 'GET'
                Write-Host "User created successfully for Rack: $($rack.Location)"
            }
            catch {
                Write-Error "Failed to create user on Rack: $($rack.Location). Error: $_"
            }
        }
    }
}
function Remove-TANLockUser {
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
        try { $appSettings = Get-AppSettings }
        catch { $PSCmdlet.ThrowTerminatingError($_) }

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
}
function Add-RFIDCardToTANLock {
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
        try { $appSettings = Get-AppSettings }
        catch { $PSCmdlet.ThrowTerminatingError($_) }

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
}