# Design Document: Hadoop Lab PC 1-Click Setup, Dual MapReduce Reference & Media Upgrade

**Date**: 2026-10-27  
**Repository**: `fridayslifes/Hadoop`  
**Status**: Pending Review  

---

## 1. Intent & Context

Students in college/university computer labs need to run Apache Hadoop practicals and MapReduce tasks on lab computers (typically running Windows 10/11). Setting up WSL, Java, SSH, XML configs, and formatting HDFS manually often consumes an entire 2-hour lab period or fails due to minor syntax or path errors.

This project delivers:
1. A **1-to-3 line shareable command** for Windows PowerShell that automatically downloads/clones the repository to the user's **Desktop**, verifies/launches WSL, and runs an unattended installation.
2. A **1-to-3 line Linux/WSL command** for direct terminal installation.
3. An upgraded, publication-grade **PDF reference guide** containing both the **1-line fast shortcut** and the **1-by-1 manual command sequence** (step-by-step for viva/practical exams).
4. **Two produced explainer/demo videos** (`lab_setup_walkthrough.mp4` and `mapreduce_shortcut_vs_manual.mp4`) with an HTML5 media viewer for easy browser playback.
5. A beautifully refreshed **README.md** with interactive command cards, badges, and quick links.

---

## 2. Goals & Non-Goals

### Goals
- **Lab PC One-Liner**: Students run a single PowerShell command (`irm https://raw.githubusercontent.com/fridayslifes/Hadoop/main/setup-lab.ps1 | iex`). It saves files to `%USERPROFILE%\Desktop\Hadoop`, checks WSL, and executes setup.
- **Piped Linux/WSL Installer**: Running `curl -sSL https://raw.githubusercontent.com/fridayslifes/Hadoop/main/install.sh | bash` automatically clones to Desktop/home and runs setup even without prior cloning.
- **Dual-Track PDF Reference**:
  - Track 1: Fast 1-click script execution for speed.
  - Track 2: Comprehensive 1-by-1 manual commands (HDFS mkdir, put, mapreduce jar, cat, get, Python streaming) for lab exam grading.
- **Two MP4 Videos**:
  - Video 1: 1-Click Lab PC & WSL Setup Walkthrough.
  - Video 2: MapReduce Masterclass (Shortcut vs Manual 1-by-1).
- **Zero-Friction GitHub Deployment**: Pushed cleanly to `https://github.com/fridayslifes/Hadoop` using authenticated git remote.

### Non-Goals
- Modifying Apache Hadoop's underlying source code or binaries (we package and orchestrate official Hadoop 3.3.6 / 3.4.x releases).
- Requiring administrative privileges when standard user rights suffice (with graceful elevation prompts only if WSL feature is uninstalled).

---

## 3. Approaches Considered & Trade-offs

### Approach 1 (Selected): Universal PowerShell & Bash 1-Liners with Self-Bootstrapping
- **PowerShell**: `irm https://raw.githubusercontent.com/fridayslifes/Hadoop/main/setup-lab.ps1 | iex`
- **Linux/WSL**: `curl -sSL https://raw.githubusercontent.com/fridayslifes/Hadoop/main/install.sh | bash`
- **Pros**: Zero prerequisites; friends only need to copy and paste a single line into Windows PowerShell or terminal; files land neatly on the Desktop; handles WSL detection automatically.
- **Cons**: Requires active internet access on the lab PC during the 1-click download (standard for lab environments).

### Approach 2: Git Clone + Local Batch File
- `git clone https://github.com/fridayslifes/Hadoop.git %USERPROFILE%\Desktop\Hadoop && %USERPROFILE%\Desktop\Hadoop\setup-wsl.bat`
- **Pros**: Simple if `git` is already in Windows PATH.
- **Cons**: Most Windows college lab PCs do not have `git` configured in standard CMD/PowerShell, causing immediate failure for students.

---

## 4. Technical Architecture & File Changes

```text
Hadoop/
├── setup-lab.ps1             # NEW: 1-Click Windows PowerShell lab installer
├── setup-wsl.bat             # UPDATED: Desktop shortcut & path detection
├── install.sh                # UPDATED: Supports pipe execution (curl | bash) & desktop auto-placement
├── ran-hadoop                # Foreground cluster supervisor & signal trap
├── run-wordcount.sh          # UPDATED: Enhanced MapReduce shortcut with custom file & arg support
├── sample_input.txt          # Big Data sample dataset
├── conf/                     # HDFS & YARN XML configuration files
├── docs/
│   ├── Hadoop_Complete_Guide_Install_Run_WordCount.pdf # REBUILT: 8+ page publication PDF
│   └── videos/               # NEW: Video assets directory
│       ├── lab_setup_walkthrough.mp4
│       ├── mapreduce_shortcut_vs_manual.mp4
│       └── index.html        # Clean HTML5 media player
├── scripts/
│   ├── generate_pdf.py       # REBUILT: Upgraded ReportLab script with dual-track guides
│   ├── generate_videos.py    # NEW: Automated FFmpeg video generator for the 2 demo videos
│   ├── stop-hadoop-clean.sh  # Clean cluster teardown
│   └── verify-cluster.sh     # Health diagnostics
└── README.md                 # REBUILT: Modern badges, 1-click copy cards, dual workflows
```

---

## 5. Video Specifications
- **Format**: MP4 (H.264 / AAC) at 1920x1080 (1080p Full HD) and 30 fps, optimized for browser streaming.
- **Video 1 (Lab PC Setup)**: Explains the single-line command, Desktop destination, WSL2 verification, automated installation steps, and launching `ran-hadoop`.
- **Video 2 (MapReduce Deep Dive)**: Visualizes the MapReduce architecture (Map -> Shuffle -> Reduce), demonstrates the 1-click `./run-wordcount.sh` shortcut, then provides the live step-by-step walkthrough of all 7 manual HDFS commands.
- **HTML5 Player**: Responsive dark-themed media page (`docs/videos/index.html`) with embedded chapters, playback speed controls, and copyable commands alongside the video.

---

## 6. Verification & Quality Gates
1. Run `setup-lab.ps1` syntax verification.
2. Test `install.sh` self-bootstrapping pipe logic in bash.
3. Run `scripts/generate_pdf.py` via local `.venv/bin/python` and verify PDF page geometry, fonts, and table layout.
4. Run `scripts/generate_videos.py` via local `.venv` and verify both MP4 files are rendered cleanly without FFmpeg errors.
5. Push changes to GitHub repository `main` branch with git credentials.
