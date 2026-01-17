@echo off
set TARGET_USER=testlina
set PS1_SCRIPT=C:\tools\Start-Badge.ps1

for /f "tokens=2 delims=\" %%a in (%USERNAME%) do set CURRENT_USER=%%a
set CURRENT_USER=%USERNAME%

if /i %CURRENT_USER%==%TARGET_USER% (
    echo Launching PowerShell script for %CURRENT_USER%...
    start "TabletTracking" powershell -NoProfile -WindowStyle Maximized -ExecutionPolicy Bypass -File "%PS1_SCRIPT%"
) else (
    echo Launching desktop for %CURRENT_USER%...
    powershell -Command  "explorer.exe"
)
