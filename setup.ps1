# ==============================================================================
#  Apache Hadoop Universal 1-Click Installer (Windows / WSL2)
#  Repository: https://github.com/fridayslifes/Hadoop
#  Usage (Universal 1-Liner):
#    irm https://raw.githubusercontent.com/fridayslifes/Hadoop/main/setup.ps1 | iex
# ==============================================================================

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host "       🐘 Apache Hadoop Universal Automated Installer (Windows / WSL2)" -ForegroundColor Yellow
Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Resolve User Desktop Path
$DesktopPath = [Environment]::GetFolderPath('Desktop')
if (-not (Test-Path $DesktopPath)) {
    $DesktopPath = "$env:USERPROFILE\Desktop"
}
$TargetDir = Join-Path $DesktopPath "Hadoop"

Write-Host "[*] Destination Directory: $TargetDir" -ForegroundColor Green

# 2. Check / Install Git if missing
$GitCmd = Get-Command git -ErrorAction SilentlyContinue
if (-not $GitCmd) {
    Write-Host "[*] Git is not detected on your system. Attempting automated installation via winget..." -ForegroundColor Yellow
    $WingetCmd = Get-Command winget -ErrorAction SilentlyContinue
    if ($WingetCmd) {
        try {
            Write-Host "    Installing Git using winget..." -ForegroundColor Gray
            & winget install --id Git.Git -e --source winget --accept-source-agreements --accept-package-agreements --silent
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            $GitCmd = Get-Command git -ErrorAction SilentlyContinue
        } catch {
            Write-Host "    winget install encountered an issue. Falling back to direct archive download..." -ForegroundColor Gray
        }
    }
}

# 3. Download or Clone Repository directly to Desktop
if (-not (Test-Path $TargetDir)) {
    Write-Host "[*] Downloading Hadoop repository to your Desktop..." -ForegroundColor Cyan

    if ($GitCmd) {
        Write-Host "    Cloning repository via Git..." -ForegroundColor Gray
        & git clone https://github.com/fridayslifes/Hadoop.git "$TargetDir"
    } else {
        Write-Host "    Downloading repository ZIP archive via secure HTTPS connection..." -ForegroundColor Gray
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
    Write-Host "[✓] Existing Hadoop folder found at $TargetDir. Syncing latest updates..." -ForegroundColor Green
    if ($GitCmd -and (Test-Path (Join-Path $TargetDir ".git"))) {
        try {
            Push-Location $TargetDir
            & git fetch --all 2>$null
            & git reset --hard origin/main 2>$null
            Pop-Location
        } catch {}
    } else {
        $ZipPath = Join-Path $env:TEMP "hadoop-main.zip"
        $ExtractPath = Join-Path $env:TEMP "hadoop-extract"
        if (Test-Path $ExtractPath) { Remove-Item -Recurse -Force $ExtractPath }
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        try {
            Invoke-WebRequest -Uri "https://github.com/fridayslifes/Hadoop/archive/refs/heads/main.zip" -OutFile $ZipPath -UseBasicParsing
            Expand-Archive -Path $ZipPath -DestinationPath $ExtractPath -Force
            $ExtractedFolder = Join-Path $ExtractPath "Hadoop-main"
            Copy-Item -Path "$ExtractedFolder\*" -Destination $TargetDir -Recurse -Force
            Remove-Item -Force $ZipPath -ErrorAction SilentlyContinue
            Remove-Item -Recurse -Force $ExtractPath -ErrorAction SilentlyContinue
        } catch {}
    }
}

# 4. Verify WSL Status & Check Linux Distribution (Ubuntu, Kali Linux, Debian, etc.)
Write-Host ""
Write-Host "[*] Checking Windows Subsystem for Linux (WSL) status..." -ForegroundColor Cyan

$WslInstalled = $false
try {
    $WslStatus = & wsl.exe --status 2>&1
    if ($LASTEXITCODE -eq 0 -and $null -ne $WslStatus) {
        $WslInstalled = $true
    }
} catch {
    $WslInstalled = $false
}

if (-not $WslInstalled) {
    Write-Host "[!] WSL is not currently installed or active." -ForegroundColor Yellow
    Write-Host "[*] Installing WSL and Ubuntu Linux..." -ForegroundColor Cyan

    $LocalMsi = Join-Path $TargetDir "wsl_update_x64.msi"
    if (Test-Path $LocalMsi) {
        Write-Host "[✓] Found local offline WSL2 update installer: wsl_update_x64.msi" -ForegroundColor Green
        try {
            Start-Process msiexec.exe -ArgumentList "/i "$LocalMsi" /quiet /norestart" -Wait
        } catch {}
    }
    
    $IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $IsAdmin) {
        Write-Host ""
        Write-Host "[!] Administrator permissions are required to enable WSL for the first time." -ForegroundColor Red
        Write-Host "    Please right-click PowerShell -> 'Run as Administrator', then run:" -ForegroundColor Yellow
        Write-Host "    wsl --install -d Ubuntu" -ForegroundColor White
        Write-Host "    After system reboot, re-run this setup." -ForegroundColor Yellow
        Write-Host ""
        Read-Host "Press Enter to exit..."
        exit 1
    } else {
        & wsl.exe --install -d Ubuntu --web-download
        Write-Host "[✓] WSL installed. System reboot may be required." -ForegroundColor Green
    }
} else {
    Write-Host "[✓] WSL is active and operational." -ForegroundColor Green
}

