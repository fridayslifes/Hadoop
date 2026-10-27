@echo off
TITLE Apache Hadoop Universal WSL Launcher
COLOR 0A

echo ==============================================================================
echo                Apache Hadoop Automated One-Click WSL Installer
echo ==============================================================================
echo.
echo Target Directory: %~dp0
echo Launching installation inside Windows Subsystem for Linux (WSL)...
echo.

wsl --status >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] WSL is not detected or enabled on this system.
    echo Please run PowerShell as Administrator and execute:
    echo     wsl --install -d Ubuntu
    echo Then restart your PC and run this file again.
    echo.
    pause
    exit /b 1
)

:: Run the Linux installer inside default WSL distro
wsl -e bash -c "cd \"$(wslpath '%~dp0')\" && chmod +x install.sh ran-hadoop run-wordcount.sh scripts/*.sh 2>/dev/null || true; ./install.sh"

echo.
echo ==============================================================================
echo Setup finished! You can start Hadoop anytime in your terminal with:
echo     ran-hadoop
echo ==============================================================================
pause
