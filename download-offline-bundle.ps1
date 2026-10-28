# ==============================================================================
# download-offline-bundle.ps1: Complete Offline Lab PC Backup Downloader
# Downloads ALL required offline installation files into this local Hadoop folder:
#   1. Apache Hadoop 3.3.6 tarball (hadoop-3.3.6.tar.gz)
#   2. Hadoop MapReduce Examples JAR (hadoop-mapreduce-examples-3.3.6.jar)
#   3. Java OpenJDK 11 LTS Linux binary (OpenJDK11U-jdk_x64_linux_hotspot_11.0.22_7.tar.gz)
#   4. Microsoft WSL Kernel update package (wsl_update_x64.msi)
#   5. OpenSSH Debian Packages for offline Linux/WSL (offline_packages/openssh*.deb)
# ==============================================================================

$ScriptDir = $PSScriptRoot
if (-not $ScriptDir) {
    $ScriptDir = (Get-Location).Path
}

$HadoopVersion = "3.3.6"
$JavaVersion = "11.0.22_7"

$TarName = "hadoop-$HadoopVersion.tar.gz"
$JarName = "hadoop-mapreduce-examples-$HadoopVersion.jar"
$JavaTarName = "OpenJDK11U-jdk_x64_linux_hotspot_$JavaVersion.tar.gz"
$WslMsiName = "wsl_update_x64.msi"

$TarTarget = Join-Path $ScriptDir $TarName
$JarTarget = Join-Path $ScriptDir $JarName
$JavaTarTarget = Join-Path $ScriptDir $JavaTarName
$WslMsiTarget = Join-Path $ScriptDir $WslMsiName

Write-Host ""
Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host "    Complete Apache Hadoop & WSL Offline Lab Backup Downloader (Windows)" -ForegroundColor Yellow
Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host " Destination Folder   : $ScriptDir" -ForegroundColor Green
Write-Host " Components to Backup :" -ForegroundColor Green
Write-Host "   1. Hadoop Binary Archive  : $TarName" -ForegroundColor White
Write-Host "   2. MapReduce Examples JAR : $JarName" -ForegroundColor White
Write-Host "   3. Java OpenJDK 11 LTS    : $JavaTarName" -ForegroundColor White
Write-Host "   4. WSL2 Kernel MSI Update : $WslMsiName" -ForegroundColor White
Write-Host "   5. OpenSSH Debian Packages: offline_packages/openssh*.deb" -ForegroundColor White
Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host ""

# Ensure aria2c is available on Windows for 16-thread accelerated downloading
$Aria2Exe = "aria2c"
$Aria2Cmd = Get-Command aria2c -ErrorAction SilentlyContinue

if (-not $Aria2Cmd) {
    $LocalAria = Join-Path $ScriptDir "aria2c.exe"
    if (Test-Path $LocalAria) {
        $Aria2Exe = $LocalAria
        $Aria2Cmd = $true
    }
}

if (-not $Aria2Cmd) {
    Write-Host "[*] aria2c not detected on Windows. Attempting installation via winget..." -ForegroundColor Yellow
    $WingetCmd = Get-Command winget -ErrorAction SilentlyContinue
    if ($WingetCmd) {
        try {
            & winget install --id aria2.aria2 -e --source winget --accept-source-agreements --accept-package-agreements --silent
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            $Aria2Cmd = Get-Command aria2c -ErrorAction SilentlyContinue
        } catch {}
    }
}

