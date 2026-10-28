# Apache Hadoop 3.3.6 Automated Setup & Offline Lab Suite

A complete, production-grade automated installer and offline backup toolkit for **Apache Hadoop 3.3.6** on **Windows (WSL2)** and **Linux (Ubuntu, Debian, Kali Linux, CentOS, Arch)**.

Features **16-thread multi-connection accelerated downloading**, automated OpenJDK 11 setup, OpenSSH server configuration, cluster XML provisioning, NameNode formatting, the `ran-hadoop` lifecycle manager, and full **offline Lab PC backup** support.

---

## ⚡ Quick Start (Online One-Command Install)

### On Windows (PowerShell):
Open **Windows PowerShell** (Run as Administrator) and execute:

```powershell
irm https://raw.githubusercontent.com/fridayslifes/Hadoop/main/setup.ps1 | iex
```

> **What this command does:**
> 1. Installs **Git** if not present.
> 2. Clones the repository directly to your **Desktop** (`%USERPROFILE%\Desktop\Hadoop`).
> 3. Verifies **WSL2** status and installs Ubuntu if no Linux distribution is found.
> 4. Runs the ordered Linux installer natively inside WSL ext4 filesystem (`~/Hadoop`).
> 5. Creates two **Desktop Shortcuts**:
>    - `Start Hadoop (ran-hadoop).lnk` (double-click to start Hadoop with auto-shutdown monitor)
>    - `Run Hadoop WordCount.lnk` (double-click to run distributed MapReduce WordCount)

---

### On Linux or WSL Terminal:
If you are already inside an Ubuntu, Kali, or Debian WSL terminal:

```bash
curl -sSL https://raw.githubusercontent.com/fridayslifes/Hadoop/main/install.sh | bash
```

---

## 💾 Offline Lab PC Backup Suite (Zero Internet Required)

If you are working on a **Lab PC, College PC, or disconnected machine cut off from the Internet**, you can pre-download all binaries into this folder while on an internet-connected PC, copy the folder to a USB drive, and install completely offline.

### Step 1: Pre-Download Offline Archives (On an Internet PC)
Clone the repository and run the offline bundle downloader:

- **On Windows:**
  Double-click `download-offline-bundle.bat`  
  *(or in PowerShell: `.\download-offline-bundle.ps1`)*

- **On Linux / WSL / macOS:**
  ```bash
  chmod +x download-offline-bundle.sh
  ./download-offline-bundle.sh
  ```

**Files Saved Directly Inside the `Hadoop` Folder on that PC:**
| Component | File Saved in `Hadoop` Folder | Description |
| :--- | :--- | :--- |
| **Hadoop Archive** | `hadoop-3.3.6.tar.gz` (~695 MB) | Complete Apache Hadoop binary runtime |
| **Examples JAR** | `hadoop-mapreduce-examples-3.3.6.jar` (~320 KB) | MapReduce WordCount test application |
| **Java OpenJDK 11** | `OpenJDK11U-jdk_x64_linux_hotspot_11.0.22_7.tar.gz` (~180 MB) | OpenJDK 11 LTS 64-bit Linux binary |
| **WSL Kernel** | `wsl_update_x64.msi` (~16 MB) | Microsoft WSL2 Linux kernel installer |
| **OpenSSH Packages** | `offline_packages/openssh*.deb` | OpenSSH server & client offline deb packages |

### Step 2: Transfer to Disconnected Lab PC
Copy the entire `Hadoop` folder onto a USB drive, then paste it onto your Lab PC Desktop:
- **Windows:** `C:\Users\<YourUsername>\Desktop\Hadoop`
- **Linux / WSL:** `~/Hadoop`

### Step 3: Run Offline Installation
- **On Windows:** Double-click `setup-wsl.bat`
- **Inside Linux / WSL:**
  ```bash
  cd ~/Hadoop
  ./install.sh
  ```

The installer detects all local offline packages, extracts Java into `/usr/lib/jvm/`, installs OpenSSH, extracts Hadoop into `~/hadoop` (and `/usr/local/hadoop`), configures all cluster XMLs, formats the NameNode, and executes WordCount **with zero Internet access**.

> 📖 **Full offline instructions:** See [OFFLINE_LAB_BACKUP_GUIDE.txt](OFFLINE_LAB_BACKUP_GUIDE.txt)

---

## 📋 Ordered Installation Sequence

