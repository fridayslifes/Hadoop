#!/usr/bin/env python3
"""
generate_pdf.py - Generates the complete Apache Hadoop Architecture, Deployment
& Dual-Track MapReduce Reference Guide.
Uses ReportLab Platypus engine to create a high-quality PDF guide.
Features:
- Universal 1-Click Windows & Linux/WSL setup instructions
- Track A: Automated 1-Line Shortcut Commands
- Track B: Step-by-Step 1-by-1 Manual Command Reference
- Python Streaming MapReduce Reference
- Diagnostic Cheat Sheet & Troubleshooting
"""

import os
import sys
from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
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
        self.setFillColor(colors.HexColor("#64748B"))

        page_w, page_h = letter
        margin = 36 # 0.5 in

        # Header on all pages except page 1
        if self._pageNumber > 1:
            self.drawString(margin, page_h - 26, "Apache Hadoop Architecture, Automated Quickstart & MapReduce Manual")
            self.setStrokeColor(colors.HexColor("#E2E8F0"))
            self.setLineWidth(0.5)
            self.line(margin, page_h - 30, page_w - margin, page_h - 30)

        # Footer on all pages
        self.setStrokeColor(colors.HexColor("#E2E8F0"))
        self.setLineWidth(0.5)
        self.line(margin, 34, page_w - margin, 34)

        self.drawString(margin, 22, "Apache Hadoop Universal Manual & Practical Reference • fridayslifes/Hadoop")
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


