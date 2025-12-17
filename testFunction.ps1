function TestFunction {
    Write-Host "Local Invocation Details" -ForegroundColor Magenta
    $MyInvocation | Select * | Out-String | Write-Host

    Write-Host "Calling Script Path" -ForegroundColor Magenta
    Write-Host "`$MyInvocation.ScriptName: $($MyInvocation.ScriptName)" -ForegroundColor Yellow
    Write-Host "Script Root" -ForegroundColor Magenta
    Write-Host "`$MyInvocation.PSScriptRoot: $($MyInvocation.PSScriptRoot)" -ForegroundColor Yellow 

    Write-Host "Parent Invocation Details" -ForegroundColor Cyan
    $parentInvocation = Get-Variable MyInvocation -Scope 1 -ValueOnly
    $parentInvocation | Select * | Out-String | Write-Host
    Write-Host "Parent Command Details" -ForegroundColor Cyan
    $parentInvocation.MyCommand | Select * | Out-String | Write-Host

    Write-Host "Calling Script Name" -ForegroundColor Cyan
    Write-Host "`$parentInvocation.MyCommand.Name: $($parentInvocation.MyCommand.Name)" -ForegroundColor Yellow
    Write-Host "Calling Script Path" -ForegroundColor Cyan
    Write-Host "`$parentInvocation.MyCommand.Path: $($parentInvocation.MyCommand.Path)" -ForegroundColor Yellow
}