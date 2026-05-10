#!/bin/bash

# ============================================================
#   FAHTECH - MULTI-SERVICE INSTALLER PRO v5.0
#   + WEBMAIL ROUNDCUBE (Email Bisa Diakses via Browser)
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
echo "║   ███████╗ █████╗ ██╗  ██╗████████╗███████╗ ██████╗██╗  ██╗║"
echo "║   ██╔════╝██╔══██╗██║  ██║╚══██╔══╝██╔════╝██╔════╝██║  ██║║"
echo "║   █████╗  ███████║███████║   ██║   █████╗  ██║     ███████║║"
echo "║   ██╔══╝  ██╔══██║██╔══██║   ██║   ██╔══╝  ██║     ██╔══██║║"
echo "║   ██║     ██║  ██║██║  ██║   ██║   ███████╗╚██████╗██║  ██║║"
echo "║   ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝ ╚═════╝╚═╝  ╚═╝║"
echo "║               AUTO INSTALLER PROFESSIONAL                  ║"
echo "║              TINGGAL PILIH, SEMUA OTOMATIS                 ║"
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

# ======================= 1. APACHE2 =======================
install_apache2() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         🌍 INSTALL APACHE2 + LANDING PAGE      ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
    apt update -qq
    apt install apache2 php libapache2-mod-php -y -qq
    
    SERVER_IP=$(hostname -I | awk '{print $1}')
    
    cat > /var/www/html/index.html <<'EOF'
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
<p style="color:white;">Server IP: <?php echo $_SERVER['SERVER_ADDR']; ?></p>
<p style="color:white;">Powered by FahTech Auto Installer</p>
</body>
</html>
EOF
    
    systemctl restart apache2
    echo -e "\n${GREEN}✅ APACHE2 BERHASIL! Akses: http://$SERVER_IP${NC}"
    read -p "Tekan Enter..."
}

