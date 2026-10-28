#!/usr/bin/env bash
# ==============================================================================
# Apache Hadoop Automated One-Click Installer & Configurator
# Fully compatible with: WSL (Windows Subsystem for Linux), Ubuntu, Debian,
# Kali Linux, CentOS, RHEL, Fedora, Rocky, AlmaLinux, Arch Linux, and openSUSE.
#
# Process Sequence:
#   [1] sudo update: System package manager cache refresh & core utilities
#   [2] Java install: OpenJDK 11 LTS installation & JAVA_HOME detection
#   [3] SSH install: OpenSSH setup, passwordless keypair, hostkeys, & service start
#   [4] 16-Connection Download: aria2c multi-connection download (strictly no fallback)
#   [5] Hadoop Configuration: XML configs, classpath, hadoop-env, & NameNode format
#   [6] CLI Installation: 'ran-hadoop' and 'run-wordcount' global environment
#   [7] Cluster Verification & MapReduce WordCount execution inside WSL
# ==============================================================================

set -e

# Ensure valid Linux home directory in WSL environments
REAL_HOME=$(getent passwd "$(whoami)" | cut -d: -f6)
if [ -n "$REAL_HOME" ] && [ -d "$REAL_HOME" ]; then
    export HOME="$REAL_HOME"
fi

# Color helpers
BOLD="\033[1m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
RED="\033[1;31m"
RESET="\033[0m"

HADOOP_VERSION="${HADOOP_VERSION:-3.3.6}"
INSTALL_DIR="${HADOOP_INSTALL_DIR:-$HOME/hadoop}"
DATA_DIR="${HADOOP_DATA_DIR:-$HOME/hadoop_data}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || pwd)"

