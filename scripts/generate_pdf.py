#!/usr/bin/env python3
"""
generate_pdf.py - Generates the complete Apache Hadoop Deployment & WordCount Guide.
Uses ReportLab Platypus engine to create a high-quality PDF.
"""

import os
import sys
from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.lib.units import inch
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, KeepTogether, HRFlowable
)
from reportlab.pdfgen import canvas

class NumberedCanvas(canvas.Canvas):
    """Canvas that performs a two-pass calculation to print 'Page X of Y' and running headers."""
    def __init__(self, *args, **kwargs):
        super(NumberedCanvas, self).__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_decorations(num_pages)
            super(NumberedCanvas, self).showPage()
        super(NumberedCanvas, self).save()

    def draw_page_decorations(self, page_count):
        self.saveState()
        self.setFont("Helvetica", 8)
        self.setFillColor(colors.HexColor("#6B7280"))

        page_w, page_h = letter
        margin = 36 # 0.5 in

        # Header on all pages except page 1
        if self._pageNumber > 1:
            self.drawString(margin, page_h - 26, "Apache Hadoop Setup, 'ran-hadoop' CLI & WordCount Guide")
            self.setStrokeColor(colors.HexColor("#E5E7EB"))
            self.setLineWidth(0.5)
            self.line(margin, page_h - 30, page_w - margin, page_h - 30)

        # Footer on all pages
        self.setStrokeColor(colors.HexColor("#E5E7EB"))
        self.setLineWidth(0.5)
        self.line(margin, 34, page_w - margin, 34)

        self.drawString(margin, 22, "Confidential / Open Source Community Guide - Fast 16-Thread Hadoop Quickstart")
        page_str = f"Page {self._pageNumber} of {page_count}"
        self.drawRightString(page_w - margin, 22, page_str)

        self.restoreState()


def create_callout(title, text, style_title, style_body, bg_color="#EFF6FF", border_color="#3B82F6"):
    content = [
        Paragraph(f"<b>{title}</b>", style_title),
        Spacer(1, 3),
        Paragraph(text, style_body)
    ]
    t = Table([[content]], colWidths=[540])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor(bg_color)),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor(border_color)),
        ('LINEBEFORE', (0,0), (0,-1), 4, colors.HexColor(border_color)),
        ('TOPPADDING', (0,0), (-1,-1), 6),
        ('BOTTOMPADDING', (0,0), (-1,-1), 6),
        ('LEFTPADDING', (0,0), (-1,-1), 10),
        ('RIGHTPADDING', (0,0), (-1,-1), 10),
    ]))
    return t


def create_code_block(code_text, style_code):
    # Escape HTML tags
    cleaned = code_text.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
    lines = cleaned.split('\n')
    formatted = "<br/>".join(lines)
    p = Paragraph(formatted, style_code)
    t = Table([[p]], colWidths=[540])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor("#1E1E2E")),
        ('BOX', (0,0), (-1,-1), 0.5, colors.HexColor("#313244")),
        ('TOPPADDING', (0,0), (-1,-1), 6),
        ('BOTTOMPADDING', (0,0), (-1,-1), 6),
        ('LEFTPADDING', (0,0), (-1,-1), 8),
        ('RIGHTPADDING', (0,0), (-1,-1), 8),
    ]))
    return t


