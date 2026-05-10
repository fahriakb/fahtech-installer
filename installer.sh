#!/bin/bash

# ============================================================
#   FAHTECH - MULTI-SERVICE INSTALLER PRO v5.0
#   TAMPILAN WEB SUPER KEREN!
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "${CYAN}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║   ███████╗ █████╗ ██╗  ██╗████████╗███████╗ ██████╗██╗  ██╗║"
echo "║   ██╔════╝██╔══██╗██║  ██║╚══██╔══╝██╔════╝██╔════╝██║  ██║║"
echo "║   █████╗  ███████║███████║   ██║   █████╗  ██║     ███████║║"
echo "║   ██╔══╝  ██╔══██║██╔══██║   ██║   ██╔══╝  ██║     ██╔══██║║"
echo "║   ██║     ██║  ██║██║  ██║   ██║   ███████╗╚██████╗██║  ██║║"
echo "║   ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝ ╚═════╝╚═╝  ╚═╝║"
echo "║                                                           ║"
echo "║        AUTO INSTALLER PROFESSIONAL - PLUG AND PLAY        ║"
echo "║              TINGGAL PILIH, SEMUA OTOMATIS                ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ Jalankan sebagai root!${NC}"
    exit 1
fi

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
    echo -e "\n${GREEN}📡 Network Interface yang terdeteksi:${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    for i in "${!INTERFACES[@]}"; do
        IFS='|' read -r iface ip <<< "${INTERFACES[$i]}"
        echo -e "  ${YELLOW}$((i+1))${NC}. ${CYAN}$iface${NC} → IP: ${GREEN}$ip${NC}"
    done
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# ============================================================
# INSTALL APACHE2 DENGAN TAMPILAN SUPER KEREN
# ============================================================
install_apache2() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         🌍 INSTALL APACHE2 + LANDING PAGE      ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
    apt update -qq
    apt install apache2 php libapache2-mod-php -y -qq
    
    SERVER_IP=$(hostname -I | awk '{print $1}')
    UPTIME=$(uptime -p | sed 's/up //')
    LOAD=$(uptime | awk -F'load average:' '{print $2}' | cut -d, -f1)
    
    cat > /var/www/html/index.html <<'EOF'
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>FahTech | Professional Server Solutions</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', 'Poppins', Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            position: relative;
            overflow-x: hidden;
        }
        
        /* Animasi background */
        @keyframes float {
            0%, 100% { transform: translateY(0px); }
            50% { transform: translateY(-20px); }
        }
        
        @keyframes pulse {
            0%, 100% { opacity: 0.3; }
            50% { opacity: 0.8; }
        }
        
        .bg-animation {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            overflow: hidden;
            z-index: 0;
        }
        
        .bg-animation div {
            position: absolute;
            display: block;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 50%;
            animation: float linear infinite;
        }
        
        /* Container utama */
        .container {
            position: relative;
            z-index: 1;
            max-width: 1200px;
            margin: 0 auto;
            padding: 40px 20px;
        }
        
        /* Card utama */
        .main-card {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(10px);
            border-radius: 30px;
            padding: 50px;
            text-align: center;
            box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
            transition: transform 0.3s ease;
        }
        
        .main-card:hover {
            transform: translateY(-5px);
        }
        
        /* Logo dan judul */
        .logo {
            font-size: 80px;
            margin-bottom: 20px;
            animation: pulse 2s infinite;
        }
        
        h1 {
            font-size: 56px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
            margin-bottom: 10px;
        }
        
        .tagline {
            font-size: 20px;
            color: #666;
            margin-bottom: 30px;
        }
        
        /* Status card */
        .status-card {
            background: linear-gradient(135deg, #4CAF50 0%, #45a049 100%);
            color: white;
            padding: 15px 30px;
            border-radius: 50px;
            display: inline-block;
            margin: 20px 0;
            font-weight: bold;
            animation: pulse 2s infinite;
        }
        
        /* Info server */
        .server-info {
            background: #f8f9fa;
            border-radius: 20px;
            padding: 20px;
            margin: 30px 0;
            display: flex;
            justify-content: space-around;
            flex-wrap: wrap;
            gap: 20px;
        }
        
        .info-item {
            text-align: center;
        }
        
        .info-icon {
            font-size: 30px;
            margin-bottom: 10px;
        }
        
        .info-label {
            font-size: 12px;
            color: #888;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        
        .info-value {
            font-size: 18px;
            font-weight: bold;
            color: #333;
        }
        
        /* Services grid */
        .services-title {
            font-size: 28px;
            margin: 40px 0 20px;
            color: #333;
        }
        
        .services-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin: 30px 0;
        }
        
        .service-card {
            background: white;
            padding: 25px;
            border-radius: 20px;
            text-align: center;
            transition: all 0.3s ease;
            cursor: pointer;
            border: 1px solid #eee;
            box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
        }
        
        .service-card:hover {
            transform: translateY(-10px);
            box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
            border-color: #667eea;
        }
        
        .service-icon {
            font-size: 48px;
            margin-bottom: 15px;
        }
        
        .service-name {
            font-size: 18px;
            font-weight: bold;
            color: #333;
            margin-bottom: 5px;
        }
        
        .service-desc {
            font-size: 12px;
            color: #888;
        }
        
        /* Footer */
        .footer {
            margin-top: 50px;
            padding-top: 20px;
            border-top: 1px solid #eee;
            color: #888;
            font-size: 12px;
        }
        
        /* Responsive */
        @media (max-width: 768px) {
            .main-card {
                padding: 30px 20px;
            }
            h1 {
                font-size: 36px;
            }
            .logo {
                font-size: 50px;
            }
            .server-info {
                flex-direction: column;
            }
            .services-grid {
                grid-template-columns: repeat(2, 1fr);
                gap: 15px;
            }
        }
    </style>
</head>
<body>
    <div class="bg-animation" id="bgAnimation"></div>
    
    <div class="container">
        <div class="main-card">
            <div class="logo">⚡</div>
            <h1>FAHTECH</h1>
            <div class="tagline">Professional Server Solutions</div>
            
            <div class="status-card">
                🟢 SERVER BERJALAN DENGAN BAIK
            </div>
            
            <div class="server-info">
                <div class="info-item">
                    <div class="info-icon">🌐</div>
                    <div class="info-label">Server IP</div>
                    <div class="info-value"><?php echo $_SERVER['SERVER_ADDR']; ?></div>
                </div>
                <div class="info-item">
                    <div class="info-icon">⏱️</div>
                    <div class="info-label">Uptime</div>
                    <div class="info-value"><?php echo shell_exec("uptime -p | sed 's/up //'"); ?></div>
                </div>
                <div class="info-item">
                    <div class="info-icon">📊</div>
                    <div class="info-label">Server Load</div>
                    <div class="info-value"><?php $load = sys_getloadavg(); echo $load[0]; ?></div>
                </div>
            </div>
            
            <div class="services-title">🚀 Available Services</div>
            
            <div class="services-grid">
                <div class="service-card">
                    <div class="service-icon">🌍</div>
                    <div class="service-name">Apache2</div>
                    <div class="service-desc">Web Server</div>
                </div>
                <div class="service-card">
                    <div class="service-icon">📁</div>
                    <div class="service-name">FTP</div>
                    <div class="service-desc">File Transfer</div>
                </div>
                <div class="service-card">
                    <div class="service-icon">🔍</div>
                    <div class="service-name">DNS</div>
                    <div class="service-desc">Domain Resolver</div>
                </div>
                <div class="service-card">
                    <div class="service-icon">💾</div>
                    <div class="service-name">Samba</div>
                    <div class="service-desc">File Sharing</div>
                </div>
                <div class="service-card">
                    <div class="service-icon">📧</div>
                    <div class="service-name">Mail</div>
                    <div class="service-desc">Email Server</div>
                </div>
                <div class="service-card">
                    <div class="service-icon">📝</div>
                    <div class="service-name">WordPress</div>
                    <div class="service-desc">CMS</div>
                </div>
                <div class="service-card">
                    <div class="service-icon">🗄️</div>
                    <div class="service-name">CRUD</div>
                    <div class="service-desc">Database App</div>
                </div>
                <div class="service-card">
                    <div class="service-icon">⚙️</div>
                    <div class="service-name">Auto Install</div>
                    <div class="service-desc">One Click Setup</div>
                </div>
            </div>
            
            <div class="footer">
                Powered by <strong>FahTech Auto Installer v5.0</strong> | &copy; 2026
            </div>
        </div>
    </div>
    
    <script>
        // Animasi background
        const bgAnimation = document.getElementById('bgAnimation');
        const elements = ['✨', '⭐', '🌟', '💫', '⚡'];
        
        for (let i = 0; i < 50; i++) {
            const div = document.createElement('div');
            div.innerHTML = elements[Math.floor(Math.random() * elements.length)];
            div.style.left = Math.random() * 100 + '%';
            div.style.animationDuration = Math.random() * 10 + 5 + 's';
            div.style.animationDelay = Math.random() * 5 + 's';
            div.style.fontSize = Math.random() * 20 + 10 + 'px';
            div.style.opacity = Math.random() * 0.3 + 0.1;
            div.style.position = 'absolute';
            div.style.animation = 'float ' + (Math.random() * 10 + 5) + 's linear infinite';
            bgAnimation.appendChild(div);
        }
    </script>
</body>
</html>
EOF
    
    systemctl restart apache2
    
    echo -e "\n${GREEN}✅ APACHE2 + LANDING PAGE KEREN BERHASIL!${NC}"
    echo -e "${GREEN}   🌐 Akses: http://$SERVER_IP${NC}"
    echo -e "\n${YELLOW}Tekan Enter untuk kembali...${NC}"
    read
}

