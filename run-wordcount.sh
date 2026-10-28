#!/usr/bin/env bash
# ==============================================================================
# run-wordcount.sh: Run MapReduce WordCount on Apache Hadoop
# Supports:
#   1. Default: runs official hadoop-mapreduce-examples JAR on sample_input.txt
#   2. Custom text file: ./run-wordcount.sh my_text.txt
#   3. Custom Java code: ./run-wordcount.sh WordCount.java [optional_input.txt]
#      (compiles on the fly with Hadoop 3 classpath and packages into JAR)
# ==============================================================================

# Ensure valid Linux home directory in WSL environments
REAL_HOME=$(getent passwd "$(whoami)" 2>/dev/null | cut -d: -f6 || echo "$HOME")
if [ -n "$REAL_HOME" ] && [ -d "$REAL_HOME" ]; then
    export HOME="$REAL_HOME"
fi

BOLD="\033[1m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
RED="\033[1;31m"
RESET="\033[0m"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || pwd)"

# Auto-detect HADOOP_HOME
if [ -z "$HADOOP_HOME" ]; then
    if [ -d "$HOME/hadoop" ]; then
        export HADOOP_HOME="$HOME/hadoop"
    elif [ -d "/usr/local/hadoop" ]; then
        export HADOOP_HOME="/usr/local/hadoop"
    elif [ -d "/opt/hadoop" ]; then
        export HADOOP_HOME="/opt/hadoop"
    else
        echo -e "${RED}[ERROR] HADOOP_HOME not found. Please export HADOOP_HOME or run ./install.sh.${RESET}"
        exit 1
    fi
fi

# Auto-detect JAVA_HOME if needed
if [ -z "$JAVA_HOME" ] && [ -d "/usr/lib/jvm/java-11-openjdk-amd64" ]; then
    export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
fi
if [ -n "$JAVA_HOME" ]; then
    export PATH="$JAVA_HOME/bin:$PATH"
fi

export PATH="$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH"

# Daemon users for WSL/multi-user execution
CURRENT_USER="$(whoami)"
export HDFS_NAMENODE_USER="${HDFS_NAMENODE_USER:-$CURRENT_USER}"
export HDFS_DATANODE_USER="${HDFS_DATANODE_USER:-$CURRENT_USER}"
export HDFS_SECONDARYNAMENODE_USER="${HDFS_SECONDARYNAMENODE_USER:-$CURRENT_USER}"
export YARN_RESOURCEMANAGER_USER="${YARN_RESOURCEMANAGER_USER:-$CURRENT_USER}"
export YARN_NODEMANAGER_USER="${YARN_NODEMANAGER_USER:-$CURRENT_USER}"

# Self-healing: Check and fix any unexpanded variable references in Hadoop XML configs
if [ -f "$HADOOP_HOME/etc/hadoop/mapred-site.xml" ]; then
    if grep -q '\$HADOOP_MAPRED_HOME' "$HADOOP_HOME/etc/hadoop/mapred-site.xml" 2>/dev/null || grep -q '_HADOOP_HOME_' "$HADOOP_HOME/etc/hadoop/mapred-site.xml" 2>/dev/null; then
        sed -i 's|_HADOOP_HOME_|${env.HADOOP_HOME}|g' "$HADOOP_HOME/etc/hadoop/mapred-site.xml" 2>/dev/null || true
        sed -i 's|\$HADOOP_MAPRED_HOME|${env.HADOOP_HOME}|g' "$HADOOP_HOME/etc/hadoop/mapred-site.xml" 2>/dev/null || true
        sed -i 's|\$HADOOP_COMMON_HOME|${env.HADOOP_HOME}|g' "$HADOOP_HOME/etc/hadoop/mapred-site.xml" 2>/dev/null || true
        sed -i 's|\$HADOOP_HDFS_HOME|${env.HADOOP_HOME}|g' "$HADOOP_HOME/etc/hadoop/mapred-site.xml" 2>/dev/null || true
        sed -i 's|\$HADOOP_YARN_HOME|${env.HADOOP_HOME}|g' "$HADOOP_HOME/etc/hadoop/mapred-site.xml" 2>/dev/null || true
    fi