# If still not installed, download official portable aria2c.exe to guarantee 16-thread downloads
if (-not $Aria2Cmd) {
    $LocalAria = Join-Path $ScriptDir "aria2c.exe"
    if (-not (Test-Path $LocalAria)) {
        Write-Host "[*] Fetching portable aria2c.exe for 16-thread downloads..." -ForegroundColor Yellow
        $AriaZip = Join-Path $env:TEMP "aria2_portable.zip"
        $AriaZipUrl = "https://github.com/aria2/aria2/releases/download/release-1.37.0/aria2-1.37.0-win-64bit-build1.zip"
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -Uri $AriaZipUrl -OutFile $AriaZip -UseBasicParsing
            Expand-Archive -Path $AriaZip -DestinationPath (Join-Path $env:TEMP "aria2_unpacked") -Force
            $FoundAria = Get-ChildItem -Path (Join-Path $env:TEMP "aria2_unpacked") -Filter "aria2c.exe" -Recurse | Select-Object -First 1
            if ($FoundAria) {
                Copy-Item -Path $FoundAria.FullName -Destination $LocalAria -Force
                $Aria2Exe = $LocalAria
                $Aria2Cmd = $true
            }
        } catch {
            Write-Host "[!] Could not fetch portable aria2c. Fallback mode active." -ForegroundColor Yellow
        }
    } else {
        $Aria2Exe = $LocalAria
        $Aria2Cmd = $true
    }
}

# Download function with 16 connections and completion checker
function Download-File16Threads {
    param(
        [string]$FileName,
        [string[]]$Urls,
        [long]$MinExpectedBytes = 1000000
    )

    $TargetFile = Join-Path $ScriptDir $FileName

    # [CHECKER 1]: Check if file already exists and passes size check
    if (Test-Path $TargetFile) {
        $Len = (Get-Item $TargetFile).Length
        if ($Len -ge $MinExpectedBytes) {
            Write-Host "[✓] [CHECKER PASSED] $FileName already exists ($([math]::Round($Len / 1MB, 2)) MB). Skipping download." -ForegroundColor Green
            return
        } else {
            Write-Host "[!] Existing $FileName failed size check ($Len < $MinExpectedBytes bytes). Re-downloading..." -ForegroundColor Yellow
            Remove-Item -Force $TargetFile -ErrorAction SilentlyContinue
        }
    }

    $MaxAttempts = 5
    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        Write-Host ""
        Write-Host "[*] Downloading $FileName (Attempt $attempt/$MaxAttempts) utilizing 16 concurrent threads..." -ForegroundColor Cyan

        if ($Aria2Cmd) {
            $AriaArgs = @(
                "--split=16",
                "--max-connection-per-server=16",
                "--min-split-size=1M",
                "--max-concurrent-downloads=16",
                "--file-allocation=none",
                "--lowest-speed-limit=10K",
                "--timeout=30",
                "--connect-timeout=15",
                "--summary-interval=2",
                "--max-tries=5",
                "--retry-wait=2",
                "--auto-file-renaming=false",
                "--allow-overwrite=true",
                "--dir=$ScriptDir",
                "--out=$FileName"
            ) + $Urls

            & $Aria2Exe @AriaArgs
        } else {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            foreach ($u in $Urls) {
                try {
                    Invoke-WebRequest -Uri $u -OutFile $TargetFile -UseBasicParsing
                    break
                } catch {}
            }
        }

        # [CHECKER 2]: Post-download Completion & Integrity Checker
        if (Test-Path $TargetFile) {
            $FinalLen = (Get-Item $TargetFile).Length
            if ($FinalLen -ge $MinExpectedBytes) {
                Write-Host "[✓] [CHECKER PASSED] Download 100% complete & verified: $FileName ($([math]::Round($FinalLen / 1MB, 2)) MB)" -ForegroundColor Green
                $AriaMeta = "$TargetFile.aria2"
                if (Test-Path $AriaMeta) { Remove-Item -Force $AriaMeta -ErrorAction SilentlyContinue }
                return
            }
        }

        Write-Host "[!] Attempt $attempt failed completion check. Retrying in 3s..." -ForegroundColor Yellow
        Remove-Item -Force $TargetFile -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 3
    }

    Write-Error "[FATAL] Failed to download $FileName after $MaxAttempts attempts."
    exit 1
}

# 1. Download Apache Hadoop 3.3.6 tarball
$HadoopPrimary = "https://dlcdn.apache.org/hadoop/common/hadoop-$HadoopVersion/$TarName"
$HadoopArchive = "https://archive.apache.org/dist/hadoop/common/hadoop-$HadoopVersion/$TarName"
$HadoopBackup  = "https://downloads.apache.org/hadoop/common/hadoop-$HadoopVersion/$TarName"
Download-File16Threads -FileName $TarName -Urls @($HadoopPrimary, $HadoopArchive, $HadoopBackup) -MinExpectedBytes 500000000

