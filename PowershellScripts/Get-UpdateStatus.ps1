param (
    [parameter(Mandatory=$false, ValueFromPipeline=$true)]
    [String]$ComputerName
)

if (!($ComputerName)) {
    $ComputerName = $env:COMPUTERNAME
}

Get-WinEvent @PSBoundParameters -LogName Setup -MaxEvents 20 | ? {$_.ProviderName -match 'servicing'}
