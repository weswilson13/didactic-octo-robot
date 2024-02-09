try{
    $checkFailed=$false
    $undocumentedDatabases=@()
    $badEncryptionStates=@()

    $sqlAttr = @{
        ServerInstance = 'SQ02,9999'
        Query = "SELECT
        d.name AS [DatabaseName],
        CASE COALESCE(e.encryption_state,0)
        WHEN 0 THEN 'No database encryption key present, no encryption'
        WHEN 1 THEN 'Unencrypted'
        WHEN 2 THEN 'Encryption in progress'
        WHEN 3 THEN 'Encrypted'
        WHEN 4 THEN 'Key change in progress'
        WHEN 5 THEN 'Decryption in progress'
        WHEN 6 THEN 'Protection change in progress'
        END AS [EncryptionState]
        FROM sys.dm_database_encryption_keys e
        RIGHT JOIN sys.databases d ON DB_NAME(e.database_id) = d.name
        WHERE d.name NOT IN ('master','model','msdb')
        ORDER BY [DatabaseName]"
    }

    $results = Invoke-SqlCmd @sqlAttr
    $results | Out-String | Write-Host 

    $encryptionStates = Import-Excel -Path "\\raspberrypi4-1\nas02\Book1.xlsx" -WorksheetName Encryption
    $encryptionStates | Out-String | Write-Host

    foreach ($result in $results) {
        if ($result.DatabaseName -notin $encryptionStates.DatabaseName) { $checkFailed = $true; $undocumentedDatabases += $result.DatabaseName }
        elseif ( ($encryptionStates | Where-Object {$_.DatabaseName -eq $result.DatabaseName}).Encryption -eq 'Yes' -and $result.EncryptionState -ne "Encrypted" ) {
                $checkFailed = $true
                $badEncryptionStates += $result.DatabaseName
            }
    }

    if ($checkFailed) {
        $comment = "The Check Failed."
        if ($undocumentedDatabases) { $comment += "`nThe following databases are missing from system documentation:`n$($undocumentedDatabases | Out-String)"}
        if ($badEncryptionStates) { $comment += "`nThe following databases are improperly encrypted:`n$($badEncryptionStates | Out-String)"}

        Write-Host $comment
        return $false
    }
}
Catch {
    $Error[0]
}
