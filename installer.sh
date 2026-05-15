#!/bin/bash

# ============================================================
#   FAHTECH - ULTIMATE AUTO INSTALLER v22.0
#   SEMUA SERVICE INTERAKTIF | 3 DNS SERVER
#   PILIH INTERFACE | TAMPILAN WEB KEREN
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'

clear
echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                              ║"
echo "║   ███████╗ █████╗ ██╗  ██╗████████╗███████╗ ██████╗██╗  ██╗                 ║"
echo "║   ██╔════╝██╔══██╗██║  ██║╚══██╔══╝██╔════╝██╔════╝██║  ██║                 ║"
echo "║   █████╗  ███████║███████║   ██║   █████╗  ██║     ███████║                 ║"
echo "║   ██╔══╝  ██╔══██║██╔══██║   ██║   ██╔══╝  ██║     ██╔══██║                 ║"
echo "║   ██║     ██║  ██║██║  ██║   ██║   ███████╗╚██████╗██║  ██║                 ║"
echo "║   ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝ ╚═════╝╚═╝  ╚═╝                 ║"
echo "║                                                                              ║"
echo "║              ULTIMATE AUTO INSTALLER v22.0                                   ║"
echo "║         SEMUA INTERAKTIF | PILIH INTERFACE | 3 DNS SERVER                    ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ Jalankan sebagai root!${NC}"
    exit 1
fi

SERVER_IP=$(hostname -I | awk '{print $1}')

detect_interfaces() {
    INTERFACES=()
    for iface in $(ls /sys/class/net/ | grep -v lo); do
        IP=$(ip -4 addr show $iface 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n1)
        if [[ -n $IP ]]; then
            INTERFACES+=("$iface|$IP")
        fi
    done
}

show_interfaces() {
    detect_interfaces
    echo -e "\n${GREEN}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${GREEN}│                    📡 NETWORK INTERFACE                      │${NC}"
    echo -e "${GREEN}├─────┬─────────────────────┬─────────────────────────────────┤${NC}"
    printf "${GREEN}│${NC} ${WHITE}No${NC} │ ${WHITE}Interface${NC}          │ ${WHITE}IP Address${NC}                       │\n"
    echo -e "${GREEN}├─────┼─────────────────────┼─────────────────────────────────┤${NC}"
    for i in "${!INTERFACES[@]}"; do
        IFS='|' read -r iface ip <<< "${INTERFACES[$i]}"
        printf "${GREEN}│${NC} ${YELLOW}%2d${NC} │ ${CYAN}%-19s${NC} │ ${GREEN}%-31s${NC} │\n" "$((i+1))" "$iface" "$ip"
    done
    echo -e "${GREEN}└─────┴─────────────────────┴─────────────────────────────────┘${NC}"
}

# ======================= CLEAN DNS =======================
clean_dns() {
    systemctl stop bind9 2>/dev/null
    systemctl disable bind9 2>/dev/null
    apt remove --purge -y bind9 bind9utils 2>/dev/null
    rm -rf /etc/bind /var/lib/bind /var/cache/bind
}

