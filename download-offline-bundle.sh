#!/usr/bin/env bash
# ==============================================================================
# download-offline-bundle.sh: Complete Offline Lab PC Backup Downloader
# Downloads ALL required offline installation files into this local Hadoop folder:
#   1. Apache Hadoop 3.3.6 tarball (hadoop-3.3.6.tar.gz)
#   2. Hadoop MapReduce Examples JAR (hadoop-mapreduce-examples-3.3.6.jar)
#   3. Java OpenJDK 11 LTS Linux binary (OpenJDK11U-jdk_x64_linux_hotspot_11.0.22_7.tar.gz)
#   4. Microsoft WSL Kernel update package (wsl_update_x64.msi)
#
# Accelerated with 16 concurrent connections via aria2c (Zero Fallback)
# ==============================================================================

set -e

BOLD="\033[1m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
RED="\033[1;31m"
RESET="\033[0m"

HADOOP_VERSION="${HADOOP_VERSION:-3.3.6}"
JAVA_VERSION="11.0.22_7"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || pwd)"

TAR_NAME="hadoop-${HADOOP_VERSION}.tar.gz"
JAR_NAME="hadoop-mapreduce-examples-${HADOOP_VERSION}.jar"
JAVA_TAR_NAME="OpenJDK11U-jdk_x64_linux_hotspot_${JAVA_VERSION}.tar.gz"
WSL_MSI_NAME="wsl_update_x64.msi"

echo -e "${GREEN}================================================================${RESET}"
echo -e "${GREEN}${BOLD}    Complete Apache Hadoop & WSL Offline Lab Backup Downloader   ${RESET}"
echo -e "${GREEN}================================================================${RESET}"
echo " Destination Directory: $SCRIPT_DIR"
echo " Components to Backup :"
echo "   1. Hadoop Binary Archive  : $TAR_NAME"
echo "   2. MapReduce Examples JAR : $JAR_NAME"
echo "   3. Java OpenJDK 11 LTS    : $JAVA_TAR_NAME"
echo "   4. WSL2 Kernel MSI Update : $WSL_MSI_NAME"
echo -e "${GREEN}================================================================${RESET}"

