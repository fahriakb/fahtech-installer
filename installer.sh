#!/bin/bash

# ============================================================
#   FAHTECH - MULTI-SERVICE INSTALLER PRO v20.0
#   3 DNS SERVER | 3 TAMPILAN BERBEDA | BISA AKSES WEB
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
echo "║              MULTI-SERVICE INSTALLER PROFESSIONAL v20.0                      ║"
echo "║              3 DNS SERVER | 3 TAMPILAN BERBEDA | BISA AKSES WEB             ║"
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

# ======================= FUNGSI CLEAN DNS =======================
clean_dns() {
    echo -e "${YELLOW}🧹 Membersihkan DNS lama...${NC}"
    systemctl stop bind9 2>/dev/null
    systemctl disable bind9 2>/dev/null
    rm -f /etc/systemd/system/bind9.service 2>/dev/null
    rm -f /etc/systemd/system/multi-user.target.wants/bind9.service 2>/dev/null
    systemctl daemon-reload 2>/dev/null
    apt remove --purge -y bind9 bind9utils 2>/dev/null
    rm -rf /etc/bind 2>/dev/null
    rm -rf /var/lib/bind 2>/dev/null
    rm -rf /var/cache/bind 2>/dev/null
}

# ======================= INSTALL DNS 1 (Tutorial DHCP) =======================
install_dns1() {
    clear
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║           🔍 DNS SERVER 1 - TUTORIAL DHCP SERVER                 ║${NC}"
    echo -e "${BLUE}║           📖 Tutorial Membuat DHCP Server di Debian              ║${NC}"
    echo -e "${BLUE}║           🌐 Bisa diakses via browser                            ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
    
    show_interfaces
    echo -e "\n${YELLOW}👉 Pilih interface untuk DNS Server 1:${NC}"
    read -p "Nomor [1-${#INTERFACES[@]}]: " choice
    
    if [[ $choice -ge 1 && $choice -le ${#INTERFACES[@]} ]]; then
        IFS='|' read -r IFACE IP <<< "${INTERFACES[$((choice-1))]}"
        
        echo -e "\n${MAGENTA}📝 Masukkan domain untuk DNS Server 1 (contoh: dhcp.fahtech.com):${NC}"
        read -p "Domain: " DOMAIN1
        
        clean_dns
        
        apt update -qq
        apt install -y bind9 bind9utils apache2
        
        mkdir -p /etc/bind /var/lib/bind /var/cache/bind
        chown -R bind:bind /var/lib/bind /var/cache/bind
        
        cat > /etc/bind/named.conf.local <<EOF
zone "$DOMAIN1" {
    type master;
    file "/etc/bind/db.$DOMAIN1";
};
EOF
        
        cat > /etc/bind/db.$DOMAIN1 <<EOF
\$TTL    604800
@       IN      SOA     ns1.$DOMAIN1. admin.$DOMAIN1. (
                  2026011501         ; Serial
                  604800         ; Refresh
                  86400         ; Retry
                  2419200        ; Expire
                  604800 )       ; Negative Cache TTL
;
@       IN      NS      ns1.$DOMAIN1.
@       IN      A       $IP
@       IN      MX 10   mail.$DOMAIN1.
ns1     IN      A       $IP
www     IN      A       $IP
mail    IN      A       $IP
EOF
        
        cat > /etc/bind/named.conf.options <<EOF
options {
    directory "/var/cache/bind";
    recursion yes;
    allow-query { any; };
    forwarders { 8.8.8.8; 8.8.4.4; };
    dnssec-validation auto;
    listen-on { any; };
    listen-on-v6 { none; };
};
EOF
        
        chown bind:bind /etc/bind/db.$DOMAIN1
        systemctl unmask bind9
        systemctl enable bind9
        systemctl restart bind9
        
        # Buat landing page untuk DNS1
        mkdir -p /var/www/html/$DOMAIN1
        cat > /var/www/html/$DOMAIN1/index.html <<EOF
<!DOCTYPE html>
<html>
<head><title>DNS Server 1 - Tutorial DHCP</title>
<style>
body{background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);font-family:Arial;text-align:center;padding:50px}
.container{background:white;border-radius:20px;padding:40px;max-width:800px;margin:auto}
h1{color:#667eea}
code{background:#f4f4f4;padding:2px 5px;border-radius:3px}
pre{background:#1a1a2e;color:#0f0;padding:15px;border-radius:10px;text-align:left}
</style>
</head>
<body>
<div class="container">
<h1>🔍 DNS SERVER 1 - TUTORIAL DHCP</h1>
<p>Domain: <strong>$DOMAIN1</strong> | IP: <strong>$IP</strong></p>
<hr>
<h2>📖 Tutorial DHCP Server Debian</h2>
<pre>
1. Install DHCP Server:
   sudo apt install isc-dhcp-server -y

2. Konfigurasi interface:
   sudo nano /etc/default/isc-dhcp-server
   INTERFACESv4="$IFACE"

3. Konfigurasi DHCP:
   sudo nano /etc/dhcp/dhcpd.conf
   subnet ${IP%.*}.0 netmask 255.255.255.0 {
       range ${IP%.*}.100 ${IP%.*}.200;
       option routers ${IP%.*}.1;
       option domain-name-servers $IP, 8.8.8.8;
   }

4. Start DHCP Server:
   sudo systemctl restart isc-dhcp-server
   sudo systemctl enable isc-dhcp-server

5. Cek client:
   sudo cat /var/lib/dhcp/dhcpd.leases
</pre>
<p><strong>Akses Webmail nanti:</strong> http://mail.$DOMAIN1/roundcube/</p>
<p>Powered by FahTech Installer v20.0</p>
</div>
</body>
</html>
EOF
        
        echo -e "\n${GREEN}✅ DNS SERVER 1 BERHASIL!${NC}"
        echo -e "   📝 Domain: $DOMAIN1"
        echo -e "   🌐 IP: $IP"
        echo -e "   🌐 Landing Page: http://$DOMAIN1"
        echo -e "   📧 Subdomain mail: mail.$DOMAIN1"
        
        echo "$DOMAIN1" > /etc/dns1_domain.conf
        echo "$IP" > /etc/dns1_ip.conf
    fi
    read -p "Tekan Enter..."
}

# ======================= INSTALL DNS 2 (Tutorial CRUD) =======================
install_dns2() {
    clear
    echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║           🔍 DNS SERVER 2 - TUTORIAL CRUD SISWA                  ║${NC}"
    echo -e "${MAGENTA}║           📖 Tutorial Konfigurasi CRUD Lengkap                   ║${NC}"
    echo -e "${MAGENTA}║           🌐 Bisa diakses via browser                            ║${NC}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════════╝${NC}"
    
    show_interfaces
    echo -e "\n${YELLOW}👉 Pilih interface untuk DNS Server 2:${NC}"
    read -p "Nomor [1-${#INTERFACES[@]}]: " choice
    
    if [[ $choice -ge 1 && $choice -le ${#INTERFACES[@]} ]]; then
        IFS='|' read -r IFACE IP <<< "${INTERFACES[$((choice-1))]}"
        
        echo -e "\n${MAGENTA}📝 Masukkan domain untuk DNS Server 2 (contoh: crud.fahtech.com):${NC}"
        read -p "Domain: " DOMAIN2
        
        clean_dns
        
        apt update -qq
        apt install -y bind9 bind9utils apache2 php-sqlite3
        
        mkdir -p /etc/bind /var/lib/bind /var/cache/bind
        chown -R bind:bind /var/lib/bind /var/cache/bind
        
        cat > /etc/bind/named.conf.local <<EOF
zone "$DOMAIN2" {
    type master;
    file "/etc/bind/db.$DOMAIN2";
};
EOF
        
        cat > /etc/bind/db.$DOMAIN2 <<EOF
\$TTL    604800
@       IN      SOA     ns1.$DOMAIN2. admin.$DOMAIN2. (
                  2026011502         ; Serial
                  604800         ; Refresh
                  86400         ; Retry
                  2419200        ; Expire
                  604800 )       ; Negative Cache TTL
;
@       IN      NS      ns1.$DOMAIN2.
@       IN      A       $IP
@       IN      MX 10   mail.$DOMAIN2.
ns1     IN      A       $IP
www     IN      A       $IP
mail    IN      A       $IP
EOF
        
        cat > /etc/bind/named.conf.options <<EOF
options {
    directory "/var/cache/bind";
    recursion yes;
    allow-query { any; };
    forwarders { 8.8.8.8; 8.8.4.4; };
    dnssec-validation auto;
    listen-on { any; };
    listen-on-v6 { none; };
};
EOF
        
        chown bind:bind /etc/bind/db.$DOMAIN2
        systemctl unmask bind9
        systemctl enable bind9
        systemctl restart bind9
        
        # Buat landing page untuk DNS2
        mkdir -p /var/www/html/$DOMAIN2
        cat > /var/www/html/$DOMAIN2/index.html <<EOF
<!DOCTYPE html>
<html>
<head><title>DNS Server 2 - Tutorial CRUD</title>
<style>
body{background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);font-family:Arial;text-align:center;padding:50px}
.container{background:white;border-radius:20px;padding:40px;max-width:800px;margin:auto}
h1{color:#667eea}
code{background:#f4f4f4;padding:2px 5px;border-radius:3px}
pre{background:#1a1a2e;color:#0f0;padding:15px;border-radius:10px;text-align:left}
table{border-collapse:collapse;width:100%;margin-top:20px}
th,td{border:1px solid #ddd;padding:8px;text-align:left}
th{background:#667eea;color:white}
</style>
</head>
<body>
<div class="container">
<h1>🗄️ DNS SERVER 2 - TUTORIAL CRUD</h1>
<p>Domain: <strong>$DOMAIN2</strong> | IP: <strong>$IP</strong></p>
<hr>
<h2>📖 Tutorial CRUD Siswa Lengkap</h2>
<pre>
1. Install Apache2 & PHP:
   sudo apt install apache2 php libapache2-mod-php php-sqlite3 -y

2. Buat folder CRUD:
   sudo mkdir -p /var/www/html/crud

3. Buat file index.php dengan fitur:
   ➕ CREATE: INSERT INTO siswa (nama, rombel, nis) VALUES (...)
   📖 READ: SELECT * FROM siswa ORDER BY id DESC
   ✏️ UPDATE: UPDATE siswa SET nama='...' WHERE id=...
   🗑️ DELETE: DELETE FROM siswa WHERE id=...
   🔍 SEARCH: SELECT * FROM siswa WHERE nama LIKE '%...%'

4. Akses CRUD:
   http://$DOMAIN2/crud/
</pre>
<h3>📋 Contoh Data Siswa</h3>
<table>
 <tr><th>ID</th><th>Nama</th><th>Rombel</th><th>NIS</th></tr>
 <tr><td>1</td><td>Fahri</td><td>XII RPL 1</td><td>12345</td></tr>
 <tr><td>2</td><td>Admin</td><td>XII RPL 2</td><td>67890</td></tr>
</table>
<p><strong>Akses CRUD:</strong> http://$DOMAIN2/crud/</p>
<p>Powered by FahTech Installer v20.0</p>
</div>
</body>
</html>
EOF
        
        echo -e "\n${GREEN}✅ DNS SERVER 2 BERHASIL!${NC}"
        echo -e "   📝 Domain: $DOMAIN2"
        echo -e "   🌐 IP: $IP"
        echo -e "   🌐 Landing Page: http://$DOMAIN2"
        
        echo "$DOMAIN2" > /etc/dns2_domain.conf
        echo "$IP" > /etc/dns2_ip.conf
    fi
    read -p "Tekan Enter..."
}

# ======================= INSTALL DNS 3 (Tutorial Apache2) =======================
install_dns3() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           🔍 DNS SERVER 3 - TUTORIAL APACHE2                     ║${NC}"
    echo -e "${CYAN}║           📖 Tutorial Konfigurasi Apache2 Web Server             ║${NC}"
    echo -e "${CYAN}║           🌐 Bisa diakses via browser                            ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    
    show_interfaces
    echo -e "\n${YELLOW}👉 Pilih interface untuk DNS Server 3:${NC}"
    read -p "Nomor [1-${#INTERFACES[@]}]: " choice
    
    if [[ $choice -ge 1 && $choice -le ${#INTERFACES[@]} ]]; then
        IFS='|' read -r IFACE IP <<< "${INTERFACES[$((choice-1))]}"
        
        echo -e "\n${CYAN}📝 Masukkan domain untuk DNS Server 3 (contoh: web.fahtech.com):${NC}"
        read -p "Domain: " DOMAIN3
        
        clean_dns
        
        apt update -qq
        apt install -y bind9 bind9utils apache2
        
        mkdir -p /etc/bind /var/lib/bind /var/cache/bind
        chown -R bind:bind /var/lib/bind /var/cache/bind
        
        cat > /etc/bind/named.conf.local <<EOF
zone "$DOMAIN3" {
    type master;
    file "/etc/bind/db.$DOMAIN3";
};
EOF
        
        cat > /etc/bind/db.$DOMAIN3 <<EOF
\$TTL    604800
@       IN      SOA     ns1.$DOMAIN3. admin.$DOMAIN3. (
                  2026011503         ; Serial
                  604800         ; Refresh
                  86400         ; Retry
                  2419200        ; Expire
                  604800 )       ; Negative Cache TTL
;
@       IN      NS      ns1.$DOMAIN3.
@       IN      A       $IP
@       IN      MX 10   mail.$DOMAIN3.
ns1     IN      A       $IP
www     IN      A       $IP
mail    IN      A       $IP
EOF
        
        cat > /etc/bind/named.conf.options <<EOF
options {
    directory "/var/cache/bind";
    recursion yes;
    allow-query { any; };
    forwarders { 8.8.8.8; 8.8.4.4; };
    dnssec-validation auto;
    listen-on { any; };
    listen-on-v6 { none; };
};
EOF
        
        chown bind:bind /etc/bind/db.$DOMAIN3
        systemctl unmask bind9
        systemctl enable bind9
        systemctl restart bind9
        
        # Buat landing page untuk DNS3
        mkdir -p /var/www/html/$DOMAIN3
        cat > /var/www/html/$DOMAIN3/index.html <<EOF
<!DOCTYPE html>
<html>
<head><title>DNS Server 3 - Tutorial Apache2</title>
<style>
body{background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);font-family:Arial;text-align:center;padding:50px}
.container{background:white;border-radius:20px;padding:40px;max-width:800px;margin:auto}
h1{color:#667eea}
code{background:#f4f4f4;padding:2px 5px;border-radius:3px}
pre{background:#1a1a2e;color:#0f0;padding:15px;border-radius:10px;text-align:left}
</style>
</head>
<body>
<div class="container">
<h1>🌍 DNS SERVER 3 - TUTORIAL APACHE2</h1>
<p>Domain: <strong>$DOMAIN3</strong> | IP: <strong>$IP</strong></p>
<hr>
<h2>📖 Tutorial Apache2 Web Server</h2>
<pre>
1. Install Apache2:
   sudo apt install apache2 -y

2. Konfigurasi Virtual Host:
   sudo nano /etc/apache2/sites-available/$DOMAIN3.conf

   <VirtualHost *:80>
       ServerName $DOMAIN3
       ServerAlias www.$DOMAIN3
       DocumentRoot /var/www/html/$DOMAIN3
   </VirtualHost>

3. Aktifkan site:
   sudo a2ensite $DOMAIN3.conf
   sudo a2dissite 000-default.conf
   sudo systemctl reload apache2

4. Buat file index.html:
   sudo mkdir -p /var/www/html/$DOMAIN3
   sudo nano /var/www/html/$DOMAIN3/index.html

5. Install PHP (opsional):
   sudo apt install php libapache2-mod-php -y

6. Aktifkan modul SSL (HTTPS):
   sudo a2enmod ssl rewrite
   sudo systemctl restart apache2
</pre>
<p><strong>Akses website:</strong> http://$DOMAIN3</p>
<p>Powered by FahTech Installer v20.0</p>
</div>
</body>
</html>
EOF
        
        echo -e "\n${GREEN}✅ DNS SERVER 3 BERHASIL!${NC}"
        echo -e "   📝 Domain: $DOMAIN3"
        echo -e "   🌐 IP: $IP"
        echo -e "   🌐 Landing Page: http://$DOMAIN3"
        
        echo "$DOMAIN3" > /etc/dns3_domain.conf
        echo "$IP" > /etc/dns3_ip.conf
    fi
    read -p "Tekan Enter..."
}

# ======================= INSTALL APACHE2 DASAR =======================
install_apache2() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              🌍 INSTALL APACHE2                ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
    apt update -qq
    apt install -y apache2 php libapache2-mod-php php-mysql php-sqlite3 php-curl php-gd php-xml php-mbstring php-zip wget curl unzip
    
    systemctl restart apache2
    echo -e "\n${GREEN}✅ APACHE2 BERHASIL!${NC}"
    read -p "Tekan Enter..."
}

# ======================= INSTALL CRUD SISWA =======================
install_crud() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         🗄️ INSTALL CRUD SISWA                 ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
    apt install -y php-sqlite3
    mkdir -p /var/www/html/crud
    
    cat > /var/www/html/crud/index.php <<'EOF'
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
<table border="1" cellpadding="10" cellspacing="0" width="100%">
<tr><th>Nama</th><th>Rombel</th><th>NIS</th><th>Aksi</th></tr>
<?php while($row=$res->fetchArray()){echo "<tr><td>".$row['nama']."</td><td>".$row['rombel']."</td><td>".$row['nis']."</td><td><a class='edit-btn' href='?edit=".$row['id']."'>Edit</a> <a class='delete-btn' href='?delete=".$row['id']."'>Hapus</a></td></tr>";}?>
</td>
<?php if(isset($_GET['edit'])){$id=(int)$_GET['edit'];$edit=$db->query("SELECT * FROM siswa WHERE id=$id")->fetchArray();if($edit){?>
<h3>Edit Data</h3>
<form method="post"><input type="hidden" name="id" value="<?=$edit['id']?>"><input type="text" name="nama" value="<?=$edit['nama']?>"><input type="text" name="rombel" value="<?=$edit['rombel']?>"><input type="text" name="nis" value="<?=$edit['nis']?>"><button type="submit" name="update">Update</button></form>
<?php }}?>
</div>
</body>
</html>
EOF
    
    chown -R www-data:www-data /var/www/html/crud
    systemctl restart apache2
    
    echo -e "\n${GREEN}✅ CRUD SISWA BERHASIL! Akses: http://$SERVER_IP/crud/${NC}"
    read -p "Tekan Enter..."
}

# ======================= MENU UTAMA =======================
while true; do
    clear
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════════════════════╗"
    echo "║            🚀 FAHTECH MULTI-SERVICE INSTALLER v20.0                        ║"
    echo "║              3 DNS SERVER | 3 TAMPILAN BERBEDA                             ║"
    echo "╠════════════════════════════════════════════════════════════════════════════╣"
    echo "║                                                                             ║"
    echo "║  🌐 DNS SERVER (3 Pilihan dengan Tutorial Berbeda)                         ║"
    echo "║  ───────────────────────────────────────────────────────────────────────── ║"
    echo "║    1.  🔍 DNS Server 1 - Tutorial DHCP (Lengkap + Bisa Akses Web)          ║"
    echo "║    2.  🔍 DNS Server 2 - Tutorial CRUD (Lengkap + Bisa Akses Web)          ║"
    echo "║    3.  🔍 DNS Server 3 - Tutorial Apache2 (Lengkap + Bisa Akses Web)       ║"
    echo "║                                                                             ║"
    echo "║  ⚡ SERVICE LAINNYA                                                        ║"
    echo "║  ───────────────────────────────────────────────────────────────────────── ║"
    echo "║    4.  🌍 Install Apache2 + Landing Page                                   ║"
    echo "║    5.  🗄️ Install CRUD Siswa (Tambah/Edit/Hapus/Cari)                      ║"
    echo "║    6.  🗑️ Hapus SEMUA Service + Folder                                     ║"
    echo "║    7.  📊 Cek Status Service                                               ║"
    echo "║    8.  🚪 Exit                                                             ║"
    echo "╚════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    read -p "👉 Pilih menu [1-8]: " menu
    
    case $menu in
        1) install_dns1 ;;
        2) install_dns2 ;;
        3) install_dns3 ;;
        4) install_apache2 ;;
        5) install_crud ;;
        6)
            echo -e "\n${RED}🗑️ Hapus SEMUA? (y/n):${NC}"
            read confirm
            if [[ "$confirm" == "y" ]]; then
                systemctl stop apache2 bind9 2>/dev/null
                apt remove --purge -y apache2* bind9* php* 2>/dev/null
                rm -rf /etc/apache2 /etc/bind /var/www/html
                apt autoremove --purge -y
                echo -e "${GREEN}✅ SEMUA DIHAPUS!${NC}"
            fi
            read -p "Tekan Enter..."
            ;;
        7)
            clear
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            systemctl is-active --quiet apache2 && echo -e "  🌍 Apache2 | ${GREEN}✅ ACTIVE${NC}" || echo -e "  🌍 Apache2 | ${RED}❌ INACTIVE${NC}"
            systemctl is-active --quiet bind9 && echo -e "  🔍 Bind9   | ${GREEN}✅ ACTIVE${NC}" || echo -e "  🔍 Bind9   | ${RED}❌ INACTIVE${NC}"
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            if [[ -f /etc/dns1_domain.conf ]]; then
                echo -e "DNS1: $(cat /etc/dns1_domain.conf) -> $(cat /etc/dns1_ip.conf)"
            fi
            if [[ -f /etc/dns2_domain.conf ]]; then
                echo -e "DNS2: $(cat /etc/dns2_domain.conf) -> $(cat /etc/dns2_ip.conf)"
            fi
            if [[ -f /etc/dns3_domain.conf ]]; then
                echo -e "DNS3: $(cat /etc/dns3_domain.conf) -> $(cat /etc/dns3_ip.conf)"
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
