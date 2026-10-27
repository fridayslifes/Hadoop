#!/usr/bin/env python3
"""
generate_videos.py - Generates 2 clean Full HD (1920x1080) walkthrough MP4 videos
for Hadoop installation and MapReduce WordCount.
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
    draw.rectangle([(0, 0), (1920, 135)], fill="#0F172A")
    draw.line([(0, 135), (1920, 135)], fill="#0284C7", width=3)
    
    font_badge = get_font(FONT_ARIAL, 20)
    font_title = get_font(FONT_ARIAL, 36)
    font_sub = get_font(FONT_ARIAL, 21)
    
    draw.rounded_rectangle([(60, 24), (200, 60)], radius=6, fill="#0284C7")
    draw.text((80, 30), "HADOOP", font=font_badge, fill="#FFFFFF")
    
    draw.text((225, 24), title, font=font_title, fill="#F8FAFC")
    draw.text((60, 82), subtitle, font=font_sub, fill="#94A3B8")

def draw_footer(draw, progress_text):
    draw.rectangle([(0, 1010), (1920, 1080)], fill="#0F172A")
    draw.line([(0, 1010), (1920, 1010)], fill="#334155", width=1)
    
    font_footer = get_font(FONT_ARIAL, 20)
    draw.text((60, 1032), "Apache Hadoop Installation & MapReduce Guide", font=font_footer, fill="#64748B")
    draw.text((1640, 1032), progress_text, font=font_footer, fill="#94A3B8")

def draw_terminal(draw, x, y, w, h, title, command_lines, output_lines=[], cursor_on=True):
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
    for i, cmd in enumerate(command_lines):
        draw.text((x + 25, curr_y), "$ ", font=font_code, fill="#89B4FA")
        draw.text((x + 55, curr_y), cmd, font=font_code, fill="#A6E3A1")
        if cursor_on and i == len(command_lines) - 1 and len(output_lines) == 0:
            bbox = font_code.getbbox(cmd)
            cursor_x = x + 55 + (bbox[2] - bbox[0]) + 4
            draw.rectangle([(cursor_x, curr_y + 2), (cursor_x + 12, curr_y + 24)], fill="#A6E3A1")
        curr_y += 36
        
    curr_y += 8
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

def draw_progress_bar(draw, x, y, w, h, progress_ratio, label):
    draw.rounded_rectangle([(x, y), (x + w, y + h)], radius=8, fill="#181825", outline="#313244", width=2)
    fill_w = int((w - 4) * min(max(progress_ratio, 0.0), 1.0))
    if fill_w > 8:
        draw.rounded_rectangle([(x + 2, y + 2), (x + 2 + fill_w, y + h - 2)], radius=6, fill="#10B981")
    font_bar = get_font(FONT_MONACO, 18)
    draw.text((x + 15, y + 8), label, font=font_bar, fill="#FFFFFF")


# =============================================================================
# VIDEO 1: Setup Walkthrough
# =============================================================================
def render_video_1_frames(out_dir, fps=30):
    os.makedirs(out_dir, exist_ok=True)
    frame_idx = 0

    def save_frame(img):
        nonlocal frame_idx
        fpath = os.path.join(out_dir, f"frame_{frame_idx:05d}.png")
        img.save(fpath)
        frame_idx += 1

    # Scene 1: Overview (3s)
    img_s1 = Image.new("RGB", (1920, 1080), "#0B0F19")
    draw = ImageDraw.Draw(img_s1)
    draw_header(draw, "Hadoop Installation Guide", "One-Command Setup for Windows (WSL) & Linux")
    draw_info_box(draw, 100, 190, 800, 740, "What Gets Installed", [
        "Installs Git if not already on the machine.",
        "Enables WSL2 & Ubuntu if on Windows.",
        "Installs OpenJDK 11 and OpenSSH.",
        "Downloads Hadoop 3.3.6 (16-thread download).",
        "Configures core-site, hdfs-site, yarn-site.",
        "Formats HDFS NameNode automatically."
    ], border_color="#10B981")
    draw_info_box(draw, 1020, 190, 800, 740, "Quick Commands", [
        "Windows (PowerShell):",
        "  irm https://raw.githubusercontent.com/.../setup.ps1 | iex",
        "",
        "Linux / WSL:",
        "  curl -sSL https://raw.githubusercontent.com/.../install.sh | bash",
        "",
        "Start Hadoop:",
        "  ran-hadoop"
    ], border_color="#38BDF8")
    draw_footer(draw, "1 / 4")
    for _ in range(90):
        save_frame(img_s1)

    # Scene 2: PowerShell Execution (5s)
    full_cmd = "irm https://raw.githubusercontent.com/fridayslifes/Hadoop/main/setup.ps1 | iex"
    out_lines = [
        "[*] Destination: C:\\Users\\User\\Desktop\\Hadoop",
        "[*] Checking for Git... [✓] Git ready",
        "[*] Downloading repository to Desktop... [✓] Done",
        "[*] Checking WSL status... [✓] WSL active",
        "[✓] Created Desktop Shortcut: 'Start Hadoop (ran-hadoop)'",
        "[✓] Created Desktop Shortcut: 'Run Hadoop WordCount'",
        "[*] Running installation inside WSL...",
        "[✓] OpenJDK 11 installed",
        "[✓] SSH localhost keys configured",
        "[✓] Hadoop XML files written and NameNode formatted"
    ]
    for f in range(150):
        img = Image.new("RGB", (1920, 1080), "#0B0F19")
        draw = ImageDraw.Draw(img)
        draw_header(draw, "Step 1: Run the Setup Command", "Downloads to Desktop and installs everything automatically")
        type_len = int(len(full_cmd) * min(f / 45.0, 1.0))
        out_count = 0
        if f > 45:
            out_count = int(len(out_lines) * min((f - 45) / 75.0, 1.0))
        draw_terminal(draw, 100, 180, 1720, 760, "PowerShell", [full_cmd[:type_len]], out_lines[:out_count], cursor_on=(f % 16 < 8))
        draw_footer(draw, "2 / 4")
        save_frame(img)

    # Scene 3: Fast Download & NameNode Format (5s)
    s3_cmd = "aria2c --split=16 --max-connection-per-server=16 https://.../hadoop-3.3.6.tar.gz"
    for f in range(150):
        img = Image.new("RGB", (1920, 1080), "#0B0F19")
        draw = ImageDraw.Draw(img)
        draw_header(draw, "Step 2: 16-Thread Download & Setup", "Downloads Hadoop 3.3.6 archive and formats NameNode")
        prog = min(f / 110.0, 1.0)
        mb = int(730 * prog)
        pct = int(prog * 100)
        s3_outs = [
            f"[*] Downloading: {mb} / 730 MB ({pct}%) • 16 connections"
        ]
        if prog >= 1.0:
            s3_outs.extend([
                "[✓] Download complete.",
                "[✓] Extracted to $HOME/hadoop.",
                "[✓] HDFS NameNode formatted successfully.",
                "[✓] 'ran-hadoop' ready."
            ])
        draw_terminal(draw, 100, 180, 1720, 760, "Installation Progress", [s3_cmd], s3_outs)
        draw_progress_bar(draw, 130, 340, 1660, 36, prog, f"Download: {pct}% ({mb}/730 MB)")
        draw_footer(draw, "3 / 4")
        save_frame(img)

    # Scene 4: Starting Hadoop (4s)
    img_s4 = Image.new("RGB", (1920, 1080), "#0B0F19")
    draw = ImageDraw.Draw(img_s4)
    draw_header(draw, "Step 3: Start Hadoop with 'ran-hadoop'", "Starts HDFS and YARN daemons with clean Ctrl+C shutdown")
    draw_terminal(draw, 100, 180, 1720, 760, "Terminal", ["ran-hadoop"], [
        "Apache Hadoop is Active & Running",
        "Daemons running (jps):",
        "  • NameNode          (http://localhost:9870)",
        "  • DataNode          (http://localhost:9864)",
        "  • SecondaryNameNode (http://localhost:9868)",
        "  • ResourceManager   (http://localhost:8088)",
        "  • NodeManager       (http://localhost:8042)",
        "",
        "To stop Hadoop anytime: Press Ctrl + C"
    ], cursor_on=False)
    draw_footer(draw, "4 / 4")
    for _ in range(120):
        save_frame(img_s4)

    return frame_idx


# =============================================================================
# VIDEO 2: MapReduce WordCount Walkthrough
# =============================================================================
def render_video_2_frames(out_dir, fps=30):
    os.makedirs(out_dir, exist_ok=True)
    frame_idx = 0

    def save_frame(img):
        nonlocal frame_idx
        fpath = os.path.join(out_dir, f"frame_{frame_idx:05d}.png")
        img.save(fpath)
        frame_idx += 1

    # Scene 1: Shortcut Method (6s)
    cmd_s1 = "./run-wordcount.sh sample_input.txt"
    outs_s1 = [
        "[1/5] Checking cluster status... [✓] HDFS is reachable.",
        "[2/5] Using hadoop-mapreduce-examples-3.3.6.jar",
        "[3/5] Uploading sample_input.txt to HDFS at /wordcount_demo/input...",
        "[4/5] Running MapReduce WordCount job on YARN...",
        "      map 100% reduce 100%",
        "[✓] Job completed successfully!",
        "[5/5] WordCount Results:",
        "----------------------------------------",
        "WORD                      | COUNT",
        "----------------------------------------",
        "and                       | 14",
        "of                        | 10",
        "Hadoop                    | 9",
        "distributed               | 5",
        "MapReduce                 | 4",
        "----------------------------------------"
    ]
    for f in range(180):
        img = Image.new("RGB", (1920, 1080), "#0B0F19")
        draw = ImageDraw.Draw(img)
        draw_header(draw, "Option 1: Quick Shortcut Script", "Runs the entire WordCount job with one command")
        type_len = int(len(cmd_s1) * min(f / 40.0, 1.0))
        out_count = 0
        if f > 40:
            out_count = int(len(outs_s1) * min((f - 40) / 90.0, 1.0))
        draw_terminal(draw, 100, 180, 1720, 760, "Terminal", [cmd_s1[:type_len]], outs_s1[:out_count], cursor_on=(f % 16 < 8))
        draw_footer(draw, "1 / 3")
        save_frame(img)

    # Scene 2: Manual Commands Step-by-Step (7s)
    cmds_s2 = [
        "jps",
        "hdfs dfs -mkdir -p /my_data/input",
        "hdfs dfs -put -f sample_input.txt /my_data/input/",
        "hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar wordcount /my_data/input /my_data/output",
        "hdfs dfs -cat /my_data/output/part-r-00000 | head -n 10"
    ]
    outs_s2 = [
        "18234 NameNode | 18356 DataNode | 18612 ResourceManager | 18745 NodeManager",
        "[✓] Directory created in HDFS",
        "[✓] File uploaded to HDFS",
        "INFO mapreduce.Job: Job completed successfully",
        "Apache\t3 | Hadoop\t9 | MapReduce\t4 | distributed\t5"
    ]
    for f in range(210):
        img = Image.new("RGB", (1920, 1080), "#0B0F19")
        draw = ImageDraw.Draw(img)
        draw_header(draw, "Option 2: Step-by-Step Manual Commands", "Running MapReduce line by line")
        step_idx = min(int(f / 40.0) + 1, len(cmds_s2))
        draw_terminal(draw, 100, 180, 1720, 760, "Terminal", cmds_s2[:step_idx], outs_s2[:step_idx])
        draw_footer(draw, "2 / 3")
        save_frame(img)

    # Scene 3: Clean Shutdown (4s)
    img_s3 = Image.new("RGB", (1920, 1080), "#0B0F19")
    draw = ImageDraw.Draw(img_s3)
    draw_header(draw, "Stopping Hadoop", "Stop all daemons cleanly")
    draw_terminal(draw, 100, 180, 1720, 760, "Terminal", ["^C"], [
        "[ran-hadoop] Caught Ctrl+C signal. Stopping cluster...",
        "Stopping YARN daemons...",
        "Stopping HDFS daemons...",
        "[✓] All Hadoop daemons stopped cleanly. No orphaned processes left."
    ], cursor_on=False)
    draw_footer(draw, "3 / 3")
    for _ in range(120):
        save_frame(img_s3)

    return frame_idx


def compile_video_from_frames(frames_dir, output_path, total_frames, fps=30):
    duration = total_frames / fps
    print(f"[✓] Compiling {total_frames} frames into {output_path} ({duration:.1f}s)...")
    
    # Clean quiet audio track so HTML5 video players load properly with no loud noise
    audio_expr = "anullsrc=channel_layout=stereo:sample_rate=44100"
    
    ffmpeg_cmd = [
        "ffmpeg", "-y",
        "-framerate", str(fps),
        "-i", os.path.join(frames_dir, "frame_%05d.png"),
        "-f", "lavfi", "-i", audio_expr,
        "-c:v", "libx264",
        "-profile:v", "high",
        "-level:v", "4.0",
        "-pix_fmt", "yuv420p",
        "-c:a", "aac",
        "-b:a", "128k",
        "-t", str(duration),
        output_path
    ]
    
    res = subprocess.run(ffmpeg_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if res.returncode != 0:
        print(f"[ERROR] FFmpeg compilation failed: {res.stderr.decode('utf-8')}")
        sys.exit(1)
        
    shutil.rmtree(frames_dir, ignore_errors=True)
    print(f"[✓] Successfully compiled: {output_path}")


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    fps = 30
    
    # Video 1
    print("\n--- Building Video 1: setup_walkthrough.mp4 ---")
    frames_v1_dir = "/tmp/v1_frames"
    shutil.rmtree(frames_v1_dir, ignore_errors=True)
    count_v1 = render_video_1_frames(frames_v1_dir, fps=fps)
    v1_main_path = os.path.join(OUTPUT_DIR, "setup_walkthrough.mp4")
    compile_video_from_frames(frames_v1_dir, v1_main_path, count_v1, fps=fps)
    # Copies for existing links
    shutil.copyfile(v1_main_path, os.path.join(OUTPUT_DIR, "hadoop_universal_setup_walkthrough.mp4"))
    shutil.copyfile(v1_main_path, os.path.join(OUTPUT_DIR, "lab_setup_walkthrough.mp4"))
    
    # Video 2
    print("\n--- Building Video 2: mapreduce_guide.mp4 ---")
    frames_v2_dir = "/tmp/v2_frames"
    shutil.rmtree(frames_v2_dir, ignore_errors=True)
    count_v2 = render_video_2_frames(frames_v2_dir, fps=fps)
    v2_path = os.path.join(OUTPUT_DIR, "mapreduce_guide.mp4")
    compile_video_from_frames(frames_v2_dir, v2_path, count_v2, fps=fps)
    # Copy for existing links
    shutil.copyfile(v2_path, os.path.join(OUTPUT_DIR, "mapreduce_shortcut_vs_manual.mp4"))
    
    print("\n[✓] Both MP4 videos compiled cleanly with zero audio noise!")

if __name__ == '__main__':
    main()
