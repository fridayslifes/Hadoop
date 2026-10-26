#!/usr/bin/env bash
# ==============================================================================
# Apache Hadoop Automated One-Click Installer & Configurator
# Compatible with: WSL (Windows Subsystem for Linux), Ubuntu, Debian, Kali,
# CentOS, RHEL, Fedora, Rocky, AlmaLinux, Arch Linux, and openSUSE.
# Features: 16-thread accelerated download, OpenJDK setup, passwordless SSH,
# pseudo-distributed cluster configuration, NameNode formatting, and 'ran-hadoop' CLI.
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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${GREEN}================================================================${RESET}"
echo -e "${GREEN}${BOLD}       Apache Hadoop Automated One-Click Installer              ${RESET}"
echo -e "${GREEN}================================================================${RESET}"
echo " Target Version   : Apache Hadoop $HADOOP_VERSION"
echo " Installation Dir : $INSTALL_DIR"
echo " Data Directory   : $DATA_DIR"
echo " User             : $(whoami)"
echo " OS / Kernel      : $(uname -s) $(uname -r)"
echo -e "${GREEN}================================================================${RESET}"

# 1. Distro & Package Manager Detection
echo -e "${CYAN}[Step 1/8] Detecting Operating System and Package Manager...${RESET}"

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

echo -e "${GREEN}  ✓ Detected package manager: $PKG_MANAGER${RESET}"

# Check for sudo capabilities
SUDO_CMD=""
if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
        SUDO_CMD="sudo"
    else
        echo -e "${YELLOW}  ! Sudo not found. Will proceed assuming packages are already installed.${RESET}"
    fi
fi

# 2. Package Installation: JDK 11, aria2 (16-thread downloader), SSH, rsync
echo -e "\n${CYAN}[Step 2/8] Installing Dependencies (Java JDK, aria2 multi-threaded downloader, OpenSSH)...${RESET}"

install_packages() {
    case "$PKG_MANAGER" in
        apt)
            echo "  Updating package cache and installing packages via apt..."
            $SUDO_CMD apt-get update -y
            # Prefer openjdk-11-jdk, fallback to openjdk-8-jdk
            $SUDO_CMD apt-get install -y aria2 openssh-server openssh-client rsync tar curl procps \
                openjdk-11-jdk 2>/dev/null || \
                $SUDO_CMD apt-get install -y aria2 openssh-server openssh-client rsync tar curl procps openjdk-8-jdk || \
                $SUDO_CMD apt-get install -y aria2 openssh-server openssh-client rsync tar curl procps default-jdk
            ;;
        dnf|yum)
            echo "  Installing packages via $PKG_MANAGER..."
            $SUDO_CMD "$PKG_MANAGER" install -y epel-release 2>/dev/null || true
            $SUDO_CMD "$PKG_MANAGER" install -y aria2 openssh-server openssh-clients rsync tar curl procps-ng java-11-openjdk-devel || \
                $SUDO_CMD "$PKG_MANAGER" install -y aria2 openssh-server openssh-clients rsync tar curl procps-ng java-1.8.0-openjdk-devel
            ;;
        pacman)
            echo "  Installing packages via pacman..."
            $SUDO_CMD pacman -Sy --noconfirm aria2 openssh rsync tar curl procps-ng jdk11-openjdk || \
                $SUDO_CMD pacman -Sy --noconfirm aria2 openssh rsync tar curl procps-ng jdk8-openjdk
            ;;
        zypper)
            echo "  Installing packages via zypper..."
            $SUDO_CMD zypper --non-interactive install aria2 openssh rsync tar curl java-11-openjdk-devel || \
                $SUDO_CMD zypper --non-interactive install aria2 openssh rsync tar curl java-1_8_0-openjdk-devel
            ;;
        *)
            echo -e "${YELLOW}  Unknown package manager. Checking if required tools are already present...${RESET}"
            ;;
    esac
}

if [ -n "$PKG_MANAGER" ] && [ -n "$SUDO_CMD" ]; then
    install_packages || echo -e "${YELLOW}  Package installation encountered warnings; checking installed binaries...${RESET}"
fi

