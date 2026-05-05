$patterns = @{
    '(25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)){3}' = '[IP_REDACTED]'
    '(([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}|([0-9A-Fa-f]{4}\.){2}[0-9A-Fa-f]{4})' = '[MAC_REDACTED]'
}
gci $PSScriptRoot -Recurse -File | ? {$_.Extension -ne '.ps1'} | foreach-object {
    $count = 0
    $content = Get-Content $_.FullName -Raw
    foreach ($pattern in $patterns.GetEnumerator()) {
        $content = $content -replace $pattern.Key, {$count++;$pattern.Value}
    }
    $content | Set-Content ("$PSScriptRoot\{0}_redacted{1}" -f $_.BaseName, $_.Extension)
    Write-Host "Processed $($_.FullName) with $count replacements."
}