# ======================= 2. DHCP =======================
install_dhcp() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         🌐 INSTALL DHCP SERVER                  ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    show_interfaces
    read -p "Pilih nomor interface: " choice
    if [[ $choice -ge 1 && $choice -le ${#INTERFACES[@]} ]]; then
        IFS='|' read -r SELECTED_IFACE SELECTED_IP <<< "${INTERFACES[$((choice-1))]}"
        SUBNET=$(echo $SELECTED_IP | cut -d. -f1-3).0
        GATEWAY=$(echo $SELECTED_IP | cut -d. -f1-3).1
        RANGE_START=$(echo $SELECTED_IP | cut -d. -f1-3).100
        RANGE_END=$(echo $SELECTED_IP | cut -d. -f1-3).200
        
        apt install isc-dhcp-server -y -qq
        echo "INTERFACESv4=\"$SELECTED_IFACE\"" > /etc/default/isc-dhcp-server
        cat > /etc/dhcp/dhcpd.conf <<EOF
subnet $SUBNET netmask 255.255.255.0 {
    range $RANGE_START $RANGE_END;
    option routers $GATEWAY;
    option domain-name-servers 8.8.8.8;
}
EOF
        systemctl restart isc-dhcp-server
        echo -e "\n${GREEN}✅ DHCP BERHASIL!${NC}"
    fi
    read -p "Tekan Enter..."
}

# ======================= 3. DNS =======================
install_dns() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         🔍 INSTALL DNS SERVER                   ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    show_interfaces
    read -p "Pilih interface untuk DNS: " choice
    if [[ $choice -ge 1 && $choice -le ${#INTERFACES[@]} ]]; then
        IFS='|' read -r DNS_IFACE DNS_IP <<< "${INTERFACES[$((choice-1))]}"
        read -p "Masukkan Nama Domain (contoh: fahtech.com): " DOMAIN_NAME
        
        apt install bind9 bind9utils -y -qq
        cat > /etc/bind/named.conf.local <<EOF
zone "$DOMAIN_NAME" {
    type master;
    file "/etc/bind/db.$DOMAIN_NAME";
};
EOF
        cat > /etc/bind/db.$DOMAIN_NAME <<EOF
\$TTL    604800
@       IN      SOA     ns1.$DOMAIN_NAME. admin.$DOMAIN_NAME. ( 1 604800 86400 2419200 604800 )
@       IN      NS      ns1.$DOMAIN_NAME.
@       IN      A       $DNS_IP
ns1     IN      A       $DNS_IP
www     IN      A       $DNS_IP
mail    IN      A       $DNS_IP
EOF
        systemctl unmask bind9
        systemctl restart bind9
        systemctl enable bind9
        echo -e "\n${GREEN}✅ DNS BERHASIL! Domain: $DOMAIN_NAME -> $DNS_IP${NC}"
    fi
    read -p "Tekan Enter..."
}

# ======================= 4. FTP =======================
install_ftp() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         📁 INSTALL FTP SERVER                  ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    apt install vsftpd -y -qq
    systemctl restart vsftpd
    echo -e "\n${GREEN}✅ FTP BERHASIL!${NC}"
    read -p "Tekan Enter..."
}

# ======================= 5. SAMBA =======================
install_samba() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         🖥️ INSTALL SAMBA                      ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    read -p "Nama Share (Enter untuk 'public'): " share_name
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
   create mask = 0777
EOF
    systemctl restart smbd
    echo -e "\n${GREEN}✅ SAMBA BERHASIL!${NC}"
    read -p "Tekan Enter..."
}

# ======================= 6. MAIL SERVER (Postfix + Dovecot) =======================
install_mail() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         📧 INSTALL MAIL SERVER (BACKEND)       ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    read -p "Masukkan Domain Email (contoh: mail.fahtech.com): " mail_domain
    
    debconf-set-selections <<EOF
postfix postfix/mailname string $mail_domain
postfix postfix/main_mailer_type string 'Internet Site'
EOF
    
    apt install postfix dovecot-core dovecot-imapd dovecot-pop3d mailutils -y -qq
    
    # Konfigurasi Postfix untuk Maildir
    postconf -e "home_mailbox = Maildir/"
    postconf -e "mailbox_command = "
    
    # Konfigurasi Dovecot
    sed -i 's/#mail_location = maildir:~/Maildir/mail_location = maildir:~/Maildir/' /etc/dovecot/conf.d/10-mail.conf
    sed -i 's/#listen = *, ::/listen = *, ::/' /etc/dovecot/dovecot.conf
    
    systemctl restart postfix
    systemctl restart dovecot
    systemctl enable postfix dovecot
    
    echo -e "\n${GREEN}✅ MAIL SERVER BERHASIL!${NC}"
    echo -e "${YELLOW}📌 Catatan: Agar bisa akses email via browser, lanjut install Webmail (menu 10).${NC}"
    read -p "Tekan Enter..."
}

# ======================= 7. WORDPRESS =======================
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
    echo -e "\n${GREEN}✅ WORDPRESS BERHASIL! Akses: http://$SERVER_IP/wp-admin/install.php${NC}"
    echo -e "${YELLOW}🔑 DB Password: $DB_PASS${NC}"
    read -p "Tekan Enter..."
}

# ======================= 8. CRUD =======================
install_crud() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         🗄️ INSTALL CRUD WEB                   ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    apt install php-sqlite3 -y -qq
    mkdir -p /var/www/html/crud
    cat > /var/www/html/crud/index.php <<'EOF'
