#!/usr/bin/env python3
"""
generate_videos.py - Programmatically creates 2 professional Full HD (1920x1080)
demo and walkthrough MP4 videos using Pillow and FFmpeg.

Video 1: lab_setup_walkthrough.mp4 (Universal 1-Click Setup Walkthrough)
         Demonstrates the 1-click Windows & Linux/WSL setup, Git check/install,
         Desktop folder placement, 16-thread download, and ran-hadoop supervisor.

Video 2: mapreduce_shortcut_vs_manual.mp4 (MapReduce Shortcut vs 1-by-1 Manual Reference)
         Demonstrates Hadoop MapReduce: The 1-line shortcut vs the complete
         step-by-step 1-by-1 manual command workflow.
"""

import os
import sys
import shutil
import subprocess
from PIL import Image, ImageDraw, ImageFont

OUTPUT_DIR = "docs/videos"
TEMP_FRAMES_DIR = "/tmp/hadoop_video_frames"

FONT_ARIAL = "/System/Library/Fonts/Supplemental/Arial.ttf"
FONT_MONACO = "/System/Library/Fonts/Monaco.ttf"

def get_font(path, size, index=0):
    try:
        return ImageFont.truetype(path, size, index=index)
    except Exception:
        try:
            return ImageFont.truetype(FONT_ARIAL, size)
        except Exception:
            return ImageFont.load_default()

def draw_header(draw, title, subtitle):
    draw.rectangle([(0, 0), (1920, 140)], fill="#0F172A")
    draw.line([(0, 140), (1920, 140)], fill="#0284C7", width=4)
    
    font_badge = get_font(FONT_ARIAL, 20)
    font_title = get_font(FONT_ARIAL, 38)
    font_sub = get_font(FONT_ARIAL, 22)
    
    draw.rounded_rectangle([(60, 26), (230, 62)], radius=6, fill="#0284C7")
    draw.text((80, 32), "APACHE HADOOP", font=font_badge, fill="#FFFFFF")
    
    draw.text((255, 26), title, font=font_title, fill="#F8FAFC")
    draw.text((60, 85), subtitle, font=font_sub, fill="#94A3B8")

def draw_footer(draw, progress_text, step_badge=""):
    draw.rectangle([(0, 1010), (1920, 1080)], fill="#0F172A")
    draw.line([(0, 1010), (1920, 1010)], fill="#334155", width=2)
    
    font_footer = get_font(FONT_ARIAL, 20)
    draw.text((60, 1032), "fridayslifes/Hadoop • Universal Quickstart & Lifecycle Guide", font=font_footer, fill="#64748B")
    
    if step_badge:
        draw.rounded_rectangle([(1400, 1025), (1600, 1065)], radius=6, fill="#1E293B")
        draw.text((1420, 1033), step_badge, font=font_footer, fill="#38BDF8")
        
    draw.text((1640, 1032), progress_text, font=font_footer, fill="#94A3B8")

def draw_terminal(draw, x, y, w, h, title, command_lines, output_lines=[]):
    draw.rounded_rectangle([(x, y), (x + w, y + h)], radius=12, fill="#1E1E2E", outline="#313244", width=2)
    draw.rounded_rectangle([(x, y), (x + w, y + 44)], radius=12, fill="#181825")
    draw.rectangle([(x, y + 30), (x + w, y + 44)], fill="#181825")
    
    draw.ellipse([(x + 18, y + 14), (x + 32, y + 28)], fill="#F38BA8")
    draw.ellipse([(x + 40, y + 14), (x + 54, y + 28)], fill="#F9E2AF")
    draw.ellipse([(x + 62, y + 14), (x + 76, y + 28)], fill="#A6E3A1")
    
    font_term_title = get_font(FONT_ARIAL, 18)
    draw.text((x + 95, y + 12), title, font=font_term_title, fill="#CDD6F4")
    
    font_code = get_font(FONT_MONACO, 21)
    font_out = get_font(FONT_MONACO, 19)
    
    curr_y = y + 65
    for cmd in command_lines:
        draw.text((x + 25, curr_y), "$ ", font=font_code, fill="#89B4FA")
        draw.text((x + 55, curr_y), cmd, font=font_code, fill="#A6E3A1")
        curr_y += 36
        
    curr_y += 10
    for out in output_lines:
        color = "#BAC2DE"
        if "[✓]" in out or "✓" in out or "SUCCESS" in out:
            color = "#A6E3A1"
        elif "[ERROR]" in out or "FAILED" in out:
            color = "#F38BA8"
        elif "[*]" in out or "Starting" in out:
            color = "#89DCEB"
        draw.text((x + 25, curr_y), out, font=font_out, fill=color)
        curr_y += 30

