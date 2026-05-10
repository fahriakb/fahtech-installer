#!/bin/bash

# ============================================================
#   FAHTECH - ULTIMATE FULL AUTO INSTALLER
#   DHCP + DNS + FTP + SAMBA + MAIL + WEBMAIL + CRUD + WP
#   AUTO FIX SEMUA ERROR
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
echo "║   ███████╗ █████╗ ██╗  ██╗████████╗███████╗ ██████╗██╗  ██╗     ║"
echo "║   ██╔════╝██╔══██╗██║  ██║╚══██╔══╝██╔════╝██╔════╝██║  ██║     ║"
echo "║   █████╗  ███████║███████║   ██║   █████╗  ██║     ███████║     ║"
echo "║   ██╔══╝  ██╔══██║██╔══██║   ██║   ██╔══╝  ██║     ██╔══██║     ║"
echo "║   ██║     ██║  ██║██║  ██║   ██║   ███████╗╚██████╗██║  ██║     ║"
echo "║   ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝ ╚═════╝╚═╝  ╚═╝     ║"
echo "║              ULTIMATE FULL AUTO INSTALLER                       ║"
echo "║     DHCP + DNS + FTP + SAMBA + MAIL + WEBMAIL + CRUD + WP       ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ Jalankan sebagai root!${NC}"
    exit 1
fi

SERVER_IP=$(hostname -I | awk '{print $1}')
EMAIL_USER="fahri"
EMAIL_DOMAIN="fahriakbar.net"
EMAIL_PASS="12345"

# Deteksi interface
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
    echo -e "\n${GREEN}📡 Network Interface terdeteksi:${NC}"
    for i in "${!INTERFACES[@]}"; do
        IFS='|' read -r iface ip <<< "${INTERFACES[$i]}"
        echo -e "  ${YELLOW}$((i+1))${NC}. ${CYAN}$iface${NC} → IP: ${GREEN}$ip${NC}"
    done
}

# ======================= APACHE2 =======================
install_apache2() {
    echo -e "${CYAN}📦 Install Apache2...${NC}"
    apt install -y apache2 php libapache2-mod-php php-mysql php-sqlite3
    systemctl restart apache2
    echo -e "${GREEN}✅ Apache2: http://$SERVER_IP${NC}"
}