<!DOCTYPE html>
<html>
<head><title>FahTech CRUD</title></head>
<body style="font-family:Arial;padding:20px">
<h1>⚡ FahTech CRUD</h1>
<?php
$db = new SQLite3('/var/www/html/crud/data.db');
$db->exec("CREATE TABLE IF NOT EXISTS items (id INTEGER PRIMARY KEY, name TEXT)");
if (isset($_POST['add'])) { $db->exec("INSERT INTO items (name) VALUES ('".SQLite3::escapeString($_POST['name'])."')"); }
if (isset($_GET['del'])) { $db->exec("DELETE FROM items WHERE id=".(int)$_GET['del']); }
$res = $db->query("SELECT * FROM items");
?>
<form method="post"><input type="text" name="name" required> <button type="submit" name="add">Tambah</button></form>
<ul><?php while($row=$res->fetchArray()){ echo "<li>".$row['name']." <a href='?del=".$row['id']."'>Hapus</a></li>"; } ?></ul>
</body>
</html>
EOF
    chown -R www-data:www-data /var/www/html/crud
    echo -e "\n${GREEN}✅ CRUD BERHASIL! Akses: http://$(hostname -I | awk '{print $1}')/crud/${NC}"
    read -p "Tekan Enter..."
}

# ======================= 9. INSTALL SEMUA (TANPA MAIL) =======================
install_all_no_mail() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║      ⚡ INSTALL SEMUA SERVICE (TANPA MAIL)     ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    read -p "Yakin install semua? (y/n): " confirm
    if [[ "$confirm" == "y" ]]; then
        install_apache2
        install_dhcp
        install_dns
        install_ftp
        install_samba
        install_wordpress
        install_crud
        echo -e "\n${GREEN}✅ SEMUA SERVICE (kecuali Mail) BERHASIL!${NC}"
    fi
    read -p "Tekan Enter..."
}

# ======================= 10. WEBMAIL (ROUNDCUBE) ⭐ YANG DITUNGGU-TUNGGU =======================
install_webmail() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         📧 INSTALL WEBMAIL (ROUNDCUBE)                ║${NC}"
    echo -e "${GREEN}║         SOLUSI AKSES EMAIL VIA BROWSER                ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
    
    # 1. Pastikan Mail Server sudah terinstall
    if ! systemctl is-active --quiet postfix; then
        echo -e "${YELLOW}⚠️ Mail Server belum terinstall! Install dulu lewat menu 7.${NC}"
        read -p "Tekan Enter..."
        return
    fi

    echo -e "\n${CYAN}📦 Step 1: Install Database (MariaDB/MySQL) untuk Webmail...${NC}"
    apt install mariadb-server -y -qq
    systemctl restart mariadb

    echo -e "${CYAN}📦 Step 2: Install Roundcube & Dependencies...${NC}"
    apt install roundcube roundcube-mysql roundcube-plugins roundcube-core php-mysql -y -qq
    
    # 2. Konfigurasi Database Roundcube
    DB_PASS=$(openssl rand -base64 12 | tr -d "=/+" | cut -c1-16)
    mysql <<MYSQL_SCRIPT
CREATE DATABASE IF NOT EXISTS roundcubemail;
CREATE USER IF NOT EXISTS 'roundcube'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON roundcubemail.* TO 'roundcube'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

    # Isi database roundcube (tables)
    if [ -f /usr/share/roundcube/SQL/mysql.initial.sql ]; then
        mysql roundcubemail < /usr/share/roundcube/SQL/mysql.initial.sql
    fi

    # 3. Konekkan Roundcube ke Database
    sed -i "s/^\(\$config\['db_dsnw'\] = \).*$/\1'mysql:\/\/roundcube:$DB_PASS@localhost\/roundcubemail';/" /etc/roundcube/config.inc.php
    
    # 4. Setting IMAP/SMTP Server
    SERVER_IP=$(hostname -I | awk '{print $1}')
    sed -i "s/^\(\$config\['default_host'\] = \).*$/\1'$SERVER_IP';/" /etc/roundcube/config.inc.php
    sed -i "s/^\(\$config\['smtp_server'\] = \).*$/\1'$SERVER_IP';/" /etc/roundcube/config.inc.php
    
    # 5. Aktifkan di Apache dan Restart
    ln -s /etc/roundcube/apache.conf /etc/apache2/conf-available/roundcube.conf 2>/dev/null
    a2enconf roundcube
    a2enmod rewrite
    systemctl restart apache2
    systemctl restart postfix dovecot
    
    echo -e "\n${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   ✅ WEBMAIL (ROUNDCUBE) BERHASIL!                          ║${NC}"
    echo -e "${GREEN}╠════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║   🌐 Akses Webmail: http://$SERVER_IP/roundcube/           ║${NC}"
    echo -e "${GREEN}║   📝 Login Menggunakan:                                     ║${NC}"
    echo -e "${GREEN}║      Username: [USERNAME_LINUX_YANG_ADA] (Contoh: root)     ║${NC}"
    echo -e "${GREEN}║      Password: [PASSWORD USER TERSEBUT]                     ║${NC}"
    echo -e "${GREEN}║                                                            ║${NC}"
    echo -e "${GREEN}║   💡 Catatan:                                              ║${NC}"
    echo -e "${GREEN}║      Agar bisa terima email dari luar, domain dan DNS      ║${NC}"
    echo -e "${GREEN}║      harus sudah diarahkan ke IP server ini.               ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    
    read -p "Tekan Enter untuk kembali..."
}

