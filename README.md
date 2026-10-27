# Apache Hadoop Installation Guide

A quick, automated installer for **Apache Hadoop** on **Windows (WSL2)** and **Linux**.

This setup installs Git (if missing), enables WSL2 and Ubuntu on Windows, installs Java OpenJDK 11, configures passwordless SSH, downloads Hadoop using a 16-thread accelerator, configures the XML files, formats the NameNode, and provides both a quick shortcut and step-by-step manual commands to run MapReduce WordCount.

---

## ⚡ How to Install (One Command)

### On Windows (PowerShell):
Open **Windows PowerShell** and run:

```powershell
irm https://raw.githubusercontent.com/fridayslifes/Hadoop/main/setup.ps1 | iex
```

> **What this command does:**
> 1. Installs **Git** if it is not already on your computer.
> 2. Saves all files directly to your **Desktop** (`%USERPROFILE%\Desktop\Hadoop`).
> 3. Enables **WSL2** and Ubuntu on Windows.
> 4. Installs OpenJDK 11, configures SSH keys, and installs Hadoop.
> 5. Creates two **Desktop Shortcuts**:
>    - `Start Hadoop (ran-hadoop).lnk` (double-click to start Hadoop anytime)
>    - `Run Hadoop WordCount.lnk` (double-click to test MapReduce WordCount)

---

### On Linux or WSL Terminal:
If you are already inside a Linux or WSL terminal, run:

```bash
curl -sSL https://raw.githubusercontent.com/fridayslifes/Hadoop/main/install.sh | bash
```

---

## 🚀 How to Start Hadoop

After installation finishes, reload your terminal:

```bash
source ~/.bashrc
ran-hadoop
```

You will see:

```text
================================================================
             Apache Hadoop is Active & Running                  
================================================================
Active Cluster Daemons (jps):
  • NameNode          (Web UI: http://localhost:9870)
  • DataNode          (Web UI: http://localhost:9864)
  • SecondaryNameNode (Web UI: http://localhost:9868)
  • ResourceManager   (Web UI: http://localhost:8088)
  • NodeManager       (Web UI: http://localhost:8042)

• To run MapReduce: Open a second terminal window and run your commands.
• To stop Hadoop: Press Ctrl + C in this terminal.
================================================================
```

---

## 📊 How to Run MapReduce WordCount

Open a **second terminal tab** while `ran-hadoop` is running in Terminal 1.

### Option 1: The Quick Shortcut Script

Run the automated script to test WordCount immediately:

```bash
./run-wordcount.sh
```

You can also pass any text file:
```bash
./run-wordcount.sh /path/to/my_file.txt
```

---

### Option 2: Step-by-Step Manual Commands

If you need to enter the commands manually one by one:

#### 1. Check running daemons
```bash
jps
```

#### 2. Create the input directory in HDFS
```bash
hdfs dfs -mkdir -p /my_data/input
```

#### 3. Upload text file to HDFS
```bash
hdfs dfs -put -f sample_input.txt /my_data/input/
```

#### 4. Verify file is in HDFS
```bash
hdfs dfs -ls /my_data/input
hdfs dfs -cat /my_data/input/sample_input.txt | head -n 10
```

#### 5. Remove previous output directory (if re-running)
```bash
hdfs dfs -rm -r -f /my_data/output
```

#### 6. Run the MapReduce JAR
```bash
hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar wordcount /my_data/input /my_data/output
```

#### 7. View results in HDFS
```bash
hdfs dfs -cat /my_data/output/part-r-00000 | head -n 25
```

#### 8. Download results to your local computer
```bash
hdfs dfs -get /my_data/output/part-r-00000 ./results.txt
cat ./results.txt | sort -k2 -nr | head -n 25
```

---

## 🎥 Video Guides

Two short Full HD MP4 video walkthroughs are included in the repository:

- 🌐 **[Interactive Video Player](docs/videos/index.html)**
- 📹 **Video 1 (Setup Walkthrough)**: [`docs/videos/setup_walkthrough.mp4`](docs/videos/setup_walkthrough.mp4)
- ⚡ **Video 2 (MapReduce Walkthrough)**: [`docs/videos/mapreduce_guide.mp4`](docs/videos/mapreduce_guide.mp4)

---

## 📄 PDF Guide

📥 **[Download Hadoop Complete Practical Guide (PDF)](docs/Hadoop_Complete_Guide_Install_Run_WordCount.pdf)**

Includes:
- Installation steps for Windows and Linux.
- Shortcut and manual 1-by-1 MapReduce commands.
- Python Hadoop Streaming example (`mapper.py` & `reducer.py`).
- Command cheat sheet and troubleshooting.

---

## 📁 Repository Files

```text
Hadoop/
├── setup.ps1                 # Windows PowerShell 1-click installer (installs Git/WSL/Hadoop)
├── setup-wsl.bat             # Windows batch launcher (runs install.sh inside WSL)
├── install.sh                # Linux installer (16-thread download & configuration)
├── ran-hadoop                # Foreground cluster manager with Ctrl+C clean shutdown
├── run-wordcount.sh          # MapReduce WordCount runner script
├── sample_input.txt          # Sample text file for testing
├── LICENSE                   # MIT License
├── README.md                 # This guide
├── conf/                     # XML configurations (core-site, hdfs-site, mapred-site, yarn-site)
├── docs/
│   ├── Hadoop_Complete_Guide_Install_Run_WordCount.pdf # PDF guide
│   └── videos/               # Video files and HTML5 player
└── scripts/
    ├── generate_pdf.py       # Python script to rebuild the PDF guide
    ├── generate_videos.py    # Python script to re-render the videos
    ├── stop-hadoop-clean.sh  # Clean cluster shutdown script
    └── verify-cluster.sh     # Health checker script
```

---

## 📜 License

MIT License. See [LICENSE](LICENSE) for details.
