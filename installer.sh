#!/bin/bash

# ============================================================
#   FAHTECH - 3 DNS SERVER with WEB INTERFACE
#   DNS1: Tutorial DHCP | DNS2: Tutorial CRUD | DNS3: Tutorial Apache2
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║   3 DNS SERVER dengan 3 TAMPILAN WEB BERBEDA                     ║"
echo "║   DNS1: Tutorial DHCP | DNS2: Tutorial CRUD | DNS3: Tutorial Apache2 ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
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

# ======================= INSTALL DNS1 (Tampilan Web - Tutorial DHCP) =======================
install_dns1() {
    clear
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     🔍 DNS SERVER 1 - TUTORIAL DHCP (Tampilan Web Keren)         ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
    
    show_interfaces
    echo -e "\n${YELLOW}👉 Pilih interface untuk DNS Server 1:${NC}"
    read -p "Nomor: " choice
    
    if [[ $choice -ge 1 && $choice -le ${#INTERFACES[@]} ]]; then
        IFS='|' read -r IFACE IP <<< "${INTERFACES[$((choice-1))]}"
        echo -e "\n${MAGENTA}📝 Masukkan domain (contoh: dhcp.fahtech.com):${NC}"
        read -p "Domain: " DOMAIN
        
        # Install Apache2 dan PHP
        apt update -qq
        apt install -y apache2 php libapache2-mod-php
        
        # Install DNS
        clean_dns
        apt install -y bind9 bind9utils
        
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
        
        # BUAT TAMPILAN WEB UNTUK DNS1 (Tutorial DHCP)
        mkdir -p /var/www/html/$DOMAIN
        cat > /var/www/html/$DOMAIN/index.html <<'HTML'
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DNS Server 1 - Tutorial DHCP</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            background: linear-gradient(135deg, #0f2027, #203a43, #2c5364);
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            min-height: 100vh;
            padding: 40px;
        }
        .container {
            max-width: 1000px;
            margin: 0 auto;
            background: rgba(255,255,255,0.95);
            border-radius: 20px;
            padding: 40px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            animation: fadeIn 0.5s ease;
        }
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(20px); }
            to { opacity: 1; transform: translateY(0); }
        }
        h1 {
            color: #2c5364;
            font-size: 36px;
            margin-bottom: 10px;
            border-left: 5px solid #2c5364;
            padding-left: 20px;
        }
        .badge {
            background: #2c5364;
            color: white;
            padding: 5px 15px;
            border-radius: 20px;
            display: inline-block;
            font-size: 12px;
            margin-bottom: 20px;
        }
        .info {
            background: #e8f4f8;
            padding: 15px;
            border-radius: 10px;
            margin: 20px 0;
        }
        pre {
            background: #1a1a2e;
            color: #0f0;
            padding: 20px;
            border-radius: 10px;
            overflow-x: auto;
            font-size: 14px;
            margin: 20px 0;
        }
        .step {
            background: white;
            border-left: 4px solid #2c5364;
            padding: 15px;
            margin: 15px 0;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        .step h3 { color: #2c5364; margin-bottom: 10px; }
        code { background: #f4f4f4; padding: 2px 6px; border-radius: 4px; color: #e83e8c; }
        .footer {
            text-align: center;
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid #ddd;
            color: #888;
        }
    </style>
</head>
<body>
<div class="container">
    <div class="badge">🔍 DNS SERVER 1</div>
    <h1>📖 Tutorial DHCP Server Debian</h1>
    <p>Panduan lengkap membuat DHCP Server di Debian 12/Ubuntu 22.04</p>
    
    <div class="info">
        <strong>📡 Domain:</strong> <code id="domain"></code> &nbsp;|&nbsp;
        <strong>🌐 IP Server:</strong> <code id="ip"></code>
    </div>
    
    <div class="step">
        <h3>📌 LANGKAH 1: Install DHCP Server</h3>
        <pre><code>sudo apt update
sudo apt install isc-dhcp-server -y</code></pre>
    </div>
    
    <div class="step">
        <h3>📌 LANGKAH 2: Konfigurasi Interface</h3>
        <pre><code>sudo nano /etc/default/isc-dhcp-server
# Isi dengan:
INTERFACESv4="ens33"</code></pre>
    </div>
    
    <div class="step">
        <h3>📌 LANGKAH 3: Konfigurasi DHCP</h3>
        <pre><code>sudo nano /etc/dhcp/dhcpd.conf
# Isi dengan:
subnet 192.168.1.0 netmask 255.255.255.0 {
    range 192.168.1.100 192.168.1.200;
    option routers 192.168.1.1;
    option domain-name-servers 8.8.8.8, 8.8.4.4;
}</code></pre>
    </div>
    
    <div class="step">
        <h3>📌 LANGKAH 4: Start DHCP Server</h3>
        <pre><code>sudo systemctl restart isc-dhcp-server
sudo systemctl enable isc-dhcp-server
sudo systemctl status isc-dhcp-server</code></pre>
    </div>
    
    <div class="step">
        <h3>📌 LANGKAH 5: Lihat Client yang Terhubung</h3>
        <pre><code>sudo cat /var/lib/dhcp/dhcpd.leases</code></pre>
    </div>
    
    <div class="step">
        <h3>📌 LANGKAH 6: Test dari Client</h3>
        <pre><code># Windows:
ipconfig /renew

# Linux:
sudo dhclient eth0</code></pre>
    </div>
    
    <div class="footer">
        Powered by FahTech Installer | Tutorial DHCP Server
    </div>
</div>
<script>
    document.getElementById('domain').innerText = window.location.hostname;
    document.getElementById('ip').innerText = window.location.hostname;
</script>
</body>
</html>
HTML
        
        # Ganti IP dan domain di HTML
        sed -i "s/ens33/$IFACE/g" /var/www/html/$DOMAIN/index.html
        sed -i "s/192.168.1.0/${IP%.*}.0/g" /var/www/html/$DOMAIN/index.html
        sed -i "s/192.168.1.100/${IP%.*}.100/g" /var/www/html/$DOMAIN/index.html
        sed -i "s/192.168.1.200/${IP%.*}.200/g" /var/www/html/$DOMAIN/index.html
        sed -i "s/192.168.1.1/${IP%.*}.1/g" /var/www/html/$DOMAIN/index.html
        
        # Buat virtual host
        cat > /etc/apache2/sites-available/$DOMAIN.conf <<EOF
<VirtualHost *:80>
    ServerName $DOMAIN
    ServerAlias www.$DOMAIN
    DocumentRoot /var/www/html/$DOMAIN
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF
        
        a2ensite $DOMAIN.conf
        a2dissite 000-default.conf
        systemctl reload apache2
        
        echo -e "\n${GREEN}✅ DNS SERVER 1 BERHASIL!${NC}"
        echo -e "   🌐 Akses Web: http://$DOMAIN"
        echo -e "   📝 Domain: $DOMAIN"
        echo -e "   🌐 IP: $IP"
        echo -e "\n${YELLOW}💡 Untuk akses dari laptop, tambahkan ke file hosts:${NC}"
        echo -e "   echo '$IP $DOMAIN' >> /etc/hosts"
    fi
    read -p "Tekan Enter..."
}

# ======================= INSTALL DNS2 (Tampilan Web - Tutorial CRUD) =======================
install_dns2() {
    clear
    echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║     🔍 DNS SERVER 2 - TUTORIAL CRUD (Tampilan Web Keren)         ║${NC}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════════╝${NC}"
    
    show_interfaces
    echo -e "\n${YELLOW}👉 Pilih interface untuk DNS Server 2:${NC}"
    read -p "Nomor: " choice
    
    if [[ $choice -ge 1 && $choice -le ${#INTERFACES[@]} ]]; then
        IFS='|' read -r IFACE IP <<< "${INTERFACES[$((choice-1))]}"
        echo -e "\n${MAGENTA}📝 Masukkan domain (contoh: crud.fahtech.com):${NC}"
        read -p "Domain: " DOMAIN
        
        apt update -qq
        apt install -y apache2 php libapache2-mod-php php-sqlite3
        
        clean_dns
        apt install -y bind9 bind9utils
        
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
        
        # BUAT TAMPILAN WEB UNTUK DNS2 (Tutorial CRUD)
        mkdir -p /var/www/html/crud
        mkdir -p /var/www/html/$DOMAIN
        
        # Buat CRUD aplikasi
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
        
        # Buat landing page untuk DNS2
        cat > /var/www/html/$DOMAIN/index.html <<HTML
<!DOCTYPE html>
<html>
<head><title>DNS Server 2 - Tutorial CRUD</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);font-family:'Segoe UI',Arial;min-height:100vh;padding:40px}
.container{max-width:1000px;margin:auto;background:white;border-radius:20px;padding:40px;box-shadow:0 20px 60px rgba(0,0,0,0.3)}
h1{color:#667eea;border-left:5px solid #667eea;padding-left:20px}
.badge{background:#667eea;color:white;padding:5px 15px;border-radius:20px;display:inline-block;font-size:12px}
pre{background:#1a1a2e;color:#0f0;padding:20px;border-radius:10px;overflow-x:auto;margin:20px 0}
.step{background:#f8f9fa;border-left:4px solid #667eea;padding:15px;margin:15px 0}
code{background:#f4f4f4;padding:2px 6px;border-radius:4px;color:#e83e8c}
.footer{text-align:center;margin-top:40px;padding-top:20px;border-top:1px solid #ddd;color:#888}
</style>
</head>
<body>
<div class="container">
<div class="badge">🗄️ DNS SERVER 2</div>
<h1>📖 Tutorial CRUD Siswa dengan PHP & SQLite</h1>
<p>Panduan lengkap membuat aplikasi CRUD (Create, Read, Update, Delete) untuk data siswa</p>

<div class="step">
<h3>📌 LANGKAH 1: Install Apache2 & PHP</h3>
<pre><code>sudo apt install apache2 php libapache2-mod-php php-sqlite3 -y</code></pre>
</div>

<div class="step">
<h3>📌 LANGKAH 2: Buat Folder CRUD</h3>
<pre><code>sudo mkdir -p /var/www/html/crud</code></pre>
</div>

<div class="step">
<h3>📌 LANGKAH 3: Buat File index.php</h3>
<pre><code>sudo nano /var/www/html/crud/index.php</code></pre>
</div>

<div class="step">
<h3>📌 LANGKAH 4: Struktur Database</h3>
<pre><code>CREATE TABLE siswa (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nama TEXT NOT NULL,
    rombel TEXT NOT NULL,
    nis TEXT NOT NULL UNIQUE
);</code></pre>
</div>

<div class="step">
<h3>📌 LANGKAH 5: Fitur CRUD</h3>
<pre><code>➕ CREATE: INSERT INTO siswa (nama, rombel, nis) VALUES (...)
📖 READ: SELECT * FROM siswa ORDER BY id DESC
✏️ UPDATE: UPDATE siswa SET nama='...' WHERE id=...
🗑️ DELETE: DELETE FROM siswa WHERE id=...
🔍 SEARCH: SELECT * FROM siswa WHERE nama LIKE '%...%'</code></pre>
</div>

<div class="step">
<h3>📌 LANGKAH 6: Akses CRUD</h3>
<pre><code>Buka browser: http://<span id="ip"></span>/crud/</code></pre>
</div>

<div class="footer">
Powered by FahTech Installer | Tutorial CRUD Siswa | <a href="/crud/">🔗 Akses CRUD App</a>
</div>
</div>
<script>document.getElementById('ip').innerText = window.location.hostname;</script>
</body>
</html>
HTML
        
        chown -R www-data:www-data /var/www/html/crud
        chown -R www-data:www-data /var/www/html/$DOMAIN
        
        cat > /etc/apache2/sites-available/$DOMAIN.conf <<EOF
<VirtualHost *:80>
    ServerName $DOMAIN
    ServerAlias www.$DOMAIN
    DocumentRoot /var/www/html/$DOMAIN
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF
        
        a2ensite $DOMAIN.conf
        systemctl reload apache2
        
        echo -e "\n${GREEN}✅ DNS SERVER 2 BERHASIL!${NC}"
        echo -e "   🌐 Akses Web: http://$DOMAIN"
        echo -e "   🗄️ CRUD App: http://$IP/crud/"
        echo -e "\n${YELLOW}💡 Tambahkan ke file hosts:${NC}"
        echo -e "   echo '$IP $DOMAIN' >> /etc/hosts"
    fi
    read -p "Tekan Enter..."
}

# ======================= INSTALL DNS3 (Tampilan Web - Tutorial Apache2) =======================
install_dns3() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║   🔍 DNS SERVER 3 - TUTORIAL APACHE2 (Tampilan Web Keren)        ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    
    show_interfaces
    echo -e "\n${YELLOW}👉 Pilih interface untuk DNS Server 3:${NC}"
    read -p "Nomor: " choice
    
    if [[ $choice -ge 1 && $choice -le ${#INTERFACES[@]} ]]; then
        IFS='|' read -r IFACE IP <<< "${INTERFACES[$((choice-1))]}"
        echo -e "\n${CYAN}📝 Masukkan domain (contoh: web.fahtech.com):${NC}"
        read -p "Domain: " DOMAIN
        
        apt update -qq
        apt install -y apache2 php libapache2-mod-php
        
        clean_dns
        apt install -y bind9 bind9utils
        
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
        
        # BUAT TAMPILAN WEB UNTUK DNS3 (Tutorial Apache2)
        mkdir -p /var/www/html/$DOMAIN
        cat > /var/www/html/$DOMAIN/index.html <<HTML
<!DOCTYPE html>
<html>
<head><title>DNS Server 3 - Tutorial Apache2</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{background:linear-gradient(135deg,#0f2027,#203a43,#2c5364);font-family:'Segoe UI',Arial;min-height:100vh;padding:40px}
.container{max-width:1000px;margin:auto;background:white;border-radius:20px;padding:40px;box-shadow:0 20px 60px rgba(0,0,0,0.3)}
h1{color:#2c5364;border-left:5px solid #2c5364;padding-left:20px}
.badge{background:#2c5364;color:white;padding:5px 15px;border-radius:20px;display:inline-block;font-size:12px}
pre{background:#1a1a2e;color:#0f0;padding:20px;border-radius:10px;overflow-x:auto;margin:20px 0}
.step{background:#e8f4f8;border-left:4px solid #2c5364;padding:15px;margin:15px 0}
code{background:#f4f4f4;padding:2px 6px;border-radius:4px;color:#e83e8c}
.footer{text-align:center;margin-top:40px;padding-top:20px;border-top:1px solid #ddd;color:#888}
</style>
</head>
<body>
<div class="container">
<div class="badge">🌍 DNS SERVER 3</div>
<h1>📖 Tutorial Apache2 Web Server</h1>
<p>Panduan lengkap konfigurasi Apache2 Web Server di Debian/Ubuntu</p>

<div class="step">
<h3>📌 LANGKAH 1: Install Apache2</h3>
<pre><code>sudo apt update
sudo apt install apache2 -y</code></pre>
</div>

<div class="step">
<h3>📌 LANGKAH 2: Cek Status Apache2</h3>
<pre><code>sudo systemctl status apache2
sudo systemctl enable apache2</code></pre>
</div>

<div class="step">
<h3>📌 LANGKAH 3: Konfigurasi Virtual Host</h3>
<pre><code>sudo nano /etc/apache2/sites-available/domain.conf

&lt;VirtualHost *:80&gt;
    ServerName domain.com
    ServerAlias www.domain.com
    DocumentRoot /var/www/html/domain
&lt;/VirtualHost&gt;</code></pre>
</div>

<div class="step">
<h3>📌 LANGKAH 4: Aktifkan Site</h3>
<pre><code>sudo a2ensite domain.conf
sudo a2dissite 000-default.conf
sudo systemctl reload apache2</code></pre>
</div>

<div class="step">
<h3>📌 LANGKAH 5: Buat File Index</h3>
<pre><code>sudo mkdir -p /var/www/html/domain
sudo nano /var/www/html/domain/index.html</code></pre>
</div>

<div class="step">
<h3>📌 LANGKAH 6: Install PHP (Opsional)</h3>
<pre><code>sudo apt install php libapache2-mod-php -y
sudo systemctl restart apache2</code></pre>
</div>

<div class="step">
<h3>📌 LANGKAH 7: Aktifkan Modul SSL (HTTPS)</h3>
<pre><code>sudo a2enmod ssl rewrite
sudo systemctl restart apache2</code></pre>
</div>

<div class="step">
<h3>📌 LANGKAH 8: Cek Log Apache</h3>
<pre><code>sudo tail -f /var/log/apache2/access.log
sudo tail -f /var/log/apache2/error.log</code></pre>
</div>

<div class="footer">
Powered by FahTech Installer | Tutorial Apache2 Web Server
</div>
</div>
</body>
</html>
HTML
        
        cat > /etc/apache2/sites-available/$DOMAIN.conf <<EOF
<VirtualHost *:80>
    ServerName $DOMAIN
    ServerAlias www.$DOMAIN
    DocumentRoot /var/www/html/$DOMAIN
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF
        
        a2ensite $DOMAIN.conf
        systemctl reload apache2
        
        echo -e "\n${GREEN}✅ DNS SERVER 3 BERHASIL!${NC}"
        echo -e "   🌐 Akses Web: http://$DOMAIN"
        echo -e "\n${YELLOW}💡 Tambahkan ke file hosts:${NC}"
        echo -e "   echo '$IP $DOMAIN' >> /etc/hosts"
    fi
    read -p "Tekan Enter..."
}

# ======================= MENU UTAMA =======================
while true; do
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║       🚀 FAHTECH - 3 DNS SERVER dengan 3 TAMPILAN WEB           ║"
    echo "║         DNS1: Tutorial DHCP | DNS2: Tutorial CRUD               ║"
    echo "║               DNS3: Tutorial Apache2                            ║"
    echo "╠══════════════════════════════════════════════════════════════════╣"
    echo "║                                                                  ║"
    echo "║  1.  🔍 Install DNS Server 1 (Tutorial DHCP - Tampilan Web)      ║"
    echo "║  2.  🗄️ Install DNS Server 2 (Tutorial CRUD - Tampilan Web)      ║"
    echo "║  3.  🌍 Install DNS Server 3 (Tutorial Apache2 - Tampilan Web)   ║"
    echo "║  4.  🚪 Exit                                                     ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    read -p "👉 Pilih menu [1-4]: " menu
    
    case $menu in
        1) install_dns1 ;;
        2) install_dns2 ;;
        3) install_dns3 ;;
        4) 
            echo -e "${GREEN}👋 Terima kasih!${NC}"
            exit 0
            ;;
        *) 
            echo -e "${RED}❌ Pilihan salah!${NC}"
            sleep 1
            ;;
    esac
done
