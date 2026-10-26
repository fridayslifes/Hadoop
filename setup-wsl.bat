@echo off
TITLE Apache Hadoop WSL Installer
COLOR 0A

echo ==============================================================================
echo                Apache Hadoop Automated One-Click WSL Installer
echo ==============================================================================
echo.
echo Launching installation inside Windows Subsystem for Linux (WSL)...
echo.

wsl --status >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] WSL is not detected on your Windows system.
    echo Please install WSL by running: wsl --install in an Administrator terminal.
    echo.
    pause
    exit /b 1
)

:: Run the Linux installer inside default WSL distro
wsl -e bash -c "cd \"$(wslpath '%~dp0')\" && chmod +x install.sh ran-hadoop run-wordcount.sh scripts/*.sh 2>/dev/null || true; ./install.sh"

echo.
echo ==============================================================================
echo Setup finished. Press any key to exit this window.
echo ==============================================================================
pause