# ------------------------------------------------------------------------------
# WSL Windows Mount Relocation Guard:
# If executed from Windows mount (/mnt/c/...) in WSL, migrate to WSL native ext4 (~/Hadoop)
# ------------------------------------------------------------------------------
case "$SCRIPT_DIR" in
    /mnt/*)
        echo -e "${CYAN}[*] Detected execution from Windows drive mount: $SCRIPT_DIR${RESET}"
        echo -e "${CYAN}[*] Migrating files into WSL native ext4 Linux filesystem ($HOME/Hadoop)...${RESET}"
        mkdir -p "$HOME/Hadoop"
        cp -rf "$SCRIPT_DIR"/* "$HOME/Hadoop/" 2>/dev/null || true
        find "$HOME/Hadoop" -maxdepth 2 -type f \( -name "*.sh" -o -name "ran-hadoop" -o -name "*.xml" -o -name "*.txt" \) -exec sed -i 's/\r$//' {} + 2>/dev/null || true
        chmod +x "$HOME/Hadoop/install.sh" "$HOME/Hadoop/ran-hadoop" "$HOME/Hadoop/run-wordcount.sh" "$HOME/Hadoop/scripts/"*.sh 2>/dev/null || true
        cd "$HOME/Hadoop"
        exec "$HOME/Hadoop/install.sh" "$@"
        ;;
esac

# Auto-bootstrap repository if executed directly via pipe (e.g. curl ... | bash)
if [ ! -f "$SCRIPT_DIR/ran-hadoop" ] || [ ! -d "$SCRIPT_DIR/conf" ] || [ ! -f "$SCRIPT_DIR/WordCount.java" ]; then
    echo -e "${YELLOW}[*] Bootstrapping latest Hadoop installer files from GitHub...${RESET}"
    BOOTSTRAP_DIR="$HOME/Hadoop"
    echo -e "${CYAN}    Target destination: $BOOTSTRAP_DIR (WSL Native Linux Filesystem)${RESET}"
    mkdir -p "$BOOTSTRAP_DIR"
    if [ -d "$BOOTSTRAP_DIR/.git" ] && command -v git >/dev/null 2>&1; then
        echo "    Pulling latest updates via git..."
        (cd "$BOOTSTRAP_DIR" && git fetch --all 2>/dev/null && git reset --hard origin/main 2>/dev/null) || true
    elif [ ! -d "$BOOTSTRAP_DIR/.git" ]; then
        if command -v git >/dev/null 2>&1; then
            git clone https://github.com/fridayslifes/Hadoop.git "$BOOTSTRAP_DIR" 2>/dev/null || (cd "$BOOTSTRAP_DIR" && git fetch --all 2>/dev/null && git reset --hard origin/main 2>/dev/null) || true
        else
            curl -sSL https://github.com/fridayslifes/Hadoop/archive/refs/heads/main.tar.gz | tar -xz -C "$BOOTSTRAP_DIR" --strip-components=1 2>/dev/null || true
        fi
    fi
    cd "$BOOTSTRAP_DIR"
    find "$BOOTSTRAP_DIR" -maxdepth 2 -type f \( -name "*.sh" -o -name "ran-hadoop" -o -name "*.xml" -o -name "*.txt" \) -exec sed -i 's/\r$//' {} + 2>/dev/null || true
    chmod +x install.sh ran-hadoop run-wordcount.sh download-offline-bundle.sh scripts/*.sh 2>/dev/null || true
    exec "$BOOTSTRAP_DIR/install.sh" "$@"
fi

# Normalize CRLF line endings on repository scripts
find "$SCRIPT_DIR" -maxdepth 2 -type f \( -name "*.sh" -o -name "ran-hadoop" -o -name "*.xml" -o -name "*.txt" \) -exec sed -i 's/\r$//' {} + 2>/dev/null || true
chmod +x "$SCRIPT_DIR/install.sh" "$SCRIPT_DIR/ran-hadoop" "$SCRIPT_DIR/run-wordcount.sh" "$SCRIPT_DIR/scripts/"*.sh 2>/dev/null || true

export DEBIAN_FRONTEND=noninteractive

echo -e "${GREEN}================================================================${RESET}"
echo -e "${GREEN}${BOLD}       Apache Hadoop Automated One-Click Installer (WSL)        ${RESET}"
echo -e "${GREEN}================================================================${RESET}"
echo " Target Version   : Apache Hadoop $HADOOP_VERSION"
echo " Installation Dir : $INSTALL_DIR"
echo " Data Directory   : $DATA_DIR"
echo " User             : $(whoami)"
echo " OS / Kernel      : $(uname -s) $(uname -r)"
echo -e "${GREEN}================================================================${RESET}"

# Sudo detection: run directly if root, otherwise prefix with sudo
SUDO_CMD=""
if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
        SUDO_CMD="sudo"
    else
        echo -e "${YELLOW}  ! Sudo not found. Will proceed assuming privileges or pre-installed packages.${RESET}"
    fi
fi

# Detect package manager
PKG_MANAGER=""
if command -v apt-get >/dev/null 2>&1; then
    PKG_MANAGER="apt"
elif command -v dnf >/dev/null 2>&1; then
    PKG_MANAGER="dnf"
elif command -v yum >/dev/null 2>&1; then
    PKG_MANAGER="yum"
elif command -v pacman >/dev/null 2>&1; then
    PKG_MANAGER="pacman"
elif command -v zypper >/dev/null 2>&1; then
    PKG_MANAGER="zypper"
fi

# ==============================================================================
# [Step 1/7] sudo update: System Package Index & Core Utilities
# ==============================================================================
echo -e "\n${CYAN}[Step 1/7] Updating System Packages (sudo update)...${RESET}"

if [ -n "$PKG_MANAGER" ]; then
    case "$PKG_MANAGER" in
        apt)
            echo "  Refreshing apt repository cache..."
            $SUDO_CMD apt-get update -y
            $SUDO_CMD apt-get install -y software-properties-common ca-certificates curl wget rsync tar git procps net-tools
            # Ensure universe repository is enabled for Ubuntu/Debian/Kali WSL
            if command -v add-apt-repository >/dev/null 2>&1; then
                $SUDO_CMD add-apt-repository -y universe 2>/dev/null || true
                $SUDO_CMD apt-get update -y
            fi
            ;;
        dnf|yum)
            echo "  Refreshing $PKG_MANAGER repository cache..."
            $SUDO_CMD "$PKG_MANAGER" update -y
            $SUDO_CMD "$PKG_MANAGER" install -y epel-release 2>/dev/null || true
            $SUDO_CMD "$PKG_MANAGER" install -y curl wget rsync tar git procps-ng net-tools
            ;;
        pacman)
            echo "  Refreshing pacman repository cache..."
            $SUDO_CMD pacman -Sy --noconfirm curl wget rsync tar git procps-ng net-tools
            ;;
        zypper)
            echo "  Refreshing zypper repository cache..."
            $SUDO_CMD zypper --non-interactive refresh
            $SUDO_CMD zypper --non-interactive install curl wget rsync tar git procps net-tools
            ;;
        *)
            echo -e "${YELLOW}  Unknown package manager. Checking installed tools...${RESET}"
            ;;
    esac
    echo -e "${GREEN}  ✓ System packages updated successfully.${RESET}"
else
    echo -e "${YELLOW}  ! No supported package manager found; proceeding with existing binaries.${RESET}"
fi

# ==============================================================================
# [Step 2/7] Java install: OpenJDK 11 LTS & Detection
# ==============================================================================
echo -e "\n${CYAN}[Step 2/7] Installing Java Development Kit (OpenJDK 11 LTS)...${RESET}"

# Check for local offline Java archive in repository folder
LOCAL_JAVA_TAR=""
for cand in "$SCRIPT_DIR"/OpenJDK11U-jdk_x64_linux_hotspot_*.tar.gz "$SCRIPT_DIR"/openjdk-11*.tar.gz /mnt/c/Users/*/Desktop/Hadoop/OpenJDK11U-jdk_x64_linux_hotspot_*.tar.gz; do
    if [ -f "$cand" ] && tar -tzf "$cand" | head -n 10 >/dev/null 2>&1; then
        LOCAL_JAVA_TAR="$cand"
        break
    fi
done

if [ -n "$LOCAL_JAVA_TAR" ]; then
    echo -e "${GREEN}  ✓ Found local offline Java JDK archive: $(basename "$LOCAL_JAVA_TAR")${RESET}"
    $SUDO_CMD mkdir -p /usr/lib/jvm/java-11-openjdk-amd64
    $SUDO_CMD tar -xzf "$LOCAL_JAVA_TAR" -C /usr/lib/jvm/java-11-openjdk-amd64 --strip-components=1
    DETECTED_JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
