# ==============================================================================
#  Apache Hadoop 1-Click Lab PC Installer (Windows PowerShell)
#  Repository: https://github.com/fridayslifes/Hadoop
#  Usage (Lab PC 1-Liner):
#    irm https://raw.githubusercontent.com/fridayslifes/Hadoop/main/setup-lab.ps1 | iex
# ==============================================================================

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host "    🐘 Apache Hadoop Automated Computer Lab Setup (Windows / WSL2)" -ForegroundColor Yellow
Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Resolve User Desktop Path
$DesktopPath = [Environment]::GetFolderPath('Desktop')
if (-not (Test-Path $DesktopPath)) {
    $DesktopPath = "$env:USERPROFILE\Desktop"
}
$TargetDir = Join-Path $DesktopPath "Hadoop"

Write-Host "[*] Target Lab Directory: $TargetDir" -ForegroundColor Green

# 2. Download or Clone Repository directly to Desktop
if (-not (Test-Path $TargetDir)) {
    Write-Host "[*] Downloading Hadoop repository to your Desktop..." -ForegroundColor Cyan
    $GitCmd = Get-Command git -ErrorAction SilentlyContinue

    if ($GitCmd) {
        Write-Host "    Using Git clone..." -ForegroundColor Gray
        & git clone https://github.com/fridayslifes/Hadoop.git "$TargetDir"
    } else {
        Write-Host "    Git not found in PATH. Downloading ZIP archive via WebClient..." -ForegroundColor Gray
        $ZipPath = Join-Path $env:TEMP "hadoop-main.zip"
        $ExtractPath = Join-Path $env:TEMP "hadoop-extract"
        
        if (Test-Path $ExtractPath) { Remove-Item -Recurse -Force $ExtractPath }
        
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri "https://github.com/fridayslifes/Hadoop/archive/refs/heads/main.zip" -OutFile $ZipPath -UseBasicParsing
        
        Expand-Archive -Path $ZipPath -DestinationPath $ExtractPath -Force
        $ExtractedFolder = Join-Path $ExtractPath "Hadoop-main"
        
        Move-Item -Path $ExtractedFolder -Destination $TargetDir -Force
        Remove-Item -Force $ZipPath -ErrorAction SilentlyContinue
        Remove-Item -Recurse -Force $ExtractPath -ErrorAction SilentlyContinue
    }
} else {
    Write-Host "[✓] Existing Hadoop folder found at $TargetDir" -ForegroundColor Green
}

# 3. Verify WSL2 Status
Write-Host ""
Write-Host "[*] Checking Windows Subsystem for Linux (WSL) status..." -ForegroundColor Cyan
$WslStatus = $null
try {
    $WslStatus = & wsl --status 2>&1
} catch {
    $WslStatus = $null
}

if ($LASTEXITCODE -ne 0 -or $null -eq $WslStatus) {
    Write-Host ""
    Write-Host "[!] WSL is not currently installed or enabled on this computer." -ForegroundColor Yellow
    Write-Host "    Attempting automated WSL installation (Ubuntu)..." -ForegroundColor Cyan
    
    $IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $IsAdmin) {
        Write-Host ""
        Write-Host "[!] Administrator permissions are required to enable WSL for the first time." -ForegroundColor Red
        Write-Host "    Please right-click PowerShell -> 'Run as Administrator', then run:" -ForegroundColor Yellow
        Write-Host "    wsl --install -d Ubuntu" -ForegroundColor White
        Write-Host "    After rebooting the PC, run this script again." -ForegroundColor Yellow
        Write-Host ""
        Read-Host "Press Enter to exit..."
        exit 1
    } else {
        & wsl --install -d Ubuntu --no-launch
        Write-Host ""
        Write-Host "[✓] WSL installed. A system reboot may be required before running Hadoop." -ForegroundColor Green
        Read-Host "Press Enter to continue or exit..."
    }
} else {
    Write-Host "[✓] WSL is active and operational." -ForegroundColor Green
}

# 4. Create Convenient Windows Desktop Shortcuts
try {
    $WshShell = New-Object -ComObject WScript.Shell
    
    # Shortcut 1: Start Hadoop Cluster
    $ShortcutHadoop = $WshShell.CreateShortcut((Join-Path $DesktopPath "Start Hadoop (ran-hadoop).lnk"))
    $ShortcutHadoop.TargetPath = "wsl.exe"
    $ShortcutHadoop.Arguments = "-e ran-hadoop"
    $ShortcutHadoop.Description = "Starts Apache Hadoop HDFS & YARN with auto-shutdown monitor"
    $ShortcutHadoop.Save()

    # Shortcut 2: Run WordCount MapReduce Demo
    $ShortcutWC = $WshShell.CreateShortcut((Join-Path $DesktopPath "Run Hadoop WordCount.lnk"))
    $ShortcutWC.TargetPath = "wsl.exe"
    $ShortcutWC.Arguments = "-e bash -c `"run-wordcount.sh; echo; read -p 'Press Enter to exit...'`""
    $ShortcutWC.Description = "Executes distributed MapReduce WordCount on Hadoop"
    $ShortcutWC.Save()
    
    Write-Host "[✓] Created Desktop Shortcuts: 'Start Hadoop' & 'Run Hadoop WordCount'" -ForegroundColor Green
} catch {
    Write-Host "[-] Note: Desktop shortcuts could not be created automatically." -ForegroundColor Gray
}

# 5. Execute Linux Installer inside WSL
Write-Host ""
Write-Host "[*] Initiating automated Hadoop setup inside WSL..." -ForegroundColor Cyan
Write-Host "------------------------------------------------------------------------------" -ForegroundColor DarkGray

$WslTargetScript = "cd `$(wslpath -u '$TargetDir') 2>/dev/null || cd /mnt/c/Users/$env:USERNAME/Desktop/Hadoop; chmod +x install.sh ran-hadoop run-wordcount.sh scripts/*.sh 2>/dev/null || true; ./install.sh"
& wsl -e bash -c $WslTargetScript

Write-Host ""
Write-Host "==============================================================================" -ForegroundColor Green
Write-Host "  🎉 Setup Complete! Files are saved on your Desktop at: $TargetDir" -ForegroundColor Yellow
Write-Host "  To launch Hadoop, double-click 'Start Hadoop (ran-hadoop)' on your Desktop" -ForegroundColor White
Write-Host "  or open your terminal and type: ran-hadoop" -ForegroundColor White
Write-Host "==============================================================================" -ForegroundColor Green
Write-Host ""