# ======================= 11. INSTALL SEMUA (DENGAN MAIL + WEBMAIL) =======================
install_all_complete() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║      ⚡ INSTALL SEMUA SERVICE LENGKAP          ║${NC}"
    echo -e "${GREEN}║      + Mail Server + Webmail Roundcube        ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    read -p "Yakin install semua? Proses akan lama. (y/n): " confirm
    if [[ "$confirm" == "y" ]]; then
        install_apache2
        install_dhcp
        install_dns
        install_ftp
        install_samba
        install_mail
        install_wordpress
        install_crud
        install_webmail  # Install Roundcube biar email bisa diakses via web
        
        SERVER_IP=$(hostname -I | awk '{print $1}')
        echo -e "\n${GREEN}╔════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║   ✅ SEMUA LAYANAN BERHASIL!                   ║${NC}"
        echo -e "${GREEN}║   🌐 Web: http://$SERVER_IP                    ║${NC}"
        echo -e "${GREEN}║   📧 Webmail: http://$SERVER_IP/roundcube/    ║${NC}"
        echo -e "${GREEN}║   📝 WP: http://$SERVER_IP/wp-admin           ║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    fi
    read -p "Tekan Enter..."
}

# ======================= MENU UTAMA (TELAH DITAMBAH WEBMAIL) =======================
while true; do
    clear
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║            🚀 FAHTECH MULTI-SERVICE INSTALLER              ║"
    echo "║         ⚡ PLUG AND PLAY | TINGGAL PILIH NOMOR ⚡          ║"
    echo "╠════════════════════════════════════════════════════════════╣"
    echo "║  1.  ⚡ Install SEMUA Service (LENGKAP + Webmail)          ║"
    echo "║  2.  🌐 Install DHCP Server (Otomatis Deteksi Interface)   ║"
    echo "║  3.  🔍 Install DNS Server                                 ║"
    echo "║  4.  🌍 Install Apache2 + Landing Page                     ║"
    echo "║  5.  📁 Install FTP Server                                 ║"
    echo "║  6.  🖥️  Install Samba File Server                         ║"
    echo "║  7.  📧 Install Mail Server (Postfix + Dovecot)            ║"
    echo "║  8.  📝 Install WordPress + Database Auto Setup            ║"
    echo "║  9.  🗄️  Install CRUD Web                                  ║"
    echo "║  10. 🌐 Install Webmail (Roundcube - Akses Email via Web) ⭐ ║"
    echo "║  11. 🚪 Exit                                               ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    read -p "👉 Pilih menu [1-11]: " menu
    
    case $menu in
        1) install_all_complete ;;
        2) install_dhcp ;;
        3) install_dns ;;
        4) install_apache2 ;;
        5) install_ftp ;;
        6) install_samba ;;
        7) install_mail ;;
        8) install_wordpress ;;
        9) install_crud ;;
        10) install_webmail ;;
        11) 
            echo -e "${GREEN}👋 Terima kasih!${NC}"
            exit 0
            ;;
        *) 
            echo -e "${RED}❌ Pilihan salah!${NC}"
            sleep 1
            ;;
    esac
done
