param(
    [string]$Template,
    [string]$AssetName
)

Write-Output ("Submitting CSR for {0} using the {1} template" -f $AssetName,$Template)