@echo off
TITLE Apache Hadoop Offline Backup Downloader
COLOR 0A

echo ==============================================================================
echo        Apache Hadoop Offline Backup Downloader (Lab PC / Windows)
echo ==============================================================================
echo.
echo Destination Folder: %~dp0
echo Downloading Hadoop 3.3.6 tarball and examples JAR for offline use...
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0download-offline-bundle.ps1"

pause