elif [ -n "$PKG_MANAGER" ]; then
    case "$PKG_MANAGER" in
        apt)
            $SUDO_CMD apt-get install -y openjdk-11-jdk 2>/dev/null || \
            $SUDO_CMD apt-get install -y openjdk-8-jdk 2>/dev/null || \
            $SUDO_CMD apt-get install -y default-jdk
            ;;
        dnf|yum)
            $SUDO_CMD "$PKG_MANAGER" install -y java-11-openjdk-devel || \
            $SUDO_CMD "$PKG_MANAGER" install -y java-1.8.0-openjdk-devel
            ;;
        pacman)
            $SUDO_CMD pacman -Sy --noconfirm jdk11-openjdk || \
            $SUDO_CMD pacman -Sy --noconfirm jdk8-openjdk
            ;;
        zypper)
            $SUDO_CMD zypper --non-interactive install java-11-openjdk-devel || \
            $SUDO_CMD zypper --non-interactive install java-1_8_0-openjdk-devel
            ;;
    esac
fi

# Probe standard JDK directories
DETECTED_JAVA_HOME=""
for candidate in \
    /usr/lib/jvm/java-11-openjdk* \
    /usr/lib/jvm/java-1.11.0-openjdk* \
    /usr/lib/jvm/java-8-openjdk* \
    /usr/lib/jvm/java-1.8.0-openjdk* \
    /usr/lib/jvm/default-java \
    /usr/lib/jvm/java-openjdk; do
    if [ -d "$candidate" ] && [ -x "$candidate/bin/java" ]; then
        DETECTED_JAVA_HOME="$candidate"
        break
    fi
done

# Fallback to resolving 'java' symlink
if [ -z "$DETECTED_JAVA_HOME" ] && command -v java >/dev/null 2>&1; then
    RESOLVED_JAVA=$(readlink -f "$(command -v java)")
    DETECTED_JAVA_HOME=$(dirname "$(dirname "$RESOLVED_JAVA")")
fi

if [ -z "$DETECTED_JAVA_HOME" ] || [ ! -d "$DETECTED_JAVA_HOME" ]; then
    echo -e "${RED}[ERROR] Valid JDK installation could not be detected.${RESET}"
    echo "Attempting recovery install via default-jdk..."
    if [ "$PKG_MANAGER" = "apt" ]; then
        $SUDO_CMD apt-get install -y --fix-missing default-jdk
        DETECTED_JAVA_HOME="/usr/lib/jvm/default-java"
    fi
    if [ ! -d "$DETECTED_JAVA_HOME" ]; then
        echo -e "${RED}[FATAL] Java JDK installation failed. Please install OpenJDK manually.${RESET}"
        exit 1
    fi
fi

export JAVA_HOME="$DETECTED_JAVA_HOME"
echo -e "${GREEN}  ✓ JAVA_HOME located: $JAVA_HOME${RESET}"
echo "    Java version: $("$JAVA_HOME/bin/java" -version 2>&1 | head -n 1)"

# ==============================================================================
# [Step 3/7] SSH install: OpenSSH Server & Passwordless Localhost Setup
# ==============================================================================
echo -e "\n${CYAN}[Step 3/7] Installing and Configuring OpenSSH Server & Client...${RESET}"

# Check for local offline OpenSSH deb packages
LOCAL_SSH_DEBS=$(ls "$SCRIPT_DIR"/offline_packages/openssh*.deb 2>/dev/null || true)
if [ -n "$LOCAL_SSH_DEBS" ]; then
    echo -e "${GREEN}  ✓ Installing OpenSSH from local offline packages...${RESET}"
    $SUDO_CMD dpkg -i "$SCRIPT_DIR"/offline_packages/openssh*.deb 2>/dev/null || true
elif [ -n "$PKG_MANAGER" ]; then
    case "$PKG_MANAGER" in
        apt)
            $SUDO_CMD apt-get install -y openssh-server openssh-client
            ;;
        dnf|yum)
            $SUDO_CMD "$PKG_MANAGER" install -y openssh-server openssh-clients
            ;;
        pacman)
            $SUDO_CMD pacman -Sy --noconfirm openssh
            ;;
        zypper)
            $SUDO_CMD zypper --non-interactive install openssh
            ;;
    esac
fi

chmod 755 "$HOME" 2>/dev/null || true
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# Generate key if not present
if [ ! -f "$HOME/.ssh/id_rsa" ]; then
    echo "  Generating new RSA keypair (~/.ssh/id_rsa)..."
    ssh-keygen -t rsa -P "" -f "$HOME/.ssh/id_rsa" -q
fi

# Add key to authorized_keys
if [ ! -f "$HOME/.ssh/authorized_keys" ] || ! grep -q -F "$(cat "$HOME/.ssh/id_rsa.pub")" "$HOME/.ssh/authorized_keys" 2>/dev/null; then
    echo "  Adding public key to ~/.ssh/authorized_keys..."
    cat "$HOME/.ssh/id_rsa.pub" >> "$HOME/.ssh/authorized_keys"