# ======================= DHCP =======================
install_dhcp() {
    echo -e "${CYAN}📦 Install DHCP Server...${NC}"
    show_interfaces
    read -p "Pilih interface: " choice
    if [[ $choice -ge 1 && $choice -le ${#INTERFACES[@]} ]]; then
        IFS='|' read -r IFACE IP <<< "${INTERFACES[$((choice-1))]}"
        SUBNET=$(echo $IP | cut -d. -f1-3).0
        apt install -y isc-dhcp-server
        echo "INTERFACESv4=\"$IFACE\"" > /etc/default/isc-dhcp-server
        cat > /etc/dhcp/dhcpd.conf <<EOF
subnet $SUBNET netmask 255.255.255.0 {
    range ${SUBNET%.0}.100 ${SUBNET%.0}.200;
    option routers ${SUBNET%.0}.1;
    option domain-name-servers 8.8.8.8;
}
EOF
        systemctl restart isc-dhcp-server
        echo -e "${GREEN}✅ DHCP Server aktif di $IFACE${NC}"
    fi
}

# ======================= DNS =======================
install_dns() {
    echo -e "${CYAN}📦 Install DNS Server...${NC}"
    show_interfaces
    read -p "Pilih interface: " choice
    if [[ $choice -ge 1 && $choice -le ${#INTERFACES[@]} ]]; then
        IFS='|' read -r IFACE IP <<< "${INTERFACES[$((choice-1))]}"
        read -p "Masukkan domain (contoh: fahriakbar.net): " DOMAIN
        apt install -y bind9
        cat > /etc/bind/named.conf.local <<EOF
zone "$DOMAIN" {
    type master;
    file "/etc/bind/db.$DOMAIN";
};
EOF
        cat > /etc/bind/db.$DOMAIN <<EOF
\$TTL 604800
@ IN SOA ns1.$DOMAIN. admin.$DOMAIN. (1 604800 86400 2419200 604800)
@ IN NS ns1.$DOMAIN.
@ IN A $IP
@ IN MX 10 mail.$DOMAIN
ns1 IN A $IP
www IN A $IP
mail IN A $IP
EOF
        systemctl restart bind9
        echo -e "${GREEN}✅ DNS Server: $DOMAIN -> $IP${NC}"
    fi
}

# ======================= FTP =======================
install_ftp() {
    echo -e "${CYAN}📦 Install FTP Server...${NC}"
    apt install -y vsftpd
    systemctl restart vsftpd
    echo -e "${GREEN}✅ FTP Server: ftp://$SERVER_IP${NC}"
}

# ======================= SAMBA =======================
install_samba() {
    echo -e "${CYAN}📦 Install Samba...${NC}"
    apt install -y samba
    mkdir -p /home/share
    chmod 777 /home/share
    cat >> /etc/samba/smb.conf <<EOF
[public]
   path = /home/share
   browseable = yes
   writable = yes
   guest ok = yes
   create mask = 0777
EOF
    systemctl restart smbd
    echo -e "${GREEN}✅ Samba: \\\\$SERVER_IP\\public${NC}"
}

# ======================= WORDPRESS =======================
install_wordpress() {
    echo -e "${CYAN}📦 Install WordPress...${NC}"
    apt install -y mariadb-server
    systemctl restart mariadb
    DB_PASS=$(openssl rand -base64 12 | tr -d "=/+" | cut -c1-16)
    mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS wordpress;
CREATE USER IF NOT EXISTS 'wpuser'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'localhost';
FLUSH PRIVILEGES;
EOF
    cd /tmp && wget -q https://wordpress.org/latest.tar.gz && tar -xzf latest.tar.gz
    cp -r wordpress/* /var/www/html/
    cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
    sed -i "s/database_name_here/wordpress/" /var/www/html/wp-config.php
    sed -i "s/username_here/wpuser/" /var/www/html/wp-config.php
    sed -i "s/password_here/$DB_PASS/" /var/www/html/wp-config.php
    chown -R www-data:www-data /var/www/html/
    systemctl restart apache2
    echo -e "${GREEN}✅ WordPress: http://$SERVER_IP/wp-admin${NC}"
}

# ======================= CRUD SISWA =======================
install_crud() {
    echo -e "${CYAN}📦 Install CRUD Siswa...${NC}"
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
<table><tr><th>Nama</th><th>Rombel</th><th>NIS</th><th>Aksi</th></tr>
<?php while($row=$res->fetchArray()){echo "<tr><td>".$row['nama']."</td><td>".$row['rombel']."</td><td>".$row['nis']."</td><td><a class='edit-btn' href='?edit=".$row['id']."'>Edit</a> <a class='delete-btn' href='?delete=".$row['id']."'>Hapus</a></td></tr>";}?>
</table>
<?php if(isset($_GET['edit'])){$id=(int)$_GET['edit'];$edit=$db->query("SELECT * FROM siswa WHERE id=$id")->fetchArray();if($edit){?>
<h3>Edit Data</h3>
<form method="post"><input type="hidden" name="id" value="<?=$edit['id']?>"><input type="text" name="nama" value="<?=$edit['nama']?>"><input type="text" name="rombel" value="<?=$edit['rombel']?>"><input type="text" name="nis" value="<?=$edit['nis']?>"><button type="submit" name="update">Update</button></form>
<?php }}?>
</div>
</body>
</html>
EOF
    chown -R www-data:www-data /var/www/html/crud
    echo -e "${GREEN}✅ CRUD Siswa: http://$SERVER_IP/crud/${NC}"
}

# ======================= MAIL SERVER =======================
install_mail() {
    echo -e "${CYAN}📦 Install Mail Server...${NC}"
    apt install -y postfix dovecot-core dovecot-imapd dovecot-pop3d mailutils
    postconf -e "myhostname = mail.$EMAIL_DOMAIN"
    postconf -e "mydomain = $EMAIL_DOMAIN"
    postconf -e "myorigin = \$mydomain"
    postconf -e "inet_interfaces = all"
    postconf -e "home_mailbox = Maildir/"
    cat > /etc/dovecot/dovecot.conf <<EOF
disable_plaintext_auth = no
mail_location = maildir:~/Maildir
passdb { driver = passwd-file args = /etc/dovecot/users }
userdb { driver = passwd }
protocols = imap pop3
ssl = no
EOF
    mkdir -p /etc/dovecot
    echo "$EMAIL_USER@$EMAIL_DOMAIN:{PLAIN}$EMAIL_PASS" > /etc/dovecot/users
    useradd -m -s /bin/false $EMAIL_USER 2>/dev/null
    echo "$EMAIL_USER:$EMAIL_PASS" | chpasswd
    mkdir -p /home/$EMAIL_USER/Maildir/{cur,new,tmp}
    chown -R $EMAIL_USER:$EMAIL_USER /home/$EMAIL_USER/Maildir
    systemctl restart postfix dovecot
    echo -e "${GREEN}✅ Mail Server: $EMAIL_USER@$EMAIL_DOMAIN / $EMAIL_PASS${NC}"
}

# ======================= WEBMAIL =======================
install_webmail() {
    echo -e "${CYAN}📦 Install Webmail...${NC}"
    apt remove --purge -y roundcube* php-roundcube* dbconfig-common 2>/dev/null
    rm -rf /etc/roundcube /var/lib/roundcube /usr/share/roundcube
    apt install -y roundcube roundcube-mysql roundcube-core php-mysql
    mysql -u root <<MYSQL 2>/dev/null
DROP DATABASE IF EXISTS roundcubemail;
CREATE DATABASE roundcubemail;
CREATE USER IF NOT EXISTS 'roundcube'@'localhost' IDENTIFIED BY 'rcube123';
GRANT ALL PRIVILEGES ON roundcubemail.* TO 'roundcube'@'localhost';
FLUSH PRIVILEGES;
MYSQL
    mysql roundcubemail < /usr/share/roundcube/SQL/mysql.initial.sql 2>/dev/null
    cat > /etc/roundcube/config.inc.php <<PHP
<?php \$config = []; \$config['db_dsnw'] = 'mysql://roundcube:rcube123@localhost/roundcubemail'; \$config['default_host'] = 'localhost'; \$config['smtp_server'] = 'localhost'; \$config['smtp_port'] = 25; \$config['smtp_user'] = '%u'; \$config['smtp_pass'] = '%p'; \$config['product_name'] = 'FahTech Webmail'; \$config['plugins'] = ['archive', 'zipdownload']; \$config['skin'] = 'elastic';
PHP
    cat > /etc/apache2/conf-available/roundcube.conf <<APACHE
Alias /roundcube /usr/share/roundcube
<Directory /usr/share/roundcube/> Options +FollowSymLinks AllowOverride All Require all granted </Directory>
APACHE
    a2enconf roundcube && a2enmod rewrite && systemctl reload apache2
    echo -e "${GREEN}✅ Webmail: http://$SERVER_IP/roundcube/${NC}"
    echo -e "${GREEN}   Login: $EMAIL_USER@$EMAIL_DOMAIN / $EMAIL_PASS${NC}"
}

# ======================= INSTALL SEMUA =======================
install_all() {
    install_apache2
    install_dhcp
    install_dns
    install_ftp
    install_samba
    install_wordpress
    install_crud
    install_mail
    install_webmail
    
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   🎉 SEMUA SERVICE BERHASIL!                               ║${NC}"
    echo -e "${GREEN}╠════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║   🌐 Landing: http://$SERVER_IP                           ║${NC}"
    echo -e "${GREEN}║   📚 CRUD:     http://$SERVER_IP/crud/                    ║${NC}"
    echo -e "${GREEN}║   📧 Webmail:  http://$SERVER_IP/roundcube/               ║${NC}"
    echo -e "${GREEN}║   📝 WordPress: http://$SERVER_IP/wp-admin                ║${NC}"
    echo -e "${GREEN}║   📁 FTP:      ftp://$SERVER_IP                           ║${NC}"
    echo -e "${GREEN}║   🖥️ Samba:    \\\\$SERVER_IP\\public                       ║${NC}"
    echo -e "${GREEN}║   📧 Login:    $EMAIL_USER@$EMAIL_DOMAIN / $EMAIL_PASS    ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
}

# ======================= MENU =======================
while true; do
    clear
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║         🚀 FAHTECH ULTIMATE FULL AUTO INSTALLER           ║"
    echo "║            AUTO DETECT IP: ${GREEN}$SERVER_IP${CYAN}                 ║"
    echo "╠════════════════════════════════════════════════════════════╣"
    echo "║  1. ⚡ INSTALL SEMUA SERVICE (REKOMENDED)                  ║"
    echo "║  2. 🌐 Install DHCP Server                                ║"
    echo "║  3. 🔍 Install DNS Server                                 ║"
    echo "║  4. 🌍 Install Apache2                                    ║"
    echo "║  5. 📁 Install FTP Server                                 ║"
    echo "║  6. 🖥️ Install Samba                                      ║"
    echo "║  7. 📝 Install WordPress                                  ║"
    echo "║  8. 📚 Install CRUD Siswa (Nama+Rombel+NIS)               ║"
    echo "║  9. 📧 Install Mail Server + Webmail                       ║"
    echo "║  10. 🚪 Exit                                              ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    read -p "👉 Pilih menu [1-10]: " menu
    
    case $menu in
        1) install_all; break ;;
        2) install_apache2; install_dhcp ;;
        3) install_apache2; install_dns ;;
        4) install_apache2 ;;
        5) install_ftp ;;
        6) install_samba ;;
        7) install_apache2; install_wordpress ;;
        8) install_apache2; install_crud ;;
        9) install_apache2; install_mail; install_webmail ;;
        10) echo -e "${GREEN}👋 Terima kasih!${NC}"; exit 0 ;;
        *) echo -e "${RED}❌ Pilihan salah!${NC}"; sleep 1 ;;
    esac
done
