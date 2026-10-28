@echo off
TITLE Apache Hadoop Universal WSL Launcher
COLOR 0A

echo ==============================================================================
echo                Apache Hadoop Automated One-Click WSL Installer
echo ==============================================================================
echo.
echo Launching installation inside Windows Subsystem for Linux (WSL)...
echo.

:: 1. Purge and unregister any existing WSL distributions to eliminate conflicts
echo [*] Checking for existing WSL Linux distributions to prevent conflicts...
wsl --shutdown >nul 2>&1
for /f "tokens=*" %%i in ('wsl -l -q 2^>nul') do (
    echo [-] Purging and unregistering existing distribution: %%i to prevent version conflicts...
    wsl --unregister %%i >nul 2>&1
)

:: 2. Verify WSL status and initialize if missing
wsl --status >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [!] WSL is not currently active on this system.
    echo [*] Attempting automated WSL & Ubuntu installation...
    wsl --install -d Ubuntu --web-download
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] Administrator privileges may be required to enable WSL.
        echo Please right-click PowerShell -> 'Run as Administrator', then run:
        echo     wsl --install -d Ubuntu
        echo Then restart your PC and run this file again.
        echo.
        pause
        exit /b 1
    )
)

:: 3. Fresh installation of Ubuntu in WSL
echo [*] Installing fresh, conflict-free Ubuntu distribution in WSL...
wsl --install -d Ubuntu --web-download
if %ERRORLEVEL% NEQ 0 (
    wsl --install -d Ubuntu
)

:: 3. Prepare directory path without trailing backslash
set "BATCH_DIR=%~dp0"
if "%BATCH_DIR:~-1%"=="\" set "BATCH_DIR=%BATCH_DIR:~0,-1%"

:: 4. Run the Linux installer natively inside WSL ext4 Linux filesystem (~/Hadoop)
echo [*] Syncing files to WSL native filesystem and launching installer...
wsl -e bash -c "mkdir -p ~/Hadoop && (cd ~/Hadoop && git pull origin main 2>/dev/null || cp -rf \"$(wslpath '%BATCH_DIR%')\"/* ~/Hadoop/ 2>/dev/null || git clone https://github.com/fridayslifes/Hadoop.git ~/Hadoop 2>/dev/null || true); cd ~/Hadoop && sed -i 's/\r$//' install.sh ran-hadoop run-wordcount.sh scripts/*.sh 2>/dev/null || true; chmod +x install.sh ran-hadoop run-wordcount.sh scripts/*.sh 2>/dev/null || true; ./install.sh"

echo.
echo ==============================================================================
echo Setup finished! You can start Hadoop anytime in your terminal with:
echo     ran-hadoop
echo ==============================================================================
pause