fi
chmod 600 "$HOME/.ssh/authorized_keys"
chmod 600 "$HOME/.ssh/id_rsa" 2>/dev/null || true
chmod 644 "$HOME/.ssh/id_rsa.pub" 2>/dev/null || true

# Config for strict host checking bypass on localhost
cat << 'EOF' > "$HOME/.ssh/config.tmp"
Host localhost 127.0.0.1 0.0.0.0
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel ERROR
EOF
mv "$HOME/.ssh/config.tmp" "$HOME/.ssh/config"
chmod 600 "$HOME/.ssh/config"

# SSH daemon host keys and privilege separation directory for WSL
$SUDO_CMD mkdir -p /run/sshd 2>/dev/null || true
$SUDO_CMD ssh-keygen -A >/dev/null 2>&1 || true

# Start SSH daemon
echo "  Starting SSH service daemon..."
if command -v service >/dev/null 2>&1; then
    $SUDO_CMD service ssh start >/dev/null 2>&1 || $SUDO_CMD service ssh restart >/dev/null 2>&1 || true
elif command -v systemctl >/dev/null 2>&1; then
    $SUDO_CMD systemctl start ssh >/dev/null 2>&1 || $SUDO_CMD systemctl start sshd >/dev/null 2>&1 || true
else
    $SUDO_CMD /usr/sbin/sshd >/dev/null 2>&1 || true
fi

# Verify passwordless SSH localhost connection
if ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=5 localhost "echo SSH_OK" >/dev/null 2>&1; then
    echo -e "${GREEN}  ✓ Passwordless SSH connection to localhost confirmed.${RESET}"
else
    echo -e "${YELLOW}  ! Retrying SSH daemon startup...${RESET}"
    $SUDO_CMD mkdir -p /run/sshd 2>/dev/null || true
    $SUDO_CMD ssh-keygen -A >/dev/null 2>&1 || true
    $SUDO_CMD service ssh restart >/dev/null 2>&1 || $SUDO_CMD /usr/sbin/sshd >/dev/null 2>&1 || true
fi

# ==============================================================================
# [Step 4/7] 16-Connection Download: aria2c (Strictly No Fallback - Always Resolve)
# ==============================================================================
echo -e "\n${CYAN}[Step 4/7] 16-Thread Accelerated Hadoop Download (aria2c)...${RESET}"

# Install aria2 if not present - do NOT fall back to curl or single thread
if ! command -v aria2c >/dev/null 2>&1; then
    echo "  aria2c is not present. Installing aria2 package for 16 concurrent connections..."
    if [ -n "$PKG_MANAGER" ]; then
        case "$PKG_MANAGER" in
            apt)
                $SUDO_CMD apt-get update -y
                $SUDO_CMD apt-get install -y software-properties-common ca-certificates 2>/dev/null || true
                $SUDO_CMD add-apt-repository -y universe 2>/dev/null || true
                $SUDO_CMD apt-get update -y
                $SUDO_CMD apt-get install -y aria2
                ;;
            dnf|yum)
                $SUDO_CMD "$PKG_MANAGER" install -y epel-release 2>/dev/null || true
                $SUDO_CMD "$PKG_MANAGER" install -y aria2
                ;;
            pacman)
                $SUDO_CMD pacman -Sy --noconfirm aria2
                ;;
            zypper)
                $SUDO_CMD zypper --non-interactive install aria2
                ;;
        esac
    fi
fi

# Verify aria2c is available
if ! command -v aria2c >/dev/null 2>&1; then
    echo -e "${RED}[ERROR] aria2c installation failed. Resolving by package retry...${RESET}"
    if [ "$PKG_MANAGER" = "apt" ]; then
        $SUDO_CMD apt-get install -y --fix-missing aria2
    fi
fi

if ! command -v aria2c >/dev/null 2>&1; then
    echo -e "${RED}[FATAL] aria2c is strictly required for 16-connection downloads. Cannot proceed without it.${RESET}"
    exit 1
fi

echo -e "${GREEN}  ✓ aria2c 16-thread downloader ready: $(aria2c --version | head -n 1)${RESET}"

TAR_NAME="hadoop-${HADOOP_VERSION}.tar.gz"
DOWNLOAD_DIR="/tmp/hadoop_download"
mkdir -p "$DOWNLOAD_DIR"

PRIMARY_URL="https://dlcdn.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/${TAR_NAME}"
ARCHIVE_URL="https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/${TAR_NAME}"
BACKUP_URL="https://downloads.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/${TAR_NAME}"