def draw_info_box(draw, x, y, w, h, title, bullets, border_color="#0284C7", bg_color="#1E293B"):
    draw.rounded_rectangle([(x, y), (x + w, y + h)], radius=12, fill=bg_color, outline=border_color, width=2)
    draw.text((x + 25, y + 20), title, font=get_font(FONT_ARIAL, 24), fill="#38BDF8")
    draw.line([(x + 25, y + 55), (x + w - 25, y + 55)], fill="#334155", width=2)
    
    curr_y = y + 70
    font_bullet = get_font(FONT_ARIAL, 20)
    for b in bullets:
        draw.text((x + 30, curr_y), "•", font=font_bullet, fill="#0284C7")
        draw.text((x + 55, curr_y), b, font=font_bullet, fill="#E2E8F0")
        curr_y += 38


# =============================================================================
# SCENES FOR VIDEO 1: Universal Setup Walkthrough
# =============================================================================
def make_video_1_scenes():
    scenes = []
    
    # Scene 1: Universal 1-Click Overview
    img = Image.new("RGB", (1920, 1080), "#0B0F19")
    draw = ImageDraw.Draw(img)
    draw_header(draw, "Universal 1-Click Apache Hadoop Setup", "Automated End-to-End Installation on Windows (WSL2) & Linux")
    draw_info_box(draw, 100, 200, 800, 720, "What This Automates", [
        "Checks & installs Git automatically if absent.",
        "Detects & configures WSL2 with Ubuntu.",
        "Downloads Hadoop via 16-thread accelerator.",
        "Configures Java OpenJDK 11 & passwordless SSH.",
        "Generates all HDFS and YARN XML configurations.",
        "Formats HDFS NameNode automatically."
    ], border_color="#10B981")
    draw_info_box(draw, 1020, 200, 800, 720, "Universal Deployment", [
        "Works on any Windows 10/11 system.",
        "Works on Ubuntu, Debian, CentOS, Fedora, Arch.",
        "Files placed cleanly in Desktop\\Hadoop.",
        "Zero manual environment variable editing.",
        "Desktop shortcuts generated for quick launch."
    ], border_color="#38BDF8")
    draw_footer(draw, "Scene 1 / 5", "Overview")
    scenes.append((img, 4))
    
    # Scene 2: Windows PowerShell 1-Liner
    img = Image.new("RGB", (1920, 1080), "#0B0F19")
    draw = ImageDraw.Draw(img)
    draw_header(draw, "Step 1: Execute the 1-Liner in PowerShell", "Single command handles Git, WSL, and Hadoop extraction to Desktop")
    draw_terminal(draw, 100, 190, 1720, 750, "Windows PowerShell", [
        "irm https://raw.githubusercontent.com/fridayslifes/Hadoop/main/setup.ps1 | iex"
    ], [
        "[*] Destination Directory: C:\\Users\\User\\Desktop\\Hadoop",
        "[*] Checking for Git... Installing Git via winget if missing... [✓] Done",
        "[*] Downloading Hadoop repository to your Desktop...",
        "[✓] Repository successfully extracted to Desktop\\Hadoop",
        "[*] Verifying Windows Subsystem for Linux (WSL) status...",
        "[✓] WSL is active and operational.",
        "[✓] Created Desktop Shortcut: 'Start Hadoop (ran-hadoop)'",
        "[✓] Created Desktop Shortcut: 'Run Hadoop WordCount'",
        "[*] Initiating automated Hadoop setup inside WSL...",
        "------------------------------------------------------------------------------",
        "[✓] OpenJDK 11 verified",
        "[✓] SSH keygen & authorized_keys configured",
        "[✓] core-site.xml, hdfs-site.xml, mapred-site.xml, yarn-site.xml generated"
    ])
    draw_footer(draw, "Scene 2 / 5", "PowerShell 1-Liner")
    scenes.append((img, 5))
    
    # Scene 3: 16-Thread Fast Download
    img = Image.new("RGB", (1920, 1080), "#0B0F19")
    draw = ImageDraw.Draw(img)
    draw_header(draw, "Step 2: 16-Thread Accelerated Hadoop Download", "Downloads the 730MB Apache distribution in seconds via aria2")
    draw_terminal(draw, 100, 190, 1720, 750, "Installation Terminal", [
        "aria2c --split=16 --max-connection-per-server=16 https://dlcdn.apache.org/.../hadoop-3.3.6.tar.gz"
    ], [
        "[*] 16 concurrent segmented streams connected across Apache CDN mirrors",
        "[#4b2a10 710MiB/730MiB(97%) CN:16 DL:68MiB ETA:0s]",
        "[#4b2a10 730MiB/730MiB(100%) CN:16 DL:72MiB]",
        "[✓] Download completed in 10.4 seconds (Average 70 MB/s)",
        "[✓] Verifying tarball archive integrity... OK",
        "[✓] Extracted to $HOME/hadoop successfully.",
        "[✓] Formatting HDFS NameNode storage... Storage directory formatted successfully.",
        "[✓] 'ran-hadoop' CLI installed globally to /usr/local/bin/ran-hadoop."
    ])
    draw_footer(draw, "Scene 3 / 5", "16-Thread Download")
    scenes.append((img, 5))
    
    # Scene 4: Starting Hadoop via ran-hadoop
    img = Image.new("RGB", (1920, 1080), "#0B0F19")
    draw = ImageDraw.Draw(img)
    draw_header(draw, "Step 3: Launch Cluster Supervisor ('ran-hadoop')", "Starts HDFS + YARN and prevents orphaned Java processes")
    draw_terminal(draw, 100, 190, 1720, 750, "Terminal 1: Foreground Supervisor", [
        "ran-hadoop"
    ], [
        "================================================================",
        "             Apache Hadoop is Active & Running                  ",
        "================================================================",
        "Active Cluster Daemons (jps):",
        "  • 18234 NameNode          (Port 9870)",
        "  • 18356 DataNode          (Port 9864)",
        "  • 18490 SecondaryNameNode (Port 9868)",
        "  • 18612 ResourceManager   (Port 8088)",
        "  • 18745 NodeManager       (Port 8042)",
        "",
        "Web Portals in your Browser: http://localhost:9870 | http://localhost:8088",
        "",
        "[LIFECYCLE CONTROL]",
        "  • Press Ctrl+C in this terminal to gracefully stop all daemons.",
        "  • Closing this terminal tab triggers SIGHUP auto-shutdown (zero memory leak)."
    ])
    draw_footer(draw, "Scene 4 / 5", "Cluster Supervisor")
    scenes.append((img, 5))
    
    # Scene 5: Setup Summary
    img = Image.new("RGB", (1920, 1080), "#0B0F19")
    draw = ImageDraw.Draw(img)
    draw_header(draw, "Ready to Process Big Data with Hadoop", "Hadoop 3.3.6 active • Pseudo-distributed cluster running • Zero residual leaks")
    draw_info_box(draw, 100, 200, 800, 720, "What Was Accomplished", [
        "Hadoop 3.3.6 installed and ready.",
        "HDFS Master (NameNode) & Workers active.",
        "YARN Resource Manager scheduling enabled.",
        "Web Management active at localhost:9870.",
        "Desktop shortcuts created for quick restart."
    ], border_color="#38BDF8")
    draw_info_box(draw, 1020, 200, 800, 720, "Next Actions", [
        "Open a second terminal for MapReduce jobs.",
        "Track A: Run shortcut './run-wordcount.sh'.",
        "Track B: Run step-by-step manual commands.",
        "Monitor jobs in browser at http://localhost:8088.",
        "Press Ctrl+C in Terminal 1 to stop cluster."
    ], border_color="#10B981")
    draw_footer(draw, "Scene 5 / 5", "Ready to Code")
    scenes.append((img, 4))
    
    return scenes


