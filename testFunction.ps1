function TestFunction {
    Write-Host "Parent Invocation"
    $MyInvocation.MyCommand.Parent | Out-String | Write-Host

    Write-Host "Invocation Details"
    $MyInvocation | Out-String | Write-Host
    Write-Host "`$MyInvocation.ScriptName: $($MyInvocation.ScriptName)" -ForegroundColor Yellow

    Write-Host "Parent Invocation 2"
    $parentInvocation = Get-Variable MyInvocation -Scope 1 -ValueOnly
    $parentInvocation.MyCommand | Select * | Out-String | Write-Host
    Write-Host "`$parentInvocation.MyCommand.Name: $($parentInvocation.MyCommand.Name)" -ForegroundColor Yellow
}