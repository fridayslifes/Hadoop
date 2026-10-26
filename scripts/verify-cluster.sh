#!/usr/bin/env bash
# ==============================================================================
# scripts/verify-cluster.sh: Comprehensive cluster diagnostic checker
# ==============================================================================

REAL_HOME=$(getent passwd "$(whoami)" | cut -d: -f6)
if [ -n "$REAL_HOME" ] && [ -d "$REAL_HOME" ]; then
    export HOME="$REAL_HOME"
fi

BOLD="\033[1m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
RED="\033[1;31m"
RESET="\033[0m"

HADOOP_HOME="${HADOOP_HOME:-$HOME/hadoop}"

echo -e "${GREEN}================================================================${RESET}"
echo -e "${GREEN}${BOLD}             Apache Hadoop Cluster Diagnostic Report            ${RESET}"
echo -e "${GREEN}================================================================${RESET}"

# 1. Java check
echo -e "\n${BOLD}[1] Java Environment:${RESET}"
if [ -n "$JAVA_HOME" ] && [ -x "$JAVA_HOME/bin/java" ]; then
    echo -e "  JAVA_HOME: ${GREEN}$JAVA_HOME${RESET}"
    echo -e "  Version  : $("$JAVA_HOME/bin/java" -version 2>&1 | head -n 1)"
else
    echo -e "  ${RED}JAVA_HOME is not set or invalid!${RESET}"
fi

# 2. Hadoop Home check
echo -e "\n${BOLD}[2] Hadoop Installation:${RESET}"
if [ -d "$HADOOP_HOME" ] && [ -x "$HADOOP_HOME/bin/hadoop" ]; then
    echo -e "  HADOOP_HOME: ${GREEN}$HADOOP_HOME${RESET}"
    echo -e "  Version    : $("$HADOOP_HOME/bin/hadoop" version 2>&1 | head -n 1)"
else
    echo -e "  ${RED}HADOOP_HOME is not set or invalid!${RESET}"
fi

# 3. SSH Localhost check
echo -e "\n${BOLD}[3] SSH Localhost Connectivity:${RESET}"
if ssh -o BatchMode=yes -o ConnectTimeout=3 localhost "echo SSH_OK" >/dev/null 2>&1; then
    echo -e "  SSH Passwordless Localhost: ${GREEN}OK (Connection successful)${RESET}"
else
    echo -e "  SSH Passwordless Localhost: ${RED}FAILED (Check ~/.ssh/authorized_keys and ssh service)${RESET}"
fi

# 4. JPS Process check
echo -e "\n${BOLD}[4] Active Hadoop Daemons (jps):${RESET}"
jps_output=$(jps 2>/dev/null)
echo "$jps_output" | sed 's/^/  • /'

for daemon in NameNode DataNode SecondaryNameNode ResourceManager NodeManager; do
    if echo "$jps_output" | grep -q "$daemon"; then
        echo -e "  $daemon: ${GREEN}RUNNING${RESET}"
    else
        echo -e "  $daemon: ${YELLOW}STOPPED${RESET}"
    fi
done

# 5. HDFS FS check
echo -e "\n${BOLD}[5] HDFS Filesystem Status:${RESET}"
if hdfs dfs -ls / >/dev/null 2>&1; then
    echo -e "  HDFS Root Access: ${GREEN}ONLINE${RESET}"
    hdfs dfsadmin -report 2>/dev/null | grep -E 'Configured Capacity|Present Capacity|DFS Remaining|Live datanodes' | sed 's/^/  /' || true
else
    echo -e "  HDFS Root Access: ${YELLOW}UNAVAILABLE (NameNode not running or starting up)${RESET}"
fi

# 6. Web Interfaces
echo -e "\n${BOLD}[6] Web Management Interfaces:${RESET}"
echo -e "  • HDFS NameNode:       ${CYAN}http://localhost:9870${RESET}"
echo -e "  • YARN ResourceManager:${CYAN}http://localhost:8088${RESET}"
echo -e "  • HDFS DataNode:       ${CYAN}http://localhost:9864${RESET}"
echo -e "${GREEN}================================================================${RESET}"
