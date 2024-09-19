param(
    [string[]]$UserDoDId,
    [string[]]$UserPID
)

begin {
    $ids = $PSBoundParameters
    Get-Date | Out-File -FilePath c:\tools\test.txt
    $ids | Out-String | Out-File -FilePath c:\tools\test.txt -Append
}

process {
    $ids.Values.ForEach({
        Write-Output $PSItem 
    })
}