# =============================================================================
# SCENES FOR VIDEO 2: MapReduce Shortcut vs Manual Step-by-Step
# =============================================================================
def make_video_2_scenes():
    scenes = []
    
    # Scene 1: MapReduce Concepts
    img = Image.new("RGB", (1920, 1080), "#0B0F19")
    draw = ImageDraw.Draw(img)
    draw_header(draw, "Hadoop MapReduce Architecture & Processing Model", "Distributed Processing Across Commodity Cluster Nodes")
    draw_info_box(draw, 100, 200, 800, 720, "Core MapReduce Pipeline", [
        "1. Input Split: 128MB HDFS block splits.",
        "2. Map Phase: Emits key-value pairs <word, 1>.",
        "3. Shuffle & Sort: Groups identical keys by hash.",
        "4. Reduce Phase: Aggregates sums <word, total>.",
        "5. Output File: Written to HDFS as part-r-00000."
    ], border_color="#0284C7")
    draw_info_box(draw, 1020, 200, 800, 720, "Two Execution Tracks", [
        "Track A (Automated Shortcut):",
        "  • Run './run-wordcount.sh' in 1 line.",
        "  • Instant execution & top 25 word frequencies.",
        "Track B (Manual Step-by-Step Commands):",
        "  • Complete reference for manual execution.",
        "  • Raw HDFS mkdir, put, jar, cat & get commands."
    ], border_color="#F59E0B")
    draw_footer(draw, "Scene 1 / 5", "Architecture")
    scenes.append((img, 4))
    
    # Scene 2: Track A - Fast 1-Line Shortcut
    img = Image.new("RGB", (1920, 1080), "#0B0F19")
    draw = ImageDraw.Draw(img)
    draw_header(draw, "Track A: The Automated 1-Line Shortcut (Speed Run)", "Execute complete WordCount job on any file with a single script")
    draw_terminal(draw, 100, 190, 1720, 750, "Terminal 2: Run WordCount Shortcut", [
        "./run-wordcount.sh sample_input.txt"
    ], [
        "[1/5] Checking Hadoop cluster status... [✓] HDFS is reachable.",
        "[2/5] Locating MapReduce Examples JAR... [✓] Found hadoop-mapreduce-examples-3.3.6.jar",
        "[3/5] Uploading 'sample_input.txt' to HDFS at /wordcount_demo/input...",
        "[4/5] Executing MapReduce WordCount Job on YARN...",
        "      map 0% reduce 0% -> map 100% reduce 100%",
        "[✓] MapReduce job completed successfully!",
        "[5/5] Fetching WordCount Results from HDFS (/wordcount_demo/output)...",
        "========================================",
        "WORD                      | COUNT",
        "----------------------------------------",
        "and                       | 14",
        "of                        | 10",
        "Hadoop                    | 9",
        "distributed               | 5",
        "MapReduce                 | 4",
        "----------------------------------------",
        "Total unique words processed: 118"
    ])
    draw_footer(draw, "Scene 2 / 5", "Track A: Shortcut")
    scenes.append((img, 5))
    
    # Scene 3: Track B - Manual Commands (Part 1: HDFS Setup)
    img = Image.new("RGB", (1920, 1080), "#0B0F19")
    draw = ImageDraw.Draw(img)
    draw_header(draw, "Track B: Manual 1-by-1 Command Reference", "Steps 1 to 4: Cluster Check, Directory Creation & Ingestion")
    draw_terminal(draw, 100, 190, 1720, 750, "Terminal 2: Raw HDFS Commands (Line-by-Line)", [
        "jps",
        "hdfs dfs -mkdir -p /my_data/input",
        "hdfs dfs -put -f sample_input.txt /my_data/input/",
        "hdfs dfs -ls /my_data/input"
    ], [
        "# Step 1: Check running daemons",
        "18234 NameNode | 18356 DataNode | 18612 ResourceManager | 18745 NodeManager",
        "",
        "# Step 2: Create HDFS input directory",
        "[✓] Directory /my_data/input created in HDFS.",
        "",
        "# Step 3: Put local text file into HDFS",
        "[✓] File sample_input.txt copied to HDFS.",
        "",
        "# Step 4: Verify file exists in HDFS",
        "Found 1 items",
        "-rw-r--r--   1 user supergroup       2041 2026-10-27 12:00 /my_data/input/sample_input.txt"
    ])
    draw_footer(draw, "Scene 3 / 5", "Track B: Steps 1-4")
    scenes.append((img, 5))
    
    # Scene 4: Track B - Manual Commands (Part 2: Jar Execution & Output)
    img = Image.new("RGB", (1920, 1080), "#0B0F19")
    draw = ImageDraw.Draw(img)
    draw_header(draw, "Track B: Manual 1-by-1 Command Reference", "Steps 5 to 7: Running MapReduce Jar, Viewing Output & Exporting")
    draw_terminal(draw, 100, 190, 1720, 750, "Terminal 2: Running the MapReduce Jar & Output Inspection", [
        "hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar wordcount /my_data/input /my_data/output",
        "hdfs dfs -ls /my_data/output",
        "hdfs dfs -cat /my_data/output/part-r-00000 | head -n 10",
        "hdfs dfs -get /my_data/output/part-r-00000 ./wordcount_results.txt"
    ], [
        "# Step 5: Execute WordCount JAR",
        "INFO mapreduce.Job: Running job: job_1729000000000_0001",
        "INFO mapreduce.Job: Job job_1729000000000_0001 completed successfully",
        "",
        "# Step 6: Verify output files",
        "/my_data/output/_SUCCESS",
        "/my_data/output/part-r-00000",
        "",
        "# Step 7: View results and download to local filesystem",
        "Apache\t3 | Hadoop\t9 | MapReduce\t4 | distributed\t5",
        "[✓] Exported results to local file: ./wordcount_results.txt"
    ])
    draw_footer(draw, "Scene 4 / 5", "Track B: Steps 5-7")
    scenes.append((img, 5))
    
    # Scene 5: Python Streaming & Graceful Shutdown
    img = Image.new("RGB", (1920, 1080), "#0B0F19")
    draw = ImageDraw.Draw(img)
    draw_header(draw, "Python Streaming MapReduce & Clean Teardown", "Writing custom Python Mappers & Graceful Auto-Shutdown with Ctrl+C")
    draw_info_box(draw, 100, 200, 800, 720, "Python Streaming Command", [
        "chmod +x mapper.py reducer.py",
        "hadoop jar $HADOOP_HOME/.../hadoop-streaming-*.jar \\",
        "   -input /my_data/input \\",
        "   -output /my_data/python_out \\",
        "   -mapper ./mapper.py \\",
        "   -reducer ./reducer.py",
        "",
        "Allows writing MapReduce in pure Python!"
    ], border_color="#38BDF8")
    draw_info_box(draw, 1020, 200, 800, 720, "Graceful Shutdown (Zero RAM Leaks)", [
        "In Terminal 1: Press Ctrl + C",
        "  • stop-yarn.sh triggers automatically.",
        "  • stop-dfs.sh triggers automatically.",
        "  • JVM processes terminated cleanly.",
        "  • Ports 9000 & 9870 freed.",
        "  • Zero orphaned memory on the computer!"
    ], border_color="#10B981")
    draw_footer(draw, "Scene 5 / 5", "Python & Teardown")
    scenes.append((img, 4))
    
    return scenes