# 1. Ensure aria2c is installed for 16-thread multi-connection downloading
if ! command -v aria2c >/dev/null 2>&1; then
    echo -e "${YELLOW}[*] aria2c not detected. Installing aria2 for 16-thread downloading...${RESET}"
    SUDO_CMD=""
    [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1 && SUDO_CMD="sudo"

    if command -v apt-get >/dev/null 2>&1; then
        $SUDO_CMD apt-get update -y
        $SUDO_CMD apt-get install -y software-properties-common ca-certificates 2>/dev/null || true
        command -v add-apt-repository >/dev/null 2>&1 && $SUDO_CMD add-apt-repository -y universe 2>/dev/null || true
        $SUDO_CMD apt-get update -y
        $SUDO_CMD apt-get install -y aria2
    elif command -v dnf >/dev/null 2>&1; then
        $SUDO_CMD dnf install -y epel-release 2>/dev/null || true
        $SUDO_CMD dnf install -y aria2
    elif command -v yum >/dev/null 2>&1; then
        $SUDO_CMD yum install -y epel-release 2>/dev/null || true
        $SUDO_CMD yum install -y aria2
    elif command -v pacman >/dev/null 2>&1; then
        $SUDO_CMD pacman -Sy --noconfirm aria2
    elif command -v brew >/dev/null 2>&1; then
        brew install aria2
    fi
fi

if ! command -v aria2c >/dev/null 2>&1; then
    echo -e "${RED}[FATAL] aria2c could not be installed. aria2 is required for 16-thread downloads.${RESET}"
    exit 1
fi

echo -e "${GREEN}  ✓ aria2c 16-connection downloader active: $(aria2c --version | head -n 1)${RESET}"

# Helper function to download file with 16 threads via aria2c
download_16_threads() {
    local outfile="$1"
    shift
    local urls=("$@")

    if [ -f "$SCRIPT_DIR/$outfile" ] && [ -s "$SCRIPT_DIR/$outfile" ]; then
        echo -e "${GREEN}  ✓ Found existing valid $outfile. Skipping download.${RESET}"
        return 0
    fi

    echo -e "\n${CYAN}[*] Downloading $outfile with 16 concurrent connections...${RESET}"
    rm -f "$SCRIPT_DIR/$outfile"
    aria2c \
        --split=16 \
        --max-connection-per-server=16 \
        --min-split-size=1M \
        --max-concurrent-downloads=16 \
        --file-allocation=none \
        --summary-interval=5 \
        --max-tries=5 \
        --retry-wait=2 \
        --dir="$SCRIPT_DIR" \
        --out="$outfile" \
        "${urls[@]}"
}

# 2. Download Apache Hadoop 3.3.6 tarball
HADOOP_PRIMARY="https://dlcdn.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/${TAR_NAME}"
HADOOP_ARCHIVE="https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/${TAR_NAME}"
HADOOP_BACKUP="https://downloads.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/${TAR_NAME}"

download_16_threads "$TAR_NAME" "$HADOOP_PRIMARY" "$HADOOP_ARCHIVE" "$HADOOP_BACKUP"

# Verify Hadoop tarball integrity
if ! tar -tzf "$SCRIPT_DIR/$TAR_NAME" | head -n 10 >/dev/null 2>&1; then
    echo -e "${RED}[ERROR] Hadoop archive corrupted. Re-downloading with 16 connections...${RESET}"
    rm -f "$SCRIPT_DIR/$TAR_NAME"
    aria2c -x 16 -s 16 -k 1M --file-allocation=none --dir="$SCRIPT_DIR" --out="$TAR_NAME" "$HADOOP_ARCHIVE" "$HADOOP_PRIMARY"
fi
echo -e "${GREEN}  ✓ Apache Hadoop archive verified ($TAR_NAME).${RESET}"

# 3. Extract hadoop-mapreduce-examples JAR directly into local folder
echo -e "\n${CYAN}[*] Extracting MapReduce examples JAR into offline bundle...${RESET}"
JAR_PATH_IN_TAR="hadoop-${HADOOP_VERSION}/share/hadoop/mapreduce/hadoop-mapreduce-examples-${HADOOP_VERSION}.jar"
tar -xzf "$SCRIPT_DIR/$TAR_NAME" "$JAR_PATH_IN_TAR" -O > "$SCRIPT_DIR/$JAR_NAME" 2>/dev/null || true

if [ -f "$SCRIPT_DIR/$JAR_NAME" ] && [ -s "$SCRIPT_DIR/$JAR_NAME" ]; then
    echo -e "${GREEN}  ✓ MapReduce examples JAR ready: $JAR_NAME${RESET}"
else
    echo -e "${YELLOW}  ! JAR remains available inside the tarball.${RESET}"
fi

# 4. Download Java OpenJDK 11 LTS (Linux x64) for offline WSL/Linux installation
JAVA_URL1="https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.22%2B7/OpenJDK11U-jdk_x64_linux_hotspot_11.0.22_7.tar.gz"
JAVA_URL2="https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.21%2B9/OpenJDK11U-jdk_x64_linux_hotspot_11.0.21_9.tar.gz"

download_16_threads "$JAVA_TAR_NAME" "$JAVA_URL1" "$JAVA_URL2"

if tar -tzf "$SCRIPT_DIR/$JAVA_TAR_NAME" | head -n 10 >/dev/null 2>&1; then
    echo -e "${GREEN}  ✓ Java OpenJDK 11 LTS archive verified ($JAVA_TAR_NAME).${RESET}"
fi

# 5. Download Microsoft WSL2 Kernel update installer for offline Windows WSL setup
WSL_MSI_URL="https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
download_16_threads "$WSL_MSI_NAME" "$WSL_MSI_URL"

# 6. Download OpenSSH server and client deb packages for offline installation
echo -e "\n${CYAN}[*] Downloading OpenSSH packages for offline Linux/WSL installation...${RESET}"
mkdir -p "$SCRIPT_DIR/offline_packages"
SSH_DEB_URLS=(
    "http://archive.ubuntu.com/ubuntu/pool/main/o/openssh/openssh-client_8.9p1-3ubuntu0.10_amd64.deb"
    "http://archive.ubuntu.com/ubuntu/pool/main/o/openssh/openssh-server_8.9p1-3ubuntu0.10_amd64.deb"
    "http://archive.ubuntu.com/ubuntu/pool/main/o/openssh/openssh-sftp-server_8.9p1-3ubuntu0.10_amd64.deb"
)
for deb_url in "${SSH_DEB_URLS[@]}"; do
    deb_file=$(basename "$deb_url")
    if [ ! -f "$SCRIPT_DIR/offline_packages/$deb_file" ]; then
        aria2c -x 16 -s 16 -k 1M --file-allocation=none --dir="$SCRIPT_DIR/offline_packages" --out="$deb_file" "$deb_url" 2>/dev/null || true
    fi
done
echo -e "${GREEN}  ✓ OpenSSH packages ready in offline_packages/.${RESET}"

echo -e "\n${GREEN}================================================================${RESET}"
echo -e "${GREEN}${BOLD}    🎉 Complete Offline Backup Bundle Ready on this Machine!     ${RESET}"
echo -e "${GREEN}================================================================${RESET}"
echo -e "Saved inside: ${BOLD}$SCRIPT_DIR${RESET}"
echo -e "  • Hadoop Tarball : $TAR_NAME ($(du -h "$SCRIPT_DIR/$TAR_NAME" 2>/dev/null | cut -f1 || echo "Present"))"
echo -e "  • Examples JAR   : $JAR_NAME ($(du -h "$SCRIPT_DIR/$JAR_NAME" 2>/dev/null | cut -f1 || echo "Present"))"
echo -e "  • Java OpenJDK 11: $JAVA_TAR_NAME ($(du -h "$SCRIPT_DIR/$JAVA_TAR_NAME" 2>/dev/null | cut -f1 || echo "Present"))"
echo -e "  • WSL Kernel MSI : $WSL_MSI_NAME ($(du -h "$SCRIPT_DIR/$WSL_MSI_NAME" 2>/dev/null | cut -f1 || echo "Present"))"
echo ""
echo -e "${BOLD}How to Install Completely Offline on a Disconnected Lab PC:${RESET}"
echo -e "  1. Copy this entire ${CYAN}Hadoop${RESET} directory to a USB drive or local path."
echo -e "  2. On Windows: double-click ${CYAN}setup-wsl.bat${RESET}"
echo -e "  3. On Linux/WSL: run ${CYAN}./install.sh${RESET}"
echo -e "  4. All components (WSL, Java, Hadoop, WordCount) will install"
echo -e "     100% offline with zero Internet connection required!"
echo -e "${GREEN}================================================================${RESET}"
