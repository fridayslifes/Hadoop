#!/usr/bin/env python3
"""
generate_pdf.py - Generates the complete Apache Hadoop Field Guide, Architecture,
Deployment & End-to-End Command Manual.

Incorporates:
1. Windows Subsystem for Linux (WSL) Check, Unregister/Delete & Fresh Reinstall
2. Linux (Ubuntu) Initialization
3. System & Repository Update (apt update) & Prerequisites
4. Java Development Kit (OpenJDK 11) Installation & Verification
5. Dedicated Hadoop User Setup (hduser / hadoop group as per Teacher's Lab Spec)
6. Passwordless SSH Key Generation & Localhost Verification
7. Apache Hadoop Download & Installation (/usr/local/hadoop)
8. Environment Variables (.bashrc) & hadoop-env.sh Configuration
9. XML Configuration (core-site, hdfs-site, yarn-site, mapred-site)
10. Cluster Storage Directories (/usr/local/hadoop_tmp) & Permissions
11. HDFS NameNode Formatting (hdfs namenode -format)
12. Starting Cluster Services (start-dfs.sh, start-yarn.sh & ran-hadoop)
13. Verification with JPS & Web Dashboards
14. MapReduce WordCount Execution (HDFS mkdir, put, jar execution, cat results, get to local)
15. Python Streaming MapReduce Reference & Master Command Cheat Sheet
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
            self.drawString(margin, page_h - 26, "Apache Hadoop Complete Lab & Deployment Manual • From Clean WSL to MapReduce")
            self.setStrokeColor(colors.HexColor("#CBD5E1"))
            self.setLineWidth(0.5)
            self.line(margin, page_h - 30, page_w - margin, page_h - 30)

        # Footer on all pages
        self.setStrokeColor(colors.HexColor("#CBD5E1"))
        self.setLineWidth(0.5)
        self.line(margin, 32, page_w - margin, 32)

        self.drawString(margin, 20, "Apache Hadoop Lab Guide • Teacher Reference & Universal Automation")
        page_str = f"Page {self._pageNumber} of {page_count}"
        self.drawRightString(page_w - margin, 20, page_str)

        self.restoreState()


def create_callout(title, text, style_title, style_body, bg_color="#EFF6FF", border_color="#3B82F6"):
    content = [
        Paragraph(f"<b>{title}</b>", style_title),
        Spacer(1, 2),
        Paragraph(text, style_body)
    ]
    t = Table([[content]], colWidths=[540])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor(bg_color)),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor(border_color)),
        ('LINEBEFORE', (0,0), (0,-1), 4, colors.HexColor(border_color)),
        ('TOPPADDING', (0,0), (-1,-1), 4),
        ('BOTTOMPADDING', (0,0), (-1,-1), 4),
        ('LEFTPADDING', (0,0), (-1,-1), 8),
        ('RIGHTPADDING', (0,0), (-1,-1), 8),
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
        ('TOPPADDING', (0,0), (-1,-1), 4),
        ('BOTTOMPADDING', (0,0), (-1,-1), 4),
        ('LEFTPADDING', (0,0), (-1,-1), 8),
        ('RIGHTPADDING', (0,0), (-1,-1), 8),
    ]))
    return t


def build_pdf(filename="docs/Hadoop_Complete_Guide_Install_Run_WordCount.pdf"):
    os.makedirs(os.path.dirname(os.path.abspath(filename)), exist_ok=True)
    doc = SimpleDocTemplate(
        filename,
        pagesize=letter,
        leftMargin=36,
        rightMargin=36,
        topMargin=40,
        bottomMargin=40
    )

    styles = getSampleStyleSheet()

    # Typography styles
    title_style = ParagraphStyle(
        'DocTitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=17,
        leading=21,
        textColor=colors.HexColor('#0F172A'),
        alignment=0
    )

    subtitle_style = ParagraphStyle(
        'DocSubtitle',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=9.5,
        leading=13,
        textColor=colors.HexColor('#0284C7'),
        alignment=0
    )

    h1_style = ParagraphStyle(
        'Heading1_Custom',
        parent=styles['Heading1'],
        fontName='Helvetica-Bold',
        fontSize=11.5,
        leading=14.5,
        textColor=colors.HexColor('#1E293B'),
        spaceBefore=8,
        spaceAfter=3,
        keepWithNext=True
    )

    h2_style = ParagraphStyle(
        'Heading2_Custom',
        parent=styles['Heading2'],
        fontName='Helvetica-Bold',
        fontSize=9,
        leading=12,
        textColor=colors.HexColor('#0369A1'),
        spaceBefore=5,
        spaceAfter=2,
        keepWithNext=True
    )

    body_style = ParagraphStyle(
        'Body_Custom',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=8.2,
        leading=11,
        textColor=colors.HexColor('#334155'),
        spaceBefore=1.5,
        spaceAfter=1.5
    )

    bullet_style = ParagraphStyle(
        'Bullet_Custom',
        parent=body_style,
        leftIndent=12,
        bulletIndent=4,
        spaceBefore=1,
        spaceAfter=1
    )

    code_style = ParagraphStyle(
        'Code_Custom',
        parent=styles['Code'],
        fontName='Courier',
        fontSize=7.2,
        leading=9.5,
        textColor=colors.HexColor('#A6E3A1')
    )

    callout_title = ParagraphStyle(
        'CalloutTitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=8,
        leading=10.5,
        textColor=colors.HexColor('#1E3A8A')
    )

    callout_body = ParagraphStyle(
        'CalloutBody',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=7.8,
        leading=10,
        textColor=colors.HexColor('#1E293B')
    )

    story = []

    # =========================================================================
    # HEADER BANNER & DOCUMENT METADATA
    # =========================================================================
    story.append(Paragraph("Apache Hadoop End-to-End Field Manual", title_style))
    story.append(Spacer(1, 2))
    story.append(Paragraph("Complete Practical Lab Guide: Clean WSL Reset → Ubuntu → Java → Hadoop → Config → MapReduce", subtitle_style))
    story.append(Spacer(1, 3))
    story.append(HRFlowable(width="100%", thickness=1.5, color=colors.HexColor("#0284C7"), spaceBefore=1, spaceAfter=5))

    meta_data = [
        [
            Paragraph("<b>Target OS:</b> Windows 10/11 with WSL2 (Ubuntu 22.04 / 24.04 LTS)", body_style),
            Paragraph("<b>Apache Hadoop Core:</b> Hadoop 2.10.x / 3.3.6 (Pseudo-Distributed)", body_style)
        ],
        [
            Paragraph("<b>Java Runtime:</b> OpenJDK 11 LTS (<code>/usr/lib/jvm/java-11-openjdk-amd64</code>)", body_style),
            Paragraph("<b>Cluster User:</b> Dedicated <code>hduser</code> in <code>hadoop</code> group", body_style)
        ],
        [
            Paragraph("<b>Configuration Base:</b> <code>/usr/local/hadoop</code> &amp; <code>/usr/local/hadoop_tmp</code>", body_style),
            Paragraph("<b>Lab Verification:</b> 5 Hadoop Daemons via <code>jps</code> + WordCount MapReduce", body_style)
        ]
    ]
    meta_table = Table(meta_data, colWidths=[270, 270])
    meta_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor("#F8FAFC")),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor("#CBD5E1")),
        ('INNERGRID', (0,0), (-1,-1), 0.5, colors.HexColor("#E2E8F0")),
        ('TOPPADDING', (0,0), (-1,-1), 2.5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 2.5),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
        ('RIGHTPADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(meta_table)
    story.append(Spacer(1, 5))

    # =========================================================================
    # SECTION 1: WSL AUDIT, DELETE / UNREGISTER & FRESH REINSTALL
    # =========================================================================
    story.append(Paragraph("1. Windows Subsystem for Linux (WSL) Clean Reset &amp; Fresh Reinstall", h1_style))
    story.append(Paragraph(
        "To guarantee an immaculate, conflict-free Hadoop environment, open <b>PowerShell as Administrator</b> on Windows and execute these commands to check, unregister/wipe existing distributions, and fresh install WSL with Ubuntu:",
        body_style
    ))

    story.append(Paragraph("<b>Step 1.1: Check Existing WSL Status &amp; List Registered Distros</b>", h2_style))
    story.append(create_code_block(
        "# 1. Check WSL operational status and default version\n"
        "wsl --status\n\n"
        "# 2. List all existing distributions, their state and WSL version\n"
        "wsl --list --verbose",
        code_style
    ))

    story.append(Paragraph("<b>Step 1.2: Shut Down and Delete / Unregister Old Ubuntu Distro</b>", h2_style))
    story.append(Paragraph("Completely terminate background instances and unregister old distributions to clear corrupted disks, packages, or stale port bindings:", body_style))
    story.append(create_code_block(
        "# 1. Shut down all running WSL processes\n"
        "wsl --shutdown\n\n"
        "# 2. Delete and unregister existing Ubuntu distribution (Complete Wipe)\n"
        "wsl --unregister Ubuntu\n\n"
        "# (If you have specific versions installed, unregister them as well):\n"
        "# wsl --unregister Ubuntu-22.04\n"
        "# wsl --unregister Ubuntu-20.04",
        code_style
    ))
    story.append(create_callout(
        "Why Unregister First?",
        "Running <code>wsl --unregister Ubuntu</code> permanently deletes the virtual root disk (ext4.vhdx). This guarantees that prior broken Java installations, orphaned Hadoop lockfiles, or duplicate SSH keys cannot interfere with your fresh setup.",
        callout_title, callout_body, bg_color="#FEF2F2", border_color="#EF4444"
    ))

    story.append(Paragraph("<b>Step 1.3: Fresh Reinstallation of WSL &amp; Ubuntu</b>", h2_style))
    story.append(create_code_block(
        "# 1. Update the Windows Subsystem for Linux kernel component\n"
        "wsl --update\n\n"
        "# 2. Set default WSL architecture to Version 2\n"
        "wsl --set-default-version 2\n\n"
        "# 3. Freshly install Ubuntu from official Microsoft cloud image\n"
        "wsl --install -d Ubuntu --web-download",
        code_style
    ))
    story.append(Paragraph("<i>Note: If Windows prompts for a system restart to enable Hyper-V / Virtual Machine Platform, reboot your PC before launching Ubuntu.</i>", bullet_style))

    story.append(PageBreak())

    # =========================================================================
    # SECTION 2: LINUX INITIALIZATION & DEDICATED HADOOP USER
    # =========================================================================
    story.append(Paragraph("2. Linux (Ubuntu) Initialization &amp; User Setup", h1_style))
    story.append(Paragraph(
        "Launch the freshly installed Ubuntu shell, configure your initial UNIX credentials, and establish the dedicated <code>hduser</code> and <code>hadoop</code> user group as required by standard Hadoop lab specifications.",
        body_style
    ))

    story.append(Paragraph("<b>Step 2.1: Launch Ubuntu &amp; Create Initial Admin User</b>", h2_style))
    story.append(create_code_block(
        "# Launch newly installed Ubuntu shell from PowerShell or Terminal\n"
        "wsl -d Ubuntu",
        code_style
    ))
    story.append(Paragraph("Enter your primary UNIX username (e.g., <code>friday</code> or <code>ubuntu</code>) and password when prompted.", bullet_style))

    story.append(Paragraph("<b>Step 2.2: Create Dedicated Hadoop Group &amp; User (hduser)</b>", h2_style))
    story.append(Paragraph("As specified in teacher lab notes, isolate Hadoop services under a dedicated service account:", body_style))
    story.append(create_code_block(
        "# 1. Create the hadoop user group\n"
        "sudo addgroup hadoop\n\n"
        "# 2. Add dedicated 'hduser' belonging to the hadoop group\n"
        "sudo adduser --ingroup hadoop hduser\n\n"
        "# 3. Grant sudo privileges to hduser\n"
        "sudo adduser hduser sudo",
        code_style
    ))

    story.append(Spacer(1, 4))

    # =========================================================================
    # SECTION 3: SYSTEM UPDATE & ESSENTIAL PREREQUISITES
    # =========================================================================
    story.append(Paragraph("3. System Update (apt update) &amp; Prerequisites", h1_style))
    story.append(Paragraph(
        "Update the APT package manager repositories, apply system security patches, and install required networking/archive utilities:",
        body_style
    ))

    story.append(Paragraph("<b>Step 3.1: Update &amp; Upgrade APT Repositories</b>", h2_style))
    story.append(create_code_block(
        "sudo apt update -y && sudo apt upgrade -y",
        code_style
    ))

    story.append(Paragraph("<b>Step 3.2: Install OpenSSH Server, rsync, aria2 &amp; Networking Tools</b>", h2_style))
    story.append(create_code_block(
        "sudo apt install -y openssh-server openssh-client rsync curl wget \\\n"
        "                    tar git aria2 procps net-tools ca-certificates nano",
        code_style
    ))

    story.append(Spacer(1, 4))

    # =========================================================================
    # SECTION 4: JAVA DEVELOPMENT KIT (OPENJDK 11) INSTALLATION
    # =========================================================================
    story.append(Paragraph("4. Java Development Kit (OpenJDK 11) Installation", h1_style))
    story.append(Paragraph(
        "Apache Hadoop executes on the Java Virtual Machine. Install OpenJDK 11 LTS (or default-jdk) and verify the compiler and runtime:",
        body_style
    ))

    story.append(Paragraph("<b>Step 4.1: Install OpenJDK 11 JDK</b>", h2_style))
    story.append(create_code_block(
        "# Install OpenJDK 11 (standard LTS for Hadoop 2.10.x & 3.x)\n"
        "sudo apt install -y openjdk-11-jdk",
        code_style
    ))

    story.append(Paragraph("<b>Step 4.2: Verify Java Runtime &amp; Detect Absolute JAVA_HOME</b>", h2_style))
    story.append(create_code_block(
        "# Check Java runtime and compiler versions\n"
        "java -version\n"
        "javac -version\n\n"
        "# Confirm exact filesystem path to JAVA_HOME (typically /usr/lib/jvm/java-11-openjdk-amd64)\n"
        "readlink -f $(which java) | sed 's:/bin/java::'",
        code_style
    ))

    story.append(PageBreak())

    # =========================================================================
    # SECTION 5: PASSWORDLESS SSH CONFIGURATION
    # =========================================================================
    story.append(Paragraph("5. Passwordless SSH Configuration for hduser", h1_style))
    story.append(Paragraph(
        "Hadoop scripts (such as <code>start-dfs.sh</code> and <code>start-yarn.sh</code>) manage master/worker daemons over SSH. Configure key-based passwordless access to <code>localhost</code>:",
        body_style
    ))

    story.append(Paragraph("<b>Step 5.1: Switch to hduser and Generate SSH Keypair</b>", h2_style))
    story.append(create_code_block(
        "# 1. Switch to hduser session and go to home directory\n"
        "su - hduser\n"
        "cd ~\n\n"
        "# 2. Generate RSA keypair without passphrase (-P \"\")\n"
        "ssh-keygen -t rsa -P \"\" -f ~/.ssh/id_rsa -q\n\n"
        "# 3. Append public key to authorized_keys and apply strict permissions\n"
        "cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys\n"
        "chmod 700 ~/.ssh\n"
        "chmod 600 ~/.ssh/authorized_keys",
        code_style
    ))

    story.append(Paragraph("<b>Step 5.2: Start SSH Service &amp; Test Connection to localhost</b>", h2_style))
    story.append(create_code_block(
        "# 1. Ensure SSH server daemon is running\n"
        "sudo service ssh start\n\n"
        "# 2. Test passwordless SSH login to localhost (should connect without prompting for password)\n"
        "ssh -o StrictHostKeyChecking=no localhost \"echo SSH_SUCCESS\"\n\n"
        "# If successful, exit back to shell:\n"
        "# exit",
        code_style
    ))

    story.append(Spacer(1, 4))

    # =========================================================================
    # SECTION 6: HADOOP DOWNLOAD & EXTRACTION TO /usr/local/hadoop
    # =========================================================================
    story.append(Paragraph("6. Apache Hadoop Download &amp; Installation (/usr/local/hadoop)", h1_style))
    story.append(Paragraph(
        "Download Apache Hadoop (either Hadoop 2.10.2 / 2.7.1 as in teacher's notes, or stable 3.3.6) using 16 concurrent connections, extract to <code>/usr/local/hadoop</code>, and set ownership:",
        body_style
    ))

    story.append(Paragraph("<b>Step 6.1: High-Speed 16-Thread Download via aria2c / curl</b>", h2_style))
    story.append(create_code_block(
        "# Option A: Download Hadoop 3.3.6 (Modern Stable) with 16 threads\n"
        "aria2c -x 16 -s 16 -k 1M -d /tmp -o hadoop.tar.gz \\\n"
        "  https://archive.apache.org/dist/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz\n\n"
        "# Option B: Download Hadoop 2.10.2 (Teacher Lab Package from Archive):\n"
        "# aria2c -x 16 -s 16 -k 1M -d /tmp -o hadoop.tar.gz \\\n"
        "#   https://archive.apache.org/dist/hadoop/common/hadoop-2.10.2/hadoop-2.10.2.tar.gz",
        code_style
    ))

    story.append(Paragraph("<b>Step 6.2: Extract Tarball to /usr/local/hadoop &amp; Assign Permissions</b>", h2_style))
    story.append(create_code_block(
        "# 1. Create destination directory and extract archive\n"
        "sudo mkdir -p /usr/local/hadoop\n"
        "sudo tar -xzf /tmp/hadoop.tar.gz -C /usr/local/hadoop --strip-components=1\n\n"
        "# 2. Assign ownership of /usr/local/hadoop to hduser:hadoop\n"
        "sudo chown -R hduser:hadoop /usr/local/hadoop\n"
        "sudo chmod -R 755 /usr/local/hadoop",
        code_style
    ))

    story.append(Paragraph("<b>Step 6.3: Create Dedicated Storage Directories (/usr/local/hadoop_tmp)</b>", h2_style))
    story.append(Paragraph("Create the HDFS data directories specified in the teacher's configuration file:", body_style))
    story.append(create_code_block(
        "# Create NameNode, DataNode and temporary directories\n"
        "sudo mkdir -p /usr/local/hadoop_tmp/hdfs/namenode\n"
        "sudo mkdir -p /usr/local/hadoop_tmp/hdfs/datanode\n"
        "sudo chown -R hduser:hadoop /usr/local/hadoop_tmp\n"
        "sudo chmod -R 775 /usr/local/hadoop_tmp",
        code_style
    ))

    story.append(PageBreak())

    # =========================================================================
    # SECTION 7: ENVIRONMENT VARIABLES & HADOOP-ENV.SH
    # =========================================================================
    story.append(Paragraph("7. Environment Variables (~/.bashrc &amp; hadoop-env.sh)", h1_style))
    story.append(Paragraph(
        "Configure shell paths and environment bindings in <code>~/.bashrc</code> and <code>hadoop-env.sh</code> exactly matching the teacher's configuration specification:",
        body_style
    ))

    story.append(Paragraph("<b>Step 7.1: Append Hadoop Paths to ~/.bashrc</b>", h2_style))
    story.append(create_code_block(
        "# Append variables to hduser's ~/.bashrc\n"
        "cat << 'EOF' >> ~/.bashrc\n\n"
        "# >>> Apache Hadoop Lab Environment >>>\n"
        "export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64\n"
        "export HADOOP_HOME=/usr/local/hadoop\n"
        "export PATH=$PATH:$HADOOP_HOME/bin\n"
        "export PATH=$PATH:$HADOOP_HOME/sbin\n"
        "export HADOOP_MAPRED_HOME=$HADOOP_HOME\n"
        "export HADOOP_COMMON_HOME=$HADOOP_HOME\n"
        "export HADOOP_HDFS_HOME=$HADOOP_HOME\n"
        "export YARN_HOME=$HADOOP_HOME\n"
        "export HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native\n"
        "export HADOOP_OPTS=\"-Djava.library.path=$HADOOP_HOME/lib\"\n"
        "# <<< Apache Hadoop Lab Environment <<<\n"
        "EOF\n\n"
        "# Apply changes immediately\n"
        "source ~/.bashrc",
        code_style
    ))

    story.append(Paragraph("<b>Step 7.2: Set JAVA_HOME in hadoop-env.sh</b>", h2_style))
    story.append(create_code_block(
        "# Explicitly declare JAVA_HOME in hadoop-env.sh\n"
        "echo 'export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64' >> /usr/local/hadoop/etc/hadoop/hadoop-env.sh",
        code_style
    ))

    story.append(Spacer(1, 4))

    # =========================================================================
    # SECTION 8: XML CLUSTER CONFIGURATION FILES
    # =========================================================================
    story.append(Paragraph("8. Hadoop XML Configuration Files (Teacher Specification)", h1_style))
    story.append(Paragraph(
        "Place the following configuration XML blocks between <code>&lt;configuration&gt;</code> and <code>&lt;/configuration&gt;</code> tags:",
        body_style
    ))

    story.append(Paragraph("<b>Step 8.1: Configure core-site.xml</b>", h2_style))
    story.append(Paragraph("File path: <code>/usr/local/hadoop/etc/hadoop/core-site.xml</code>", body_style))
    story.append(create_code_block(
        "cat << 'EOF' > /usr/local/hadoop/etc/hadoop/core-site.xml\n"
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        "<?xml-stylesheet type=\"text/xsl\" href=\"configuration.xsl\"?>\n"
        "<configuration>\n"
        "    <property>\n"
        "        <name>fs.default.name</name>\n"
        "        <value>hdfs://localhost:9000</value>\n"
        "    </property>\n"
        "    <property>\n"
        "        <name>hadoop.tmp.dir</name>\n"
        "        <value>/usr/local/hadoop_tmp</value>\n"
        "    </property>\n"
        "</configuration>\n"
        "EOF",
        code_style
    ))

    story.append(Paragraph("<b>Step 8.2: Configure hdfs-site.xml</b>", h2_style))
    story.append(Paragraph("File path: <code>/usr/local/hadoop/etc/hadoop/hdfs-site.xml</code>", body_style))
    story.append(create_code_block(
        "cat << 'EOF' > /usr/local/hadoop/etc/hadoop/hdfs-site.xml\n"
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        "<?xml-stylesheet type=\"text/xsl\" href=\"configuration.xsl\"?>\n"
        "<configuration>\n"
        "    <property>\n"
        "        <name>dfs.replication</name>\n"
        "        <value>1</value>\n"
        "    </property>\n"
        "    <property>\n"
        "        <name>dfs.namenode.name.dir</name>\n"
        "        <value>file:/usr/local/hadoop_tmp/hdfs/namenode</value>\n"
        "    </property>\n"
        "    <property>\n"
        "        <name>dfs.datanode.data.dir</name>\n"
        "        <value>file:/usr/local/hadoop_tmp/hdfs/datanode</value>\n"
        "    </property>\n"
        "</configuration>\n"
        "EOF",
        code_style
    ))

    story.append(PageBreak())

    story.append(Paragraph("<b>Step 8.3: Configure yarn-site.xml</b>", h2_style))
    story.append(Paragraph("File path: <code>/usr/local/hadoop/etc/hadoop/yarn-site.xml</code>", body_style))
    story.append(create_code_block(
        "cat << 'EOF' > /usr/local/hadoop/etc/hadoop/yarn-site.xml\n"
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        "<?xml-stylesheet type=\"text/xsl\" href=\"configuration.xsl\"?>\n"
        "<configuration>\n"
        "    <property>\n"
        "        <name>yarn.nodemanager.aux-services</name>\n"
        "        <value>mapreduce_shuffle</value>\n"
        "    </property>\n"
        "    <property>\n"
        "        <name>yarn.nodemanager.aux-services.mapreduce.shuffle.class</name>\n"
        "        <value>org.apache.hadoop.mapred.ShuffleHandler</value>\n"
        "    </property>\n"
        "    <!-- WSL / Container Virtual Memory Protection -->\n"
        "    <property>\n"
        "        <name>yarn.nodemanager.pmem-check-enabled</name>\n"
        "        <value>false</value>\n"
        "    </property>\n"
        "    <property>\n"
        "        <name>yarn.nodemanager.vmem-check-enabled</name>\n"
        "        <value>false</value>\n"
        "    </property>\n"
        "</configuration>\n"
        "EOF",
        code_style
    ))

    story.append(Paragraph("<b>Step 8.4: Configure mapred-site.xml</b>", h2_style))
    story.append(Paragraph("File path: <code>/usr/local/hadoop/etc/hadoop/mapred-site.xml</code> (copy template if on Hadoop 2.x):", body_style))
    story.append(create_code_block(
        "# If mapred-site.xml.template exists (Hadoop 2.x), copy template first:\n"
        "[ -f /usr/local/hadoop/etc/hadoop/mapred-site.xml.template ] && \\\n"
        "  cp /usr/local/hadoop/etc/hadoop/mapred-site.xml.template /usr/local/hadoop/etc/hadoop/mapred-site.xml\n\n"
        "cat << 'EOF' > /usr/local/hadoop/etc/hadoop/mapred-site.xml\n"
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        "<?xml-stylesheet type=\"text/xsl\" href=\"configuration.xsl\"?>\n"
        "<configuration>\n"
        "    <property>\n"
        "        <name>mapreduce.framework.name</name>\n"
        "        <value>yarn</value>\n"
        "    </property>\n"
        "</configuration>\n"
        "EOF",
        code_style
    ))

    story.append(Paragraph("<b>Step 8.5: Format HDFS NameNode Storage</b>", h2_style))
    story.append(Paragraph("Initialize the distributed filesystem directory structure (execute only once before the very first cluster startup):", body_style))
    story.append(create_code_block(
        "hdfs namenode -format",
        code_style
    ))
    story.append(create_callout(
        "Format Verification",
        "Look for the output line: <code>common.Storage: Storage directory /usr/local/hadoop_tmp/hdfs/namenode has been successfully formatted.</code> and <code>Exiting with status 0</code>.",
        callout_title, callout_body, bg_color="#F0FDF4", border_color="#22C55E"
    ))

    story.append(Spacer(1, 4))

    # =========================================================================
    # SECTION 9: STARTING SERVICES & VERIFICATION VIA JPS
    # =========================================================================
    story.append(Paragraph("9. Starting Hadoop Services &amp; JPS Daemon Verification", h1_style))
    story.append(Paragraph(
        "Start HDFS and YARN daemons using standard scripts or the auto-stopping supervisor, then verify all 5 cluster daemons using <code>jps</code>:",
        body_style
    ))

    story.append(Paragraph("<b>Step 9.1: Start HDFS and YARN Services</b>", h2_style))
    story.append(create_code_block(
        "# Start HDFS daemons (NameNode, DataNode, SecondaryNameNode)\n"
        "start-dfs.sh\n\n"
        "# Start YARN daemons (ResourceManager, NodeManager)\n"
        "start-yarn.sh\n\n"
        "# (Alternative: You can also run 'start-all.sh' or use 'ran-hadoop')",
        code_style
    ))

    story.append(Paragraph("<b>Step 9.2: Verify Active Daemons with 'jps'</b>", h2_style))
    story.append(create_code_block(
        "jps\n\n"
        "# Expected Output (All 5 Hadoop Daemons + Jps):\n"
        "# [PID] NameNode\n"
        "# [PID] DataNode\n"
        "# [PID] SecondaryNameNode\n"
        "# [PID] ResourceManager\n"
        "# [PID] NodeManager\n"
        "# [PID] Jps",
        code_style
    ))

    # Port table
    jps_data = [
        [Paragraph("<b>Hadoop Daemon</b>", body_style), Paragraph("<b>Process Role</b>", body_style), Paragraph("<b>Web Dashboard URL</b>", body_style)],
        [Paragraph("<b>NameNode</b>", body_style), Paragraph("HDFS Master: Block metadata &amp; namespace", body_style), Paragraph("<code>http://localhost:9870</code> (or <code>:50070</code>)", body_style)],
        [Paragraph("<b>DataNode</b>", body_style), Paragraph("HDFS Worker: Physical block storage", body_style), Paragraph("<code>http://localhost:9864</code> (or <code>:50075</code>)", body_style)],
        [Paragraph("<b>ResourceManager</b>", body_style), Paragraph("YARN Master: Scheduling &amp; cluster resources", body_style), Paragraph("<code>http://localhost:8088</code>", body_style)],
        [Paragraph("<b>NodeManager</b>", body_style), Paragraph("YARN Worker: Container lifecycle monitor", body_style), Paragraph("<code>http://localhost:8042</code>", body_style)],
    ]
    jps_table = Table(jps_data, colWidths=[115, 235, 190])
    jps_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor("#0284C7")),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#CBD5E1")),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, colors.HexColor("#F8FAFC")]),
        ('TOPPADDING', (0,0), (-1,-1), 2.5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 2.5),
        ('LEFTPADDING', (0,0), (-1,-1), 5),
        ('RIGHTPADDING', (0,0), (-1,-1), 5),
    ]))
    story.append(jps_table)

    story.append(PageBreak())

    # =========================================================================
    # SECTION 10: RUNNING MAPREDUCE (WORDCOUNT)
    # =========================================================================
    story.append(Paragraph("10. Executing MapReduce WordCount Step-by-Step", h1_style))
    story.append(Paragraph(
        "Demonstrate the complete distributed MapReduce computation pipeline: create local input data, ingest into HDFS, execute the MapReduce JAR, inspect output, and download results to the local filesystem:",
        body_style
    ))

    story.append(Paragraph("<b>Step 10.1: Create Local Sample Data File</b>", h2_style))
    story.append(create_code_block(
        "cat << 'EOF' > sample_input.txt\n"
        "Hadoop is an open source framework for distributed storage and processing.\n"
        "MapReduce is a programming model for processing big data with a parallel algorithm.\n"
        "HDFS provides high-throughput access to application data.\n"
        "YARN manages resources and schedules computational jobs on the cluster.\n"
        "Hadoop MapReduce and HDFS make big data scalable, fault-tolerant, and reliable.\n"
        "EOF",
        code_style
    ))

    story.append(Paragraph("<b>Step 10.2: Prepare HDFS Directories &amp; Ingest Input Data</b>", h2_style))
    story.append(create_code_block(
        "# 1. Create target input directory in HDFS\n"
        "hdfs dfs -mkdir -p /my_data/input\n\n"
        "# 2. Copy local sample file into HDFS\n"
        "hdfs dfs -put -f sample_input.txt /my_data/input/\n\n"
        "# 3. Verify directory contents and file content in HDFS\n"
        "hdfs dfs -ls /my_data/input\n"
        "hdfs dfs -cat /my_data/input/sample_input.txt | head -n 5",
        code_style
    ))

    story.append(Paragraph("<b>Step 10.3: Execute MapReduce WordCount Job</b>", h2_style))
    story.append(Paragraph("Locate and execute the Hadoop MapReduce examples JAR:", body_style))
    story.append(create_code_block(
        "# 1. Ensure previous output directory is removed (MapReduce requires non-existent output dir)\n"
        "hdfs dfs -rm -r -f /my_data/output\n\n"
        "# 2. Run MapReduce WordCount Job across cluster nodes\n"
        "hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar \\\n"
        "       wordcount /my_data/input /my_data/output",
        code_style
    ))

    story.append(Paragraph("<b>Step 10.4: Inspect Computed Output in HDFS</b>", h2_style))
    story.append(create_code_block(
        "# 1. Check generated files (_SUCCESS and part-r-00000)\n"
        "hdfs dfs -ls /my_data/output\n\n"
        "# 2. Display computed word counts\n"
        "hdfs dfs -cat /my_data/output/part-r-00000 | head -n 25",
        code_style
    ))

    story.append(Paragraph("<b>Step 10.5: Export Output Results to Local Disk / Desktop</b>", h2_style))
    story.append(create_code_block(
        "# Download the output file from HDFS to local directory\n"
        "hdfs dfs -get /my_data/output/part-r-00000 ./wordcount_results.txt\n\n"
        "# Display local results file\n"
        "cat wordcount_results.txt",
        code_style
    ))

    story.append(Paragraph("<b>Step 10.6: Safely Stop Hadoop Services</b>", h2_style))
    story.append(create_code_block(
        "# Stop YARN compute daemons\n"
        "stop-yarn.sh\n\n"
        "# Stop HDFS storage daemons\n"
        "stop-dfs.sh",
        code_style
    ))

    story.append(Spacer(1, 4))

    # =========================================================================
    # SECTION 11: PYTHON STREAMING MAPREDUCE
    # =========================================================================
    story.append(Paragraph("11. Python Streaming MapReduce Reference", h1_style))
    story.append(Paragraph(
        "Hadoop Streaming allows any Python script to act as a MapReduce task through standard Unix STDIN and STDOUT:",
        body_style
    ))

    story.append(Paragraph("<b>The Mapper (mapper.py)</b>", h2_style))
    story.append(create_code_block(
        "#!/usr/bin/env python3\n"
        "import sys\n"
        "for line in sys.stdin:\n"
        "    for word in line.strip().split():\n"
        "        print(f\"{word}\\t1\")",
        code_style
    ))

    story.append(Paragraph("<b>The Reducer (reducer.py)</b>", h2_style))
    story.append(create_code_block(
        "#!/usr/bin/env python3\n"
        "import sys\n"
        "current_word, current_count = None, 0\n"
        "for line in sys.stdin:\n"
        "    word, count = line.strip().split('\\t', 1)\n"
        "    count = int(count)\n"
        "    if current_word == word:\n"
        "        current_count += count\n"
        "    else:\n"
        "        if current_word: print(f\"{current_word}\\t{current_count}\")\n"
        "        current_word, current_count = word, count\n"
        "if current_word: print(f\"{current_word}\\t{current_count}\")",
        code_style
    ))

    story.append(Paragraph("<b>Running Python Streaming on Hadoop:</b>", h2_style))
    story.append(create_code_block(
        "chmod +x mapper.py reducer.py\n"
        "hdfs dfs -rm -r -f /my_data/py_output\n"
        "hadoop jar $HADOOP_HOME/share/hadoop/tools/lib/hadoop-streaming-*.jar \\\n"
        "       -input /my_data/input \\\n"
        "       -output /my_data/py_output \\\n"
        "       -mapper ./mapper.py \\\n"
        "       -reducer ./reducer.py",
        code_style
    ))

    story.append(PageBreak())

    # =========================================================================
    # SECTION 12: MASTER COMMAND CHEAT SHEET & TROUBLESHOOTING
    # =========================================================================
    story.append(Paragraph("12. Master Command Cheat Sheet &amp; Troubleshooting Matrix", h1_style))
    story.append(Paragraph(
        "Sequential cheat sheet matching every action from clean WSL setup to MapReduce job verification:",
        body_style
    ))

    cheat_data = [
        [Paragraph("<b>Phase / Step</b>", body_style), Paragraph("<b>Exact Terminal Command</b>", body_style)],
        [Paragraph("1. Check WSL Status", body_style), Paragraph("<code>wsl --status</code> and <code>wsl -l -v</code>", body_style)],
        [Paragraph("2. Wipe / Unregister WSL", body_style), Paragraph("<code>wsl --shutdown && wsl --unregister Ubuntu</code>", body_style)],
        [Paragraph("3. Fresh WSL &amp; Ubuntu Install", body_style), Paragraph("<code>wsl --install -d Ubuntu --web-download</code>", body_style)],
        [Paragraph("4. Launch Ubuntu Shell", body_style), Paragraph("<code>wsl -d Ubuntu</code>", body_style)],
        [Paragraph("5. Update APT Packages", body_style), Paragraph("<code>sudo apt update -y && sudo apt upgrade -y</code>", body_style)],
        [Paragraph("6. Install Dependencies", body_style), Paragraph("<code>sudo apt install -y openssh-server rsync curl aria2</code>", body_style)],
        [Paragraph("7. Install OpenJDK 11", body_style), Paragraph("<code>sudo apt install -y openjdk-11-jdk</code>", body_style)],
        [Paragraph("8. Create Hadoop User", body_style), Paragraph("<code>sudo addgroup hadoop && sudo adduser --ingroup hadoop hduser</code>", body_style)],
        [Paragraph("9. SSH Keypair Generation", body_style), Paragraph("<code>ssh-keygen -t rsa -P \"\" -f ~/.ssh/id_rsa</code>", body_style)],
        [Paragraph("10. Authorize Public Key", body_style), Paragraph("<code>cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys</code>", body_style)],
        [Paragraph("11. Download Hadoop (16 Threads)", body_style), Paragraph("<code>aria2c -x 16 -s 16 -o hadoop.tar.gz &lt;Archive_URL&gt;</code>", body_style)],
        [Paragraph("12. Extract to /usr/local/hadoop", body_style), Paragraph("<code>sudo tar -xzf hadoop.tar.gz -C /usr/local/hadoop --strip-components=1</code>", body_style)],
        [Paragraph("13. Create Cluster Temp Dirs", body_style), Paragraph("<code>sudo mkdir -p /usr/local/hadoop_tmp/hdfs/{namenode,datanode}</code>", body_style)],
        [Paragraph("14. Format NameNode", body_style), Paragraph("<code>hdfs namenode -format</code>", body_style)],
        [Paragraph("15. Start Cluster Services", body_style), Paragraph("<code>start-dfs.sh && start-yarn.sh</code> (or <code>ran-hadoop</code>)", body_style)],
        [Paragraph("16. Verify Daemons", body_style), Paragraph("<code>jps</code> (NameNode, DataNode, SecNameNode, RM, NM)", body_style)],
        [Paragraph("17. Ingest Input File", body_style), Paragraph("<code>hdfs dfs -mkdir -p /input && hdfs dfs -put sample.txt /input/</code>", body_style)],
        [Paragraph("18. Run WordCount MapReduce", body_style), Paragraph("<code>hadoop jar hadoop-mapreduce-examples-*.jar wordcount /input /output</code>", body_style)],
        [Paragraph("19. Inspect WordCount Results", body_style), Paragraph("<code>hdfs dfs -cat /output/part-r-00000 | head -n 25</code>", body_style)],
        [Paragraph("20. Stop Cluster Services", body_style), Paragraph("<code>stop-yarn.sh && stop-dfs.sh</code>", body_style)],
    ]
    cheat_table = Table(cheat_data, colWidths=[160, 380])
    cheat_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor("#0284C7")),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
        ('BOTTOMPADDING', (0,0), (-1,0), 2),
        ('TOPPADDING', (0,0), (-1,0), 2),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#CBD5E1")),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, colors.HexColor("#F8FAFC")]),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('LEFTPADDING', (0,0), (-1,-1), 4),
        ('RIGHTPADDING', (0,0), (-1,-1), 4),
    ]))
    story.append(cheat_table)
    story.append(Spacer(1, 6))

    # Common issues table
    issue_data = [
        [Paragraph("<b>Common Issue</b>", body_style), Paragraph("<b>Diagnostic Cause</b>", body_style), Paragraph("<b>Resolution Command</b>", body_style)],
        [
            Paragraph("<b>NameNode in SafeMode</b>", body_style),
            Paragraph("HDFS is in read-only audit mode upon boot", body_style),
            Paragraph("<code>hdfs dfsadmin -safemode leave</code>", body_style)
        ],
        [
            Paragraph("<b>Port 9000 / 9870 Locked</b>", body_style),
            Paragraph("Previous orphaned daemon holding port open", body_style),
            Paragraph("<code>kill -9 $(lsof -t -i:9000)</code>", body_style)
        ],
        [
            Paragraph("<b>Output Dir Already Exists</b>", body_style),
            Paragraph("Hadoop refuses overwrite for data integrity", body_style),
            Paragraph("<code>hdfs dfs -rm -r -f &lt;path&gt;</code>", body_style)
        ],
        [
            Paragraph("<b>YARN Container Memory Fail</b>", body_style),
            Paragraph("WSL virtual memory calculation mismatch", body_style),
            Paragraph("Add <code>pmem-check-enabled=false</code> to <code>yarn-site.xml</code>", body_style)
        ],
    ]
    issue_table = Table(issue_data, colWidths=[130, 200, 210])
    issue_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor("#334155")),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#CBD5E1")),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, colors.HexColor("#F8FAFC")]),
        ('TOPPADDING', (0,0), (-1,-1), 2),
        ('BOTTOMPADDING', (0,0), (-1,-1), 2),
        ('LEFTPADDING', (0,0), (-1,-1), 4),
        ('RIGHTPADDING', (0,0), (-1,-1), 4),
    ]))
    story.append(issue_table)

    # Build the document
    doc.build(story, canvasmaker=NumberedCanvas)
    print(f"Successfully generated PDF: {filename}")


if __name__ == '__main__':
    target = sys.argv[1] if len(sys.argv) > 1 else "docs/Hadoop_Complete_Guide_Install_Run_WordCount.pdf"
    build_pdf(target)
