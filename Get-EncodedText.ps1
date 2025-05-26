[CmdletBinding()]
param(
    [string]$Path,
    [string]$Destination
)

$text = Get-Content $Path -Raw
$bytes = [System.Text.Encoding]::Unicode.GetBytes($text) 
$encodedText = [System.Convert]::ToBase64String($bytes)

if ($Destination) {
    $encodedText | Out-File -FilePath $Destination -Force -Encoding utf8
}
else {
    Write-Host $encodedText
}