def create_code_block(code_text, style_code, bg_color="#1E1E2E"):
    cleaned = code_text.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
    lines = cleaned.split('\n')
    formatted = "<br/>".join(lines)
    p = Paragraph(formatted, style_code)
    t = Table([[p]], colWidths=[540])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor(bg_color)),
        ('BOX', (0,0), (-1,-1), 0.5, colors.HexColor("#334155")),
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
        fontSize=20,
        leading=24,
        textColor=colors.HexColor('#0F172A'),
        alignment=0
    )

    subtitle_style = ParagraphStyle(
        'DocSubtitle',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=10.5,
        leading=14,
        textColor=colors.HexColor('#0284C7'),
        alignment=0
    )

    h1_style = ParagraphStyle(
        'Heading1_Custom',
        parent=styles['Heading1'],
        fontName='Helvetica-Bold',
        fontSize=13,
        leading=17,
        textColor=colors.HexColor('#1E293B'),
        spaceBefore=12,
        spaceAfter=5,
        keepWithNext=True
    )

    h2_style = ParagraphStyle(
        'Heading2_Custom',
        parent=styles['Heading2'],
        fontName='Helvetica-Bold',
        fontSize=10.5,
        leading=14,
        textColor=colors.HexColor('#0369A1'),
        spaceBefore=8,
        spaceAfter=3,
        keepWithNext=True
    )

    body_style = ParagraphStyle(
        'Body_Custom',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=8.8,
        leading=12.5,
        textColor=colors.HexColor('#334155'),
        spaceBefore=2,
        spaceAfter=3
    )

    bullet_style = ParagraphStyle(
        'Bullet_Custom',
        parent=body_style,
        leftIndent=14,
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
    # HEADER BANNER
    # =========================================================================
    story.append(Paragraph("Apache Hadoop Architecture &amp; MapReduce Manual", title_style))
    story.append(Spacer(1, 3))
    story.append(Paragraph("Universal 1-Click Installation • Fast Shortcuts vs. Complete 1-by-1 Manual Reference", subtitle_style))
    story.append(Spacer(1, 6))
    story.append(HRFlowable(width="100%", thickness=1.5, color=colors.HexColor("#0284C7"), spaceBefore=1, spaceAfter=8))

    # Metadata Table
    meta_data = [
        [
            Paragraph("<b>Target Environment:</b> Windows 10/11 (WSL2), Ubuntu, Debian, CentOS, Arch, macOS", body_style),
            Paragraph("<b>Apache Hadoop Version:</b> 3.3.6 / 3.4.x (Stable Distributed)", body_style)
        ],
        [
            Paragraph("<b>Universal 1-Liner:</b> <code>irm https://raw.githubusercontent.com/.../setup.ps1 | iex</code>", body_style),
            Paragraph("<b>Auto-Placement:</b> Saves cleanly to <code>Desktop\\Hadoop</code> or home directory", body_style)
        ],
        [
            Paragraph("<b>Dual MapReduce Tracks:</b> Automated 1-Click Script &amp; Step-by-Step Raw Commands", body_style),
            Paragraph("<b>Cluster Supervisor:</b> <code>ran-hadoop</code> (POSIX SIGHUP auto-stop)", body_style)
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
    story.append(Spacer(1, 8))

    # =========================================================================
    # SECTION 1: UNIVERSAL 1-CLICK QUICKSTART
    # =========================================================================
    story.append(Paragraph("1. Universal Automated Quickstart (1 to 3 Line Commands)", h1_style))
    story.append(Paragraph(
        "Deploy a complete, fully configured Apache Hadoop pseudo-distributed cluster without manual XML edits or environment path headaches:",
        body_style
    ))

    story.append(Paragraph("<b>Option A: Windows (PowerShell 1-Liner)</b>", h2_style))
    story.append(Paragraph("Paste this single command into Windows PowerShell (installs Git if missing, verifies WSL, and sets up Hadoop):", body_style))
    story.append(create_code_block("irm https://raw.githubusercontent.com/fridayslifes/Hadoop/main/setup.ps1 | iex", code_style))
    story.append(Paragraph(
        "<i>What this does:</i> Checks and installs Git if absent, saves to <code>%USERPROFILE%\\Desktop\\Hadoop</code>, launches WSL2 Ubuntu, deploys OpenJDK 11, configures passwordless SSH, formats the NameNode, and creates Desktop shortcuts.",
        bullet_style
    ))

    story.append(Spacer(1, 4))
    story.append(Paragraph("<b>Option B: Linux / WSL Terminal 1-Liner</b>", h2_style))
    story.append(Paragraph("In any Linux terminal or existing WSL shell, run:", body_style))
    story.append(create_code_block("curl -sSL https://raw.githubusercontent.com/fridayslifes/Hadoop/main/install.sh | bash", code_style))

    story.append(Spacer(1, 4))
    story.append(Paragraph("<b>Option C: Git Clone 2-Liner</b>", h2_style))
    story.append(create_code_block(
        "git clone https://github.com/fridayslifes/Hadoop.git ~/Desktop/Hadoop\n"
        "cd ~/Desktop/Hadoop && ./install.sh",
        code_style
    ))

    story.append(Spacer(1, 8))

    # =========================================================================
    # SECTION 2: CLUSTER LIFECYCLE & 'ran-hadoop'
    # =========================================================================
    story.append(Paragraph("2. Starting &amp; Managing the Cluster ('ran-hadoop')", h1_style))
    story.append(Paragraph(
        "Standard Hadoop scripts spawn background daemons that leave ports locked and consume gigabytes of RAM when you close your terminal. The <b><code>ran-hadoop</code></b> CLI solves this with automatic POSIX signal interception.",
        body_style
    ))

    story.append(create_code_block("ran-hadoop", code_style))

    story.append(Paragraph("<b>Cluster Lifecycle Controls:</b>", h2_style))
    story.append(Paragraph("• <b>Foreground Dashboard:</b> Keeps the cluster active and shows real-time daemon status.", bullet_style))
    story.append(Paragraph("• <b>Clean Stop:</b> Press <b>Ctrl + C</b> in the terminal to cleanly terminate all HDFS and YARN daemons.", bullet_style))
    story.append(Paragraph("• <b>Close Window Auto-Stop:</b> Closing the terminal window sends a <code>SIGHUP</code> trap that safely cleans up all JVMs, leaving <b>zero orphaned processes</b>.", bullet_style))

    # Verification Table
    jps_data = [
        [Paragraph("<b>Hadoop Daemon</b>", body_style), Paragraph("<b>Process Role</b>", body_style), Paragraph("<b>Web Interface URL</b>", body_style)],
        [Paragraph("<b>NameNode</b>", body_style), Paragraph("Master: Manages directory namespace and block map", body_style), Paragraph("<code>http://localhost:9870</code>", body_style)],
        [Paragraph("<b>DataNode</b>", body_style), Paragraph("Worker: Stores actual file data blocks on disk", body_style), Paragraph("<code>http://localhost:9864</code>", body_style)],
        [Paragraph("<b>SecondaryNameNode</b>", body_style), Paragraph("Checkpoint: Merges fsimage and editlogs", body_style), Paragraph("<code>http://localhost:9868</code>", body_style)],
        [Paragraph("<b>ResourceManager</b>", body_style), Paragraph("Master: Allocates CPU and memory across cluster", body_style), Paragraph("<code>http://localhost:8088</code>", body_style)],
        [Paragraph("<b>NodeManager</b>", body_style), Paragraph("Worker: Monitors local containers and CPU/RAM", body_style), Paragraph("<code>http://localhost:8042</code>", body_style)],
    ]
    jps_table = Table(jps_data, colWidths=[120, 240, 180])
    jps_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor("#0284C7")),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#CBD5E1")),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, colors.HexColor("#F8FAFC")]),
        ('TOPPADDING', (0,0), (-1,-1), 3),
        ('BOTTOMPADDING', (0,0), (-1,-1), 3),
        ('LEFTPADDING', (0,0), (-1,-1), 5),
        ('RIGHTPADDING', (0,0), (-1,-1), 5),
    ]))
    story.append(jps_table)

    story.append(PageBreak())

    # =========================================================================
    # SECTION 3: TRACK A - FAST 1-LINE SHORTCUT MAPREDUCE
    # =========================================================================
    story.append(Paragraph("3. Track A: Automated 1-Line Shortcut Commands (Speed Run)", h1_style))
    story.append(Paragraph(
        "When you need to test WordCount or MapReduce immediately without typing repetitive HDFS commands, use the automated shortcut tool:",
        body_style
    ))

    story.append(Paragraph("<b>Shortcut 1: Run WordCount on Default Dataset</b>", h2_style))
    story.append(create_code_block("./run-wordcount.sh", code_style))
    story.append(Paragraph("<i>Result:</i> Automatically creates HDFS directories, ingests <code>sample_input.txt</code>, executes the MapReduce job on YARN, and displays the top 25 word frequencies in a formatted table.", bullet_style))

    story.append(Spacer(1, 4))
    story.append(Paragraph("<b>Shortcut 2: Run WordCount on Any Custom File</b>", h2_style))
    story.append(Paragraph("Pass any text file on your computer to process it immediately:", body_style))
    story.append(create_code_block("./run-wordcount.sh /path/to/my_big_data.txt", code_style))

    story.append(Spacer(1, 4))
    story.append(Paragraph("<b>Shortcut 3: Global System Command</b>", h2_style))
    story.append(Paragraph("Because the installer links commands into <code>/usr/local/bin</code>, you can run from anywhere:", body_style))
    story.append(create_code_block("run-wordcount ~/sample_input.txt", code_style))

    story.append(Spacer(1, 10))

    # =========================================================================
    # SECTION 4: TRACK B - 1-BY-1 MANUAL COMMANDS
    # =========================================================================
    story.append(Paragraph("4. Track B: Step-by-Step 1-by-1 Manual Commands", h1_style))
    story.append(Paragraph(
        "For manual execution and complete visibility into HDFS state transitions, execute this step-by-step sequence in a second terminal while <code>ran-hadoop</code> is active:",
        body_style
    ))

    story.append(Spacer(1, 4))
    story.append(Paragraph("<b>Step 1: Verify Running Cluster Daemons</b>", h2_style))
    story.append(Paragraph("Confirm NameNode, DataNode, ResourceManager, and NodeManager are active:", body_style))
    story.append(create_code_block("jps", code_style))

    story.append(Paragraph("<b>Step 2: Create Input Directory in HDFS</b>", h2_style))
    story.append(Paragraph("Hadoop MapReduce requires input directories inside the distributed filesystem (HDFS):", body_style))
    story.append(create_code_block("hdfs dfs -mkdir -p /my_data/input", code_style))

    story.append(Paragraph("<b>Step 3: Upload Local File to HDFS</b>", h2_style))
    story.append(Paragraph("Transfer your local dataset (e.g. <code>sample_input.txt</code>) into HDFS:", body_style))
    story.append(create_code_block("hdfs dfs -put -f sample_input.txt /my_data/input/", code_style))

    story.append(Paragraph("<b>Step 4: Verify Input File in HDFS</b>", h2_style))
    story.append(Paragraph("List the directory contents and view the file inside HDFS:", body_style))
    story.append(create_code_block(
        "hdfs dfs -ls /my_data/input\n"
        "hdfs dfs -cat /my_data/input/sample_input.txt | head -n 10",
        code_style
    ))

    story.append(Paragraph("<b>Step 5: Clean Previous Output Directory (if re-running)</b>", h2_style))
    story.append(Paragraph("Hadoop will refuse to run if the destination output directory already exists:", body_style))
    story.append(create_code_block("hdfs dfs -rm -r -f /my_data/output", code_style))

    story.append(Paragraph("<b>Step 6: Execute the MapReduce Jar Step-by-Step</b>", h2_style))
    story.append(Paragraph("Run the official Hadoop MapReduce examples JAR via YARN:", body_style))
    story.append(create_code_block(
        "hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar \\\n"
        "       wordcount /my_data/input /my_data/output",
        code_style
    ))

    story.append(Paragraph("<b>Step 7: Inspect MapReduce Output Files in HDFS</b>", h2_style))
    story.append(Paragraph("MapReduce creates a success flag and partition files (<code>part-r-00000</code>):", body_style))
    story.append(create_code_block(
        "hdfs dfs -ls /my_data/output\n"
        "hdfs dfs -cat /my_data/output/part-r-00000 | head -n 25",
        code_style
    ))

    story.append(Paragraph("<b>Step 8: Export Output from HDFS back to Local Machine</b>", h2_style))
    story.append(Paragraph("Download the final computed results to your local folder:", body_style))
    story.append(create_code_block("hdfs dfs -get /my_data/output/part-r-00000 ./wordcount_results.txt", code_style))

    story.append(PageBreak())

    # =========================================================================
    # SECTION 5: PYTHON STREAMING MAPREDUCE
    # =========================================================================
    story.append(Paragraph("5. Python Hadoop Streaming MapReduce", h1_style))
    story.append(Paragraph(
        "Hadoop Streaming allows any standard Unix executable or Python script to act as a MapReduce worker via standard input and standard output.",
        body_style
    ))

    story.append(Paragraph("<b>A. The Mapper Script (mapper.py)</b>", h2_style))
    story.append(create_code_block(
        "#!/usr/bin/env python3\n"
        "import sys\n\n"
        "for line in sys.stdin:\n"
        "    line = line.strip()\n"
        "    words = line.split()\n"
        "    for word in words:\n"
        "        print(f\"{word}\\t1\")",
        code_style
    ))

    story.append(Paragraph("<b>B. The Reducer Script (reducer.py)</b>", h2_style))
    story.append(create_code_block(
        "#!/usr/bin/env python3\n"
        "import sys\n\n"
        "current_word = None\n"
        "current_count = 0\n\n"
        "for line in sys.stdin:\n"
        "    line = line.strip()\n"
        "    word, count = line.split('\\t', 1)\n"
        "    count = int(count)\n"
        "    if current_word == word:\n"
        "        current_count += count\n"
        "    else:\n"
        "        if current_word:\n"
        "            print(f\"{current_word}\\t{current_count}\")\n"
        "        current_word = word\n"
        "        current_count = count\n\n"
        "if current_word:\n"
        "    print(f\"{current_word}\\t{current_count}\")",
        code_style
    ))

    story.append(Paragraph("<b>C. Running Python Streaming on Hadoop:</b>", h2_style))
    story.append(create_code_block(
        "chmod +x mapper.py reducer.py\n"
        "hadoop jar $HADOOP_HOME/share/hadoop/tools/lib/hadoop-streaming-*.jar \\\n"
        "       -input /my_data/input \\\n"
        "       -output /my_data/python_output \\\n"
        "       -mapper ./mapper.py \\\n"
        "       -reducer ./reducer.py",
        code_style
    ))

    story.append(Spacer(1, 10))

    # =========================================================================
    # SECTION 6: QUICK COMMAND CHEAT SHEET
    # =========================================================================
    story.append(Paragraph("6. Quick Command Cheat Sheet", h1_style))

    cheat_data = [
        [Paragraph("<b>Task / Action</b>", body_style), Paragraph("<b>Terminal Command</b>", body_style)],
        [Paragraph("Windows 1-Click Setup (Installs Git/WSL/Hadoop)", body_style), Paragraph("<code>irm https://raw.githubusercontent.com/.../setup.ps1 | iex</code>", body_style)],
        [Paragraph("Linux / WSL 1-Click Setup", body_style), Paragraph("<code>curl -sSL https://raw.githubusercontent.com/.../install.sh | bash</code>", body_style)],
        [Paragraph("Start Hadoop Cluster (with auto-shutdown)", body_style), Paragraph("<code>ran-hadoop</code>", body_style)],
        [Paragraph("Graceful Stop", body_style), Paragraph("Press <b>Ctrl + C</b> in <code>ran-hadoop</code> terminal", body_style)],
        [Paragraph("Fast MapReduce WordCount Shortcut", body_style), Paragraph("<code>./run-wordcount.sh [data.txt]</code>", body_style)],
        [Paragraph("Create HDFS Directory", body_style), Paragraph("<code>hdfs dfs -mkdir -p &lt;hdfs-path&gt;</code>", body_style)],
        [Paragraph("Copy Local File to HDFS", body_style), Paragraph("<code>hdfs dfs -put -f &lt;local-file&gt; &lt;hdfs-path&gt;</code>", body_style)],
        [Paragraph("List HDFS Directory Contents", body_style), Paragraph("<code>hdfs dfs -ls &lt;hdfs-path&gt;</code>", body_style)],
        [Paragraph("Print HDFS File to Terminal", body_style), Paragraph("<code>hdfs dfs -cat &lt;hdfs-path&gt;</code>", body_style)],
        [Paragraph("Download File from HDFS to Local", body_style), Paragraph("<code>hdfs dfs -get &lt;hdfs-path&gt; &lt;local-dest&gt;</code>", body_style)],
        [Paragraph("Leave HDFS Safe Mode", body_style), Paragraph("<code>hdfs dfsadmin -safemode leave</code>", body_style)],
        [Paragraph("HDFS NameNode Browser UI", body_style), Paragraph("<code>http://localhost:9870</code>", body_style)],
        [Paragraph("YARN Compute Browser UI", body_style), Paragraph("<code>http://localhost:8088</code>", body_style)],
    ]
    cheat_table = Table(cheat_data, colWidths=[200, 340])
    cheat_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor("#0284C7")),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
        ('BOTTOMPADDING', (0,0), (-1,0), 3),
        ('TOPPADDING', (0,0), (-1,0), 3),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#CBD5E1")),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, colors.HexColor("#F8FAFC")]),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('LEFTPADDING', (0,0), (-1,-1), 5),
        ('RIGHTPADDING', (0,0), (-1,-1), 5),
    ]))
    story.append(cheat_table)

    # Build the document
    doc.build(story, canvasmaker=NumberedCanvas)
    print(f"Successfully generated PDF: {filename}")


if __name__ == '__main__':
    target = sys.argv[1] if len(sys.argv) > 1 else "docs/Hadoop_Complete_Guide_Install_Run_WordCount.pdf"
    build_pdf(target)
