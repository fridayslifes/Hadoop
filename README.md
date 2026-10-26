# 🐘 Apache Hadoop Automated Quickstart & Lifecycle CLI

[![Apache Hadoop](https://img.shields.io/badge/Apache%20Hadoop-3.3.6%20%7C%203.4.x-FF6600?logo=apache&logoColor=white)](https://hadoop.apache.org/)
[![Java](https://img.shields.io/badge/Java-OpenJDK%2011%20%7C%208-ED8B00?logo=openjdk&logoColor=white)](https://openjdk.org/)
[![OS Support](https://img.shields.io/badge/OS-WSL2%20%7C%20Ubuntu%20%7C%20Debian%20%7C%20CentOS%20%7C%20Fedora%20%7C%20Arch-2496ED?logo=linux&logoColor=white)](https://ubuntu.com/wsl)
[![Downloader](https://img.shields.io/badge/Speed-16--Thread%20Parallel%20aria2-4CAF50)](#fast-16-thread-accelerated-download)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

An enterprise-grade, one-click installer, configuration generator, and managed terminal lifecycle command (`ran-hadoop`) for **Apache Hadoop** in **Windows Subsystem for Linux (WSL2)** and **any Linux distribution**.

Includes a complete **6-page PDF guide** (`docs/Hadoop_Complete_Guide_Install_Run_WordCount.pdf`), sample dataset, and an automated distributed **MapReduce WordCount** verification script.

---

## ⚡ Highlights

- **🚀 One-Click Installation (`./install.sh`)**: Automatically detects your Linux distribution (`apt`, `dnf`, `yum`, `pacman`, `zypper`), installs OpenJDK 11, configures passwordless SSH localhost, tunes XML configuration files, and formats the HDFS NameNode.
- **⚡ 16-Thread Fast Download**: Employs `aria2c` configured for 16 concurrent segmented streams across Apache CDN and archive mirrors, downloading the ~730 MB package in seconds.
- **🖥️ The `ran-hadoop` Terminal Lifecycle CLI**:
  - Run `ran-hadoop` in any terminal to start all HDFS and YARN daemons.
  - Keeps a real-time health monitor and dashboard in the foreground.
  - **Press `Ctrl + C`**: Gracefully and cleanly stops all daemons (`stop-yarn.sh`, `stop-dfs.sh`).
  - **Close the Terminal Window**: POSIX `SIGHUP` trap automatically catches the hangup signal and terminates all daemons cleanly before exiting, ensuring **zero orphaned Java processes** or locked ports in WSL/Linux.
- **📊 MapReduce WordCount Demo (`./run-wordcount.sh`)**: Complete hands-on tutorial that prepares HDFS directories, ingests text, runs the MapReduce job, and displays the top word counts.
- **📄 Complete PDF Documentation**: Pre-compiled publication-quality PDF guide included directly inside the repository.

---

## 📁 Repository Structure

```text
hadoop-quickstart/
├── install.sh                  # Main one-click installer (distro detection, 16-thread download, config)
├── ran-hadoop                  # Foreground cluster manager with Ctrl+C and SIGHUP auto-shutdown
├── run-wordcount.sh            # Automated MapReduce WordCount execution and results reporter
├── setup-wsl.bat               # Windows batch launcher (runs install.sh inside WSL with 1-click)
├── sample_input.txt            # Ready-to-process Big Data text file for WordCount
├── LICENSE                     # MIT License
├── README.md                   # This documentation
├── conf/                       # Pre-tuned XML configuration templates
│   ├── core-site.xml           # HDFS master URI (hdfs://localhost:9000) & tmp paths
│   ├── hdfs-site.xml           # Replication factor 1 & NameNode/DataNode storage
│   ├── mapred-site.xml         # YARN execution framework & memory tuning
│   └── yarn-site.xml           # Shuffle service & WSL memory check adjustments
├── docs/
│   └── Hadoop_Complete_Guide_Install_Run_WordCount.pdf  # 6-page comprehensive reference guide
└── scripts/
    ├── generate_pdf.py         # Python ReportLab compiler to re-generate the PDF guide
    ├── stop-hadoop-clean.sh    # Emergency force-cleanup utility for lingering daemons
    └── verify-cluster.sh       # Comprehensive cluster diagnostics and health checker
```

---

## 🚀 Quickstart Guide

### Option A: From Windows (Using WSL2)

1. Clone the repository into Windows or WSL:
   ```powershell
   git clone <repo-url> hadoop-quickstart
   cd hadoop-quickstart
   ```
2. Double-click `setup-wsl.bat` (or run it from CMD/PowerShell):
   ```cmd
   setup-wsl.bat
   ```
3. Open your WSL terminal (`wsl`) and run:
   ```bash
   source ~/.bashrc
   ran-hadoop
   ```

---

### Option B: From Linux / WSL Terminal

#### 1. Clone & Run the One-Click Installer
```bash
git clone <repo-url> hadoop-quickstart
cd hadoop-quickstart
chmod +x install.sh ran-hadoop run-wordcount.sh scripts/*.sh
./install.sh
```
*The installer automatically handles distro packages, installs OpenJDK 11, downloads Hadoop using 16 threads, generates all configuration files, configures passwordless SSH, formats the NameNode, and registers `ran-hadoop` into `/usr/local/bin`.*

#### 2. Reload Shell Profile
```bash
source ~/.bashrc
```

#### 3. Start Hadoop via `ran-hadoop`
```bash
ran-hadoop
```
You will see the live cluster dashboard:
```text
================================================================
             Apache Hadoop is Active & Running                  
================================================================
Active Cluster Daemons (jps):
  • 18234 NameNode
  • 18356 DataNode
  • 18490 SecondaryNameNode
  • 18612 ResourceManager
  • 18745 NodeManager

Web Management Interfaces:
  🌐 HDFS NameNode Web UI:       http://localhost:9870
  🌐 YARN ResourceManager Web UI: http://localhost:8088
  🌐 DataNode Web UI:             http://localhost:9864

================================================================
 [CONTROL & LIFECYCLE INSTRUCTIONS]
  • To run MapReduce jobs: Open a NEW terminal window and run your commands.
    Example: ./run-wordcount.sh
  • To stop Hadoop: Press [Ctrl + C] in this terminal.
  • Closing this terminal window will automatically shut down all Hadoop daemons.
================================================================
```

---

## 🛑 How the Auto-Shutdown Lifecycle Works

In standard Hadoop setups, users often forget background daemons, leaving ports `9000` and `9870` locked and consuming gigabytes of WSL RAM. 

`ran-hadoop` solves this using **POSIX Signal Interception**:

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

## 📊 Running the MapReduce WordCount Demo

While `ran-hadoop` is running in **Terminal 1**, open **Terminal 2** and execute:

```bash
cd hadoop-quickstart
./run-wordcount.sh
```

### What `run-wordcount.sh` Does:
1. Validates that HDFS is reachable.
2. Creates an HDFS input directory: `/wordcount_demo/input`.
3. Ingests `sample_input.txt` into HDFS.
4. Executes the MapReduce job using `hadoop-mapreduce-examples-*.jar`.
5. Cleans previous outputs and computes parallel word frequencies across YARN containers.
6. Retrieves and sorts the top words in descending frequency:

```text
================================================================
TOP 25 MOST FREQUENT WORDS:
================================================================
WORD                      | COUNT
----------------------------------------
and                       | 14
of                        | 10
Hadoop                    | 9
the                       | 9
in                        | 7
to                        | 6
data                      | 6
distributed               | 5
is                        | 5
processing                | 4
MapReduce                 | 4
cluster                   | 3
...
----------------------------------------
Total unique words processed: 118
```

You can also pass your own custom text file:
```bash
./run-wordcount.sh /path/to/my_big_text_file.txt
```

---

## 🌐 Web Management Interfaces

Once `ran-hadoop` is active, open your favorite browser (in Windows or Linux):

| Web Portal | Browser URL | Key Features |
| :--- | :--- | :--- |
| **HDFS NameNode UI** | [`http://localhost:9870`](http://localhost:9870) | Storage capacity, live DataNodes, block reports, HDFS file browser. |
| **YARN ResourceManager UI** | [`http://localhost:8088`](http://localhost:8088) | Running/completed MapReduce jobs, allocated vcores/RAM, container logs. |
| **HDFS DataNode UI** | [`http://localhost:9864`](http://localhost:9864) | Local block pool utilization and storage paths. |

---

## 🛠️ Diagnostics & Emergency Utilities

- **Verify Cluster Health**:
  ```bash
  ./scripts/verify-cluster.sh
  ```
  Tests Java version, HDFS connectivity, SSH localhost connection, running daemons (`jps`), and storage health.

- **Emergency Clean Teardown**:
  ```bash
  ./scripts/stop-hadoop-clean.sh
  ```
  Stops DFS and YARN and kills any lingering orphaned JVMs.

- **Rebuild the PDF Guide**:
  ```bash
  python scripts/generate_pdf.py
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