def compile_video(scenes, output_path, title_sound=440):
    os.makedirs(TEMP_FRAMES_DIR, exist_ok=True)
    frame_idx = 0
    fps = 30
    
    print(f"[*] Rendering {len(scenes)} scenes to frames...")
    for scene_img, duration_sec in scenes:
        num_frames = int(duration_sec * fps)
        for _ in range(num_frames):
            frame_file = os.path.join(TEMP_FRAMES_DIR, f"frame_{frame_idx:05d}.png")
            scene_img.save(frame_file)
            frame_idx += 1
            
    print(f"[✓] Generated {frame_idx} frames. Compiling MP4 video with FFmpeg...")
    
    ffmpeg_cmd = [
        "ffmpeg", "-y",
        "-framerate", str(fps),
        "-i", os.path.join(TEMP_FRAMES_DIR, "frame_%05d.png"),
        "-f", "lavfi", "-i", f"sine=frequency={title_sound}:duration={frame_idx/fps}",
        "-c:v", "libx264",
        "-profile:v", "high",
        "-level:v", "4.0",
        "-pix_fmt", "yuv420p",
        "-c:a", "aac",
        "-b:a", "128k",
        "-shortest",
        output_path
    ]
    
    res = subprocess.run(ffmpeg_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if res.returncode != 0:
        print(f"[ERROR] FFmpeg error: {res.stderr.decode('utf-8')}")
        sys.exit(1)
        
    shutil.rmtree(TEMP_FRAMES_DIR, ignore_errors=True)
    print(f"[✓] Successfully compiled: {output_path}")


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    v1_path = os.path.join(OUTPUT_DIR, "lab_setup_walkthrough.mp4")
    print(f"\n--- Building Video 1: {v1_path} ---")
    scenes_v1 = make_video_1_scenes()
    compile_video(scenes_v1, v1_path, title_sound=523)
    
    v2_path = os.path.join(OUTPUT_DIR, "mapreduce_shortcut_vs_manual.mp4")
    print(f"\n--- Building Video 2: {v2_path} ---")
    scenes_v2 = make_video_2_scenes()
    compile_video(scenes_v2, v2_path, title_sound=659)
    
    print("\n[✓] Both videos successfully generated!")

if __name__ == '__main__':
    main()