# Auto-detect local offline backup archive in repository directory or Desktop
LOCAL_TAR=""
for candidate_tar in \
    "$SCRIPT_DIR/$TAR_NAME" \
    "$HOME/Hadoop/$TAR_NAME" \
    "$DOWNLOAD_DIR/$TAR_NAME" \
    /mnt/c/Users/*/Desktop/Hadoop/"$TAR_NAME"; do
    if [ -f "$candidate_tar" ] && tar -tzf "$candidate_tar" | head -n 10 >/dev/null 2>&1; then
        LOCAL_TAR="$candidate_tar"
        break
    fi
done

if [ -n "$LOCAL_TAR" ]; then
    echo -e "${GREEN}  ✓ Found local offline backup archive: $LOCAL_TAR${RESET}"
    echo -e "${GREEN}  ✓ Utilizing local offline bundle (No Internet Required)!${RESET}"
    if [ "$LOCAL_TAR" != "$DOWNLOAD_DIR/$TAR_NAME" ]; then
        cp -f "$LOCAL_TAR" "$DOWNLOAD_DIR/$TAR_NAME"
    fi
else
    echo "  Downloading Apache Hadoop $HADOOP_VERSION with 16 concurrent connections (aria2c)..."
    rm -f "$DOWNLOAD_DIR/$TAR_NAME" "$DOWNLOAD_DIR/$TAR_NAME.aria2"

    max_dl_attempts=5
    dl_attempt=1
    target_dl="$DOWNLOAD_DIR/$TAR_NAME"

    while [ "$dl_attempt" -le "$max_dl_attempts" ]; do
        echo -e "  ${CYAN}[Attempt $dl_attempt/$max_dl_attempts] Starting 16-thread download with live stall monitor...${RESET}"
        
        aria2c \
            --split=16 \
            --max-connection-per-server=16 \
            --min-split-size=1M \
            --max-concurrent-downloads=16 \
            --file-allocation=none \
            --lowest-speed-limit=10K \
            --timeout=30 \
            --connect-timeout=15 \
            --summary-interval=2 \
            --max-tries=5 \
            --retry-wait=2 \
            --auto-file-renaming=false \
            --allow-overwrite=true \
            --dir="$DOWNLOAD_DIR" \
            --out="$TAR_NAME" \
            "$PRIMARY_URL" "$ARCHIVE_URL" "$BACKUP_URL" || true

        # Completion & Integrity Checker
        if [ -f "$target_dl" ]; then
            final_sz=$(stat -c%s "$target_dl" 2>/dev/null || stat -f%z "$target_dl" 2>/dev/null || wc -c < "$target_dl" 2>/dev/null || echo 0)
            if [ "$final_sz" -ge 500000000 ] && tar -tzf "$target_dl" | head -n 10 >/dev/null 2>&1; then
                echo -e "${GREEN}  ✓ [CHECKER PASSED] Download 100% complete & archive verified ($(( final_sz / 1048576 )) MB).${RESET}"
                rm -f "$target_dl.aria2"
                break
            else
                echo -e "${RED}  ! [CHECKER FAILED] Archive failed integrity test ($(( final_sz / 1048576 )) MB). Retrying in 3s...${RESET}"
                rm -f "$target_dl" "$target_dl.aria2"
            fi
        fi

        dl_attempt=$(( dl_attempt + 1 ))
        sleep 3
    done

    # Save a persistent offline backup inside the local repository directory on this PC
    if [ -d "$SCRIPT_DIR" ] && [ -w "$SCRIPT_DIR" ]; then
        echo "  Saving offline backup tarball inside local Hadoop folder on this PC..."
        cp -f "$DOWNLOAD_DIR/$TAR_NAME" "$SCRIPT_DIR/$TAR_NAME" 2>/dev/null || true
    fi
fi

# Verify archive integrity
if ! tar -tzf "$DOWNLOAD_DIR/$TAR_NAME" | head -n 10 >/dev/null 2>&1; then
    echo -e "${RED}[ERROR] Downloaded archive is corrupt. Re-downloading with 16 connections...${RESET}"
    rm -f "$DOWNLOAD_DIR/$TAR_NAME"
    aria2c -x 16 -s 16 -k 1M --file-allocation=none --dir="$DOWNLOAD_DIR" --out="$TAR_NAME" "$ARCHIVE_URL" "$PRIMARY_URL"
    cp -f "$DOWNLOAD_DIR/$TAR_NAME" "$SCRIPT_DIR/$TAR_NAME" 2>/dev/null || true
fi
echo -e "${GREEN}  ✓ Apache Hadoop archive verified successfully.${RESET}"

# Also ensure mapreduce examples JAR is backed up locally in the repo folder
JAR_IN_TAR="hadoop-${HADOOP_VERSION}/share/hadoop/mapreduce/hadoop-mapreduce-examples-${HADOOP_VERSION}.jar"
if [ ! -f "$SCRIPT_DIR/hadoop-mapreduce-examples-${HADOOP_VERSION}.jar" ] && [ -w "$SCRIPT_DIR" ]; then
    tar -xzf "$DOWNLOAD_DIR/$TAR_NAME" "$JAR_IN_TAR" -O > "$SCRIPT_DIR/hadoop-mapreduce-examples-${HADOOP_VERSION}.jar" 2>/dev/null || true
    [ -s "$SCRIPT_DIR/hadoop-mapreduce-examples-${HADOOP_VERSION}.jar" ] && echo -e "${GREEN}  ✓ Saved MapReduce examples JAR backup inside $SCRIPT_DIR.${RESET}"
fi

# ==============================================================================
# [Step 5/7] Hadoop Extraction & Configuration
# ==============================================================================
echo -e "\n${CYAN}[Step 5/7] Extracting & Configuring Apache Hadoop Pseudo-Distributed Cluster...${RESET}"

# Wipe any prior conflicting cluster binaries or data
rm -rf "$INSTALL_DIR"/* "$DATA_DIR/tmp" "$DATA_DIR/hdfs/namenode" "$DATA_DIR/hdfs/datanode" 2>/dev/null || true
mkdir -p "$INSTALL_DIR"
tar -xzf "$DOWNLOAD_DIR/$TAR_NAME" -C "$INSTALL_DIR" --strip-components=1

# Ensure official verified binary examples JAR is in place (overwriting any sources jar)
if [ -f "$SCRIPT_DIR/hadoop-mapreduce-examples-3.3.6.jar" ]; then
    cp -f "$SCRIPT_DIR/hadoop-mapreduce-examples-3.3.6.jar" "$INSTALL_DIR/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar" 2>/dev/null || true
fi

# Create cluster temporary and metadata storage directories
mkdir -p "$DATA_DIR/tmp"
mkdir -p "$DATA_DIR/hdfs/namenode"
mkdir -p "$DATA_DIR/hdfs/datanode"
chmod -R 755 "$DATA_DIR"

HADOOP_CONF_DIR="$INSTALL_DIR/etc/hadoop"
mkdir -p "$HADOOP_CONF_DIR"

# 5a. core-site.xml
cat << EOF > "$HADOOP_CONF_DIR/core-site.xml"
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://localhost:9000</value>
        <description>Default HDFS Master URI</description>
    </property>
    <property>
        <name>fs.default.name</name>
        <value>hdfs://localhost:9000</value>
        <description>Legacy alias for teacher script compatibility</description>
    </property>
    <property>
        <name>hadoop.tmp.dir</name>
        <value>$DATA_DIR/tmp</value>
        <description>Base directory for temporary files</description>
    </property>
    <property>
        <name>io.file.buffer.size</name>
        <value>131072</value>
    </property>
</configuration>
EOF

# 5b. hdfs-site.xml
cat << EOF > "$HADOOP_CONF_DIR/hdfs-site.xml"
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
        <description>Single-node replication factor</description>
    </property>
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>file://$DATA_DIR/hdfs/namenode</value>
        <description>Directory for NameNode transactional metadata</description>
    </property>
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>file://$DATA_DIR/hdfs/datanode</value>
        <description>Directory for DataNode blocks</description>
    </property>
    <property>
        <name>dfs.namenode.http-address</name>
        <value>0.0.0.0:9870</value>
    </property>
    <property>
        <name>dfs.permissions.enabled</name>
        <value>false</value>
    </property>
</configuration>
EOF

# 5c. mapred-site.xml
cat << EOF > "$HADOOP_CONF_DIR/mapred-site.xml"
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
    <property>
        <name>yarn.app.mapreduce.am.env</name>
        <value>HADOOP_MAPRED_HOME=$INSTALL_DIR,HADOOP_COMMON_HOME=$INSTALL_DIR,HADOOP_HDFS_HOME=$INSTALL_DIR,HADOOP_YARN_HOME=$INSTALL_DIR,HADOOP_HOME=$INSTALL_DIR</value>
    </property>
    <property>
        <name>mapreduce.map.env</name>
        <value>HADOOP_MAPRED_HOME=$INSTALL_DIR,HADOOP_COMMON_HOME=$INSTALL_DIR,HADOOP_HDFS_HOME=$INSTALL_DIR,HADOOP_YARN_HOME=$INSTALL_DIR,HADOOP_HOME=$INSTALL_DIR</value>
    </property>
    <property>
        <name>mapreduce.reduce.env</name>
        <value>HADOOP_MAPRED_HOME=$INSTALL_DIR,HADOOP_COMMON_HOME=$INSTALL_DIR,HADOOP_HDFS_HOME=$INSTALL_DIR,HADOOP_YARN_HOME=$INSTALL_DIR,HADOOP_HOME=$INSTALL_DIR</value>
    </property>
    <property>
        <name>mapreduce.map.memory.mb</name>
        <value>1024</value>
    </property>
    <property>
        <name>mapreduce.reduce.memory.mb</name>
        <value>1024</value>
    </property>
    <property>
        <name>mapreduce.application.classpath</name>
        <value>$INSTALL_DIR/share/hadoop/mapreduce/*:$INSTALL_DIR/share/hadoop/mapreduce/lib/*:$INSTALL_DIR/share/hadoop/common/*:$INSTALL_DIR/share/hadoop/common/lib/*:$INSTALL_DIR/share/hadoop/hdfs/*:$INSTALL_DIR/share/hadoop/hdfs/lib/*:$INSTALL_DIR/share/hadoop/yarn/*:$INSTALL_DIR/share/hadoop/yarn/lib/*</value>
    </property>
</configuration>
EOF

# 5d. yarn-site.xml
cat << EOF > "$HADOOP_CONF_DIR/yarn-site.xml"
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
    <property>
        <name>yarn.nodemanager.aux-services.mapreduce.shuffle.class</name>
        <value>org.apache.hadoop.mapred.ShuffleHandler</value>
    </property>
    <property>
        <name>yarn.resourcemanager.hostname</name>
        <value>localhost</value>
    </property>
    <property>
        <name>yarn.resourcemanager.webapp.address</name>
        <value>0.0.0.0:8088</value>
    </property>
    <property>
        <name>yarn.nodemanager.env-whitelist</name>
        <value>JAVA_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,CLASSPATH_PREPEND_DISTCACHE,HADOOP_YARN_HOME,HADOOP_HOME,HADOOP_MAPRED_HOME,PATH,LANG,LC_ALL</value>
    </property>
    <property>
        <name>yarn.application.classpath</name>
        <value>$INSTALL_DIR/etc/hadoop,$INSTALL_DIR/share/hadoop/common/*,$INSTALL_DIR/share/hadoop/common/lib/*,$INSTALL_DIR/share/hadoop/hdfs/*,$INSTALL_DIR/share/hadoop/hdfs/lib/*,$INSTALL_DIR/share/hadoop/mapreduce/*,$INSTALL_DIR/share/hadoop/mapreduce/lib/*,$INSTALL_DIR/share/hadoop/yarn/*,$INSTALL_DIR/share/hadoop/yarn/lib/*</value>
    </property>
    <!-- Prevent container memory check failures in WSL / virtualized environments -->
    <property>
        <name>yarn.nodemanager.pmem-check-enabled</name>
        <value>false</value>
    </property>
    <property>
        <name>yarn.nodemanager.vmem-check-enabled</name>
        <value>false</value>
    </property>
</configuration>
EOF

# 5e. hadoop-env.sh
if grep -q "export JAVA_HOME=" "$HADOOP_CONF_DIR/hadoop-env.sh"; then
    sed -i "s|^#* *export JAVA_HOME=.*|export JAVA_HOME=\"$JAVA_HOME\"|" "$HADOOP_CONF_DIR/hadoop-env.sh"
else
    echo "export JAVA_HOME=\"$JAVA_HOME\"" >> "$HADOOP_CONF_DIR/hadoop-env.sh"
fi

if ! grep -q "export HADOOP_HOME=" "$HADOOP_CONF_DIR/hadoop-env.sh"; then
    cat << EOF >> "$HADOOP_CONF_DIR/hadoop-env.sh"

# Hadoop Environment Exports
export HADOOP_HOME="$INSTALL_DIR"
export HADOOP_CONF_DIR="$HADOOP_CONF_DIR"
export HADOOP_COMMON_HOME="$INSTALL_DIR"
export HADOOP_HDFS_HOME="$INSTALL_DIR"
export HADOOP_MAPRED_HOME="$INSTALL_DIR"
export HADOOP_YARN_HOME="$INSTALL_DIR"
export HADOOP_OS_TYPE="\${HADOOP_OS_TYPE:-\$(uname -s)}"

# Daemon users configuration for WSL and multi-user compatibility
export HDFS_NAMENODE_USER="\${HDFS_NAMENODE_USER:-\$(whoami)}"
export HDFS_DATANODE_USER="\${HDFS_DATANODE_USER:-\$(whoami)}"
export HDFS_SECONDARYNAMENODE_USER="\${HDFS_SECONDARYNAMENODE_USER:-\$(whoami)}"
export YARN_RESOURCEMANAGER_USER="\${YARN_RESOURCEMANAGER_USER:-\$(whoami)}"
export YARN_NODEMANAGER_USER="\${YARN_NODEMANAGER_USER:-\$(whoami)}"
EOF
fi

# Ensure /usr/local/hadoop and /usr/local/hadoop_tmp symlinks exist for teacher/standard scripts
if [ -n "$SUDO_CMD" ] || [ "$(id -u)" -eq 0 ]; then
    $SUDO_CMD mkdir -p /usr/local 2>/dev/null || true
    $SUDO_CMD ln -sfn "$INSTALL_DIR" /usr/local/hadoop 2>/dev/null || true
    $SUDO_CMD ln -sfn "$DATA_DIR" /usr/local/hadoop_tmp 2>/dev/null || true
fi

echo -e "${GREEN}  ✓ Hadoop cluster configurations written to $HADOOP_CONF_DIR.${RESET}"

# Format HDFS NameNode
if [ ! -d "$DATA_DIR/hdfs/namenode/current" ]; then
    echo "  Formatting HDFS NameNode storage..."
    "$INSTALL_DIR/bin/hdfs" namenode -format -force -nonInteractive
    echo -e "${GREEN}  ✓ NameNode format complete.${RESET}"
else
    echo "  HDFS NameNode already contains current metadata. Skipping reformat."
fi

# ==============================================================================
# [Step 6/7] Install CLI Commands ('ran-hadoop', 'run-wordcount') into WSL PATH
# ==============================================================================
echo -e "\n${CYAN}[Step 6/7] Installing 'ran-hadoop' and 'run-wordcount' Globally...${RESET}"

chmod +x "$SCRIPT_DIR/ran-hadoop" "$SCRIPT_DIR/run-wordcount.sh" 2>/dev/null || true

CLI_INSTALLED=0
if [ -w "/usr/local/bin" ] || [ -n "$SUDO_CMD" ] || [ "$(id -u)" -eq 0 ]; then
    if $SUDO_CMD cp "$SCRIPT_DIR/ran-hadoop" /usr/local/bin/ran-hadoop 2>/dev/null && \
       $SUDO_CMD cp "$SCRIPT_DIR/run-wordcount.sh" /usr/local/bin/run-wordcount 2>/dev/null && \
       $SUDO_CMD cp "$SCRIPT_DIR/run-wordcount.sh" /usr/local/bin/run-wordcount.sh 2>/dev/null && \
       $SUDO_CMD chmod 755 /usr/local/bin/ran-hadoop /usr/local/bin/run-wordcount /usr/local/bin/run-wordcount.sh 2>/dev/null; then
        echo -e "${GREEN}  ✓ 'ran-hadoop' and 'run-wordcount' installed to /usr/local/bin.${RESET}"
        CLI_INSTALLED=1
    fi
fi

if [ "$CLI_INSTALLED" -eq 0 ]; then
    mkdir -p "$HOME/.local/bin"
    cp "$SCRIPT_DIR/ran-hadoop" "$HOME/.local/bin/ran-hadoop"
    cp "$SCRIPT_DIR/run-wordcount.sh" "$HOME/.local/bin/run-wordcount"
    cp "$SCRIPT_DIR/run-wordcount.sh" "$HOME/.local/bin/run-wordcount.sh"
    chmod 755 "$HOME/.local/bin/ran-hadoop" "$HOME/.local/bin/run-wordcount" "$HOME/.local/bin/run-wordcount.sh"
    echo -e "${GREEN}  ✓ Commands installed to $HOME/.local/bin.${RESET}"
fi

cp "$SCRIPT_DIR/run-wordcount.sh" "$HOME/run-wordcount.sh" 2>/dev/null || true
cp "$SCRIPT_DIR/sample_input.txt" "$HOME/sample_input.txt" 2>/dev/null || true

# Update Shell Profiles (~/.bashrc, ~/.profile, ~/.zshrc)
ENV_SNIPPET=$(cat << EOF
# >>> hadoop-quickstart env >>>
export JAVA_HOME="$JAVA_HOME"
export HADOOP_HOME="$INSTALL_DIR"
export HADOOP_CONF_DIR="$HADOOP_CONF_DIR"
export HADOOP_MAPRED_HOME="\$HADOOP_HOME"
export HADOOP_COMMON_HOME="\$HADOOP_HOME"
export HADOOP_HDFS_HOME="\$HADOOP_HOME"
export HADOOP_YARN_HOME="\$HADOOP_HOME"
export PATH="\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin:\$HOME/.local/bin:\$PATH"
# <<< hadoop-quickstart env <<<
EOF
)

update_profile() {
    local target="$1"
    if [ -f "$target" ]; then
        if grep -q "# >>> hadoop-quickstart env >>>" "$target"; then
            sed -i '/# >>> hadoop-quickstart env >>>/,/# <<< hadoop-quickstart env <<</d' "$target"
        fi
        echo "" >> "$target"
        echo "$ENV_SNIPPET" >> "$target"
        echo "  Updated $target with Hadoop environment variables."
    fi
}

update_profile "$HOME/.bashrc"
update_profile "$HOME/.profile"
[ -f "$HOME/.zshrc" ] && update_profile "$HOME/.zshrc"

# ==============================================================================
# [Step 7/7] Execute Automated MapReduce WordCount Test inside WSL
# ==============================================================================
echo -e "\n${CYAN}[Step 7/7] Executing MapReduce WordCount Demonstration inside WSL...${RESET}"
echo "  Starting cluster services..."
export HADOOP_HOME="$INSTALL_DIR"
export PATH="$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$JAVA_HOME/bin:$PATH"

"$SCRIPT_DIR/ran-hadoop" start
sleep 3

echo -e "\n  Running distributed MapReduce WordCount..."
"$SCRIPT_DIR/run-wordcount.sh" "$SCRIPT_DIR/sample_input.txt"

echo -e "\n  Stopping temporary cluster services..."
"$SCRIPT_DIR/ran-hadoop" stop

echo -e "\n${GREEN}================================================================${RESET}"
echo -e "${GREEN}${BOLD}      Apache Hadoop Installation & Setup Successfully Completed! ${RESET}"
echo -e "${GREEN}================================================================${RESET}"
echo -e "${BOLD}All components are fully installed and verified inside WSL Linux.${RESET}"
echo ""
echo -e "${BOLD}Next Steps:${RESET}"
echo -e "  1. Reload your terminal environment:"
echo -e "     ${CYAN}source ~/.bashrc${RESET}"
echo ""
echo -e "  2. Start Hadoop and launch the cluster monitor:"
echo -e "     ${BOLD}${GREEN}ran-hadoop${RESET}"
echo -e "     ${YELLOW}• Press Ctrl+C anytime to stop all services gracefully.${RESET}"
echo -e "     ${YELLOW}• Closing the terminal window also stops all services automatically.${RESET}"
echo ""
echo -e "  3. In another terminal, run MapReduce WordCount anytime:"
echo -e "     ${CYAN}./run-wordcount.sh${RESET}  or  ${CYAN}run-wordcount${RESET}"
echo ""
echo -e "  4. Access Web Management Dashboards in your browser:"
echo -e "     • NameNode UI : ${CYAN}http://localhost:9870${RESET}"
echo -e "     • YARN UI     : ${CYAN}http://localhost:8088${RESET}"
echo -e "${GREEN}================================================================${RESET}"