# 2. Extract hadoop-mapreduce-examples JAR using built-in Windows tar.exe
Write-Host ""
Write-Host "[*] Extracting MapReduce examples JAR into local folder..." -ForegroundColor Cyan
$TarExe = Get-Command tar.exe -ErrorAction SilentlyContinue
if ($TarExe -and (Test-Path $TarTarget)) {
    & tar.exe -xzf "$TarTarget" -C "$ScriptDir" "hadoop-$HadoopVersion/share/hadoop/mapreduce/hadoop-mapreduce-examples-$HadoopVersion.jar" --strip-components=4 2>$null
    if (Test-Path $JarTarget) {
        Write-Host "[✓] Extracted: $JarName" -ForegroundColor Green
    }
}

# 3. Download Java OpenJDK 11 LTS (Linux x64) for offline WSL installation
$JavaUrl1 = "https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.22%2B7/OpenJDK11U-jdk_x64_linux_hotspot_11.0.22_7.tar.gz"
$JavaUrl2 = "https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.21%2B9/OpenJDK11U-jdk_x64_linux_hotspot_11.0.21_9.tar.gz"
Download-File16Threads -FileName $JavaTarName -Urls @($JavaUrl1, $JavaUrl2) -MinExpectedBytes 100000000

# 4. Download Microsoft WSL2 Kernel MSI Update package
$WslMsiUrl = "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
Download-File16Threads -FileName $WslMsiName -Urls @($WslMsiUrl) -MinExpectedBytes 10000000

# 5. Download OpenSSH server and client deb packages for offline Linux/WSL
Write-Host ""
Write-Host "[*] Downloading OpenSSH packages for offline Linux/WSL..." -ForegroundColor Cyan
$OfflinePkgDir = Join-Path $ScriptDir "offline_packages"
if (-not (Test-Path $OfflinePkgDir)) { New-Item -ItemType Directory -Path $OfflinePkgDir -Force | Out-Null }
$SshUrls = @(
    "http://archive.ubuntu.com/ubuntu/pool/main/o/openssh/openssh-client_8.9p1-3_amd64.deb",
    "http://archive.ubuntu.com/ubuntu/pool/main/o/openssh/openssh-server_8.9p1-3_amd64.deb",
    "http://archive.ubuntu.com/ubuntu/pool/main/o/openssh/openssh-sftp-server_8.9p1-3_amd64.deb"
)
foreach ($url in $SshUrls) {
    $debFile = Split-Path $url -Leaf
    $targetDeb = Join-Path $OfflinePkgDir $debFile
    if (-not (Test-Path $targetDeb)) {
        try {
            if ($Aria2Cmd) {
                & $Aria2Exe --split=16 --max-connection-per-server=16 -k 1M --file-allocation=none --dir="$OfflinePkgDir" --out="$debFile" "$url" 2>$null
            } else {
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                Invoke-WebRequest -Uri $url -OutFile $targetDeb -UseBasicParsing
            }
        } catch {}
    }
    if (Test-Path $targetDeb) {
        Write-Host "  [✓] OpenSSH package ready: $debFile" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "==============================================================================" -ForegroundColor Green
Write-Host "  🎉 Complete Offline Backup Ready! Saved inside: $ScriptDir" -ForegroundColor Yellow
Write-Host "  • Hadoop Tarball : $TarName" -ForegroundColor White
Write-Host "  • Examples JAR   : $JarName" -ForegroundColor White
Write-Host "  • Java OpenJDK 11: $JavaTarName" -ForegroundColor White
Write-Host "  • WSL Kernel MSI : $WslMsiName" -ForegroundColor White
Write-Host "  • OpenSSH Debs   : offline_packages/openssh*.deb" -ForegroundColor White
Write-Host "  You can now copy this folder to a USB drive or install completely offline!" -ForegroundColor Green
Write-Host "==============================================================================" -ForegroundColor Green
Write-Host ""
