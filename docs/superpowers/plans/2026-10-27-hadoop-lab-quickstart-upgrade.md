# Hadoop Lab PC 1-Click Setup, Dual-Track PDF & Media Upgrade Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Provide an automated 1-to-3 line lab computer setup saved to the user's Desktop, an upgraded PDF guide with both shortcut and step-by-step manual MapReduce commands, two HD explainer videos with an HTML5 player, a modernized README, and push to GitHub.

**Architecture:** PowerShell script (`setup-lab.ps1`) for 1-click Windows Lab PC bootstrapping onto Desktop; pipe-enabled `install.sh` for Linux/WSL; Python ReportLab script for generating the dual-track PDF guide; FFmpeg-based automated video generator for two 1080p MP4 videos; and responsive HTML5 media gallery.

**Tech Stack:** PowerShell, Bash, Python 3 (.venv), ReportLab, FFmpeg, HTML5/CSS3, Git.

**Spec:** `docs/superpowers/specs/2026-10-27-hadoop-lab-quickstart-upgrade-design.md`

## Global Constraints
- Dedicated virtual environment `.venv` used for all Python executions (`.venv/bin/python`, `.venv/bin/pip`).
- 16-thread multi-connection downloads used for heavy assets.
- Clean execution on Windows 10/11 lab PCs without admin rights required unless enabling WSL feature for the first time.
- Clean cluster lifecycle termination (`ran-hadoop` SIGHUP/SIGINT trap) preserved.

## Review Focus
1. PowerShell 1-liner running on Windows without `git` pre-installed (must download repository archive directly via Invoke-WebRequest or Net.WebClient).
2. Bash 1-liner running via `curl -sSL ... | bash` without an existing cloned directory (must bootstrap clone to Desktop).
3. ReportLab PDF page overflow or missing fonts on clean systems.
4. FFmpeg video rendering compatibility (standard H.264 high profile, yuv420p for universal browser & player playback).
5. Git credential authorization for pushing to `fridayslifes/Hadoop:main`.

---

### Task 1: Windows Lab PC 1-Liner (`setup-lab.ps1`) & Batch Launcher Update

**Files:**
- Create: `setup-lab.ps1`
- Modify: `setup-wsl.bat`

**Interfaces:**
- Consumes: GitHub raw URL for `setup-lab.ps1`
- Produces: `%USERPROFILE%\Desktop\Hadoop` directory containing repository files, executes WSL setup.

- [ ] **Step 1: Create `setup-lab.ps1`**
  Implement self-contained PowerShell script:
  - Finds user Desktop (`[Environment]::GetFolderPath('Desktop')`).
  - Target: `$env:USERPROFILE\Desktop\Hadoop`.
  - If `git` is available, clones `https://github.com/fridayslifes/Hadoop.git`.
  - If `git` is not installed, downloads zip from `https://github.com/fridayslifes/Hadoop/archive/refs/heads/main.zip`, extracts to `$target`, moves contents cleanly.
  - Checks WSL status (`wsl --status`). If WSL is absent, attempts `wsl --install -d Ubuntu --no-launch` or provides plain English guidance.
  - Converts Windows path to WSL path using `wsl wslpath` and invokes `./install.sh`.
  - Creates a Windows Desktop shortcut `.lnk` for "Start Hadoop (ran-hadoop)".

- [ ] **Step 2: Update `setup-wsl.bat`**
  Ensure batch script cleanly supports being double-clicked from the Desktop and correctly invokes WSL with path translation.

- [ ] **Step 3: Verification**
  Run syntax check with PowerShell/bash:
  `pwsh -Command "Get-Command setup-lab.ps1" || powershell -Command "..." || bash -n install.sh`

- [ ] **Step 4: Commit**
  `git add setup-lab.ps1 setup-wsl.bat && git commit -m "feat(lab): add 1-click Windows lab PowerShell installer setup-lab.ps1"`

---