# 3. Detect and Validate JAVA_HOME
echo -e "\n${CYAN}[Step 3/8] Configuring Java Environment...${RESET}"

DETECTED_JAVA_HOME=""

# Probe standard JDK directories
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

# Fallback to which java
if [ -z "$DETECTED_JAVA_HOME" ] && command -v java >/dev/null 2>&1; then
    RESOLVED_JAVA=$(readlink -f "$(command -v java)")
    DETECTED_JAVA_HOME=$(dirname "$(dirname "$RESOLVED_JAVA")")
fi

if [ -z "$DETECTED_JAVA_HOME" ] || [ ! -d "$DETECTED_JAVA_HOME" ]; then
    echo -e "${RED}[ERROR] Valid JDK installation could not be detected.${RESET}"
    echo "Please install OpenJDK 11 or 8, then re-run this script."
    exit 1
fi

export JAVA_HOME="$DETECTED_JAVA_HOME"
echo -e "${GREEN}  ✓ JAVA_HOME located: $JAVA_HOME${RESET}"
echo "    Java version: $("$JAVA_HOME/bin/java" -version 2>&1 | head -n 1)"

# 4. Configure Passwordless SSH for Localhost
echo -e "\n${CYAN}[Step 4/8] Configuring Passwordless SSH for Hadoop Services...${RESET}"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# Generate key if not present
if [ ! -f "$HOME/.ssh/id_rsa" ]; then
    echo "  Generating new RSA keypair (~/.ssh/id_rsa)..."
    ssh-keygen -t rsa -P "" -f "$HOME/.ssh/id_rsa" -q
fi

# Add key to authorized_keys if not already present
if [ ! -f "$HOME/.ssh/authorized_keys" ] || ! grep -q -F "$(cat "$HOME/.ssh/id_rsa.pub")" "$HOME/.ssh/authorized_keys" 2>/dev/null; then
    echo "  Adding public key to ~/.ssh/authorized_keys..."
    cat "$HOME/.ssh/id_rsa.pub" >> "$HOME/.ssh/authorized_keys"
fi
chmod 600 "$HOME/.ssh/authorized_keys"

# Ensure SSH config suppresses host key verification prompts for localhost
cat << 'EOF' > "$HOME/.ssh/config.tmp"
Host localhost 127.0.0.1 0.0.0.0
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel ERROR
EOF

if [ ! -f "$HOME/.ssh/config" ]; then
    mv "$HOME/.ssh/config.tmp" "$HOME/.ssh/config"
    chmod 600 "$HOME/.ssh/config"
else
    if ! grep -q "Host localhost" "$HOME/.ssh/config"; then
        cat "$HOME/.ssh/config.tmp" >> "$HOME/.ssh/config"
    fi
    rm -f "$HOME/.ssh/config.tmp"
    chmod 600 "$HOME/.ssh/config"
fi

# Ensure SSH service is running
echo "  Checking and starting SSH daemon..."
if command -v service >/dev/null 2>&1; then
    $SUDO_CMD service ssh status >/dev/null 2>&1 || $SUDO_CMD service ssh start >/dev/null 2>&1 || true
elif command -v systemctl >/dev/null 2>&1; then
    $SUDO_CMD systemctl start ssh >/dev/null 2>&1 || $SUDO_CMD systemctl start sshd >/dev/null 2>&1 || true
fi

# Test SSH connection
if ssh -o BatchMode=yes -o ConnectTimeout=5 localhost "echo SSH_OK" >/dev/null 2>&1; then
    echo -e "${GREEN}  ✓ Passwordless SSH connection to localhost confirmed.${RESET}"
else
    echo -e "${YELLOW}  ! Passwordless SSH test returned non-zero. Attempting host key generation...${RESET}"
    $SUDO_CMD ssh-keygen -A >/dev/null 2>&1 || true
    $SUDO_CMD service ssh restart >/dev/null 2>&1 || true
fi

# 5. Fast 16-Thread Download of Apache Hadoop
echo -e "\n${CYAN}[Step 5/8] Downloading Apache Hadoop $HADOOP_VERSION with 16 Threads...${RESET}"

