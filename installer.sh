#!/bin/bash

# ============================================================
#   FAHTECH - MULTI-SERVICE INSTALLER PRO v4.0
#   SEMUA OTOMATIS | TINGGAL PILIH NOMOR
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Header
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

# Cek root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ Jalankan sebagai root!${NC}"
    exit 1
fi

# ============================================================
# DETEKSI INTERFACE OTOMATIS
# ============================================================
detect_interfaces() {
    INTERFACES=()
    INTERFACE_LIST=()
    
    for iface in $(ls /sys/class/net/ | grep -v lo); do
        IP=$(ip -4 addr show $iface 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n1)
        if [[ -n $IP ]]; then
            INTERFACES+=("$iface|$IP")
            INTERFACE_LIST+=("$iface")
        fi
    done
}

# Tampilkan pilihan interface
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
# 1. INSTALL DHCP - OTOMATIS DETEKSI
# ============================================================
install_dhcp() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         🌐 INSTALL DHCP SERVER                  ║${NC}"
    echo -e "${GREEN}║         (Otomatis Deteksi Interface)            ║${NC}"
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
        
        echo -e "\n${YELLOW}Apakah ingin mengubah konfigurasi? (y/n):${NC}"
        read -p "" edit_confirm
        
        if [[ "$edit_confirm" == "y" ]]; then
            echo -n "Subnet (Enter untuk default $SUBNET): "
            read input_subnet
            SUBNET=${input_subnet:-$SUBNET}
            
            echo -n "Gateway (Enter untuk default $GATEWAY): "
            read input_gateway
            GATEWAY=${input_gateway:-$GATEWAY}
            
            echo -n "Range Mulai (Enter untuk default $RANGE_START): "
            read input_start
            RANGE_START=${input_start:-$RANGE_START}
            
            echo -n "Range Akhir (Enter untuk default $RANGE_END): "
            read input_end
            RANGE_END=${input_end:-$RANGE_END}
        fi
        
        echo -e "\n${CYAN}📦 Menginstall DHCP Server...${NC}"
        
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
        
        systemctl restart isc-dhcp-server
        systemctl enable isc-dhcp-server
        
        echo -e "\n${GREEN}✅ DHCP BERHASIL!${NC}"
        echo -e "   Interface: $SELECTED_IFACE"
        echo -e "   Subnet: $SUBNET/24"
        
    else
        echo -e "${RED}❌ Pilihan salah!${NC}"
    fi
    
    echo -e "\n${YELLOW}Tekan Enter untuk kembali...${NC}"
    read
}

# ============================================================
# 2. INSTALL DNS - OTOMATIS DETEKSI
# ============================================================
install_dns() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         🔍 INSTALL DNS SERVER                   ║${NC}"
    echo -e "${GREEN}║         (Domain & IP Otomatis)                 ║${NC}"
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
# 3. INSTALL APACHE2
# ============================================================
install_apache2() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         🌍 INSTALL APACHE2                      ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
    apt update -qq
    apt install apache2 php libapache2-mod-php -y -qq
    
    SERVER_IP=$(hostname -I | awk '{print $1}')
    
    cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html>
<head><title>FahTech Server</title>
<style>
body { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); font-family: Arial; text-align: center; padding: 50px; }
h1 { color: white; font-size: 48px; }
.status { background: #4CAF50; padding: 10px; border-radius: 10px; color: white; }
</style>
</head>
<body>
<h1>⚡ FAHTECH SERVER ⚡</h1>
<div class="status">✅ SERVER BERJALAN DENGAN BAIK</div>
<p style="color:white;">Server IP: <?php echo \$_SERVER['SERVER_ADDR']; ?></p>
<p style="color:white;">Powered by FahTech Auto Installer</p>
</body>
</html>
EOF
    
    systemctl restart apache2
    
    echo -e "\n${GREEN}✅ APACHE2 BERHASIL!${NC}"
    echo -e "   Akses: http://$SERVER_IP"
    
    echo -e "\n${YELLOW}Tekan Enter untuk kembali...${NC}"
    read
}