### Task 2: Piped Linux/WSL Installer Upgrade (`install.sh`)

**Files:**
- Modify: `install.sh`

**Interfaces:**
- Consumes: Direct execution or pipe `curl -sSL ... | bash`
- Produces: Automated unattended installation, Desktop/home directory placement, shell aliases.

- [ ] **Step 1: Add self-bootstrap detection to `install.sh`**
  Check if script is running in a directory containing `ran-hadoop` and `conf/`. If running piped via stdin without files:
  - Detect Desktop directory (`$HOME/Desktop` or `/mnt/c/Users/$USER/Desktop`).
  - Clone repo into `$HOME/Desktop/Hadoop` (or `$HOME/Hadoop`).
  - `cd` into that directory and re-execute `./install.sh`.

- [ ] **Step 2: Ensure unattended defaults and 16-thread download**
  Ensure package manager installation, SSH keygen, configuration generation, and NameNode format run smoothly without hanging for interactive input.

- [ ] **Step 3: Test syntax and execution check**
  Run `bash -n install.sh` to ensure zero syntax errors.

- [ ] **Step 4: Commit**
  `git add install.sh && git commit -m "feat(installer): enable curl pipe bootstrapping and desktop auto-placement"`

---

### Task 3: Upgraded Dual-Track PDF Guide (`scripts/generate_pdf.py`)

**Files:**
- Modify: `scripts/generate_pdf.py`
- Generate: `docs/Hadoop_Complete_Guide_Install_Run_WordCount.pdf`

**Interfaces:**
- Consumes: ReportLab in `.venv`
- Produces: Comprehensive PDF reference guide containing Fast Shortcut and 1-by-1 Manual Lab commands.

- [ ] **Step 1: Enhance `scripts/generate_pdf.py`**
  Add dedicated styled sections:
  1. **Quick-Start & Fast 1-Line Shortcuts**:
     - Windows Lab 1-liner & Linux/WSL 1-liner.
     - Single-command cluster start: `ran-hadoop`.
     - Single-command automated WordCount: `./run-wordcount.sh [input_file]`.
  2. **Step-by-Step 1-by-1 Manual Reference (Lab Exam & Viva)**:
     - Step 1: Daemon Startup & Health (`start-dfs.sh`, `start-yarn.sh`, `jps`).
     - Step 2: HDFS directory hierarchy (`hdfs dfs -mkdir -p /user/hadoop/input`).
     - Step 3: Data Ingestion (`hdfs dfs -put sample_input.txt /user/hadoop/input/`).
     - Step 4: Verification of HDFS Files (`hdfs dfs -ls /user/hadoop/input/`, `hdfs dfs -cat ...`).
     - Step 5: Manual MapReduce execution (`hadoop jar ... hadoop-mapreduce-examples-*.jar wordcount ...`).
     - Step 6: Reading Output Blocks (`hdfs dfs -ls /user/hadoop/output`, `hdfs dfs -cat .../part-r-00000`).
     - Step 7: Exporting results to local filesystem (`hdfs dfs -get ... ./results.txt`).
     - Step 8: Python Streaming MapReduce manual reference (`mapper.py`, `reducer.py`, `hadoop-streaming.jar`).

- [ ] **Step 2: Build the PDF using local `.venv`**
  Run: `.venv/bin/python scripts/generate_pdf.py`
  Verify `docs/Hadoop_Complete_Guide_Install_Run_WordCount.pdf` is generated and check size and page count.

- [ ] **Step 3: Commit**
  `git add scripts/generate_pdf.py docs/Hadoop_Complete_Guide_Install_Run_WordCount.pdf && git commit -m "docs(pdf): upgrade complete guide with dual shortcut and manual 1-by-1 reference"`

---

### Task 4: High-Definition Video Assets & HTML5 Player

**Files:**
- Create: `scripts/generate_videos.py`
- Create: `docs/videos/lab_setup_walkthrough.mp4`
- Create: `docs/videos/mapreduce_shortcut_vs_manual.mp4`
- Create: `docs/videos/index.html`

