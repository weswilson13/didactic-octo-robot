z:

REM Start Notepad++
start notepad++.exe

REM Start RDCManager
cd z:\Microsoft\Sysinternals\
start /max RDCMan.exe rdphomelab.rdg

REM Start Windows Terminal
start z:\Microsoft\WindowsTerminal\WindowsTerminal.exe

REM REM Start Visual Studio
REM start devenv.exe /nosplash

REM Start SSMS
start ssms.exe /nosplash /S SQ02\mysqlserver,9999

REM Start Admin MMC
start mmc.exe "z:\MMC Config\AdminConsole.msc"

REM Start Windows Admin Center
c:
cd "C:\Program Files\Windows Admin Center"
start SmeDesktop.exe

timeout /T 30