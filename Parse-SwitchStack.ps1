[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)] 
    [ValidateScript({
        if (!(Test-Path $_ )) { throw [System.IO.FileNotFoundException] }

        return $true
    })]
    [System.IO.FileInfo[]]$Path
)

$Path | Foreach-Object -ThrottleLimit 5 -Parallel {
    
    [regex]$versionRegex = 'version (?<version>(\d\.?)+)'
    [regex]$nameRegex = '(?<name>.+)(?= Uptime is)'
    [regex]$serialNumberRegex = 'System Serial Number:(?<serialNumber>.+)'
    [regex]$modelRegex = 'Model:(?<model>.+)'

    return [PSCustomObject]@{
        Name         = (Select-String -InputObject $PSItem -pattern $nameRegex).Matches[0].Groups['name'].Value.Trim() 
        Version      = (Select-String -InputObject $PSItem -pattern $versionRegex).Matches[0].Groups['version'].Value.Trim() 
        SerialNumber = (Select-String -InputObject $PSItem -pattern $serialNumberRegex).Matches[0].Groups['serialNumber'].Value.Trim()
        Model        = (Select-String -InputObject $PSItem -pattern $modelRegex).Matches[0].Groups['model'].Value.Trim()
    } 
}