**Interfaces:**
- Consumes: FFmpeg, local `.venv/bin/python`
- Produces: Two 1080p MP4 videos with visual slides, command code boxes, smooth animations, and an HTML5 player.

- [ ] **Step 1: Write `scripts/generate_videos.py`**
  Generates frames and renders MP4 videos using FFmpeg with high-contrast developer terminal aesthetics:
  - **Video 1 (`lab_setup_walkthrough.mp4`)**:
    - Scene 1: The Computer Lab Challenge & 1-Line Solution.
    - Scene 2: Windows PowerShell 1-Liner running and saving to Desktop.
    - Scene 3: Automatic WSL & Ubuntu initialization.
    - Scene 4: 16-Thread accelerated Hadoop download & NameNode formatting.
    - Scene 5: Launching `ran-hadoop` and the Web UI at `localhost:9870`.
  - **Video 2 (`mapreduce_shortcut_vs_manual.mp4`)**:
    - Scene 1: MapReduce Concepts (Split -> Map -> Shuffle -> Reduce).
    - Scene 2: The Fast Shortcut (`./run-wordcount.sh sample_input.txt`).
    - Scene 3: The 1-by-1 Manual Lab Practical Workflow (7 explicit steps).
    - Scene 4: Python Streaming MapReduce bonus.
    - Scene 5: Clean shutdown with `Ctrl + C`.

- [ ] **Step 2: Render videos and verify playback**
  Run: `.venv/bin/python scripts/generate_videos.py`
  Verify both MP4 files exist and have valid video streams (`ffprobe`).

- [ ] **Step 3: Create `docs/videos/index.html`**
  A responsive dark-mode video player with tab switching between Video 1 and Video 2, speed controls, chapter markers, and one-click copy command cards.

- [ ] **Step 4: Commit**
  `git add scripts/generate_videos.py docs/videos/ && git commit -m "feat(media): add 2 HD explainer videos and interactive HTML5 video player"`

---

### Task 5: Modernized Visual README & Documentation Polish

**Files:**
- Modify: `README.md`

**Interfaces:**
- Consumes: Updated scripts, video paths, and PDF links
- Produces: Beautiful, high-converting GitHub README.

- [ ] **Step 1: Update `README.md`**
  - Add prominent "1-Click Lab PC Quickstart" banner with direct copy-paste code blocks for Windows PowerShell and Linux/WSL.
  - Add "Lab Exam Reference" section showing both the 1-line shortcut and the 7-step 1-by-1 manual commands in high-contrast syntax blocks.
  - Add "Watch Video Demos" section linking to `docs/videos/index.html` and the MP4 assets.
  - Add direct download badge/link for the updated PDF guide.
  - Add Architecture flowcharts and Web UI guide.

- [ ] **Step 2: Review markdown rendering**
  Ensure all links, code blocks, tables, and badges are properly formatted.

- [ ] **Step 3: Commit**
  `git add README.md && git commit -m "docs: modernize README with 1-click lab cards, video previews, and dual MapReduce reference"`

---

### Task 6: Final Verification, Git Remote Configuration & Push

**Files:**
- Verify entire repository tree.

- [ ] **Step 1: Configure Git credentials**
  Set authenticated remote URL using user's GitHub token:
  `git remote set-url origin https://fridayslifes:<TOKEN>@github.com/fridayslifes/Hadoop.git`

- [ ] **Step 2: Run verification script**
  Run cluster verification syntax test: `bash -n scripts/verify-cluster.sh`

- [ ] **Step 3: Push all commits to `origin main`**
  Run `git push origin main` and confirm remote branch is up to date.

- [ ] **Step 4: Clean up sensitive token from local git config**
  Reset remote URL to standard `https://github.com/fridayslifes/Hadoop.git` so tokens are never left stored in plain text.