TAR_NAME="hadoop-${HADOOP_VERSION}.tar.gz"
DOWNLOAD_DIR="/tmp/hadoop_download"
mkdir -p "$DOWNLOAD_DIR"

# Apache mirrors
PRIMARY_URL="https://dlcdn.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/${TAR_NAME}"
ARCHIVE_URL="https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/${TAR_NAME}"
BACKUP_URL="https://downloads.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/${TAR_NAME}"

if [ -f "$DOWNLOAD_DIR/$TAR_NAME" ] && tar -tzf "$DOWNLOAD_DIR/$TAR_NAME" >/dev/null 2>&1; then
    echo -e "${GREEN}  ✓ Found existing valid archive: $DOWNLOAD_DIR/$TAR_NAME. Skipping download.${RESET}"
else
    rm -f "$DOWNLOAD_DIR/$TAR_NAME"
    echo "  Downloading from Apache mirrors utilizing 16 concurrent connections..."
    
    if command -v aria2c >/dev/null 2>&1; then
        aria2c \
            --split=16 \
            --max-connection-per-server=16 \
            --min-split-size=1M \
            --max-concurrent-downloads=16 \
            --file-allocation=none \
            --summary-interval=2 \
            --max-tries=5 \
            --retry-wait=2 \
            --dir="$DOWNLOAD_DIR" \
            --out="$TAR_NAME" \
            "$PRIMARY_URL" "$ARCHIVE_URL" "$BACKUP_URL"
    elif command -v axel >/dev/null 2>&1; then
        echo "  (Using axel with 16 connections)"
        axel -n 16 -o "$DOWNLOAD_DIR/$TAR_NAME" "$PRIMARY_URL" || axel -n 16 -o "$DOWNLOAD_DIR/$TAR_NAME" "$ARCHIVE_URL"
    else
        echo -e "${YELLOW}  aria2c not found, falling back to curl...${RESET}"
        curl -L -C - --retry 3 --output "$DOWNLOAD_DIR/$TAR_NAME" "$PRIMARY_URL" || \
        curl -L -C - --retry 3 --output "$DOWNLOAD_DIR/$TAR_NAME" "$ARCHIVE_URL"
    fi
fi

# Verify tar archive integrity
echo "  Verifying tarball integrity..."
if ! tar -tzf "$DOWNLOAD_DIR/$TAR_NAME" | head -n 10 >/dev/null 2>&1; then
    echo -e "${RED}[ERROR] Downloaded archive is corrupt. Re-run installer to retry download.${RESET}"
    rm -f "$DOWNLOAD_DIR/$TAR_NAME"
    exit 1
fi
echo -e "${GREEN}  ✓ Archive verified.${RESET}"

# 6. Extraction and Directory Structure
echo -e "\n${CYAN}[Step 6/8] Extracting Hadoop to $INSTALL_DIR...${RESET}"

mkdir -p "$INSTALL_DIR"
tar -xzf "$DOWNLOAD_DIR/$TAR_NAME" -C "$INSTALL_DIR" --strip-components=1

# Create cluster data directories
mkdir -p "$DATA_DIR/tmp"
mkdir -p "$DATA_DIR/hdfs/namenode"
mkdir -p "$DATA_DIR/hdfs/datanode"
chmod -R 755 "$DATA_DIR"

echo -e "${GREEN}  ✓ Extracted Hadoop successfully.${RESET}"
echo -e "${GREEN}  ✓ Cluster data directory prepared at $DATA_DIR.${RESET}"

# 7. Write Configurations (core-site, hdfs-site, mapred-site, yarn-site, hadoop-env)
echo -e "\n${CYAN}[Step 7/8] Generating Hadoop XML Configuration Files...${RESET}"

HADOOP_CONF_DIR="$INSTALL_DIR/etc/hadoop"
mkdir -p "$HADOOP_CONF_DIR"

# 7a. core-site.xml
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

# 7b. hdfs-site.xml
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

