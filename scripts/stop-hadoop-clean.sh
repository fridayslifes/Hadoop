#!/usr/bin/env bash
# ==============================================================================
# scripts/stop-hadoop-clean.sh: Force clean stop of all Hadoop daemons
# ==============================================================================

set -e

REAL_HOME=$(getent passwd "$(whoami)" | cut -d: -f6)
if [ -n "$REAL_HOME" ] && [ -d "$REAL_HOME" ]; then
    export HOME="$REAL_HOME"
fi

BOLD="\033[1m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
RESET="\033[0m"

HADOOP_HOME="${HADOOP_HOME:-$HOME/hadoop}"

echo -e "${YELLOW}Stopping all Apache Hadoop daemons...${RESET}"

if [ -x "$HADOOP_HOME/sbin/stop-yarn.sh" ]; then
    "$HADOOP_HOME/sbin/stop-yarn.sh" 2>/dev/null || true
fi

if [ -x "$HADOOP_HOME/sbin/stop-dfs.sh" ]; then
    "$HADOOP_HOME/sbin/stop-dfs.sh" 2>/dev/null || true
fi

if [ -x "$HADOOP_HOME/bin/mapred" ]; then
    "$HADOOP_HOME/bin/mapred" --daemon stop historyserver 2>/dev/null || true
fi

# Kill any remaining orphaned Hadoop processes
sleep 1
ORPHANS=$(jps 2>/dev/null | grep -E 'NameNode|DataNode|SecondaryNameNode|ResourceManager|NodeManager' | awk '{print $1}' || true)
if [ -n "$ORPHANS" ]; then
    echo -e "${YELLOW}Cleaning up lingering PIDs: $ORPHANS...${RESET}"
    kill -9 $ORPHANS 2>/dev/null || true
fi

echo -e "${GREEN}All Hadoop services have been stopped.${RESET}"
echo "Current JPS status:"
jps || true