def build_pdf(filename="docs/Hadoop_Complete_Guide_Install_Run_WordCount.pdf"):
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    doc = SimpleDocTemplate(
        filename,
        pagesize=letter,
        leftMargin=36,
        rightMargin=36,
        topMargin=42,
        bottomMargin=42
    )

    styles = getSampleStyleSheet()

    # Custom styles
    title_style = ParagraphStyle(
        'DocTitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=21,
        leading=25,
        textColor=colors.HexColor('#0F172A'),
        alignment=0
    )

    subtitle_style = ParagraphStyle(
        'DocSubtitle',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=11,
        leading=15,
        textColor=colors.HexColor('#0284C7'),
        alignment=0
    )

    h1_style = ParagraphStyle(
        'Heading1_Custom',
        parent=styles['Heading1'],
        fontName='Helvetica-Bold',
        fontSize=14,
        leading=18,
        textColor=colors.HexColor('#1E293B'),
        spaceBefore=14,
        spaceAfter=6,
        keepWithNext=True
    )

    h2_style = ParagraphStyle(
        'Heading2_Custom',
        parent=styles['Heading2'],
        fontName='Helvetica-Bold',
        fontSize=11,
        leading=15,
        textColor=colors.HexColor('#0369A1'),
        spaceBefore=10,
        spaceAfter=4,
        keepWithNext=True
    )

    body_style = ParagraphStyle(
        'Body_Custom',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=9,
        leading=13,
        textColor=colors.HexColor('#334155'),
        spaceBefore=3,
        spaceAfter=4
    )

    bullet_style = ParagraphStyle(
        'Bullet_Custom',
        parent=body_style,
        leftIndent=15,
        bulletIndent=5,
        spaceBefore=2,
        spaceAfter=2
    )

    code_style = ParagraphStyle(
        'Code_Custom',
        parent=styles['Code'],
        fontName='Courier',
        fontSize=7.8,
        leading=10.5,
        textColor=colors.HexColor('#A6E3A1')
    )

    callout_title = ParagraphStyle(
        'CalloutTitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=9,
        leading=12,
        textColor=colors.HexColor('#1E3A8A')
    )

    callout_body = ParagraphStyle(
        'CalloutBody',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=8.5,
        leading=11.5,
        textColor=colors.HexColor('#1E293B')
    )

    story = []

    # =========================================================================
    # COVER / HEADER BANNER
    # =========================================================================
    story.append(Paragraph("Apache Hadoop Complete Architecture &amp; Deployment Guide", title_style))
    story.append(Spacer(1, 3))
    story.append(Paragraph("16-Thread Fast Installation • Terminal Lifecycle CLI (ran-hadoop) • MapReduce WordCount Tutorial", subtitle_style))
    story.append(Spacer(1, 8))
    story.append(HRFlowable(width="100%", thickness=1.5, color=colors.HexColor("#0284C7"), spaceBefore=1, spaceAfter=8))

    # Metadata Table
    meta_data = [
        [
            Paragraph("<b>Hadoop Version:</b> 3.3.6 / 3.4.x", body_style),
            Paragraph("<b>Target OS:</b> WSL (Windows 10/11), Ubuntu, Debian, Kali, CentOS, RHEL, Arch", body_style)
        ],
        [
            Paragraph("<b>Runtime JDK:</b> OpenJDK 11 / OpenJDK 8", body_style),
            Paragraph("<b>Accelerator:</b> aria2 (16 Concurrent Connections / Multi-Source)", body_style)
        ],
        [
            Paragraph("<b>Process Lifecycle:</b> ran-hadoop (Ctrl+C &amp; SIGHUP auto-stop)", body_style),
            Paragraph("<b>Verification Demo:</b> Distributed MapReduce WordCount on YARN", body_style)
        ]
    ]
    meta_table = Table(meta_data, colWidths=[270, 270])
    meta_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor("#F8FAFC")),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor("#E2E8F0")),
        ('INNERGRID', (0,0), (-1,-1), 0.5, colors.HexColor("#EDF2F7")),
        ('TOPPADDING', (0,0), (-1,-1), 4),
        ('BOTTOMPADDING', (0,0), (-1,-1), 4),
        ('LEFTPADDING', (0,0), (-1,-1), 8),
        ('RIGHTPADDING', (0,0), (-1,-1), 8),
    ]))
    story.append(meta_table)
    story.append(Spacer(1, 10))

    # =========================================================================
    # SECTION 1: INTRODUCTION & ARCHITECTURE
    # =========================================================================
    story.append(Paragraph("1. Executive Summary &amp; Architecture Overview", h1_style))
    story.append(Paragraph(
        "<b>Apache Hadoop</b> is the bedrock framework for distributed storage (HDFS) and distributed parallel processing (YARN &amp; MapReduce) across commodity server clusters. In a single-node <b>pseudo-distributed mode</b>, all Hadoop daemons run on a single machine (such as a Windows Subsystem for Linux (WSL) instance or Linux host) simulating a fully functional multi-node cluster with full API compatibility.",
        body_style
    ))

    # Daemon Overview Table
    daemon_data = [
        [Paragraph("<b>Component</b>", body_style), Paragraph("<b>Daemon Name</b>", body_style), Paragraph("<b>Function &amp; Role in Cluster</b>", body_style), Paragraph("<b>Default Port / UI</b>", body_style)],
        [Paragraph("HDFS Master", body_style), Paragraph("NameNode", body_style), Paragraph("Manages filesystem namespace, directory tree, block-to-DataNode mappings", body_style), Paragraph("9000 (RPC) / 9870 (Web)", body_style)],
        [Paragraph("HDFS Worker", body_style), Paragraph("DataNode", body_style), Paragraph("Stores and retrieves actual data blocks (typically 128MB chunks) on disk", body_style), Paragraph("9866 (Data) / 9864 (Web)", body_style)],
        [Paragraph("HDFS Checkpoint", body_style), Paragraph("SecondaryNameNode", body_style), Paragraph("Merges edit logs with fsimage periodically to prevent log explosion", body_style), Paragraph("9868 (Web)", body_style)],
        [Paragraph("YARN Master", body_style), Paragraph("ResourceManager", body_style), Paragraph("Arbitrates compute resources (CPU/RAM) across all submitted jobs", body_style), Paragraph("8032 (RPC) / 8088 (Web)", body_style)],
        [Paragraph("YARN Worker", body_style), Paragraph("NodeManager", body_style), Paragraph("Launches and monitors MapReduce task containers on the host node", body_style), Paragraph("8042 (Web)", body_style)],
    ]
    daemon_table = Table(daemon_data, colWidths=[90, 95, 235, 120])
    daemon_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor("#0284C7")),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
        ('BOTTOMPADDING', (0,0), (-1,0), 5),
        ('TOPPADDING', (0,0), (-1,0), 5),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#CBD5E1")),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, colors.HexColor("#F8FAFC")]),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('LEFTPADDING', (0,0), (-1,-1), 5),
        ('RIGHTPADDING', (0,0), (-1,-1), 5),
    ]))
    story.append(daemon_table)
    story.append(Spacer(1, 10))

    # =========================================================================
    # SECTION 2: PREREQUISITES & WSL SETUP
    # =========================================================================
    story.append(Paragraph("2. Prerequisites &amp; System Preparation (WSL / Any Linux)", h1_style))
    story.append(Paragraph(
        "This installation is engineered to run seamlessly inside <b>Windows Subsystem for Linux (WSL2)</b> or native Linux distributions (Ubuntu, Debian, Kali, CentOS, RHEL, Fedora, Rocky, Arch, openSUSE).",
        body_style
    ))

    story.append(Paragraph("<b>A. Setting up WSL on Windows 10 / 11 (if not already enabled):</b>", h2_style))
    story.append(Paragraph("Open Windows PowerShell as Administrator and run:", body_style))
    story.append(create_code_block("wsl --install\nwsl --set-default-version 2", code_style))

    story.append(Paragraph("<b>B. Java JDK Selection (Why OpenJDK 11 or 8?):</b>", h2_style))
    story.append(Paragraph(
        "Apache Hadoop core, IPC serialization, and YARN node containers have strict compatibility with <b>OpenJDK 11</b> and <b>OpenJDK 8</b>. Bleeding-edge Java versions (such as Java 17, 21, or 25) enforce JVM module encapsulation, requiring numerous <code>--add-opens</code> reflective access flags. The installer automatically detects, verifies, and installs <b>OpenJDK 11</b> as the golden standard.",
        body_style
    ))

    # Callout
    story.append(create_callout(
        "💡 Important Tip for WSL Users",
        "Inside WSL, services like SSH daemon (sshd) do not always start automatically on boot. The <code>ran-hadoop</code> CLI and <code>install.sh</code> automatically check and start <code>sshd</code> for you, ensuring zero connection errors.",
        callout_title, callout_body,
        bg_color="#FEF3C7", border_color="#F59E0B"
    ))
    story.append(Spacer(1, 10))

    # =========================================================================
    # SECTION 3: 16-THREAD FAST DOWNLOAD & ONE-CLICK INSTALLATION
    # =========================================================================
    story.append(Paragraph("3. One-Click Installation &amp; 16-Thread Fast Download", h1_style))
    story.append(Paragraph(
        "Hadoop distribution tarballs exceed 700MB. Downloading over single-stream HTTP can be throttled or stall. Our installer deploys <b>aria2c</b> configured for <b>16 concurrent segment downloads</b> across mirror fallbacks, maximizing throughput and completing the download in seconds.",
        body_style
    ))

    story.append(Paragraph("<b>Download Accelerator Command Implemented in install.sh:</b>", h2_style))
    story.append(create_code_block(
        "aria2c --split=16 --max-connection-per-server=16 --min-split-size=1M \\\n"
        "       --max-concurrent-downloads=16 --file-allocation=none \\\n"
        "       https://dlcdn.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz",
        code_style
    ))

    story.append(Paragraph("<b>Step-by-Step Installation Procedure:</b>", h2_style))
    story.append(Paragraph("<b>1. Clone the repository and enter the directory:</b>", bullet_style))
    story.append(create_code_block("git clone <repo-url> hadoop-quickstart\ncd hadoop-quickstart", code_style))
    story.append(Paragraph("<b>2. Execute the one-click installer:</b>", bullet_style))
    story.append(create_code_block("chmod +x install.sh ran-hadoop run-wordcount.sh\n./install.sh", code_style))
    story.append(Paragraph("<b>3. (Alternative for Windows):</b> Double-click <code>setup-wsl.bat</code> in File Explorer to launch and install inside WSL with zero typing.", bullet_style))

    story.append(Spacer(1, 8))
    story.append(Paragraph("<b>What install.sh Does Automatically:</b>", h2_style))
    story.append(Paragraph("• <b>Distro Detection:</b> Supports apt (Debian/Ubuntu/Kali), dnf/yum (RHEL/Fedora), pacman (Arch), zypper (openSUSE).", bullet_style))
    story.append(Paragraph("• <b>Dependency Setup:</b> Installs OpenJDK 11, aria2, openssh-server, rsync, and procps.", bullet_style))
    story.append(Paragraph("• <b>Passwordless SSH:</b> Generates RSA keys, configures <code>~/.ssh/authorized_keys</code>, sets <code>StrictHostKeyChecking no</code>.", bullet_style))
    story.append(Paragraph("• <b>16-Thread Download:</b> Retrieves Hadoop 3.3.6 from official Apache CDN with multi-stream acceleration.", bullet_style))
    story.append(Paragraph("• <b>Directory Extraction:</b> Extracts to <code>$HOME/hadoop</code>, avoiding root permission locks in WSL.", bullet_style))
    story.append(Paragraph("• <b>Configuration Generation:</b> Builds <code>core-site.xml</code>, <code>hdfs-site.xml</code>, <code>mapred-site.xml</code>, <code>yarn-site.xml</code>, and <code>hadoop-env.sh</code>.", bullet_style))
    story.append(Paragraph("• <b>Storage Initialization:</b> Formats the HDFS NameNode automatically.", bullet_style))
    story.append(Paragraph("• <b>System Integration:</b> Installs <code>ran-hadoop</code> into <code>/usr/local/bin</code> and configures <code>~/.bashrc</code>.", bullet_style))

    story.append(PageBreak())

    # =========================================================================
    # SECTION 4: THE 'ran-hadoop' CLI & LIFECYCLE
    # =========================================================================
    story.append(Paragraph("4. The 'ran-hadoop' Terminal Lifecycle CLI", h1_style))
    story.append(Paragraph(
        "Standard Hadoop utilities (<code>start-dfs.sh</code>, <code>start-yarn.sh</code>) spawn disconnected background background daemons. If a user closes their WSL or Linux window, JVM processes can stay orphaned, holding ports 9000 and 9870, locking NameNode editlogs, and draining RAM.<br/><br/>"
        "The custom <b><code>ran-hadoop</code></b> command solves this by providing a unified foreground cluster lifecycle manager with <b>automatic POSIX signal cleanup</b>.",
        body_style
    ))

    story.append(Paragraph("<b>Command Usage:</b>", h2_style))
    story.append(create_code_block("ran-hadoop", code_style))

    story.append(Paragraph("<b>Key Lifecycle Features:</b>", h2_style))
    story.append(Paragraph("• <b>Single Command Startup:</b> Automatically verifies SSH, initializes NameNode if needed, and starts DFS and YARN.", bullet_style))
    story.append(Paragraph("• <b>Live Health Dashboard:</b> Displays running daemon PIDs and clickable browser links to Web UIs.", bullet_style))
    story.append(Paragraph("• <b>Traps Ctrl + C (SIGINT):</b> Intercepting Ctrl+C gracefully invokes <code>stop-yarn.sh</code> and <code>stop-dfs.sh</code>.", bullet_style))
    story.append(Paragraph("• <b>Traps Terminal Close (SIGHUP):</b> When the terminal window or WSL tab is closed, the operating system issues a <code>SIGHUP</code> (Hangup) signal to the process group. <code>ran-hadoop</code> traps this signal and shuts down all daemons cleanly before exiting.", bullet_style))
    story.append(Paragraph("• <b>Orphan Process Prevention:</b> Performs a secondary sweep to guarantee no rogue Java processes remain.", bullet_style))

    story.append(Spacer(1, 5))
    story.append(Paragraph("<b>Under the Hood: POSIX Signal Trap Mechanism in ran-hadoop:</b>", h2_style))
    story.append(create_code_block(
        "cleanup() {\n"
        "    trap '' SIGINT SIGTERM SIGHUP EXIT  # Prevent recursion\n"
        "    echo \"[ran-hadoop] Stopping YARN and HDFS daemons...\"\n"
        "    \"$HADOOP_HOME/sbin/stop-yarn.sh\"\n"
        "    \"$HADOOP_HOME/sbin/stop-dfs.sh\"\n"
        "    exit 0\n"
        "}\n"
        "trap cleanup SIGINT SIGTERM SIGHUP EXIT",
        code_style
    ))

    story.append(Spacer(1, 10))

    # =========================================================================
    # SECTION 5: WORDCOUNT MAPREDUCE TUTORIAL
    # =========================================================================
    story.append(Paragraph("5. Step-by-Step WordCount MapReduce Tutorial", h1_style))
    story.append(Paragraph(
        "The <b>WordCount</b> job is the classic 'Hello World' of distributed computing. It demonstrates parallel tokenization across split blocks (Map phase) and aggregation of token frequencies across partitions (Reduce phase).",
        body_style
    ))

    # Flow Table
    flow_data = [
        [Paragraph("<b>Phase</b>", body_style), Paragraph("<b>Input</b>", body_style), Paragraph("<b>Operation</b>", body_style), Paragraph("<b>Output Key-Value Pair</b>", body_style)],
        [Paragraph("1. Input Split", body_style), Paragraph("Text file in HDFS", body_style), Paragraph("HDFS breaks file into 128MB block splits", body_style), Paragraph("&lt;byte_offset, line_text&gt;", body_style)],
        [Paragraph("2. Map", body_style), Paragraph("Line of text", body_style), Paragraph("Mapper tokenizes words and emits count '1'", body_style), Paragraph("&lt;word, 1&gt;", body_style)],
        [Paragraph("3. Shuffle / Sort", body_style), Paragraph("Mapped pairs", body_style), Paragraph("Partitions pairs by key hash and groups identical keys", body_style), Paragraph("&lt;word, [1, 1, 1, ...]&gt;", body_style)],
        [Paragraph("4. Reduce", body_style), Paragraph("Grouped values", body_style), Paragraph("Sums total count list for each distinct word", body_style), Paragraph("&lt;word, total_count&gt;", body_style)],
    ]
    flow_table = Table(flow_data, colWidths=[90, 110, 200, 140])
    flow_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor("#0F766E")),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
        ('BOTTOMPADDING', (0,0), (-1,0), 4),
        ('TOPPADDING', (0,0), (-1,0), 4),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#CBD5E1")),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, colors.HexColor("#F8FAFC")]),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('LEFTPADDING', (0,0), (-1,-1), 5),
        ('RIGHTPADDING', (0,0), (-1,-1), 5),
    ]))
    story.append(flow_table)
    story.append(Spacer(1, 10))

    story.append(Paragraph("<b>Executing WordCount Manually (Step-by-Step):</b>", h2_style))
    story.append(Paragraph("<b>Step 1:</b> While <code>ran-hadoop</code> is running in Terminal 1, open <b>Terminal 2</b>.", bullet_style))
    story.append(Paragraph("<b>Step 2:</b> Create an input directory inside HDFS:", bullet_style))
    story.append(create_code_block("hdfs dfs -mkdir -p /wordcount_demo/input", code_style))

    story.append(Paragraph("<b>Step 3:</b> Upload the sample text file (or any document) into HDFS:", bullet_style))
    story.append(create_code_block("hdfs dfs -put -f sample_input.txt /wordcount_demo/input/", code_style))

    story.append(Paragraph("<b>Step 4:</b> Execute the bundled MapReduce examples JAR:", bullet_style))
    story.append(create_code_block(
        "hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar \\\n"
        "       wordcount /wordcount_demo/input /wordcount_demo/output",
        code_style
    ))

    story.append(Paragraph("<b>Step 5:</b> Inspect the word count output from HDFS:", bullet_style))
    story.append(create_code_block("hdfs dfs -cat /wordcount_demo/output/part-r-00000 | sort -k2 -nr | head -n 25", code_style))

    story.append(Spacer(1, 6))
    story.append(Paragraph("<b>One-Click Execution with run-wordcount.sh:</b>", h2_style))
    story.append(Paragraph("You can also execute all the above steps automatically with a single script:", body_style))
    story.append(create_code_block("./run-wordcount.sh [optional_custom_textfile.txt]", code_style))

    story.append(PageBreak())

    # =========================================================================
    # SECTION 6: WEB USER INTERFACES & VERIFICATION
    # =========================================================================
    story.append(Paragraph("6. Web User Interfaces &amp; Cluster Verification", h1_style))
    story.append(Paragraph(
        "Hadoop provides rich browser-based administrative portals for monitoring storage and distributed compute jobs.",
        body_style
    ))

    web_data = [
        [Paragraph("<b>Web Portal</b>", body_style), Paragraph("<b>Browser URL</b>", body_style), Paragraph("<b>Key Metrics &amp; Monitoring Features</b>", body_style)],
        [
            Paragraph("<b>HDFS NameNode UI</b>", body_style),
            Paragraph("<font color='#0284C7'>http://localhost:9870</font>", body_style),
            Paragraph("DFS Used/Remaining capacity, Live DataNodes status, Block pool breakdown, Utilities &gt; Browse the File System.", body_style)
        ],
        [
            Paragraph("<b>YARN ResourceManager UI</b>", body_style),
            Paragraph("<font color='#0284C7'>http://localhost:8088</font>", body_style),
            Paragraph("Active/Completed MapReduce applications, NodeManager health, Memory (MB) and VCores allocated, container execution logs.", body_style)
        ],
        [
            Paragraph("<b>HDFS DataNode UI</b>", body_style),
            Paragraph("<font color='#0284C7'>http://localhost:9864</font>", body_style),
            Paragraph("Individual node block statistics, physical disk mount utilization, and block storage reports.", body_style)
        ],
    ]
    web_table = Table(web_data, colWidths=[130, 140, 270])
    web_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor("#1E293B")),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
        ('BOTTOMPADDING', (0,0), (-1,0), 5),
        ('TOPPADDING', (0,0), (-1,0), 5),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#CBD5E1")),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, colors.HexColor("#F8FAFC")]),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
        ('RIGHTPADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(web_table)
    story.append(Spacer(1, 10))

    story.append(Paragraph("<b>Terminal Diagnostic Verification (jps):</b>", h2_style))
    story.append(Paragraph("Run <code>jps</code> in any terminal. A healthy cluster will show exactly these 5 daemons:", body_style))
    story.append(create_code_block(
        "12345 NameNode\n"
        "12456 DataNode\n"
        "12567 SecondaryNameNode\n"
        "12678 ResourceManager\n"
        "12789 NodeManager\n"
        "12890 Jps",
        code_style
    ))

    # =========================================================================
    # SECTION 7: TROUBLESHOOTING & FAQ
    # =========================================================================
    story.append(Spacer(1, 6))
    story.append(Paragraph("7. Troubleshooting &amp; Common Pitfalls", h1_style))

    trouble_data = [
        [
            Paragraph("<b>Symptom / Error</b>", body_style),
            Paragraph("<b>Root Cause</b>", body_style),
            Paragraph("<b>Proven Solution</b>", body_style)
        ],
        [
            Paragraph("<code>Name node is in safe mode</code>", body_style),
            Paragraph("HDFS requires a brief warmup period or block threshold check on startup.", body_style),
            Paragraph("Force leave safe mode by executing:<br/><code>hdfs dfsadmin -safemode leave</code>", body_style)
        ],
        [
            Paragraph("<code>ssh: connect to host localhost port 22: Connection refused</code>", body_style),
            Paragraph("OpenSSH server daemon is inactive in WSL.", body_style),
            Paragraph("Start SSH service:<br/><code>sudo service ssh start</code><br/>(install.sh and ran-hadoop do this automatically)", body_style)
        ],
        [
            Paragraph("<code>Container [pid=...] is running beyond virtual memory limits</code>", body_style),
            Paragraph("WSL kernel reports different virtual memory commit ratios to YARN NodeManager.", body_style),
            Paragraph("Disabled by default in our <code>yarn-site.xml</code>:<br/><code>yarn.nodemanager.vmem-check-enabled=false</code>", body_style)
        ],
        [
            Paragraph("<code>Cannot access localhost:9870 in Windows Chrome/Edge</code>", body_style),
            Paragraph("WSL2 localhost forwarding or Windows firewall blocking bridge.", body_style),
            Paragraph("Access via WSL IP: run <code>wsl hostname -I</code>, then visit <code>http://&lt;wsl-ip&gt;:9870</code> in Windows browser.", body_style)
        ],
        [
            Paragraph("<code>Orphan processes locking port 9000</code>", body_style),
            Paragraph("Terminal was forcefully killed with kill -9 without cleanup.", body_style),
            Paragraph("Run the cleanup helper:<br/><code>./scripts/stop-hadoop-clean.sh</code>", body_style)
        ],
    ]
    trouble_table = Table(trouble_data, colWidths=[140, 160, 240])
    trouble_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor("#B91C1C")),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
        ('BOTTOMPADDING', (0,0), (-1,0), 5),
        ('TOPPADDING', (0,0), (-1,0), 5),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#CBD5E1")),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, colors.HexColor("#F8FAFC")]),
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('LEFTPADDING', (0,0), (-1,-1), 5),
        ('RIGHTPADDING', (0,0), (-1,-1), 5),
    ]))
    story.append(trouble_table)

    # =========================================================================
    # SECTION 8: CHEAT SHEET
    # =========================================================================
    story.append(Spacer(1, 10))
    story.append(Paragraph("8. Quick Command Cheat Sheet", h1_style))

    cheat_data = [
        [Paragraph("<b>Task / Action</b>", body_style), Paragraph("<b>Command</b>", body_style)],
        [Paragraph("Install &amp; Configure Hadoop (16-thread)", body_style), Paragraph("<code>./install.sh</code> (or double-click <code>setup-wsl.bat</code>)", body_style)],
        [Paragraph("Start Hadoop &amp; Monitor in Terminal", body_style), Paragraph("<code>ran-hadoop</code>", body_style)],
        [Paragraph("Stop Hadoop Gracefully", body_style), Paragraph("<b>Ctrl + C</b> in <code>ran-hadoop</code> terminal, or close window", body_style)],
        [Paragraph("Run WordCount MapReduce Demo", body_style), Paragraph("<code>./run-wordcount.sh [filename]</code>", body_style)],
        [Paragraph("Cluster Health Diagnostics", body_style), Paragraph("<code>./scripts/verify-cluster.sh</code>", body_style)],
        [Paragraph("Emergency Daemon Teardown", body_style), Paragraph("<code>./scripts/stop-hadoop-clean.sh</code>", body_style)],
        [Paragraph("List Files in HDFS", body_style), Paragraph("<code>hdfs dfs -ls /</code>", body_style)],
        [Paragraph("Upload Local File to HDFS", body_style), Paragraph("<code>hdfs dfs -put &lt;local-file&gt; &lt;hdfs-path&gt;</code>", body_style)],
        [Paragraph("Download File from HDFS", body_style), Paragraph("<code>hdfs dfs -get &lt;hdfs-path&gt; &lt;local-file&gt;</code>", body_style)],
        [Paragraph("Read File Content from HDFS", body_style), Paragraph("<code>hdfs dfs -cat &lt;hdfs-path&gt;</code>", body_style)],
        [Paragraph("Check HDFS Cluster Capacity", body_style), Paragraph("<code>hdfs dfsadmin -report</code>", body_style)],
    ]
    cheat_table = Table(cheat_data, colWidths=[200, 340])
    cheat_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor("#0284C7")),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
        ('BOTTOMPADDING', (0,0), (-1,0), 4),
        ('TOPPADDING', (0,0), (-1,0), 4),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#CBD5E1")),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, colors.HexColor("#F8FAFC")]),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
        ('RIGHTPADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(cheat_table)

    # Build the document
    doc.build(story, canvasmaker=NumberedCanvas)
    print(f"Successfully generated PDF: {filename}")


if __name__ == '__main__':
    target = sys.argv[1] if len(sys.argv) > 1 else "docs/Hadoop_Complete_Guide_Install_Run_WordCount.pdf"
    build_pdf(target)
