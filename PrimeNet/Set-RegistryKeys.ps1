function Set-RegistryKeys {
    [cmdletbinding()]
    param([string]$DefaultPath = "$env:USERPROFILE\OneDrive\OneDrive - PrimeNet\ToNNPP")

    $onedrive = "$env:USERPROFILE\OneDrive\OneDrive - PrimeNet\"
    $paths = @{
        MonitoredFolder = $DefaultPath
        SoftwareVersions = Join-Path $onedrive SoftwareVersions
        TransferLog = Join-Path $onedrive SoftwareVersions\FileTransferLog.csv
        ActivityLog = Join-Path $onedrive Documents\FileTransferLogger.log
    }

    foreach ($item in $paths.GetEnumerator()) {
        try {
            $null = Get-ItemProperty HKCU:\Environment\FileTransfer -Name $item.Key -ErrorAction Stop #| Select-Object -ExpandProperty MonitoredFolder
        }
        catch {
            Write-Host "Adding $($item.Key) with value $($item.Value) to Registry Key HKCU:\Environment\FileTransfer" -ForegroundColor Yellow
            reg add 'HKCU\Environment\FileTransfer' /t REG_EXPAND_SZ /v $item.Key /d $item.Value
        }
    }

}

Set-RegistryKeys