# ============================================================
# INSTALL DHCP
# ============================================================
install_dhcp() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         🌐 INSTALL DHCP SERVER                  ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
    show_interfaces
    
    echo -e "\n${YELLOW}👉 Pilih interface untuk DHCP:${NC}"
    read -p "Masukkan nomor: " choice
    
    if [[ $choice -ge 1 && $choice -le ${#INTERFACES[@]} ]]; then
        IFS='|' read -r SELECTED_IFACE SELECTED_IP <<< "${INTERFACES[$((choice-1))]}"
        echo -e "${GREEN}✅ Terpilih: $SELECTED_IFACE (IP: $SELECTED_IP)${NC}"
        
        SUBNET=$(echo $SELECTED_IP | cut -d. -f1-3).0
        GATEWAY=$(echo $SELECTED_IP | cut -d. -f1-3).1
        RANGE_START=$(echo $SELECTED_IP | cut -d. -f1-3).100
        RANGE_END=$(echo $SELECTED_IP | cut -d. -f1-3).200
        
        echo -e "\n${YELLOW}📝 Konfigurasi otomatis:${NC}"
        echo -e "   Subnet: ${GREEN}$SUBNET${NC}"
        echo -e "   Gateway: ${GREEN}$GATEWAY${NC}"
        echo -e "   Range IP: ${GREEN}$RANGE_START - $RANGE_END${NC}"
        
        apt update -qq
        apt install isc-dhcp-server -y -qq
        
        cat > /etc/default/isc-dhcp-server <<EOF
INTERFACESv4="$SELECTED_IFACE"
INTERFACESv6=""
EOF
        
        cat > /etc/dhcp/dhcpd.conf <<EOF
subnet $SUBNET netmask 255.255.255.0 {
    range $RANGE_START $RANGE_END;
    option routers $GATEWAY;
    option domain-name-servers 8.8.8.8, 8.8.4.4;
    default-lease-time 600;
    max-lease-time 7200;
}
EOF
        
        systemctl restart isc-dhcp-server 2>/dev/null
        systemctl enable isc-dhcp-server 2>/dev/null
        
        echo -e "\n${GREEN}✅ DHCP BERHASIL!${NC}"
    else
        echo -e "${RED}❌ Pilihan salah!${NC}"
    fi
    
    echo -e "\n${YELLOW}Tekan Enter untuk kembali...${NC}"
    read
}

# ============================================================
# INSTALL DNS (dengan perbaikan systemd)
# ============================================================
install_dns() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         🔍 INSTALL DNS SERVER                   ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
    show_interfaces
    
    echo -e "\n${YELLOW}👉 Pilih interface untuk DNS Server:${NC}"
    read -p "Masukkan nomor: " choice
    
    if [[ $choice -ge 1 && $choice -le ${#INTERFACES[@]} ]]; then
        IFS='|' read -r DNS_IFACE DNS_IP <<< "${INTERFACES[$((choice-1))]}"
        echo -e "${GREEN}✅ Terpilih: $DNS_IFACE (IP: $DNS_IP)${NC}"
        
        echo -e "\n${YELLOW}📝 Masukkan nama domain:${NC}"
        read -p "Domain (contoh: fahtech.com): " DOMAIN_NAME
        
        apt update -qq
        apt install bind9 bind9utils -y -qq
        
        cat > /etc/bind/named.conf.local <<EOF
zone "$DOMAIN_NAME" {
    type master;
    file "/etc/bind/db.$DOMAIN_NAME";
};
EOF
        
        cat > /etc/bind/db.$DOMAIN_NAME <<EOF
\$TTL    604800
@       IN      SOA     ns1.$DOMAIN_NAME. admin.$DOMAIN_NAME. (
                  2026010501         ; Serial
                  604800         ; Refresh
                  86400         ; Retry
                  2419200        ; Expire
                  604800 )       ; Negative Cache TTL
;
@       IN      NS      ns1.$DOMAIN_NAME.
@       IN      A       $DNS_IP
@       IN      MX 10   mail.$DOMAIN_NAME.
ns1     IN      A       $DNS_IP
www     IN      A       $DNS_IP
mail    IN      A       $DNS_IP
EOF
        
        systemctl unmask bind9 2>/dev/null
        systemctl restart bind9
        systemctl enable bind9
        
        echo -e "\n${GREEN}✅ DNS BERHASIL!${NC}"
        echo -e "   Domain: $DOMAIN_NAME"
        echo -e "   IP: $DNS_IP"
    else
        echo -e "${RED}❌ Pilihan salah!${NC}"
    fi
    
    echo -e "\n${YELLOW}Tekan Enter untuk kembali...${NC}"
    read
}

# ============================================================
# INSTALL FTP
# ============================================================
install_ftp() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         📁 INSTALL FTP SERVER                  ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
    apt update -qq
    apt install vsftpd -y -qq
    systemctl restart vsftpd
    systemctl enable vsftpd
    
    echo -e "\n${GREEN}✅ FTP BERHASIL!${NC}"
    echo -e "\n${YELLOW}Tekan Enter untuk kembali...${NC}"
    read
}

# ============================================================
# INSTALL SAMBA
# ============================================================
install_samba() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         🖥️  INSTALL SAMBA                      ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
    echo -n "📝 Nama share (Enter untuk 'public'): "
    read share_name
    share_name=${share_name:-public}
    
    apt update -qq
    apt install samba -y -qq
    
    mkdir -p /home/share
    chmod 777 /home/share
    
    cat >> /etc/samba/smb.conf <<EOF

[$share_name]
   path = /home/share
   browseable = yes
   writable = yes
   guest ok = yes
   public = yes
   create mask = 0777
   directory mask = 0777
EOF
    
    systemctl restart smbd
    systemctl enable smbd
    
    echo -e "\n${GREEN}✅ SAMBA BERHASIL!${NC}"
    echo -e "\n${YELLOW}Tekan Enter untuk kembali...${NC}"
    read
}

# ============================================================
# INSTALL MAIL SERVER
# ============================================================
install_mail() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         📧 INSTALL MAIL SERVER                 ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
    echo -n "📝 Domain untuk email: "
    read mail_domain
    
    debconf-set-selections <<EOF
postfix postfix/mailname string $mail_domain
postfix postfix/main_mailer_type string 'Internet Site'
EOF
    
    apt update -qq
    apt install postfix dovecot-core dovecot-imapd -y -qq
    
    systemctl restart postfix dovecot
    systemctl enable postfix dovecot
    
    echo -e "\n${GREEN}✅ MAIL SERVER BERHASIL!${NC}"
    echo -e "\n${YELLOW}Tekan Enter untuk kembali...${NC}"
    read
}

# ============================================================
# INSTALL WORDPRESS
# ============================================================
install_wordpress() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         📝 INSTALL WORDPRESS                   ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
    apt update -qq
    apt install mariadb-server php php-mysql php-curl php-gd php-xml php-mbstring php-zip unzip wget -y -qq
    
    systemctl restart mariadb
    
    DB_PASS=$(openssl rand -base64 12 | tr -d "=/+" | cut -c1-16)
    
    mysql <<MYSQL_SCRIPT
CREATE DATABASE IF NOT EXISTS wordpress;
CREATE USER IF NOT EXISTS 'wpuser'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT
    
    cd /tmp
    wget -q https://wordpress.org/latest.tar.gz
    tar -xzf latest.tar.gz
    cp -r wordpress/* /var/www/html/
    cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
    
    sed -i "s/database_name_here/wordpress/" /var/www/html/wp-config.php
    sed -i "s/username_here/wpuser/" /var/www/html/wp-config.php
    sed -i "s/password_here/$DB_PASS/" /var/www/html/wp-config.php
    
    chown -R www-data:www-data /var/www/html/
    systemctl restart apache2
    
    SERVER_IP=$(hostname -I | awk '{print $1}')
    
    echo -e "\n${GREEN}✅ WORDPRESS BERHASIL!${NC}"
    echo -e "   🔗 Akses: http://$SERVER_IP/wp-admin/install.php"
    echo -e "   🔑 DB Pass: $DB_PASS"
    echo -e "\n${YELLOW}Tekan Enter untuk kembali...${NC}"
    read
}

# ============================================================
# INSTALL CRUD WEB
# ============================================================
install_crud() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         🗄️  INSTALL CRUD WEB                   ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
    apt update -qq
    apt install php-sqlite3 -y -qq
    
    mkdir -p /var/www/html/crud
    
    cat > /var/www/html/crud/index.php <<'EOF'
<!DOCTYPE html>
<html>
<head><title>FahTech CRUD</title>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
* { margin: 0; padding: 0; box-sizing: border-box; }
body { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); font-family: 'Segoe UI', Arial, sans-serif; min-height: 100vh; padding: 40px; }
.container { max-width: 800px; margin: auto; background: white; border-radius: 20px; padding: 30px; box-shadow: 0 20px 60px rgba(0,0,0,0.3); }
h1 { color: #667eea; margin-bottom: 10px; }
form { display: flex; gap: 10px; margin: 20px 0; }
input { flex: 1; padding: 12px; border: 1px solid #ddd; border-radius: 10px; font-size: 16px; }
button { background: #667eea; color: white; border: none; padding: 12px 24px; border-radius: 10px; cursor: pointer; font-size: 16px; }
button:hover { background: #5a67d8; }
table { width: 100%; border-collapse: collapse; margin-top: 20px; }
th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
th { background: #667eea; color: white; }
.delete { color: #e74c3c; text-decoration: none; font-weight: bold; }
.delete:hover { text-decoration: underline; }
.success { background: #d4edda; color: #155724; padding: 12px; border-radius: 10px; margin: 10px 0; }
</style>
</head>
<body>
<div class="container">
<h1>⚡ FahTech CRUD Application</h1>
<p>Sistem Manajemen Data Sederhana dengan SQLite</p>
<?php
$db = new SQLite3('/var/www/html/crud/data.db');
$db->exec("CREATE TABLE IF NOT EXISTS items (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, created_at DATETIME DEFAULT CURRENT_TIMESTAMP)");
if (isset($_POST['add']) && !empty($_POST['name'])) {
    $name = SQLite3::escapeString($_POST['name']);
    $db->exec("INSERT INTO items (name) VALUES ('$name')");
    echo "<div class='success'>✅ Data berhasil ditambahkan!</div>";
}
if (isset($_GET['delete'])) {
    $id = (int)$_GET['delete'];
    $db->exec("DELETE FROM items WHERE id = $id");
    echo "<div class='success'>✅ Data berhasil dihapus!</div>";
}
$result = $db->query("SELECT * FROM items ORDER BY id DESC");
?>
<form method="post">
    <input type="text" name="name" placeholder="Masukkan nama item..." required>
    <button type="submit" name="add">➕ Tambah Data</button>
</form>
<h2>📋 Daftar Items</h2>
<table>
<tr><th>ID</th><th>Nama Item</th><th>Tanggal Dibuat</th><th>Aksi</th></tr>
<?php while ($row = $result->fetchArray()): ?>
<tr>
<td><?= $row['id'] ?></td>
<td><?= htmlspecialchars($row['name']) ?></td>
<td><?= $row['created_at'] ?></td>
<td><a href="?delete=<?= $row['id'] ?>" class="delete" onclick="return confirm('Yakin hapus data ini?')">🗑️ Hapus</a></td>
</tr>
<?php endwhile; ?>
</table>
</div>
</body>
</html>
EOF
    
    chown -R www-data:www-data /var/www/html/crud
    systemctl restart apache2
    
    SERVER_IP=$(hostname -I | awk '{print $1}')
    
    echo -e "\n${GREEN}✅ CRUD WEB BERHASIL!${NC}"
    echo -e "   🔗 Akses: http://$SERVER_IP/crud/"
    echo -e "\n${YELLOW}Tekan Enter untuk kembali...${NC}"
    read
}

# ============================================================
# INSTALL SEMUA
# ============================================================
install_all() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║      ⚡ INSTALL SEMUA SERVICE                  ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${YELLOW}Mulai install semua service? (y/n):${NC}"
    read confirm
    
    if [[ "$confirm" == "y" ]]; then
        install_apache2
        install_dhcp
        install_dns
        install_ftp
        install_samba
        install_mail
        install_wordpress
        install_crud
        
        SERVER_IP=$(hostname -I | awk '{print $1}')
        echo -e "\n${GREEN}╔════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║   ✅ SEMUA SERVICE BERHASIL DIINSTALL!        ║${NC}"
        echo -e "${GREEN}║   🌐 Landing Page: http://$SERVER_IP          ║${NC}"
        echo -e "${GREEN}║   📝 WordPress: http://$SERVER_IP/wp-admin   ║${NC}"
        echo -e "${GREEN}║   🗄️  CRUD App: http://$SERVER_IP/crud/      ║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    fi
    
    echo -e "\n${YELLOW}Tekan Enter untuk kembali...${NC}"
    read
}

# ============================================================
# MENU UTAMA
# ============================================================
while true; do
    clear
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║            🚀 FAHTECH MULTI-SERVICE INSTALLER              ║"
    echo "║         ⚡ PLUG AND PLAY | TINGGAL PILIH NOMOR ⚡          ║"
    echo "╠════════════════════════════════════════════════════════════╣"
    echo "║  1. ⚡ Install SEMUA Service                               ║"
    echo "║  2. 🌐 Install DHCP Server (Otomatis Deteksi Interface)    ║"
    echo "║  3. 🔍 Install DNS Server (Fix Systemd)                    ║"
    echo "║  4. 🌍 Install Apache2 + Landing Page SUPER KEREN          ║"
    echo "║  5. 📁 Install FTP Server                                 ║"
    echo "║  6. 🖥️  Install Samba File Server                         ║"
    echo "║  7. 📧 Install Mail Server                                ║"
    echo "║  8. 📝 Install WordPress + Database Auto Setup            ║"
    echo "║  9. 🗄️  Install CRUD Web                                  ║"
    echo "║  10. 🚪 Exit                                              ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    read -p "👉 Pilih menu [1-10]: " menu
    
    case $menu in
        1) install_all ;;
        2) install_dhcp ;;
        3) install_dns ;;
        4) install_apache2 ;;
        5) install_ftp ;;
        6) install_samba ;;
        7) install_mail ;;
        8) install_wordpress ;;
        9) install_crud ;;
        10) 
            echo -e "${GREEN}👋 Terima kasih!${NC}"
            exit 0
            ;;
        *) 
            echo -e "${RED}❌ Pilihan salah!${NC}"
            sleep 1
            ;;
    esac
done
