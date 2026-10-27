# 🐘 Apache Hadoop Automated Lab PC Quickstart & Lifecycle CLI

[![Apache Hadoop](https://img.shields.io/badge/Apache%20Hadoop-3.3.6%20%7C%203.4.x-FF6600?logo=apache&logoColor=white)](https://hadoop.apache.org/)
[![Java](https://img.shields.io/badge/Java-OpenJDK%2011%20%7C%208-ED8B00?logo=openjdk&logoColor=white)](https://openjdk.org/)
[![OS Support](https://img.shields.io/badge/OS-Windows%20Lab%20PC%20%7C%20WSL2%20%7C%20Ubuntu%20%7C%20Debian%20%7C%20CentOS%20%7C%20Arch-2496ED?logo=linux&logoColor=white)](https://ubuntu.com/wsl)
[![Downloader](https://img.shields.io/badge/Speed-16--Thread%20Parallel%20aria2-4CAF50)](#-16-thread-accelerated-download)
[![Videos](https://img.shields.io/badge/Video%20Demos-Full%20HD%201080p-E11D48?logo=youtube&logoColor=white)](docs/videos/index.html)
[![PDF Manual](https://img.shields.io/badge/PDF%20Guide-Lab%20Practical%20Manual-7C3AED?logo=adobeacrobatreader&logoColor=white)](docs/Hadoop_Complete_Guide_Install_Run_WordCount.pdf)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

An enterprise-grade, one-click installer, configuration generator, and managed terminal lifecycle command (`ran-hadoop`) for **Apache Hadoop** in **Windows Subsystem for Linux (WSL2)** and **any Linux distribution**.

Engineered specifically for **college & university computer lab environments**, allowing students to set up a complete Hadoop cluster in **one single command** and master MapReduce both with **automated shortcuts** and **raw 1-by-1 manual commands** for viva and practical exams.

---

## ⚡ Quickstart for Lab PCs (Share with Friends!)

### Option A: Windows Lab PC (PowerShell 1-Liner) — *Recommended for Labs*
Copy and paste this single command into **Windows PowerShell**:

```powershell
irm https://raw.githubusercontent.com/fridayslifes/Hadoop/main/setup-lab.ps1 | iex
```

> **What this does automatically:**
> 1. Saves all repository files directly onto your **Windows Desktop** (`%USERPROFILE%\Desktop\Hadoop`).
> 2. Automatically verifies/enables **WSL2** and Ubuntu.
> 3. Installs OpenJDK 11, configures SSH keys, tunes Hadoop XML files, and formats the NameNode.
> 4. Creates convenient **Desktop Shortcuts**:
>    - `Start Hadoop (ran-hadoop).lnk` (double-click to start Hadoop anytime)
>    - `Run Hadoop WordCount.lnk` (double-click to test MapReduce instantly)

---

### Option B: Linux / WSL Terminal (Bash 1-Liner)
If you already have a terminal open in WSL or native Linux, run:

```bash
curl -sSL https://raw.githubusercontent.com/fridayslifes/Hadoop/main/install.sh | bash
```

---

### Option C: Traditional Git Clone (2-Liner)
```bash
git clone https://github.com/fridayslifes/Hadoop.git ~/Desktop/Hadoop
cd ~/Desktop/Hadoop && ./install.sh
```

---

## 🎥 Video Demonstrations & Interactive Player

We provide two pre-compiled Full HD (1080p) explainer videos along with an interactive media player:

| Video | Topic | Direct Video File | Interactive Player |
| :--- | :--- | :--- | :--- |
| **Video 1** | **1-Click Lab PC & WSL Setup Walkthrough** | [Download MP4](docs/videos/lab_setup_walkthrough.mp4) | [Open Web Player](docs/videos/index.html) |
| **Video 2** | **MapReduce: Fast Shortcut vs 1-by-1 Manual Commands** | [Download MP4](docs/videos/mapreduce_shortcut_vs_manual.mp4) | [Open Web Player](docs/videos/index.html) |

👉 **[Click Here to Open the Interactive HTML5 Video Player](docs/videos/index.html)** (includes 1-click copy buttons for all commands).

---

## 📄 Complete PDF Lab Practical Manual

A publication-grade reference PDF is included directly inside the repository:

📥 **[Download Hadoop Complete Practical Guide (PDF)](docs/Hadoop_Complete_Guide_Install_Run_WordCount.pdf)**

**What's inside the PDF:**
- 1-Click Windows Lab PC & Linux/WSL Setup Guide.
- **Track A (Speed Run)**: 1-line automated MapReduce shortcuts.
- **Track B (Viva & Practical Exams)**: Line-by-line manual commands without shortcuts.
- Python Hadoop Streaming MapReduce (`mapper.py` & `reducer.py`).
- Troubleshooting table for NameNode Safe Mode, port conflicts, and memory limits.

---

## 🚀 How to Run the Cluster (`ran-hadoop`)

Once installed, reload your shell and launch the supervisor:

```bash
source ~/.bashrc
ran-hadoop
```

You will see the live foreground cluster monitor:

```text
================================================================
             Apache Hadoop is Active & Running                  
================================================================
Active Cluster Daemons (jps):
  • 18234 NameNode          (Port 9870)
  • 18356 DataNode          (Port 9864)
  • 18490 SecondaryNameNode (Port 9868)
  • 18612 ResourceManager   (Port 8088)
  • 18745 NodeManager       (Port 8042)

Web Management Portals in your Browser:
  🌐 HDFS NameNode Web UI:       http://localhost:9870
  🌐 YARN ResourceManager Web UI: http://localhost:8088
  🌐 DataNode Web UI:             http://localhost:9864

================================================================
 [LIFECYCLE INSTRUCTIONS]
  • To run MapReduce: Open a NEW terminal window and run your commands.
  • To stop Hadoop: Press [Ctrl + C] in this terminal.
  • Closing this terminal window cleanly terminates all daemons (Zero RAM leak).
================================================================
```

---

## 📊 MapReduce: Dual Execution Tracks

Open a **second terminal tab** while `ran-hadoop` is running in Terminal 1.

### Track A: The Fast 1-Line Shortcut (Speed Run)

To process the default Big Data dataset:
```bash
./run-wordcount.sh
```

To process any custom text file on your computer:
```bash
./run-wordcount.sh /path/to/my_document.txt
```

*(Because commands are linked globally, you can also run `run-wordcount <file>` from anywhere).*

---

### Track B: Step-by-Step 1-by-1 Manual Commands (for Lab Exams & Viva)

During lab examinations and viva voce evaluations, professors often ask students to enter each command manually. Follow this exact sequence:

#### Step 1: Check running cluster daemons
```bash
jps
```
*(Verify `NameNode`, `DataNode`, `ResourceManager`, and `NodeManager` appear).*

#### Step 2: Create input directory in HDFS
```bash
hdfs dfs -mkdir -p /my_lab/input
```

#### Step 3: Upload local text file to HDFS
```bash
hdfs dfs -put -f sample_input.txt /my_lab/input/
```

#### Step 4: Verify file exists in HDFS
```bash
hdfs dfs -ls /my_lab/input
hdfs dfs -cat /my_lab/input/sample_input.txt | head -n 10
```

#### Step 5: Clean previous output directory (if re-running)
```bash
hdfs dfs -rm -r -f /my_lab/output
```

#### Step 6: Execute the MapReduce JAR
```bash
hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar wordcount /my_lab/input /my_lab/output
```

#### Step 7: Inspect output word frequencies in HDFS
```bash
hdfs dfs -ls /my_lab/output
hdfs dfs -cat /my_lab/output/part-r-00000 | head -n 25
```

#### Step 8: Download results back to your local computer
```bash
hdfs dfs -get /my_lab/output/part-r-00000 ./lab_results.txt
cat ./lab_results.txt | sort -k2 -nr | head -n 25
```

---

## 🐍 Bonus: Python Hadoop Streaming MapReduce

If your curriculum uses Python instead of Java:

### 1. `mapper.py`
```python
#!/usr/bin/env python3
import sys

for line in sys.stdin:
    line = line.strip()
    words = line.split()
    for word in words:
        print(f"{word}\t1")
```

### 2. `reducer.py`
```python
#!/usr/bin/env python3
import sys

current_word = None
current_count = 0

for line in sys.stdin:
    line = line.strip()
    word, count = line.split('\t', 1)
    count = int(count)
    if current_word == word:
        current_count += count
    else:
        if current_word:
            print(f"{current_word}\t{current_count}")
        current_word = word
        current_count = count

if current_word:
    print(f"{current_word}\t{current_count}")
```

### 3. Run Python Streaming Job:
```bash
chmod +x mapper.py reducer.py
hadoop jar $HADOOP_HOME/share/hadoop/tools/lib/hadoop-streaming-*.jar \
       -input /my_lab/input \
       -output /my_lab/python_output \
       -mapper ./mapper.py \
       -reducer ./reducer.py
```

---

## 📁 Repository Structure

```text
Hadoop/
├── setup-lab.ps1             # 1-Click Windows PowerShell lab installer (saves to Desktop)
├── setup-wsl.bat             # Windows batch launcher (runs install.sh inside WSL)
├── install.sh                # Main automated installer (16-thread download & pipe support)
├── ran-hadoop                # Foreground cluster manager with Ctrl+C and SIGHUP auto-stop
├── run-wordcount.sh          # Automated MapReduce WordCount execution and results reporter
├── sample_input.txt          # Big Data sample dataset for testing
├── LICENSE                   # MIT License
├── README.md                 # Complete documentation
├── conf/                     # Pre-tuned XML configuration templates
│   ├── core-site.xml         # HDFS master URI (hdfs://localhost:9000) & tmp paths
│   ├── hdfs-site.xml         # Replication factor 1 & storage paths
│   ├── mapred-site.xml       # YARN execution framework & memory tuning
│   └── yarn-site.xml         # Shuffle service & WSL memory check adjustments
├── docs/
│   ├── Hadoop_Complete_Guide_Install_Run_WordCount.pdf # Publication-quality PDF manual
│   └── videos/               # High-definition video assets & web player
│       ├── lab_setup_walkthrough.mp4
│       ├── mapreduce_shortcut_vs_manual.mp4
│       └── index.html        # Interactive HTML5 media player
└── scripts/
    ├── generate_pdf.py       # Python ReportLab compiler to re-generate the PDF guide
    ├── generate_videos.py    # Automated FFmpeg generator for the 2 demo videos
    ├── stop-hadoop-clean.sh  # Clean cluster teardown utility
    └── verify-cluster.sh     # Comprehensive diagnostics and health checker
```

---

## 🛑 How the Auto-Shutdown Lifecycle Works

In standard Hadoop setups, users forget background daemons, leaving ports `9000` and `9870` locked and consuming gigabytes of WSL RAM. `ran-hadoop` solves this using **POSIX Signal Interception**:

```
+--------------------------------------------------------------+
|                       'ran-hadoop' CLI                       |
|               (Running in Foreground Terminal)               |
+--------------------------------------------------------------+
                                |
             +------------------+------------------+
             |                                     |
    [Press Ctrl + C]                     [Close Terminal Tab]
     (SIGINT Signal)                       (SIGHUP Signal)
             |                                     |
             +------------------+------------------+
                                |
                                v
               +----------------------------------+
               |      trap cleanup() Triggered    |
               +----------------------------------+
                                |
             +------------------+------------------+
             |                                     |
             v                                     v
   stop-yarn.sh (YARN)                    stop-dfs.sh (HDFS)
   ResourceManager &                      NameNode, DataNode &
   NodeManager killed                     SecondaryNameNode killed
             |                                     |
             +------------------+------------------+
                                |
                                v
               +----------------------------------+
               |  Orphan Process Check & Cleanup  |
               +----------------------------------+
                                |
                                v
                   Zero Residual Memory / Clean Exit
```

---

## 🛠️ Diagnostics & Emergency Utilities

- **Verify Cluster Health**:
  ```bash
  ./scripts/verify-cluster.sh
  ```
  Tests Java version, HDFS connectivity, SSH localhost connection, running daemons (`jps`), and storage health.

- **Emergency Force Teardown**:
  ```bash
  ./scripts/stop-hadoop-clean.sh
  ```
  Stops DFS and YARN and terminates any lingering orphaned JVMs.

- **Rebuild the PDF Guide**:
  ```bash
  python scripts/generate_pdf.py
  ```

- **Re-render the Videos**:
  ```bash
  python scripts/generate_videos.py
  ```

---

## ❓ Frequently Asked Questions (FAQ)

### 1. What if `hdfs dfs` reports `Name node is in safe mode`?
When Hadoop starts, HDFS enters a momentary Safe Mode while checking block replication. You can exit safe mode immediately with:
```bash
hdfs dfsadmin -safemode leave
```

### 2. Can I access the Web UIs from Windows when running Hadoop inside WSL2?
Yes! WSL2 automatically proxies localhost ports to Windows. Simply navigate to `http://localhost:9870` or `http://localhost:8088` in Chrome/Edge. If your Windows port forwarding is blocked by a firewall, find the WSL IP using `wsl hostname -I` and open `http://<WSL-IP>:9870`.

### 3. Why OpenJDK 11 instead of Java 17 / 21?
Hadoop 3.3.x / 3.4.x relies heavily on internal JVM reflection for IPC serialization and object cloning. Java 17+ encapsulates internal packages (`--add-opens java.base/java.lang=ALL-UNNAMED`). OpenJDK 11 provides rock-solid, production-tested stability without needing dozens of extra JVM flags.

---

## 📜 License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