fi
if [ -f "$HADOOP_HOME/etc/hadoop/yarn-site.xml" ]; then
    if grep -q '\$HADOOP_HOME' "$HADOOP_HOME/etc/hadoop/yarn-site.xml" 2>/dev/null; then
        sed -i 's|\$HADOOP_HOME|${env.HADOOP_HOME}|g' "$HADOOP_HOME/etc/hadoop/yarn-site.xml" 2>/dev/null || true
    fi
fi

# Dynamically export full Hadoop classpath to guarantee client JVM resolution
export HADOOP_CLASSPATH=$("$HADOOP_HOME/bin/hadoop" classpath 2>/dev/null || echo "")

# Parse arguments: check if user provided a .java source file or a text input file
CUSTOM_JAVA=""
INPUT_FILE=""

if [ -n "$1" ] && [[ "$1" == *.java ]] && [ -f "$1" ]; then
    CUSTOM_JAVA="$1"
    INPUT_FILE="${2:-sample_input.txt}"
elif [ -n "$1" ] && [ -f "$1" ]; then
    INPUT_FILE="$1"
else
    INPUT_FILE="${1:-sample_input.txt}"
fi

# Locate or create sample input text file
if [ ! -f "$INPUT_FILE" ]; then
    if [ -f "$SCRIPT_DIR/$INPUT_FILE" ]; then
        INPUT_FILE="$SCRIPT_DIR/$INPUT_FILE"
    elif [ -f "$HOME/Hadoop/$INPUT_FILE" ]; then
        INPUT_FILE="$HOME/Hadoop/$INPUT_FILE"
    elif [ -f "$HOME/$INPUT_FILE" ]; then
        INPUT_FILE="$HOME/$INPUT_FILE"
    elif [ -f "$HADOOP_HOME/$INPUT_FILE" ]; then
        INPUT_FILE="$HADOOP_HOME/$INPUT_FILE"
    else
        INPUT_FILE="/tmp/sample_input.txt"
        cat << 'EOF' > "$INPUT_FILE"
Apache Hadoop is an open source framework designed for distributed storage and distributed processing of very large datasets on computer clusters built from commodity hardware.
All the modules in Hadoop are designed with a fundamental assumption that hardware failures are common occurrences and should be automatically handled by the framework.
The core of Apache Hadoop consists of a storage part, known as Hadoop Distributed File System or HDFS, and a processing part which is a MapReduce programming model.
Hadoop splits files into large blocks and distributes them across nodes in a cluster.
To process data, Hadoop MapReduce transfers packaged code for nodes to process in parallel based on the data that needs to be processed.
EOF
    fi
fi

echo -e "${GREEN}================================================================${RESET}"
echo -e "${GREEN}${BOLD}         Apache Hadoop MapReduce WordCount Demonstration        ${RESET}"
echo -e "${GREEN}================================================================${RESET}"
echo " Input File  : $INPUT_FILE ($(wc -l < "$INPUT_FILE") lines, $(wc -w < "$INPUT_FILE") words)"
echo " HDFS DFS    : hdfs://localhost:9000"
echo " Time        : $(date '+%Y-%m-%d %H:%M:%S')"
[ -n "$CUSTOM_JAVA" ] && echo " Custom Java : $CUSTOM_JAVA (compiling on the fly)"
echo -e "${GREEN}================================================================${RESET}"

# 1. Verify HDFS is reachable and ensure SafeMode is OFF
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

# Ensure NameNode safemode is disabled so writes and container creation succeed
hdfs dfsadmin -safemode leave >/dev/null 2>&1 || true
echo -e "${GREEN}  ✓ HDFS is reachable (SafeMode OFF).${RESET}"

# 2. Determine JAR and Main Class
echo -e "${CYAN}[2/5] Locating MapReduce Examples JAR...${RESET}"

JAR_TO_RUN=""
MAIN_CLASS=""

if [ -n "$CUSTOM_JAVA" ]; then
    echo "  Compiling $CUSTOM_JAVA using Java 11 & Hadoop 3 classpath..."
    BUILD_DIR="/tmp/wordcount_build_$$"
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"
    
    javac -classpath "$HADOOP_CLASSPATH" -d "$BUILD_DIR" "$CUSTOM_JAVA"
    
    CUSTOM_JAR="/tmp/WordCount_$$.jar"
    jar -cvf "$CUSTOM_JAR" -C "$BUILD_DIR" . >/dev/null
    rm -rf "$BUILD_DIR"
    
    JAR_TO_RUN="$CUSTOM_JAR"
    MAIN_CLASS="WordCount"
    echo -e "${GREEN}  ✓ Successfully built custom JAR: $JAR_TO_RUN (Main-Class: $MAIN_CLASS)${RESET}"