# Check for installed Linux distribution
Write-Host "[*] Checking for installed Linux distributions in WSL (Ubuntu, Kali, Debian)..." -ForegroundColor Cyan
$Distros = @()
try {
    $RawDistros = & wsl.exe --list --quiet 2>$null
    $Distros = $RawDistros | ForEach-Object { ($_ -replace "`0", "").Trim() } | Where-Object { $_ -ne "" }
} catch {
    $Distros = @()
}

if ($Distros.Count -eq 0) {
    Write-Host "[!] No Linux distribution detected in WSL." -ForegroundColor Yellow
    Write-Host "[*] Installing Ubuntu Linux distribution for WSL..." -ForegroundColor Cyan
    & wsl.exe --install -d Ubuntu --web-download
    if ($LASTEXITCODE -ne 0) {
        & wsl.exe --install -d Ubuntu
    }
    Write-Host "[✓] Ubuntu Linux distribution installation completed." -ForegroundColor Green
} else {
    Write-Host "[✓] Detected Linux distribution(s): $($Distros -join ', ')" -ForegroundColor Green
}

# 5. Create Desktop Shortcuts
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
    Write-Host "[-] Note: Desktop shortcuts could not be registered automatically." -ForegroundColor Gray
}

# 6. Execute Hadoop Setup inside WSL native Linux environment
Write-Host ""
Write-Host "[*] Setting up Hadoop natively inside WSL Linux filesystem..." -ForegroundColor Cyan
Write-Host "------------------------------------------------------------------------------" -ForegroundColor DarkGray

$NormalizedTarget = $TargetDir.Replace('\', '/')
$WslTargetScript = "mkdir -p ~/Hadoop && (cd ~/Hadoop && git pull origin main 2>/dev/null || cp -rf `"`$(wslpath -u '$NormalizedTarget')`"/* ~/Hadoop/ 2>/dev/null || git clone https://github.com/fridayslifes/Hadoop.git ~/Hadoop 2>/dev/null || true); cd ~/Hadoop && sed -i 's/\r$//' install.sh ran-hadoop run-wordcount.sh scripts/*.sh 2>/dev/null || true; chmod +x install.sh ran-hadoop run-wordcount.sh scripts/*.sh 2>/dev/null || true; ./install.sh"
& wsl.exe -e bash -c $WslTargetScript

Write-Host ""
Write-Host "==============================================================================" -ForegroundColor Green
Write-Host "  🎉 Setup Complete! Hadoop is installed and saved at: $TargetDir" -ForegroundColor Yellow
Write-Host "  To launch Hadoop, double-click 'Start Hadoop (ran-hadoop)' on your Desktop" -ForegroundColor White
Write-Host "  or open your terminal and type: ran-hadoop" -ForegroundColor White
Write-Host "==============================================================================" -ForegroundColor Green
Write-Host ""