# 7c. mapred-site.xml
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
        <value>HADOOP_MAPRED_HOME=$INSTALL_DIR</value>
    </property>
    <property>
        <name>mapreduce.map.env</name>
        <value>HADOOP_MAPRED_HOME=$INSTALL_DIR</value>
    </property>
    <property>
        <name>mapreduce.reduce.env</name>
        <value>HADOOP_MAPRED_HOME=$INSTALL_DIR</value>
    </property>
    <property>
        <name>mapreduce.map.memory.mb</name>
        <value>1024</value>
    </property>
    <property>
        <name>mapreduce.reduce.memory.mb</name>
        <value>1024</value>
    </property>
</configuration>
EOF

# 7d. yarn-site.xml
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
        <value>JAVA_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,CLASSPATH_PREPEND_DISTCACHE,HADOOP_YARN_HOME,HADOOP_HOME,PATH,LANG,LC_ALL</value>
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

# 7e. hadoop-env.sh: Ensure JAVA_HOME and HADOOP_HOME are explicitly set
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
export HADOOP_OS_TYPE="\${HADOOP_OS_TYPE:-\$(uname -s)}"
EOF
fi

echo -e "${GREEN}  ✓ Configurations written to $HADOOP_CONF_DIR.${RESET}"

# Format NameNode if not yet formatted
if [ ! -d "$DATA_DIR/hdfs/namenode/current" ]; then
    echo "  Formatting HDFS NameNode storage..."
    "$INSTALL_DIR/bin/hdfs" namenode -format -force -nonInteractive
    echo -e "${GREEN}  ✓ NameNode format complete.${RESET}"
else
    echo "  HDFS NameNode already contains current metadata. Skipping reformat."
fi

# 8. Install 'ran-hadoop' CLI, 'run-wordcount' & Persisting Environment
echo -e "\n${CYAN}[Step 8/8] Installing 'ran-hadoop' and 'run-wordcount' Globally...${RESET}"

# Copy scripts and set permissions
chmod +x "$SCRIPT_DIR/ran-hadoop" "$SCRIPT_DIR/run-wordcount.sh" 2>/dev/null || true

CLI_INSTALLED=0
if [ -w "/usr/local/bin" ] || [ -n "$SUDO_CMD" ]; then
    if $SUDO_CMD cp "$SCRIPT_DIR/ran-hadoop" /usr/local/bin/ran-hadoop 2>/dev/null && \
       $SUDO_CMD cp "$SCRIPT_DIR/run-wordcount.sh" /usr/local/bin/run-wordcount 2>/dev/null && \
       $SUDO_CMD cp "$SCRIPT_DIR/run-wordcount.sh" /usr/local/bin/run-wordcount.sh 2>/dev/null && \
       $SUDO_CMD chmod 755 /usr/local/bin/ran-hadoop /usr/local/bin/run-wordcount /usr/local/bin/run-wordcount.sh 2>/dev/null; then
        echo -e "${GREEN}  ✓ 'ran-hadoop' and 'run-wordcount' installed globally to /usr/local/bin.${RESET}"
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

# Also place helper copies into user's home directory
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
            # Replace existing block
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

echo -e "\n${GREEN}================================================================${RESET}"
echo -e "${GREEN}${BOLD}      Apache Hadoop Installation & Setup Successfully Completed! ${RESET}"
echo -e "${GREEN}================================================================${RESET}"
echo -e "${BOLD}Next Steps:${RESET}"
echo -e "  1. Reload your terminal environment:"
echo -e "     ${CYAN}source ~/.bashrc${RESET}"
echo ""
echo -e "  2. Start Hadoop and launch the cluster monitor:"
echo -e "     ${BOLD}${GREEN}ran-hadoop${RESET}"
echo -e "     ${YELLOW}• Press Ctrl+C anytime to stop all services gracefully.${RESET}"
echo -e "     ${YELLOW}• Closing the terminal window also stops all services automatically.${RESET}"
echo ""
echo -e "  3. In a second terminal, run the MapReduce WordCount demonstration:"
echo -e "     ${CYAN}./run-wordcount.sh${RESET}"
echo ""
echo -e "  4. Access Web Interfaces in your browser:"
echo -e "     • NameNode UI : ${CYAN}http://localhost:9870${RESET}"
echo -e "     • YARN UI     : ${CYAN}http://localhost:8088${RESET}"
echo -e "${GREEN}================================================================${RESET}"