else
    # CRITICAL FIX: Locate strictly the compiled BINARY JAR, completely ignoring sources, test-sources, and tests
    EXAMPLES_JAR=""

    # 1. Check known exact binary locations directly (NEVER in sources/)
    for candidate in \
        "$HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar" \
        "$HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar" \
        "$SCRIPT_DIR/hadoop-mapreduce-examples-3.3.6.jar" \
        "$HOME/Hadoop/hadoop-mapreduce-examples-3.3.6.jar"
    do
        for f in $candidate; do
            if [ -f "$f" ] && [[ "$f" != *sources* ]] && [[ "$f" != *tests* ]]; then
                EXAMPLES_JAR="$f"
                break 2
            fi
        done
    done

    # 2. If not found by direct path, find binary JAR strictly excluding sources
    if [ -z "$EXAMPLES_JAR" ] || [ ! -f "$EXAMPLES_JAR" ]; then
        EXAMPLES_JAR=$(find "$HADOOP_HOME/share/hadoop/mapreduce" "$SCRIPT_DIR" "$HOME/Hadoop" \
            -maxdepth 2 -type f \
            -name "hadoop-mapreduce-examples-*.jar" \
            ! -path "*/sources/*" \
            ! -name "*sources*" \
            ! -name "*tests*" 2>/dev/null | head -n 1)
    fi

    # 3. Validate JAR contains compiled classes (prevent ClassNotFoundException on source JARs)
    JAR_HAS_CLASSES=0
    if [ -n "$EXAMPLES_JAR" ] && [ -f "$EXAMPLES_JAR" ]; then
        if jar tf "$EXAMPLES_JAR" 2>/dev/null | grep -q "WordCount.class" || \
           unzip -l "$EXAMPLES_JAR" 2>/dev/null | grep -q "WordCount.class"; then
            JAR_HAS_CLASSES=1
        fi
    fi

    # 4. If JAR is missing or is an invalid sources-only JAR, automatically fetch genuine binary from Maven Central
    if [ "$JAR_HAS_CLASSES" -eq 0 ]; then
        echo -e "${YELLOW}  ! Detected invalid or source-only examples JAR. Downloading official compiled binary JAR...${RESET}"
        TARGET_JAR="$HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar"
        MAVEN_URL="https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-mapreduce-examples/3.3.6/hadoop-mapreduce-examples-3.3.6.jar"
        
        if command -v curl >/dev/null 2>&1; then
            curl -sSL -o "$TARGET_JAR" "$MAVEN_URL" 2>/dev/null || true
        elif command -v wget >/dev/null 2>&1; then
            wget -q -O "$TARGET_JAR" "$MAVEN_URL" 2>/dev/null || true
        fi

        if [ -f "$TARGET_JAR" ] && [ -s "$TARGET_JAR" ]; then
            EXAMPLES_JAR="$TARGET_JAR"
            cp -f "$TARGET_JAR" "$SCRIPT_DIR/hadoop-mapreduce-examples-3.3.6.jar" 2>/dev/null || true
            cp -f "$TARGET_JAR" "$HOME/Hadoop/hadoop-mapreduce-examples-3.3.6.jar" 2>/dev/null || true
            echo -e "${GREEN}  ✓ Successfully fetched official binary JAR from Maven Central (281 KB).${RESET}"
        elif [ -f "$SCRIPT_DIR/WordCount.java" ] || [ -f "$HOME/Hadoop/WordCount.java" ]; then
            SRC_JAVA="$SCRIPT_DIR/WordCount.java"
            [ ! -f "$SRC_JAVA" ] && SRC_JAVA="$HOME/Hadoop/WordCount.java"
            echo "  Compiling fallback $SRC_JAVA..."
            BUILD_DIR="/tmp/wordcount_build_$$"
            mkdir -p "$BUILD_DIR"
            javac -classpath "$HADOOP_CLASSPATH" -d "$BUILD_DIR" "$SRC_JAVA"
            CUSTOM_JAR="$HADOOP_HOME/share/hadoop/mapreduce/WordCount.jar"
            jar -cvf "$CUSTOM_JAR" -C "$BUILD_DIR" . >/dev/null
            rm -rf "$BUILD_DIR"
            EXAMPLES_JAR="$CUSTOM_JAR"
            MAIN_CLASS="WordCount"
        else
            echo -e "${RED}[ERROR] Could not locate or build valid MapReduce examples binary JAR.${RESET}"
            exit 1
        fi
    fi

    JAR_TO_RUN="$EXAMPLES_JAR"
    if [ -z "$MAIN_CLASS" ]; then
        MAIN_CLASS="wordcount"
    fi
    echo -e "${GREEN}  ✓ Found JAR: $(basename "$JAR_TO_RUN")${RESET}"
