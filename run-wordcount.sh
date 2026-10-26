#!/usr/bin/env bash
# ==============================================================================
# run-wordcount.sh: Run MapReduce WordCount on Apache Hadoop
# Uploads input text to HDFS, executes the MapReduce job, and displays results.
# ==============================================================================

set -e

BOLD="\033[1m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
RED="\033[1;31m"
RESET="\033[0m"

# Auto-detect HADOOP_HOME
if [ -z "$HADOOP_HOME" ]; then
    if [ -d "$HOME/hadoop" ]; then
        export HADOOP_HOME="$HOME/hadoop"
    elif [ -d "/opt/hadoop" ]; then
        export HADOOP_HOME="/opt/hadoop"
    else
        echo -e "${RED}[ERROR] HADOOP_HOME not found. Please export HADOOP_HOME or run ./install.sh.${RESET}"
        exit 1
    fi
fi

export PATH="$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH"

# Input file determination
INPUT_FILE="${1:-sample_input.txt}"

if [ ! -f "$INPUT_FILE" ]; then
    # Try resolving relative to script directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "$SCRIPT_DIR/$INPUT_FILE" ]; then
        INPUT_FILE="$SCRIPT_DIR/$INPUT_FILE"
    else
        echo -e "${RED}[ERROR] Input file '$INPUT_FILE' not found!${RESET}"
        echo "Usage: ./run-wordcount.sh [path/to/textfile.txt]"
        exit 1
    fi
fi

echo -e "${GREEN}================================================================${RESET}"
echo -e "${GREEN}${BOLD}         Apache Hadoop MapReduce WordCount Demonstration        ${RESET}"
echo -e "${GREEN}================================================================${RESET}"
echo " Input File  : $INPUT_FILE ($(wc -l < "$INPUT_FILE") lines, $(wc -w < "$INPUT_FILE") words)"
echo " HDFS DFS    : hdfs://localhost:9000"
echo " Time        : $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "${GREEN}================================================================${RESET}"

# Verify NameNode is reachable
echo -e "${CYAN}[1/5] Checking Hadoop cluster status...${RESET}"
if ! jps 2>/dev/null | grep -q "NameNode"; then
    echo -e "${YELLOW}[WARNING] NameNode not detected in 'jps'.${RESET}"
    echo "Attempting to test HDFS filesystem connection..."
fi

if ! hdfs dfs -ls / >/dev/null 2>&1; then
    echo -e "${RED}[ERROR] Unable to connect to HDFS.${RESET}"
    echo -e "Please ensure Hadoop is running by starting it in a terminal:"
    echo -e "   ${BOLD}ran-hadoop${RESET}"
    echo -e "or execute: ${BOLD}start-dfs.sh && start-yarn.sh${RESET}"
    exit 1
fi
echo -e "${GREEN}  ✓ HDFS is reachable.${RESET}"

# Locate MapReduce examples JAR
echo -e "${CYAN}[2/5] Locating MapReduce Examples JAR...${RESET}"
EXAMPLES_JAR=$(find "$HADOOP_HOME/share/hadoop/mapreduce" -name "hadoop-mapreduce-examples-*.jar" 2>/dev/null | head -n 1)

if [ -z "$EXAMPLES_JAR" ] || [ ! -f "$EXAMPLES_JAR" ]; then
    echo -e "${RED}[ERROR] Could not find hadoop-mapreduce-examples JAR in $HADOOP_HOME/share/hadoop/mapreduce.${RESET}"
    exit 1
fi
echo -e "${GREEN}  ✓ Found JAR: $(basename "$EXAMPLES_JAR")${RESET}"

# Prepare HDFS directories
HDFS_INPUT_DIR="/wordcount_demo/input"
HDFS_OUTPUT_DIR="/wordcount_demo/output"

echo -e "${CYAN}[3/5] Uploading '$INPUT_FILE' to HDFS at $HDFS_INPUT_DIR...${RESET}"
hdfs dfs -mkdir -p "$HDFS_INPUT_DIR"
hdfs dfs -put -f "$INPUT_FILE" "$HDFS_INPUT_DIR/$(basename "$INPUT_FILE")"
echo -e "${GREEN}  ✓ File uploaded successfully:${RESET}"
hdfs dfs -ls "$HDFS_INPUT_DIR"

# Clean up previous output directory if it exists
if hdfs dfs -test -d "$HDFS_OUTPUT_DIR" 2>/dev/null; then
    echo -e "${YELLOW}  Cleaning up prior output directory $HDFS_OUTPUT_DIR...${RESET}"
    hdfs dfs -rm -r -f "$HDFS_OUTPUT_DIR" >/dev/null 2>&1
fi

# Run the MapReduce job
echo ""
echo -e "${CYAN}[4/5] Executing MapReduce WordCount Job on YARN...${RESET}"
echo -e "${BOLD}Command:${RESET} hadoop jar \"$EXAMPLES_JAR\" wordcount \"$HDFS_INPUT_DIR\" \"$HDFS_OUTPUT_DIR\""
echo "----------------------------------------------------------------"

hadoop jar "$EXAMPLES_JAR" wordcount "$HDFS_INPUT_DIR" "$HDFS_OUTPUT_DIR"

echo "----------------------------------------------------------------"
echo -e "${GREEN}  ✓ MapReduce job completed successfully!${RESET}"

# Display results
echo ""
echo -e "${CYAN}[5/5] Fetching WordCount Results from HDFS ($HDFS_OUTPUT_DIR)...${RESET}"
echo -e "${GREEN}================================================================${RESET}"
echo -e "${BOLD}TOP 25 MOST FREQUENT WORDS:${RESET}"
echo -e "${GREEN}================================================================${RESET}"
printf "%-25s | %s\n" "WORD" "COUNT"
echo "----------------------------------------"
hdfs dfs -cat "$HDFS_OUTPUT_DIR/part-r-00000" | sort -k2 -nr | head -n 25 | while read -r word count; do
    printf "%-25s | %s\n" "$word" "$count"
done

TOTAL_DISTINCT=$(hdfs dfs -cat "$HDFS_OUTPUT_DIR/part-r-00000" | wc -l)
echo "----------------------------------------"
echo -e "Total unique words processed: ${BOLD}$TOTAL_DISTINCT${RESET}"
echo -e "${GREEN}================================================================${RESET}"
echo -e "To view all output lines: ${BOLD}hdfs dfs -cat $HDFS_OUTPUT_DIR/part-r-00000${RESET}"
echo -e "To check YARN Web UI:      ${BOLD}http://localhost:8088${RESET}"
echo -e "To check HDFS Web UI:      ${BOLD}http://localhost:9870${RESET}"
echo -e "${GREEN}================================================================${RESET}"