The installer executes a strict 7-phase setup inside WSL:
1. **`sudo update`**: Refreshes package cache (`sudo apt update -y && sudo apt upgrade -y`) and enables `universe` repository.
2. **`Java install`**: Installs OpenJDK 11 LTS (from local offline archive or package manager), sets and exports `JAVA_HOME`.
3. **`SSH install`**: Installs `openssh-server`, generates host keys (`ssh-keygen -A`), creates passwordless RSA keypair (`~/.ssh/id_rsa`), configures `authorized_keys`, starts `service ssh`, and verifies localhost connectivity.
4. **`16-Connection Download`**: Verifies `aria2c` (strictly zero fallback). Downloads Apache Hadoop 3.3.6 utilizing 16 concurrent connections (`aria2c -x 16 -s 16 -k 1M`).
5. **`Hadoop Configuration`**: Configures `core-site.xml`, `hdfs-site.xml`, `mapred-site.xml` (with MapReduce classpath), `yarn-site.xml` (with container classpath & disabled memory checks for WSL), exports daemon users in `hadoop-env.sh`, and formats the NameNode (`hdfs namenode -format -force -nonInteractive`).
6. **`Global CLI Tools`**: Installs `ran-hadoop` and `run-wordcount` to `/usr/local/bin` and updates `~/.bashrc`.
7. **`WordCount Verification in WSL`**: Boots the cluster, ingests sample text into HDFS, runs MapReduce WordCount on YARN, prints top word counts, and exports `wordcount_results.txt`.

---

## 🚀 How to Start & Manage Hadoop

After installation, reload your shell:

```bash
source ~/.bashrc
```

### Launch Cluster with Single-Terminal Auto-Shutdown Monitor:

```bash
ran-hadoop
```

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

 [SINGLE-TERMINAL INTERACTIVE MODE ACTIVE]
  • Type 'exit' or press [Ctrl + D] to stop Hadoop and exit.
  • Closing this terminal window automatically stops all Hadoop services.
================================================================
```

### Background Service Management:
```bash
ran-hadoop start    # Start daemons in background
ran-hadoop status   # Check daemon health & HDFS report
ran-hadoop stop     # Cleanly shutdown all daemons
```

---

## 📊 How to Run MapReduce WordCount

In a second terminal window (while Hadoop is running):

### Option 1: Automated WordCount Command
```bash
run-wordcount
```
*(Or specify a custom text file: `run-wordcount /path/to/text.txt`)*

### Option 2: Step-by-Step Manual Commands
```bash
# 1. Ingest input file to HDFS
hdfs dfs -mkdir -p /my_data/input
hdfs dfs -put -f sample_input.txt /my_data/input/
hdfs dfs -ls /my_data/input

# 2. Run MapReduce WordCount JAR
hdfs dfs -rm -r -f /my_data/output
hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar wordcount /my_data/input /my_data/output

# 3. View results from HDFS
hdfs dfs -cat /my_data/output/part-r-00000 | head -n 25

# 4. Save results to local file
hdfs dfs -get /my_data/output/part-r-00000 ./wordcount_results.txt
cat wordcount_results.txt
```

> 📖 **All 36 Step-by-Step Commands:** See [docs/HADOOP_ALL_COMMANDS_STEP_BY_STEP.txt](docs/HADOOP_ALL_COMMANDS_STEP_BY_STEP.txt)

---

## 🌐 Web Management Dashboards

When Hadoop is running, open these URLs in your Windows or Linux browser:
- **HDFS NameNode Web UI:** [http://localhost:9870](http://localhost:9870)
- **YARN ResourceManager:** [http://localhost:8088](http://localhost:8088)
- **HDFS DataNode:** [http://localhost:9864](http://localhost:9864)

---

## 📁 Repository Structure

```text
Hadoop/
├── setup.ps1                      # Windows PowerShell 1-click installer (WSL/distro check)
├── setup-wsl.bat                  # Windows batch launcher (runs install.sh natively in WSL)
├── install.sh                     # Ordered 7-step installer (offline-aware, 16-thread)
├── ran-hadoop                     # Cluster lifecycle manager (auto-shutdown monitor)
├── run-wordcount.sh               # MapReduce WordCount demonstration script
├── download-offline-bundle.sh     # Linux/WSL/macOS 16-thread offline backup downloader
├── download-offline-bundle.bat    # Windows batch launcher for offline backup
├── download-offline-bundle.ps1    # Windows PowerShell 16-thread offline backup downloader
├── sample_input.txt               # Sample text dataset for testing
├── OFFLINE_LAB_BACKUP_GUIDE.txt   # Step-by-step Lab PC disconnected usage guide
├── .gitattributes                 # Linux LF line-ending enforcement for shell scripts
├── LICENSE                        # MIT License
├── README.md                      # This documentation
├── conf/                          # Pre-tuned XML cluster configuration files
│   ├── core-site.xml              # Master URI & temporary directories
│   ├── hdfs-site.xml              # Replication factor & storage paths
│   ├── mapred-site.xml            # YARN framework & MapReduce classpath
│   └── yarn-site.xml              # Shuffle service & container application classpath
└── docs/
    ├── HADOOP_ALL_COMMANDS_STEP_BY_STEP.txt # All 36 commands from clean wipe to WordCount
    ├── OFFLINE_LAB_BACKUP_GUIDE.txt         # Offline Lab PC guide copy
    ├── Hadoop_Complete_Guide_Install_Run_WordCount.pdf # 10-page master PDF manual
    └── videos/                              # Video guides and HTML5 web player
```

---

## 📜 License

MIT License. See [LICENSE](LICENSE) for details.