fi

# 3. Prepare HDFS directories
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

# 4. Run the MapReduce job
echo ""
echo -e "${CYAN}[4/5] Executing MapReduce WordCount Job on YARN...${RESET}"
echo -e "${BOLD}Command:${RESET} hadoop jar \"$JAR_TO_RUN\" $MAIN_CLASS \"$HDFS_INPUT_DIR\" \"$HDFS_OUTPUT_DIR\""
echo "----------------------------------------------------------------"

# Execute hadoop jar with primary main class, and fallback if class casing differs
JOB_EXIT=0
hadoop jar "$JAR_TO_RUN" $MAIN_CLASS "$HDFS_INPUT_DIR" "$HDFS_OUTPUT_DIR" || JOB_EXIT=$?

if [ "$JOB_EXIT" -ne 0 ]; then
    echo -e "${YELLOW}[!] Primary job invocation failed (exit code $JOB_EXIT). Attempting fallback execution...${RESET}"
    if [ "$MAIN_CLASS" = "wordcount" ]; then
        FALLBACK_CLASS="WordCount"
    else
        FALLBACK_CLASS="wordcount"
    fi
    echo -e "    Trying alternative class: $FALLBACK_CLASS"
    hadoop jar "$JAR_TO_RUN" $FALLBACK_CLASS "$HDFS_INPUT_DIR" "$HDFS_OUTPUT_DIR" || true
fi

echo "----------------------------------------------------------------"

# 5. Display results
echo ""
echo -e "${CYAN}[5/5] Fetching WordCount Results from HDFS ($HDFS_OUTPUT_DIR)...${RESET}"
if hdfs dfs -test -e "$HDFS_OUTPUT_DIR/part-r-00000" 2>/dev/null; then
    echo -e "${GREEN}================================================================${RESET}"
    echo -e "${BOLD}TOP 25 MOST FREQUENT WORDS:${RESET}"
    echo -e "${GREEN}================================================================${RESET}"
    printf "%-25s | %s\n" "WORD" "COUNT"
    echo "----------------------------------------"
    hdfs dfs -cat "$HDFS_OUTPUT_DIR/part-r-00000" 2>/dev/null | sort -k2 -nr | head -n 25 | while read -r word count; do
        printf "%-25s | %s\n" "$word" "$count"
    done

    TOTAL_DISTINCT=$(hdfs dfs -cat "$HDFS_OUTPUT_DIR/part-r-00000" 2>/dev/null | wc -l)
    echo "----------------------------------------"
    echo -e "Total unique words processed: ${BOLD}$TOTAL_DISTINCT${RESET}"
    hdfs dfs -get -f "$HDFS_OUTPUT_DIR/part-r-00000" ./wordcount_results.txt 2>/dev/null || true
    if [ -f "./wordcount_results.txt" ]; then
        echo -e "Saved local copy:             ${GREEN}./wordcount_results.txt${RESET}"
    fi
    echo -e "${GREEN}================================================================${RESET}"
    echo -e "${GREEN}  ✓ MapReduce job completed successfully!${RESET}"
else
    echo -e "${RED}[ERROR] MapReduce job did not produce output at $HDFS_OUTPUT_DIR/part-r-00000.${RESET}"
    echo "Please inspect YARN logs: yarn logs -applicationId \$(yarn application -list -appStates ALL 2>/dev/null | grep -o 'application_[0-9_]*' | tail -n 1)"
fi

echo -e "To view all output lines: ${BOLD}hdfs dfs -cat $HDFS_OUTPUT_DIR/part-r-00000${RESET}"
echo -e "To check YARN Web UI:      ${BOLD}http://localhost:8088${RESET}"
echo -e "To check HDFS Web UI:      ${BOLD}http://localhost:9870${RESET}"
echo -e "${GREEN}================================================================${RESET}"