# ======================= INSTALL 3 DNS SERVER SEKALIGUS =======================
install_all_dns() {
    clear
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              🔍 INSTALL 3 DNS SERVER SEKALIGUS                   ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    
    # ======================= DNS 1 =======================
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  📍 DNS SERVER 1 - TUTORIAL DHCP${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    show_interfaces
    echo -e "\n${YELLOW}👉 Pilih interface untuk DNS Server 1:${NC}"
    read -p "Nomor [1-${#INTERFACES[@]}]: " choice1
    
    if [[ $choice1 -ge 1 && $choice1 -le ${#INTERFACES[@]} ]]; then
        IFS='|' read -r IFACE1 IP1 <<< "${INTERFACES[$((choice1-1))]}"
        echo -e "\n${MAGENTA}📝 Masukkan domain untuk DNS Server 1 (contoh: dhcp.fahtech.com):${NC}"
        read -p "Domain: " DOMAIN1
    else
        echo -e "${RED}❌ Pilihan tidak valid!${NC}"
        return
    fi
    
    # ======================= DNS 2 =======================
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  📍 DNS SERVER 2 - TUTORIAL CRUD${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    show_interfaces
    echo -e "\n${YELLOW}👉 Pilih interface untuk DNS Server 2:${NC}"
    read -p "Nomor [1-${#INTERFACES[@]}]: " choice2
    
    if [[ $choice2 -ge 1 && $choice2 -le ${#INTERFACES[@]} ]]; then
        IFS='|' read -r IFACE2 IP2 <<< "${INTERFACES[$((choice2-1))]}"
        echo -e "\n${MAGENTA}📝 Masukkan domain untuk DNS Server 2 (contoh: crud.fahtech.com):${NC}"
        read -p "Domain: " DOMAIN2
    else
        echo -e "${RED}❌ Pilihan tidak valid!${NC}"
        return
    fi
    
    # ======================= DNS 3 =======================
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  📍 DNS SERVER 3 - TUTORIAL APACHE2${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    show_interfaces
    echo -e "\n${YELLOW}👉 Pilih interface untuk DNS Server 3:${NC}"
    read -p "Nomor [1-${#INTERFACES[@]}]: " choice3
    
    if [[ $choice3 -ge 1 && $choice3 -le ${#INTERFACES[@]} ]]; then
        IFS='|' read -r IFACE3 IP3 <<< "${INTERFACES[$((choice3-1))]}"
        echo -e "\n${MAGENTA}📝 Masukkan domain untuk DNS Server 3 (contoh: web.fahtech.com):${NC}"
        read -p "Domain: " DOMAIN3
    else
        echo -e "${RED}❌ Pilihan tidak valid!${NC}"
        return
    fi
    
    echo -e "\n${CYAN}📦 Menginstall 3 DNS Server...${NC}"
    
    # Install Apache2 dasar
    apt update -qq
    apt install -y apache2 php libapache2-mod-php php-sqlite3 bind9 bind9utils
    
    # ======================= INSTALL DNS1 =======================
    clean_dns
    mkdir -p /etc/bind /var/lib/bind /var/cache/bind
    chown -R bind:bind /var/lib/bind /var/cache/bind
    
    cat > /etc/bind/named.conf.local <<EOF
zone "$DOMAIN1" {
    type master;
    file "/etc/bind/db.$DOMAIN1";
};
zone "$DOMAIN2" {
    type master;
    file "/etc/bind/db.$DOMAIN2";
};
zone "$DOMAIN3" {
    type master;
    file "/etc/bind/db.$DOMAIN3";
};
EOF
    
    cat > /etc/bind/db.$DOMAIN1 <<EOF
\$TTL    604800
@       IN      SOA     ns1.$DOMAIN1. admin.$DOMAIN1. ( 1 604800 86400 2419200 604800 )
@       IN      NS      ns1.$DOMAIN1.
@       IN      A       $IP1
ns1     IN      A       $IP1
www     IN      A       $IP1
EOF
    
    cat > /etc/bind/db.$DOMAIN2 <<EOF
\$TTL    604800
@       IN      SOA     ns1.$DOMAIN2. admin.$DOMAIN2. ( 2 604800 86400 2419200 604800 )
@       IN      NS      ns1.$DOMAIN2.
@       IN      A       $IP2
ns1     IN      A       $IP2
www     IN      A       $IP2
EOF
    
    cat > /etc/bind/db.$DOMAIN3 <<EOF
\$TTL    604800
@       IN      SOA     ns1.$DOMAIN3. admin.$DOMAIN3. ( 3 604800 86400 2419200 604800 )
@       IN      NS      ns1.$DOMAIN3.
@       IN      A       $IP3
ns1     IN      A       $IP3
www     IN      A       $IP3
EOF
    
    cat > /etc/bind/named.conf.options <<EOF
options {
    directory "/var/cache/bind";
    recursion yes;
    allow-query { any; };
    forwarders { 8.8.8.8; 8.8.4.4; };
    listen-on { any; };
    listen-on-v6 { none; };
};
EOF
    
    systemctl start bind9
    systemctl enable bind9
    
    # ======================= BUAT TAMPILAN WEB DNS1 =======================
    mkdir -p /var/www/html/$DOMAIN1
    cat > /var/www/html/$DOMAIN1/index.html <<EOF
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DNS Server 1 - Tutorial DHCP</title>
    <style>
        *{margin:0;padding:0;box-sizing:border-box}
        body{background:linear-gradient(135deg,#0f2027,#203a43,#2c5364);font-family:'Segoe UI',Arial;min-height:100vh;padding:40px}
        .container{max-width:1000px;margin:auto;background:rgba(255,255,255,0.95);border-radius:20px;padding:40px;box-shadow:0 20px 60px rgba(0,0,0,0.3)}
        h1{color:#2c5364;border-left:5px solid #2c5364;padding-left:20px;margin-bottom:20px}
        .badge{background:#2c5364;color:#fff;padding:5px 15px;border-radius:20px;display:inline-block;font-size:12px}
        .info{background:#e8f4f8;padding:15px;border-radius:10px;margin:20px 0}
        pre{background:#1a1a2e;color:#0f0;padding:20px;border-radius:10px;overflow-x:auto;margin:20px 0}
        .step{background:#fff;border-left:4px solid #2c5364;padding:15px;margin:15px 0;box-shadow:0 2px 5px rgba(0,0,0,0.1)}
        .step h3{color:#2c5364;margin-bottom:10px}
        code{background:#f4f4f4;padding:2px 6px;border-radius:4px;color:#e83e8c}
        .footer{text-align:center;margin-top:40px;padding-top:20px;border-top:1px solid #ddd;color:#888}
        @media (max-width:600px){.container{padding:20px}}
    </style>
</head>
<body>
<div class="container">
    <div class="badge">🔍 DNS SERVER 1 - TUTORIAL DHCP</div>
    <h1>📖 Tutorial DHCP Server Debian</h1>
    <div class="info">
        <strong>📡 Domain:</strong> <code>$DOMAIN1</code> &nbsp;|&nbsp;
        <strong>🌐 IP Server:</strong> <code>$IP1</code> &nbsp;|&nbsp;
        <strong>🔧 Interface:</strong> <code>$IFACE1</code>
    </div>
    <div class="step"><h3>📌 LANGKAH 1: Install DHCP Server</h3><pre><code>sudo apt update
sudo apt install isc-dhcp-server -y</code></pre></div>
    <div class="step"><h3>📌 LANGKAH 2: Konfigurasi Interface</h3><pre><code>sudo nano /etc/default/isc-dhcp-server
# Isi dengan:
INTERFACESv4="$IFACE1"</code></pre></div>
    <div class="step"><h3>📌 LANGKAH 3: Konfigurasi DHCP</h3><pre><code>sudo nano /etc/dhcp/dhcpd.conf
# Isi dengan:
subnet ${IP1%.*}.0 netmask 255.255.255.0 {
    range ${IP1%.*}.100 ${IP1%.*}.200;
    option routers ${IP1%.*}.1;
    option domain-name-servers $IP1, 8.8.8.8;
}</code></pre></div>
    <div class="step"><h3>📌 LANGKAH 4: Start DHCP Server</h3><pre><code>sudo systemctl restart isc-dhcp-server
sudo systemctl enable isc-dhcp-server
sudo systemctl status isc-dhcp-server</code></pre></div>
    <div class="step"><h3>📌 LANGKAH 5: Lihat Client</h3><pre><code>sudo cat /var/lib/dhcp/dhcpd.leases</code></pre></div>
    <div class="footer">Powered by FahTech Installer | Tutorial DHCP Server</div>
</div>
</body>
</html>
EOF
    
    # ======================= BUAT TAMPILAN WEB DNS2 + CRUD =======================
    mkdir -p /var/www/html/crud
    mkdir -p /var/www/html/$DOMAIN2
    
    cat > /var/www/html/crud/index.php <<'PHP'
<!DOCTYPE html>
<html>
<head><title>CRUD Siswa</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);font-family:Arial;padding:40px}
.container{max-width:800px;margin:auto;background:#fff;border-radius:20px;padding:30px}
h1{color:#667eea}
input,button{padding:10px;margin:5px;border-radius:5px}
button{background:#667eea;color:#fff;border:none;cursor:pointer}
table{width:100%;border-collapse:collapse}
th,td{padding:10px;text-align:left;border-bottom:1px solid #ddd}
th{background:#667eea;color:#fff}
.delete-btn{background:#e74c3c;color:#fff;padding:5px 10px;text-decoration:none;border-radius:5px}
.edit-btn{background:#3498db;color:#fff;padding:5px 10px;text-decoration:none;border-radius:5px}
</style>
</head>
<body>
<div class="container">
<h1>📚 CRUD Data Siswa</h1>
<?php
$db=new SQLite3('/var/www/html/crud/siswa.db');
$db->exec("CREATE TABLE IF NOT EXISTS siswa (id INTEGER PRIMARY KEY, nama TEXT, rombel TEXT, nis TEXT)");
if(isset($_POST['add'])){$db->exec("INSERT INTO siswa (nama,rombel,nis) VALUES ('".$_POST['nama']."','".$_POST['rombel']."','".$_POST['nis']."')");}
if(isset($_GET['delete'])){$db->exec("DELETE FROM siswa WHERE id=".(int)$_GET['delete']);}
if(isset($_POST['update'])){$db->exec("UPDATE siswa SET nama='".$_POST['nama']."',rombel='".$_POST['rombel']."',nis='".$_POST['nis']."' WHERE id=".(int)$_POST['id']);}
$res=$db->query("SELECT * FROM siswa");
?>
<form method="post">
<input type="text" name="nama" placeholder="Nama" required>
<input type="text" name="rombel" placeholder="Rombel" required>
<input type="text" name="nis" placeholder="NIS" required>
<button type="submit" name="add">Tambah</button>
</form>
<h3>Daftar Siswa</h3>
<table border="1" cellpadding="10">
<tr><th>Nama</th><th>Rombel</th><th>NIS</th><th>Aksi</th></tr>
<?php while($row=$res->fetchArray()){echo "<tr><td>".$row['nama']."</td><td>".$row['rombel']."</td><td>".$row['nis']."</td><td><a class='edit-btn' href='?edit=".$row['id']."'>Edit</a> <a class='delete-btn' href='?delete=".$row['id']."'>Hapus</a></td></tr>";}?>
</table>
<?php if(isset($_GET['edit'])){$id=(int)$_GET['edit'];$edit=$db->query("SELECT * FROM siswa WHERE id=$id")->fetchArray();if($edit){?>
<h3>Edit Data</h3>
<form method="post"><input type="hidden" name="id" value="<?=$edit['id']?>"><input type="text" name="nama" value="<?=$edit['nama']?>"><input type="text" name="rombel" value="<?=$edit['rombel']?>"><input type="text" name="nis" value="<?=$edit['nis']?>"><button type="submit" name="update">Update</button></form>
<?php }}?>
</div>
</body>
</html>
PHP
    
    cat > /var/www/html/$DOMAIN2/index.html <<EOF
<!DOCTYPE html>
<html>
<head><title>DNS Server 2 - Tutorial CRUD</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);font-family:'Segoe UI',Arial;min-height:100vh;padding:40px}
.container{max-width:1000px;margin:auto;background:#fff;border-radius:20px;padding:40px;box-shadow:0 20px 60px rgba(0,0,0,0.3)}
h1{color:#667eea;border-left:5px solid #667eea;padding-left:20px}
.badge{background:#667eea;color:#fff;padding:5px 15px;border-radius:20px;display:inline-block;font-size:12px}
.info{background:#f0f4ff;padding:15px;border-radius:10px;margin:20px 0}
pre{background:#1a1a2e;color:#0f0;padding:20px;border-radius:10px;overflow-x:auto;margin:20px 0}
.step{background:#f8f9fa;border-left:4px solid #667eea;padding:15px;margin:15px 0}
code{background:#f4f4f4;padding:2px 6px;border-radius:4px;color:#e83e8c}
.footer{text-align:center;margin-top:40px;padding-top:20px;border-top:1px solid #ddd;color:#888}
</style>
</head>
<body>
<div class="container">
<div class="badge">🗄️ DNS SERVER 2 - TUTORIAL CRUD</div>
<h1>📖 Tutorial CRUD Siswa dengan PHP & SQLite</h1>
<div class="info"><strong>📡 Domain:</strong> <code>$DOMAIN2</code> &nbsp;|&nbsp; <strong>🌐 IP Server:</strong> <code>$IP2</code> &nbsp;|&nbsp; <strong>🔧 Interface:</strong> <code>$IFACE2</code></div>
<div class="step"><h3>📌 LANGKAH 1: Install Apache2 & PHP</h3><pre><code>sudo apt install apache2 php libapache2-mod-php php-sqlite3 -y</code></pre></div>
<div class="step"><h3>📌 LANGKAH 2: Buat Folder CRUD</h3><pre><code>sudo mkdir -p /var/www/html/crud</code></pre></div>
<div class="step"><h3>📌 LANGKAH 3: Fitur CRUD</h3><pre><code>➕ CREATE: INSERT INTO siswa (nama, rombel, nis) VALUES (...)
📖 READ: SELECT * FROM siswa ORDER BY id DESC
✏️ UPDATE: UPDATE siswa SET nama='...' WHERE id=...
🗑️ DELETE: DELETE FROM siswa WHERE id=...
🔍 SEARCH: SELECT * FROM siswa WHERE nama LIKE '%...%'</code></pre></div>
<div class="step"><h3>📌 LANGKAH 4: Akses CRUD</h3><pre><code>Buka browser: http://$IP2/crud/</code></pre></div>
<div class="footer">Powered by FahTech Installer | Tutorial CRUD | <a href="/crud/">🔗 Akses CRUD App</a></div>
</div>
</body>
</html>
EOF
    
    # ======================= BUAT TAMPILAN WEB DNS3 =======================
    mkdir -p /var/www/html/$DOMAIN3
    cat > /var/www/html/$DOMAIN3/index.html <<EOF
<!DOCTYPE html>
<html>
<head><title>DNS Server 3 - Tutorial Apache2</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{background:linear-gradient(135deg,#0f2027,#203a43,#2c5364);font-family:'Segoe UI',Arial;min-height:100vh;padding:40px}
.container{max-width:1000px;margin:auto;background:#fff;border-radius:20px;padding:40px;box-shadow:0 20px 60px rgba(0,0,0,0.3)}
h1{color:#2c5364;border-left:5px solid #2c5364;padding-left:20px}
.badge{background:#2c5364;color:#fff;padding:5px 15px;border-radius:20px;display:inline-block;font-size:12px}
.info{background:#e8f4f8;padding:15px;border-radius:10px;margin:20px 0}
pre{background:#1a1a2e;color:#0f0;padding:20px;border-radius:10px;overflow-x:auto;margin:20px 0}
.step{background:#f8f9fa;border-left:4px solid #2c5364;padding:15px;margin:15px 0}
code{background:#f4f4f4;padding:2px 6px;border-radius:4px;color:#e83e8c}
.footer{text-align:center;margin-top:40px;padding-top:20px;border-top:1px solid #ddd;color:#888}
</style>
</head>
<body>
<div class="container">
<div class="badge">🌍 DNS SERVER 3 - TUTORIAL APACHE2</div>
<h1>📖 Tutorial Apache2 Web Server</h1>
<div class="info"><strong>📡 Domain:</strong> <code>$DOMAIN3</code> &nbsp;|&nbsp; <strong>🌐 IP Server:</strong> <code>$IP3</code> &nbsp;|&nbsp; <strong>🔧 Interface:</strong> <code>$IFACE3</code></div>
<div class="step"><h3>📌 LANGKAH 1: Install Apache2</h3><pre><code>sudo apt install apache2 -y</code></pre></div>
<div class="step"><h3>📌 LANGKAH 2: Konfigurasi Virtual Host</h3><pre><code>sudo nano /etc/apache2/sites-available/$DOMAIN3.conf
&lt;VirtualHost *:80&gt;
    ServerName $DOMAIN3
    ServerAlias www.$DOMAIN3
    DocumentRoot /var/www/html/$DOMAIN3
&lt;/VirtualHost&gt;</code></pre></div>
<div class="step"><h3>📌 LANGKAH 3: Aktifkan Site</h3><pre><code>sudo a2ensite $DOMAIN3.conf
sudo a2dissite 000-default.conf
sudo systemctl reload apache2</code></pre></div>
<div class="step"><h3>📌 LANGKAH 4: Install PHP</h3><pre><code>sudo apt install php libapache2-mod-php -y</code></pre></div>
<div class="step"><h3>📌 LANGKAH 5: Aktifkan SSL</h3><pre><code>sudo a2enmod ssl rewrite
sudo systemctl restart apache2</code></pre></div>
<div class="footer">Powered by FahTech Installer | Tutorial Apache2 Web Server</div>
</div>
</body>
</html>
EOF
    
    # ======================= VIRTUAL HOST UNTUK 3 DNS =======================
    cat > /etc/apache2/sites-available/$DOMAIN1.conf <<EOF
<VirtualHost *:80>
    ServerName $DOMAIN1
    ServerAlias www.$DOMAIN1
    DocumentRoot /var/www/html/$DOMAIN1
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF
    
    cat > /etc/apache2/sites-available/$DOMAIN2.conf <<EOF
<VirtualHost *:80>
    ServerName $DOMAIN2
    ServerAlias www.$DOMAIN2
    DocumentRoot /var/www/html/$DOMAIN2
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF
    
    cat > /etc/apache2/sites-available/$DOMAIN3.conf <<EOF
<VirtualHost *:80>
    ServerName $DOMAIN3
    ServerAlias www.$DOMAIN3
    DocumentRoot /var/www/html/$DOMAIN3
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF
    
    a2ensite $DOMAIN1.conf $DOMAIN2.conf $DOMAIN3.conf
    a2dissite 000-default.conf
    systemctl reload apache2
    
    chown -R www-data:www-data /var/www/html/crud
    chown -R www-data:www-data /var/www/html/$DOMAIN1
    chown -R www-data:www-data /var/www/html/$DOMAIN2
    chown -R www-data:www-data /var/www/html/$DOMAIN3
    
    # ======================= TAMPILAN HASIL =======================
    echo -e "\n${GREEN}════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}   🎉 3 DNS SERVER BERHASIL DIINSTALL! 🎉${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e ""
    echo -e "${CYAN}📋 HASIL INSTALASI:${NC}"
    echo -e ""
    echo -e "${GREEN}🔍 DNS SERVER 1 - TUTORIAL DHCP${NC}"
    echo -e "   📝 Domain: ${YELLOW}$DOMAIN1${NC}"
    echo -e "   🌐 IP: ${YELLOW}$IP1${NC}"
    echo -e "   🔧 Interface: ${YELLOW}$IFACE1${NC}"
    echo -e "   🌐 Web: ${YELLOW}http://$DOMAIN1${NC}"
    echo -e ""
    echo -e "${GREEN}🗄️ DNS SERVER 2 - TUTORIAL CRUD${NC}"
    echo -e "   📝 Domain: ${YELLOW}$DOMAIN2${NC}"
    echo -e "   🌐 IP: ${YELLOW}$IP2${NC}"
    echo -e "   🔧 Interface: ${YELLOW}$IFACE2${NC}"
    echo -e "   🌐 Web: ${YELLOW}http://$DOMAIN2${NC}"
    echo -e "   🗄️ CRUD App: ${YELLOW}http://$IP2/crud/${NC}"
    echo -e ""
    echo -e "${GREEN}🌍 DNS SERVER 3 - TUTORIAL APACHE2${NC}"
    echo -e "   📝 Domain: ${YELLOW}$DOMAIN3${NC}"
    echo -e "   🌐 IP: ${YELLOW}$IP3${NC}"
    echo -e "   🔧 Interface: ${YELLOW}$IFACE3${NC}"
    echo -e "   🌐 Web: ${YELLOW}http://$DOMAIN3${NC}"
    echo -e ""
    echo -e "${CYAN}💡 CARA AKSES DARI LAPTOP/PC KAMU:${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "1. Setting IP laptop ke 1 jaringan dengan Debian:"
    echo -e "   ${GREEN}IP: 10.1.27.100, Netmask: 255.255.255.0, Gateway: 10.1.27.1${NC}"
    echo -e ""
    echo -e "2. Tambahkan ke file hosts (Windows: C:\\Windows\\System32\\drivers\\etc\\hosts)"
    echo -e "   ${GREEN}$IP1 $DOMAIN1${NC}"
    echo -e "   ${GREEN}$IP2 $DOMAIN2${NC}"
    echo -e "   ${GREEN}$IP3 $DOMAIN3${NC}"
    echo -e ""
    echo -e "3. Buka browser dan akses:"
    echo -e "   ${GREEN}http://$DOMAIN1${NC} → Tutorial DHCP"
    echo -e "   ${GREEN}http://$DOMAIN2${NC} → Tutorial CRUD"
    echo -e "   ${GREEN}http://$DOMAIN3${NC} → Tutorial Apache2"
    echo -e "   ${GREEN}http://$IP2/crud/${NC} → Aplikasi CRUD"
    echo -e ""
    echo -e "4. Test DNS dari terminal Debian:"
    echo -e "   ${GREEN}nslookup $DOMAIN1 localhost${NC}"
    echo -e "   ${GREEN}nslookup $DOMAIN2 localhost${NC}"
    echo -e "   ${GREEN}nslookup $DOMAIN3 localhost${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    read -p "Tekan Enter..."
}

# ======================= INSTALL DNS1 SAJA =======================
install_dns1_only() {
    clear
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║           🔍 INSTALL DNS SERVER 1 (TUTORIAL DHCP)                ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
    
    show_interfaces
    echo -e "\n${YELLOW}👉 Pilih interface untuk DNS Server 1:${NC}"
    read -p "Nomor [1-${#INTERFACES[@]}]: " choice
    
    if [[ $choice -ge 1 && $choice -le ${#INTERFACES[@]} ]]; then
        IFS='|' read -r IFACE IP <<< "${INTERFACES[$((choice-1))]}"
        echo -e "\n${MAGENTA}📝 Masukkan domain (contoh: dhcp.fahtech.com):${NC}"
        read -p "Domain: " DOMAIN
        
        apt update -qq
        apt install -y apache2 bind9 bind9utils
        
        clean_dns
        mkdir -p /etc/bind /var/lib/bind /var/cache/bind
        chown -R bind:bind /var/lib/bind /var/cache/bind
        
        cat > /etc/bind/named.conf.local <<EOF
zone "$DOMAIN" {
    type master;
    file "/etc/bind/db.$DOMAIN";
};
EOF
        
        cat > /etc/bind/db.$DOMAIN <<EOF
\$TTL    604800
@       IN      SOA     ns1.$DOMAIN. admin.$DOMAIN. ( 1 604800 86400 2419200 604800 )
@       IN      NS      ns1.$DOMAIN.
@       IN      A       $IP
ns1     IN      A       $IP
www     IN      A       $IP
EOF
        
        cat > /etc/bind/named.conf.options <<EOF
options {
    directory "/var/cache/bind";
    recursion yes;
    allow-query { any; };
    forwarders { 8.8.8.8; 8.8.4.4; };
    listen-on { any; };
};
EOF
        
        systemctl start bind9
        systemctl enable bind9
        
        mkdir -p /var/www/html/$DOMAIN
        cat > /var/www/html/$DOMAIN/index.html <<EOF
<!DOCTYPE html>
<html>
<head><title>DNS Server 1 - Tutorial DHCP</title>
<style>
body{background:linear-gradient(135deg,#0f2027,#203a43,#2c5364);font-family:Arial;padding:40px}
.container{max-width:1000px;margin:auto;background:#fff;border-radius:20px;padding:40px}
h1{color:#2c5364}
pre{background:#1a1a2e;color:#0f0;padding:15px;border-radius:10px}
</style>
</head>
<body>
<div class="container">
<h1>📖 Tutorial DHCP Server Debian</h1>
<p><strong>Domain:</strong> $DOMAIN | <strong>IP:</strong> $IP | <strong>Interface:</strong> $IFACE</p>
<h3>1. Install DHCP Server</h3>
<pre>sudo apt install isc-dhcp-server -y</pre>
<h3>2. Konfigurasi Interface</h3>
<pre>sudo nano /etc/default/isc-dhcp-server
INTERFACESv4="$IFACE"</pre>
<h3>3. Konfigurasi DHCP</h3>
<pre>subnet ${IP%.*}.0 netmask 255.255.255.0 {
    range ${IP%.*}.100 ${IP%.*}.200;
    option routers ${IP%.*}.1;
    option domain-name-servers $IP, 8.8.8.8;
}</pre>
<h3>4. Start DHCP Server</h3>
<pre>sudo systemctl restart isc-dhcp-server
sudo systemctl enable isc-dhcp-server</pre>
<p>Powered by FahTech Installer</p>
</div>
</body>
</html>
EOF
        
        cat > /etc/apache2/sites-available/$DOMAIN.conf <<EOF
<VirtualHost *:80>
    ServerName $DOMAIN
    DocumentRoot /var/www/html/$DOMAIN
</VirtualHost>
EOF
        
        a2ensite $DOMAIN.conf
        a2dissite 000-default.conf
        systemctl reload apache2
        
        echo -e "\n${GREEN}✅ DNS SERVER 1 BERHASIL!${NC}"
        echo -e "   🌐 Akses: http://$DOMAIN"
        echo -e "   📝 Domain: $DOMAIN"
        echo -e "   🔍 Test: nslookup $DOMAIN localhost"
        echo -e "\n${YELLOW}💡 Tambahkan ke hosts laptop: $IP $DOMAIN${NC}"
    fi
    read -p "Tekan Enter..."
}

# ======================= INSTALL DNS2 SAJA =======================
install_dns2_only() {
    clear
    echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║           🔍 INSTALL DNS SERVER 2 (TUTORIAL CRUD)                ║${NC}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════════╝${NC}"
    
    show_interfaces
    echo -e "\n${YELLOW}👉 Pilih interface untuk DNS Server 2:${NC}"
    read -p "Nomor [1-${#INTERFACES[@]}]: " choice
    
    if [[ $choice -ge 1 && $choice -le ${#INTERFACES[@]} ]]; then
        IFS='|' read -r IFACE IP <<< "${INTERFACES[$((choice-1))]}"
        echo -e "\n${MAGENTA}📝 Masukkan domain (contoh: crud.fahtech.com):${NC}"
        read -p "Domain: " DOMAIN
        
        apt update -qq
        apt install -y apache2 php libapache2-mod-php php-sqlite3 bind9 bind9utils
        
        clean_dns
        mkdir -p /etc/bind /var/lib/bind /var/cache/bind
        chown -R bind:bind /var/lib/bind /var/cache/bind
        
        cat > /etc/bind/named.conf.local <<EOF
zone "$DOMAIN" {
    type master;
    file "/etc/bind/db.$DOMAIN";
};
EOF
        
        cat > /etc/bind/db.$DOMAIN <<EOF
\$TTL    604800
@       IN      SOA     ns1.$DOMAIN. admin.$DOMAIN. ( 2 604800 86400 2419200 604800 )
@       IN      NS      ns1.$DOMAIN.
@       IN      A       $IP
ns1     IN      A       $IP
www     IN      A       $IP
EOF
        
        cat > /etc/bind/named.conf.options <<EOF
options {
    directory "/var/cache/bind";
    recursion yes;
    allow-query { any; };
    forwarders { 8.8.8.8; 8.8.4.4; };
    listen-on { any; };
};
EOF
        
        systemctl start bind9
        systemctl enable bind9
        
        mkdir -p /var/www/html/crud
        cat > /var/www/html/crud/index.php <<'PHP'
<!DOCTYPE html>
<html>
<head><title>CRUD Siswa</title>
<style>
body{background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);font-family:Arial;padding:40px}
.container{max-width:800px;margin:auto;background:#fff;border-radius:20px;padding:30px}
h1{color:#667eea}
input,button{padding:10px;margin:5px;border-radius:5px}
button{background:#667eea;color:#fff;border:none;cursor:pointer}
table{width:100%;border-collapse:collapse}
th,td{padding:10px;text-align:left;border-bottom:1px solid #ddd}
th{background:#667eea;color:#fff}
.delete-btn{background:#e74c3c;color:#fff;padding:5px 10px;text-decoration:none;border-radius:5px}
.edit-btn{background:#3498db;color:#fff;padding:5px 10px;text-decoration:none;border-radius:5px}
</style>
</head>
<body>
<div class="container">
<h1>📚 CRUD Data Siswa</h1>
<?php
$db=new SQLite3('/var/www/html/crud/siswa.db');
$db->exec("CREATE TABLE IF NOT EXISTS siswa (id INTEGER PRIMARY KEY, nama TEXT, rombel TEXT, nis TEXT)");
if(isset($_POST['add'])){$db->exec("INSERT INTO siswa (nama,rombel,nis) VALUES ('".$_POST['nama']."','".$_POST['rombel']."','".$_POST['nis']."')");}
if(isset($_GET['delete'])){$db->exec("DELETE FROM siswa WHERE id=".(int)$_GET['delete']);}
if(isset($_POST['update'])){$db->exec("UPDATE siswa SET nama='".$_POST['nama']."',rombel='".$_POST['rombel']."',nis='".$_POST['nis']."' WHERE id=".(int)$_POST['id']);}
$res=$db->query("SELECT * FROM siswa");
?>
<form method="post">
<input type="text" name="nama" placeholder="Nama" required>
<input type="text" name="rombel" placeholder="Rombel" required>
<input type="text" name="nis" placeholder="NIS" required>
<button type="submit" name="add">Tambah</button>
</form>
<h3>Daftar Siswa</h3>
<table border="1" cellpadding="10">
<tr><th>Nama</th><th>Rombel</th><th>NIS</th><th>Aksi</th></tr>
<?php while($row=$res->fetchArray()){echo "<td>".$row['nama']."<td>".$row['rombel']."</td>".$row['nis']."</td><a class='edit-btn' href='?edit=".$row['id']."'>Edit</a> <a class='delete-btn' href='?delete=".$row['id']."'>Hapus</a></td>";}?>
</table>
<?php if(isset($_GET['edit'])){$id=(int)$_GET['edit'];$edit=$db->query("SELECT * FROM siswa WHERE id=$id")->fetchArray();if($edit){?>
<h3>Edit Data</h3>
<form method="post"><input type="hidden" name="id" value="<?=$edit['id']?>"><input type="text" name="nama" value="<?=$edit['nama']?>"><input type="text" name="rombel" value="<?=$edit['rombel']?>"><input type="text" name="nis" value="<?=$edit['nis']?>"><button type="submit" name="update">Update</button></form>
<?php }?>
</div>
</body>
</html>
PHP
        
        mkdir -p /var/www/html/$DOMAIN
        cat > /var/www/html/$DOMAIN/index.html <<EOF
<!DOCTYPE html>
<html>
<head><title>DNS Server 2 - Tutorial CRUD</title>
<style>
body{background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);font-family:Arial;padding:40px}
.container{max-width:1000px;margin:auto;background:#fff;border-radius:20px;padding:40px}
h1{color:#667eea}
pre{background:#1a1a2e;color:#0f0;padding:15px;border-radius:10px}
</style>
</head>
<body>
<div class="container">
<h1>📖 Tutorial CRUD Siswa</h1>
<p><strong>Domain:</strong> $DOMAIN | <strong>IP:</strong> $IP | <strong>Interface:</strong> $IFACE</p>
<h3>Fitur CRUD:</h3>
<pre>➕ CREATE: INSERT INTO siswa (nama, rombel, nis) VALUES (...)
📖 READ: SELECT * FROM siswa ORDER BY id DESC
✏️ UPDATE: UPDATE siswa SET nama='...' WHERE id=...
🗑️ DELETE: DELETE FROM siswa WHERE id=...
🔍 SEARCH: SELECT * FROM siswa WHERE nama LIKE '%...%'</pre>
<h3>Akses CRUD App:</h3>
<pre>http://$IP/crud/</pre>
<p>Powered by FahTech Installer | <a href="/crud/">🔗 Buka CRUD App</a></p>
</div>
</body>
</html>
EOF
        
        cat > /etc/apache2/sites-available/$DOMAIN.conf <<EOF
<VirtualHost *:80>
    ServerName $DOMAIN
    DocumentRoot /var/www/html/$DOMAIN
</VirtualHost>
EOF
        
        a2ensite $DOMAIN.conf
        systemctl reload apache2
        chown -R www-data:www-data /var/www/html/crud
        
        echo -e "\n${GREEN}✅ DNS SERVER 2 BERHASIL!${NC}"
        echo -e "   🌐 Akses: http://$DOMAIN"
        echo -e "   🗄️ CRUD: http://$IP/crud/"
        echo -e "   🔍 Test: nslookup $DOMAIN localhost"
        echo -e "\n${YELLOW}💡 Tambahkan ke hosts laptop: $IP $DOMAIN${NC}"
    fi
    read -p "Tekan Enter..."
}

# ======================= INSTALL DNS3 SAJA =======================
install_dns3_only() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║        🔍 INSTALL DNS SERVER 3 (TUTORIAL APACHE2)                ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    
    show_interfaces
    echo -e "\n${YELLOW}👉 Pilih interface untuk DNS Server 3:${NC}"
    read -p "Nomor [1-${#INTERFACES[@]}]: " choice
    
    if [[ $choice -ge 1 && $choice -le ${#INTERFACES[@]} ]]; then
        IFS='|' read -r IFACE IP <<< "${INTERFACES[$((choice-1))]}"
        echo -e "\n${CYAN}📝 Masukkan domain (contoh: web.fahtech.com):${NC}"
        read -p "Domain: " DOMAIN
        
        apt update -qq
        apt install -y apache2 bind9 bind9utils
        
        clean_dns
        mkdir -p /etc/bind /var/lib/bind /var/cache/bind
        chown -R bind:bind /var/lib/bind /var/cache/bind
        
        cat > /etc/bind/named.conf.local <<EOF
zone "$DOMAIN" {
    type master;
    file "/etc/bind/db.$DOMAIN";
};
EOF
        
        cat > /etc/bind/db.$DOMAIN <<EOF
\$TTL    604800
@       IN      SOA     ns1.$DOMAIN. admin.$DOMAIN. ( 3 604800 86400 2419200 604800 )
@       IN      NS      ns1.$DOMAIN.
@       IN      A       $IP
ns1     IN      A       $IP
www     IN      A       $IP
EOF
        
        cat > /etc/bind/named.conf.options <<EOF
options {
    directory "/var/cache/bind";
    recursion yes;
    allow-query { any; };
    forwarders { 8.8.8.8; 8.8.4.4; };
    listen-on { any; };
};
EOF
        
        systemctl start bind9
        systemctl enable bind9
        
        mkdir -p /var/www/html/$DOMAIN
        cat > /var/www/html/$DOMAIN/index.html <<EOF
<!DOCTYPE html>
<html>
<head><title>DNS Server 3 - Tutorial Apache2</title>
<style>
body{background:linear-gradient(135deg,#0f2027,#203a43,#2c5364);font-family:Arial;padding:40px}
.container{max-width:1000px;margin:auto;background:#fff;border-radius:20px;padding:40px}
h1{color:#2c5364}
pre{background:#1a1a2e;color:#0f0;padding:15px;border-radius:10px}
</style>
</head>
<body>
<div class="container">
<h1>📖 Tutorial Apache2 Web Server</h1>
<p><strong>Domain:</strong> $DOMAIN | <strong>IP:</strong> $IP | <strong>Interface:</strong> $IFACE</p>
<h3>1. Install Apache2</h3>
<pre>sudo apt install apache2 -y</pre>
<h3>2. Konfigurasi Virtual Host</h3>
<pre>sudo nano /etc/apache2/sites-available/$DOMAIN.conf
&lt;VirtualHost *:80&gt;
    ServerName $DOMAIN
    DocumentRoot /var/www/html/$DOMAIN
&lt;/VirtualHost&gt;</pre>
<h3>3. Aktifkan Site</h3>
<pre>sudo a2ensite $DOMAIN.conf
sudo systemctl reload apache2</pre>
<h3>4. Install PHP</h3>
<pre>sudo apt install php libapache2-mod-php -y</pre>
<p>Powered by FahTech Installer</p>
</div>
</body>
</html>
EOF
        
        cat > /etc/apache2/sites-available/$DOMAIN.conf <<EOF
<VirtualHost *:80>
    ServerName $DOMAIN
    DocumentRoot /var/www/html/$DOMAIN
</VirtualHost>
EOF
        
        a2ensite $DOMAIN.conf
        a2dissite 000-default.conf
        systemctl reload apache2
        
        echo -e "\n${GREEN}✅ DNS SERVER 3 BERHASIL!${NC}"
        echo -e "   🌐 Akses: http://$DOMAIN"
        echo -e "   🔍 Test: nslookup $DOMAIN localhost"
        echo -e "\n${YELLOW}💡 Tambahkan ke hosts laptop: $IP $DOMAIN${NC}"
    fi
    read -p "Tekan Enter..."
}

# ======================= CRUD SISWA =======================
install_crud_only() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         🗄️ INSTALL CRUD SISWA                 ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
    apt install -y apache2 php libapache2-mod-php php-sqlite3
    mkdir -p /var/www/html/crud
    
    cat > /var/www/html/crud/index.php <<'PHP'
<!DOCTYPE html>
<html>
<head><title>CRUD Siswa</title>
<style>
body{background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);font-family:Arial;padding:40px}
.container{max-width:800px;margin:auto;background:#fff;border-radius:20px;padding:30px}
h1{color:#667eea}
input,button{padding:10px;margin:5px;border-radius:5px}
button{background:#667eea;color:#fff;border:none;cursor:pointer}
table{width:100%;border-collapse:collapse}
th,td{padding:10px;text-align:left;border-bottom:1px solid #ddd}
th{background:#667eea;color:#fff}
.delete-btn{background:#e74c3c;color:#fff;padding:5px 10px;text-decoration:none;border-radius:5px}
.edit-btn{background:#3498db;color:#fff;padding:5px 10px;text-decoration:none;border-radius:5px}
</style>
</head>
<body>
<div class="container">
<h1>📚 CRUD Data Siswa</h1>
<?php
$db=new SQLite3('/var/www/html/crud/siswa.db');
$db->exec("CREATE TABLE IF NOT EXISTS siswa (id INTEGER PRIMARY KEY, nama TEXT, rombel TEXT, nis TEXT)");
if(isset($_POST['add'])){$db->exec("INSERT INTO siswa (nama,rombel,nis) VALUES ('".$_POST['nama']."','".$_POST['rombel']."','".$_POST['nis']."')");}
if(isset($_GET['delete'])){$db->exec("DELETE FROM siswa WHERE id=".(int)$_GET['delete']);}
if(isset($_POST['update'])){$db->exec("UPDATE siswa SET nama='".$_POST['nama']."',rombel='".$_POST['rombel']."',nis='".$_POST['nis']."' WHERE id=".(int)$_POST['id']);}
$res=$db->query("SELECT * FROM siswa");
?>
<form method="post">
<input type="text" name="nama" placeholder="Nama" required>
<input type="text" name="rombel" placeholder="Rombel" required>
<input type="text" name="nis" placeholder="NIS" required>
<button type="submit" name="add">Tambah</button>
</form>
<h3>Daftar Siswa</h3>
<table border="1" cellpadding="10">
<tr><th>Nama</th><th>Rombel</th><th>NIS</th><th>Aksi</th></tr>
<?php while($row=$res->fetchArray()){echo "<tr><td>".$row['nama']."</td><td>".$row['rombel']."</td><td>".$row['nis']."</td><td><a class='edit-btn' href='?edit=".$row['id']."'>Edit</a> <a class='delete-btn' href='?delete=".$row['id']."'>Hapus</a></td></tr>";}?>
</table>
<?php if(isset($_GET['edit'])){$id=(int)$_GET['edit'];$edit=$db->query("SELECT * FROM siswa WHERE id=$id")->fetchArray();if($edit){?>
<h3>Edit Data</h3>
<form method="post"><input type="hidden" name="id" value="<?=$edit['id']?>"><input type="text" name="nama" value="<?=$edit['nama']?>"><input type="text" name="rombel" value="<?=$edit['rombel']?>"><input type="text" name="nis" value="<?=$edit['nis']?>"><button type="submit" name="update">Update</button></form>
<?php }}?>
</div>
</body>
</html>
PHP
    
    chown -R www-data:www-data /var/www/html/crud
    systemctl restart apache2
    
    echo -e "\n${GREEN}✅ CRUD SISWA BERHASIL! Akses: http://$SERVER_IP/crud/${NC}"
    read -p "Tekan Enter..."
}

# ======================= CEK STATUS =======================
check_status() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              📊 CEK STATUS SERVICE             ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    systemctl is-active --quiet apache2 && echo -e "  🌍 Apache2  | ${GREEN}✅ ACTIVE${NC}" || echo -e "  🌍 Apache2  | ${RED}❌ INACTIVE${NC}"
    systemctl is-active --quiet bind9 && echo -e "  🔍 Bind9    | ${GREEN}✅ ACTIVE${NC}" || echo -e "  🔍 Bind9    | ${RED}❌ INACTIVE${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if [[ -f /etc/bind/named.conf.local ]]; then
        echo -e "\n📋 DNS ZONES TERDAFTAR:"
        grep -E "zone.*{" /etc/bind/named.conf.local | sed 's/zone/  📝/g' | sed 's/ {//g'
    fi
    
    read -p "Tekan Enter..."
}

# ======================= MENU UTAMA =======================
while true; do
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                                                  ║"
    echo "║                     🚀 FAHTECH ULTIMATE AUTO INSTALLER v22.0                                     ║"
    echo "║                           SEMUA INTERAKTIF | PILIH INTERFACE                                     ║"
    echo "║                                                                                                  ║"
    echo "╠══════════════════════════════════════════════════════════════════════════════════════════════════╣"
    echo "║                                                                                                  ║"
    echo "║  🔍 3 DNS SERVER (TAMPILAN WEB KEREN)                                                            ║"
    echo "║  ────────────────────────────────────────────────────────────────────────────────────────────── ║"
    echo "║     1.  🚀 Install 3 DNS Server SEKALIGUS (REKOMENDED)                                           ║"
    echo "║     2.  🔍 Install DNS Server 1 (Tutorial DHCP + Tampilan Web)                                  ║"
    echo "║     3.  🗄️ Install DNS Server 2 (Tutorial CRUD + Tampilan Web + CRUD App)                       ║"
    echo "║     4.  🌍 Install DNS Server 3 (Tutorial Apache2 + Tampilan Web)                                ║"
    echo "║                                                                                                  ║"
    echo "║  ⚡ SERVICE LAINNYA                                                                              ║"
    echo "║  ────────────────────────────────────────────────────────────────────────────────────────────── ║"
    echo "║     5.  📚 Install CRUD Siswa (Tambah/Edit/Hapus/Cari)                                          ║"
    echo "║     6.  📊 Cek Status Service                                                                   ║"
    echo "║     7.  🗑️ Hapus SEMUA Service + Folder                                                         ║"
    echo "║     8.  🚪 Exit                                                                                 ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    read -p "👉 Pilih menu [1-8]: " menu
    
    case $menu in
        1) install_all_dns ;;
        2) install_dns1_only ;;
        3) install_dns2_only ;;
        4) install_dns3_only ;;
        5) install_crud_only ;;
        6) check_status ;;
        7)
            echo -e "\n${RED}🗑️ Hapus SEMUA? (y/n):${NC}"
            read confirm
            if [[ "$confirm" == "y" ]]; then
                systemctl stop apache2 bind9 2>/dev/null
                apt remove --purge -y apache2* bind9* php* 2>/dev/null
                rm -rf /etc/apache2 /etc/bind /var/www/html
                rm -rf /etc/roundcube /var/lib/roundcube /usr/share/roundcube
                apt autoremove --purge -y
                echo -e "${GREEN}✅ SEMUA SERVICE DAN FOLDER DIHAPUS!${NC}"
            fi
            read -p "Tekan Enter..."
            ;;
        8)
            echo -e "${GREEN}👋 Terima kasih!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Pilihan salah!${NC}"
            sleep 1
            ;;
    esac
done