# ============================================================
# 4. INSTALL FTP
# ============================================================
install_ftp() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         📁 INSTALL FTP SERVER                  ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
    apt install vsftpd -y -qq
    systemctl restart vsftpd
    systemctl enable vsftpd
    
    SERVER_IP=$(hostname -I | awk '{print $1}')
    
    echo -e "\n${GREEN}✅ FTP BERHASIL!${NC}"
    echo -e "   Server: $SERVER_IP"
    
    echo -e "\n${YELLOW}Tekan Enter untuk kembali...${NC}"
    read
}

# ============================================================
# 5. INSTALL SAMBA
# ============================================================
install_samba() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         🖥️  INSTALL SAMBA                      ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
    echo -n "📝 Nama share (Enter untuk 'public'): "
    read share_name
    share_name=${share_name:-public}
    
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
    
    SERVER_IP=$(hostname -I | awk '{print $1}')
    
    echo -e "\n${GREEN}✅ SAMBA BERHASIL!${NC}"
    echo -e "   Akses: //$SERVER_IP/$share_name"
    
    echo -e "\n${YELLOW}Tekan Enter untuk kembali...${NC}"
    read
}

# ============================================================
# 6. INSTALL MAIL SERVER
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
    
    apt install postfix dovecot-core dovecot-imapd -y -qq
    
    systemctl restart postfix dovecot
    systemctl enable postfix dovecot
    
    echo -e "\n${GREEN}✅ MAIL SERVER BERHASIL!${NC}"
    
    echo -e "\n${YELLOW}Tekan Enter untuk kembali...${NC}"
    read
}

# ============================================================
# 7. INSTALL WORDPRESS
# ============================================================
install_wordpress() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         📝 INSTALL WORDPRESS                   ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
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
# 8. INSTALL CRUD WEB
# ============================================================
install_crud() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         🗄️  INSTALL CRUD WEB                   ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
    apt install php-sqlite3 -y -qq
    
    mkdir -p /var/www/html/crud
    
    cat > /var/www/html/crud/index.php <<'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>FahTech CRUD</title>
    <style>
        body { background: #f0f2f5; font-family: Arial; padding: 40px; }
        .container { max-width: 800px; margin: auto; background: white; border-radius: 15px; padding: 30px; }
        h1 { color: #667eea; }
        form { display: flex; gap: 10px; margin-bottom: 20px; }
        input { flex: 1; padding: 10px; border: 1px solid #ddd; border-radius: 5px; }
        button { background: #667eea; color: white; padding: 10px 20px; border: none; border-radius: 5px; cursor: pointer; }
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
        .delete { color: red; text-decoration: none; }
    </style>
</head>
<body>
<div class="container">
    <h1>⚡ FahTech CRUD App</h1>
    <?php
    $db = new SQLite3('/var/www/html/crud/data.db');
    $db->exec("CREATE TABLE IF NOT EXISTS items (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, created_at DATETIME DEFAULT CURRENT_TIMESTAMP)");
    if (isset($_POST['add']) && !empty($_POST['name'])) {
        $name = SQLite3::escapeString($_POST['name']);
        $db->exec("INSERT INTO items (name) VALUES ('$name')");
        echo "<p style='color:green'>✅ Berhasil!</p>";
    }
    if (isset($_GET['delete'])) {
        $id = (int)$_GET['delete'];
        $db->exec("DELETE FROM items WHERE id = $id");
    }
    $result = $db->query("SELECT * FROM items ORDER BY id DESC");
    ?>
    <form method="post">
        <input type="text" name="name" placeholder="Nama item..." required>
        <button type="submit" name="add">Tambah</button>
    </form>
    <h2>Data Items</h2>
    <table><tr><th>ID</th><th>Nama</th><th>Tanggal</th><th>Aksi</th></tr>
    <?php while ($row = $result->fetchArray()): ?>
    <tr><td><?= $row['id'] ?></td><td><?= htmlspecialchars($row['name']) ?></td><td><?= $row['created_at'] ?></td><td><a href="?delete=<?= $row['id'] ?>" class="delete">Hapus</a></td></tr>
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
# 9. INSTALL SEMUA
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
        
        echo -e "\n${GREEN}✅ SEMUA SERVICE BERHASIL DIINSTALL!${NC}"
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
    echo "║  3. 🔍 Install DNS Server                                 ║"
    echo "║  4. 🌍 Install Apache2 + Landing Page                     ║"
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
