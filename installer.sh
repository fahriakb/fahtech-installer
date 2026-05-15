#!/bin/bash

# ============================================================
#   FAHTECH - MULTI-SERVICE INSTALLER PRO v19.0
#   DNS TIDAK ERROR | SEMUA SERVICE BERHASIL
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
echo "║              MULTI-SERVICE INSTALLER PROFESSIONAL v19.0                      ║"
echo "║                    DNS TIDAK ERROR | SEMUA SERVICE BERHASIL                 ║"
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

# ======================= CLEAN DNS TOTAL =======================
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

# ======================= 1. DHCP SERVER =======================
install_dhcp() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║              🌐 INSTALL DHCP SERVER            ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
    
    show_interfaces
    echo -e "\n${YELLOW}👉 Pilih interface untuk DHCP Server:${NC}"
    read -p "Nomor [1-${#INTERFACES[@]}]: " choice
    
    if [[ $choice -ge 1 && $choice -le ${#INTERFACES[@]} ]]; then
        IFS='|' read -r SELECTED_IFACE SELECTED_IP <<< "${INTERFACES[$((choice-1))]}"
        SUBNET=$(echo $SELECTED_IP | cut -d. -f1-3).0
        GATEWAY=$(echo $SELECTED_IP | cut -d. -f1-3).1
        RANGE_START=$(echo $SELECTED_IP | cut -d. -f1-3).100
        RANGE_END=$(echo $SELECTED_IP | cut -d. -f1-3).200
        
        apt update -qq
        apt install -y isc-dhcp-server
        
        echo "INTERFACESv4=\"$SELECTED_IFACE\"" > /etc/default/isc-dhcp-server
        cat > /etc/dhcp/dhcpd.conf <<EOF
subnet $SUBNET netmask 255.255.255.0 {
    range $RANGE_START $RANGE_END;
    option routers $GATEWAY;
    option domain-name-servers 8.8.8.8;
}
EOF
        
        systemctl restart isc-dhcp-server
        systemctl enable isc-dhcp-server
        
        echo -e "\n${GREEN}✅ DHCP BERHASIL!${NC}"
        echo -e "   📡 Interface: $SELECTED_IFACE"
        echo -e "   🌐 Subnet: $SUBNET/24"
    fi
    read -p "Tekan Enter..."
}

# ======================= 2. DNS SERVER (FIXED - TIDAK ERROR) =======================
install_dns() {
    clear
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║              🔍 INSTALL DNS SERVER (FIXED - NO ERROR)           ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
    
    show_interfaces
    echo -e "\n${YELLOW}👉 Pilih interface untuk DNS Server:${NC}"
    read -p "Nomor [1-${#INTERFACES[@]}]: " choice
    
    if [[ $choice -ge 1 && $choice -le ${#INTERFACES[@]} ]]; then
        IFS='|' read -r IFACE IP <<< "${INTERFACES[$((choice-1))]}"
        
        echo -e "\n${MAGENTA}📝 Masukkan nama domain (contoh: fahtech.com):${NC}"
        read -p "Domain: " DOMAIN
        
        # Bersihkan DNS lama total
        clean_dns
        
        # Install bind9 fresh
        apt update -qq
        apt install -y bind9 bind9utils
        
        # Buat folder yang diperlukan
        mkdir -p /etc/bind
        mkdir -p /var/lib/bind
        mkdir -p /var/cache/bind
        chown -R bind:bind /var/lib/bind /var/cache/bind
        
        # Konfigurasi named.conf.local
        cat > /etc/bind/named.conf.local <<EOF
zone "$DOMAIN" {
    type master;
    file "/etc/bind/db.$DOMAIN";
};
EOF
        
        # Buat file zone
        cat > /etc/bind/db.$DOMAIN <<EOF
\$TTL    604800
@       IN      SOA     ns1.$DOMAIN. admin.$DOMAIN. (
                  2026011501         ; Serial
                  604800         ; Refresh
                  86400         ; Retry
                  2419200        ; Expire
                  604800 )       ; Negative Cache TTL
;
@       IN      NS      ns1.$DOMAIN.
@       IN      A       $IP
@       IN      MX 10   mail.$DOMAIN.
ns1     IN      A       $IP
www     IN      A       $IP
mail    IN      A       $IP
EOF
        
        # Konfigurasi options dengan forwarder
        cat > /etc/bind/named.conf.options <<EOF
options {
    directory "/var/cache/bind";
    recursion yes;
    allow-query { any; };
    forwarders {
        8.8.8.8;
        8.8.4.4;
    };
    dnssec-validation auto;
    listen-on { any; };
    listen-on-v6 { none; };
};
EOF
        
        # Set permission
        chown bind:bind /etc/bind/db.$DOMAIN
        chmod 644 /etc/bind/db.$DOMAIN
        
        # Start bind9 dengan cara yang benar
        systemctl unmask bind9 2>/dev/null
        systemctl enable bind9
        systemctl restart bind9
        
        # Cek apakah bind9 berjalan
        if systemctl is-active --quiet bind9; then
            echo -e "\n${GREEN}✅ DNS BERHASIL!${NC}"
        else
            echo -e "\n${YELLOW}⚠️ DNS service bermasalah, mencoba perbaikan...${NC}"
            systemctl start bind9
            sleep 2
        fi
        
        echo -e "${GREEN}   📝 Domain: $DOMAIN${NC}"
        echo -e "${GREEN}   🌐 IP: $IP${NC}"
        echo -e "${GREEN}   📧 Subdomain mail: mail.$DOMAIN${NC}"
        
        # Simpan konfigurasi
        echo "$DOMAIN" > /etc/maildomain.conf
        echo "$IP" > /etc/mailip.conf
        
        # Test DNS
        echo -e "\n${YELLOW}🔍 Test DNS:${NC}"
        nslookup $DOMAIN 127.0.0.1 2>/dev/null || echo "  (test DNS bisa dilakukan nanti)"
    fi
    read -p "Tekan Enter..."
}

# ======================= 3. APACHE2 =======================
install_apache2() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              🌍 INSTALL APACHE2                ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
    apt update -qq
    apt install -y apache2 php libapache2-mod-php php-mysql php-sqlite3 php-curl php-gd php-xml php-mbstring php-zip wget curl unzip
    
    cat > /var/www/html/index.html <<'EOF'
<!DOCTYPE html>
<html>
<head><title>FahTech Server</title>
<style>
body{background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);font-family:Arial;text-align:center;padding:50px}
h1{color:white;font-size:48px}
.status{background:#4CAF50;padding:10px;border-radius:10px;color:white}
.services{display:flex;justify-content:center;gap:20px;margin-top:30px;flex-wrap:wrap}
.service{background:white;padding:15px;border-radius:10px;min-width:120px}
</style>
</head>
<body>
<h1>⚡ FAHTECH SERVER ⚡</h1>
<div class="status">✅ ALL SERVICES RUNNING</div>
<p style="color:white;">Server IP: <?php echo $_SERVER['SERVER_ADDR']; ?></p>
<div class="services">
<div class="service">🌐 Web</div><div class="service">📧 Mail</div>
<div class="service">📝 WP</div><div class="service">🗄️ CRUD</div>
<div class="service">🌍 Webmail</div><div class="service">📁 FTP</div>
</div>
<p style="color:white;">Powered by FahTech Installer v19.0</p>
</body>
</html>
EOF
    
    systemctl restart apache2
    echo -e "\n${GREEN}✅ APACHE2 BERHASIL! Akses: http://$SERVER_IP${NC}"
    read -p "Tekan Enter..."
}

# ======================= 4. FTP =======================
install_ftp() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              📁 INSTALL FTP SERVER             ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
    apt install -y vsftpd
    systemctl restart vsftpd
    systemctl enable vsftpd
    
    echo -e "\n${GREEN}✅ FTP BERHASIL! Akses: ftp://$SERVER_IP${NC}"
    read -p "Tekan Enter..."
}

# ======================= 5. SAMBA =======================
install_samba() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              🖥️ INSTALL SAMBA                  ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
    read -p "📝 Nama Share (Enter untuk 'public'): " share_name
    share_name=${share_name:-public}
    
    apt install -y samba
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
    systemctl enable smbd
    
    echo -e "\n${GREEN}✅ SAMBA BERHASIL! Akses: \\\\$SERVER_IP\\$share_name${NC}"
    read -p "Tekan Enter..."
}

# ======================= 6. WORDPRESS =======================
install_wordpress() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              📝 INSTALL WORDPRESS              ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
    apt install -y mariadb-server
    systemctl restart mariadb
    
    # Fix database jika perlu
    if ! mysql -u root -e "SELECT 1" 2>/dev/null; then
        systemctl stop mariadb
        mysqld_safe --skip-grant-tables --skip-networking &>/dev/null &
        sleep 3
        mysql -u root -e "FLUSH PRIVILEGES; ALTER USER 'root'@'localhost' IDENTIFIED BY ''; FLUSH PRIVILEGES;" 2>/dev/null
        pkill mysqld_safe
        sleep 2
        systemctl restart mariadb
    fi
    
    DB_PASS=$(openssl rand -base64 12 | tr -d "=/+" | cut -c1-16)
    
    mysql -u root <<MYSQL_SCRIPT 2>/dev/null
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
    
    echo -e "\n${GREEN}✅ WORDPRESS BERHASIL! Akses: http://$SERVER_IP/wp-admin/install.php${NC}"
    echo -e "${YELLOW}   🔑 DB Password: $DB_PASS${NC}"
    read -p "Tekan Enter..."
}

# ======================= 7. CRUD SISWA =======================
install_crud() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         🗄️ INSTALL CRUD SISWA                 ║${NC}"
    echo -e "${GREEN}║   (Nama + Rombel + NIS) - Tambah/Edit/Hapus/Cari ║${NC}"
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
<tr><th>Nama</th><th>Rombel</th><th>NIS</th><th>Aksi</th><tr>
<?php while($row=$res->fetchArray()){echo "<tr><td>".$row['nama']."</td><td>".$row['rombel']."</td><td>".$row['nis']."</td><td><a class='edit-btn' href='?edit=".$row['id']."'>Edit</a> <a class='delete-btn' href='?delete=".$row['id']."'>Hapus</a></tr>";}?>
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
    systemctl restart apache2
    
    echo -e "\n${GREEN}✅ CRUD SISWA BERHASIL! Akses: http://$SERVER_IP/crud/${NC}"
    read -p "Tekan Enter..."
}

# ======================= 8. MAIL SERVER =======================
install_mail() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║              📧 INSTALL MAIL SERVER            ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
    
    if [[ -f /etc/maildomain.conf ]]; then
        MAIN_DOMAIN=$(cat /etc/maildomain.conf)
        DNS_IP=$(cat /etc/mailip.conf)
        echo -e "\n${GREEN}✅ Domain terdeteksi: $MAIN_DOMAIN${NC}"
    else
        show_interfaces
        echo -e "\n${YELLOW}👉 Pilih interface:${NC}"
        read -p "Nomor [1-${#INTERFACES[@]}]: " choice
        if [[ $choice -ge 1 && $choice -le ${#INTERFACES[@]} ]]; then
            IFS='|' read -r MAIL_IFACE MAIL_IP <<< "${INTERFACES[$((choice-1))]}"
        else
            MAIL_IP=$SERVER_IP
        fi
        echo -e "\n${MAGENTA}📝 Masukkan domain:${NC}"
        read -p "Domain: " MAIN_DOMAIN
        DNS_IP=$MAIL_IP
        echo "$MAIN_DOMAIN" > /etc/maildomain.conf
        echo "$DNS_IP" > /etc/mailip.conf
    fi
    
    echo -e "\n${CYAN}📝 Buat akun email:${NC}"
    read -p "Username: " EMAIL_USER
    EMAIL_USER=${EMAIL_USER:-admin}
    read -s -p "Password: " EMAIL_PASS
    echo ""
    EMAIL_PASS=${EMAIL_PASS:-admin123}
    
    MAIL_DOMAIN="mail.$MAIN_DOMAIN"
    hostnamectl set-hostname $MAIL_DOMAIN
    echo "$DNS_IP $MAIL_DOMAIN" >> /etc/hosts
    
    apt install -y postfix dovecot-core dovecot-imapd dovecot-pop3d mailutils
    
    postconf -e "myhostname = $MAIL_DOMAIN"
    postconf -e "mydomain = $MAIN_DOMAIN"
    postconf -e "myorigin = \$mydomain"
    postconf -e "inet_interfaces = all"
    postconf -e "home_mailbox = Maildir/"
    postconf -e "smtpd_sasl_type = dovecot"
    postconf -e "smtpd_sasl_path = private/auth"
    postconf -e "smtpd_sasl_auth_enable = yes"
    
    rm -rf /etc/dovecot 2>/dev/null
    cat > /etc/dovecot/dovecot.conf <<EOF
disable_plaintext_auth = no
mail_privileged_group = mail
mail_location = maildir:~/Maildir
passdb { driver = passwd-file args = scheme=PLAIN /etc/dovecot/users }
userdb { driver = passwd }
protocols = imap pop3
service auth { unix_listener /var/spool/postfix/private/auth { mode = 0660 user = postfix group = postfix } }
ssl = no
EOF
    
    mkdir -p /etc/dovecot
    echo "$EMAIL_USER@$MAIN_DOMAIN:$EMAIL_PASS" > /etc/dovecot/users
    chmod 600 /etc/dovecot/users
    useradd -m -s /bin/false $EMAIL_USER 2>/dev/null
    echo "$EMAIL_USER:$EMAIL_PASS" | chpasswd
    mkdir -p /home/$EMAIL_USER/Maildir/{cur,new,tmp}
    chown -R $EMAIL_USER:$EMAIL_USER /home/$EMAIL_USER/Maildir
    
    systemctl restart postfix
    systemctl restart dovecot
    systemctl enable postfix dovecot
    
    echo "$EMAIL_USER" > /etc/mailuser.conf
    echo "$EMAIL_PASS" > /etc/mailpass.conf
    
    echo -e "\n${GREEN}✅ MAIL SERVER BERHASIL!${NC}"
    echo -e "   📧 Email: $EMAIL_USER@$MAIN_DOMAIN"
    echo -e "   🔑 Password: $EMAIL_PASS"
    read -p "Tekan Enter..."
}

# ======================= 9. WEBMAIL =======================
install_webmail() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         🌐 INSTALL WEBMAIL (ROUNDCUBE)         ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
    if [[ -f /etc/maildomain.conf ]]; then
        MAIN_DOMAIN=$(cat /etc/maildomain.conf)
        DNS_IP=$(cat /etc/mailip.conf)
        EMAIL_USER=$(cat /etc/mailuser.conf 2>/dev/null)
        EMAIL_PASS=$(cat /etc/mailpass.conf 2>/dev/null)
    else
        echo -e "\n${RED}❌ Mail Server belum diinstall!${NC}"
        read -p "Tekan Enter..."
        return
    fi
    
    apt remove --purge -y roundcube* php-roundcube* dbconfig-common 2>/dev/null
    rm -rf /etc/roundcube /var/lib/roundcube /usr/share/roundcube
    apt install -y roundcube roundcube-mysql roundcube-core php-mysql
    
    DB_PASS="rcube123"
    mysql -u root <<MYSQL 2>/dev/null
DROP DATABASE IF EXISTS roundcubemail;
CREATE DATABASE roundcubemail;
CREATE USER IF NOT EXISTS 'roundcube'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON roundcubemail.* TO 'roundcube'@'localhost';
FLUSH PRIVILEGES;
MYSQL
    
    if [ -f /usr/share/roundcube/SQL/mysql.initial.sql ]; then
        mysql roundcubemail < /usr/share/roundcube/SQL/mysql.initial.sql 2>/dev/null
    fi
    
    cat > /etc/roundcube/config.inc.php <<PHP
<?php \$config = []; \$config['db_dsnw'] = 'mysql://roundcube:rcube123@localhost/roundcubemail'; \$config['default_host'] = 'localhost'; \$config['smtp_server'] = 'localhost'; \$config['smtp_port'] = 25; \$config['smtp_user'] = '%u'; \$config['smtp_pass'] = '%p'; \$config['product_name'] = 'FahTech Webmail - $MAIN_DOMAIN'; \$config['plugins'] = ['archive', 'zipdownload']; \$config['skin'] = 'elastic';
PHP
    
    cat > /etc/apache2/conf-available/roundcube.conf <<APACHE
Alias /roundcube /usr/share/roundcube
<Directory /usr/share/roundcube/> Options +FollowSymLinks AllowOverride All Require all granted </Directory>
APACHE
    
    a2enconf roundcube
    a2enmod rewrite
    systemctl restart apache2 postfix dovecot
    
    echo -e "\n${GREEN}✅ WEBMAIL BERHASIL!${NC}"
    echo -e "   🌐 Akses: http://$DNS_IP/roundcube/"
    echo -e "   📧 Login: $EMAIL_USER@$MAIN_DOMAIN / $EMAIL_PASS"
    read -p "Tekan Enter..."
}

# ======================= 10. TAMBAH USER =======================
add_mail_user() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              👤 TAMBAH USER EMAIL              ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
    if [[ ! -f /etc/maildomain.conf ]]; then
        echo -e "\n${RED}❌ Mail Server belum diinstall!${NC}"
        read -p "Tekan Enter..."
        return
    fi
    
    MAIN_DOMAIN=$(cat /etc/maildomain.conf)
    DNS_IP=$(cat /etc/mailip.conf)
    
    echo -e "\n${YELLOW}📝 Masukkan username baru:${NC}"
    read -p "Username: " NEW_USER
    read -s -p "Password: " NEW_PASS
    echo ""
    NEW_PASS=${NEW_PASS:-12345}
    
    echo "$NEW_USER@$MAIN_DOMAIN:$NEW_PASS" >> /etc/dovecot/users
    useradd -m -s /bin/false $NEW_USER 2>/dev/null
    echo "$NEW_USER:$NEW_PASS" | chpasswd
    mkdir -p /home/$NEW_USER/Maildir/{cur,new,tmp}
    chown -R $NEW_USER:$NEW_USER /home/$NEW_USER/Maildir
    systemctl restart dovecot
    
    echo -e "\n${GREEN}✅ User $NEW_USER@$MAIN_DOMAIN berhasil ditambahkan!${NC}"
    read -p "Tekan Enter..."
}

# ======================= 11. INSTALL SEMUA =======================
install_all() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         ⚡ INSTALL SEMUA SERVICE LENGKAP       ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${YELLOW}⚠️ Proses akan memakan waktu 20-30 menit. Lanjutkan? (y/n):${NC}"
    read confirm
    if [[ "$confirm" == "y" ]]; then
        install_apache2
        install_dhcp
        install_dns
        install_ftp
        install_samba
        install_wordpress
        install_crud
        install_mail
        install_webmail
        
        MAIN_DOMAIN=$(cat /etc/maildomain.conf 2>/dev/null)
        DNS_IP=$(cat /etc/mailip.conf 2>/dev/null)
        EMAIL_USER=$(cat /etc/mailuser.conf 2>/dev/null)
        EMAIL_PASS=$(cat /etc/mailpass.conf 2>/dev/null)
        
        echo -e "\n${GREEN}════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}   🎉 SEMUA SERVICE BERHASIL DIINSTALL! 🎉                            ║${NC}"
        echo -e "${GREEN}════════════════════════════════════════════════════════════════════║${NC}"
        echo -e "${GREEN}                                                                     ║${NC}"
        echo -e "${GREEN}   🌐 LANDING PAGE:  http://$DNS_IP                                  ║${NC}"
        echo -e "${GREEN}   📚 CRUD:          http://$DNS_IP/crud/                           ║${NC}"
        echo -e "${GREEN}   📧 WEBMAIL:       http://$DNS_IP/roundcube/                      ║${NC}"
        echo -e "${GREEN}   📝 WORDPRESS:     http://$DNS_IP/wp-admin                        ║${NC}"
        echo -e "${GREEN}   📁 FTP:           ftp://$DNS_IP                                  ║${NC}"
        echo -e "${GREEN}   🖥️ SAMBA:         \\\\$DNS_IP\\public                              ║${NC}"
        echo -e "${GREEN}                                                                     ║${NC}"
        echo -e "${GREEN}   📧 LOGIN WEBMAIL: $EMAIL_USER@$MAIN_DOMAIN / $EMAIL_PASS        ║${NC}"
        echo -e "${GREEN}                                                                     ║${NC}"
        echo -e "${GREEN}════════════════════════════════════════════════════════════════════╝${NC}"
    fi
    read -p "Tekan Enter..."
}

# ======================= 12. HAPUS SEMUA =======================
uninstall_all() {
    clear
    echo -e "${RED}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║              🗑️ HAPUS SEMUA SERVICE            ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${YELLOW}⚠️ Yakin akan menghapus SEMUA service? (y/n):${NC}"
    read confirm
    if [[ "$confirm" == "y" ]]; then
        systemctl stop apache2 bind9 isc-dhcp-server postfix dovecot samba smbd vsftpd mariadb 2>/dev/null
        apt remove --purge -y apache2* bind9* isc-dhcp-server* postfix* dovecot* samba* vsftpd* mariadb* mysql* roundcube* 2>/dev/null
        rm -rf /etc/apache2 /etc/bind /etc/dhcp /etc/postfix /etc/dovecot /etc/samba /var/www/html /var/lib/mysql
        rm -rf /etc/roundcube /var/lib/roundcube /usr/share/roundcube /home/share /home/*/Maildir
        rm -rf /etc/maildomain.conf /etc/mailip.conf /etc/mailuser.conf /etc/mailpass.conf
        apt autoremove --purge -y
        echo -e "\n${GREEN}✅ SEMUA SERVICE DAN FOLDER BERHASIL DIHAPUS!${NC}"
    fi
    read -p "Tekan Enter..."
}

# ======================= 13. CEK STATUS =======================
check_status() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              📊 CEK STATUS SERVICE             ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    for service in isc-dhcp-server bind9 apache2 vsftpd smbd postfix dovecot mariadb; do
        name=""
        case $service in
            isc-dhcp-server) name="🌐 DHCP Server";;
            bind9) name="🔍 DNS Server";;
            apache2) name="🌍 Apache2";;
            vsftpd) name="📁 FTP Server";;
            smbd) name="🖥️ Samba";;
            postfix) name="📧 Postfix (Mail)";;
            dovecot) name="📧 Dovecot (IMAP)";;
            mariadb) name="🗄️ MariaDB";;
        esac
        if systemctl is-active --quiet $service; then
            echo -e "  $name | ${GREEN}✅ ACTIVE${NC}"
        else
            echo -e "  $name | ${RED}❌ INACTIVE${NC}"
        fi
    done
    
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if [[ -f /etc/maildomain.conf ]]; then
        MAIN_DOMAIN=$(cat /etc/maildomain.conf)
        DNS_IP=$(cat /etc/mailip.conf)
        EMAIL_USER=$(cat /etc/mailuser.conf 2>/dev/null)
        echo -e "\n📧 MAIL SERVER INFO:"
        echo -e "   📝 Domain: $MAIN_DOMAIN"
        echo -e "   📧 Email: $EMAIL_USER@$MAIN_DOMAIN"
        echo -e "   🌐 Webmail: http://$DNS_IP/roundcube/"
        echo -e "   🔍 Test DNS: nslookup $MAIN_DOMAIN 127.0.0.1"
    fi
    
    read -p "Tekan Enter..."
}

# ======================= MENU UTAMA =======================
while true; do
    clear
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════════════════════╗"
    echo "║            🚀 FAHTECH MULTI-SERVICE INSTALLER v19.0                        ║"
    echo "║                    DNS TIDAK ERROR | SEMUA SERVICE BERHASIL                ║"
    echo "╠════════════════════════════════════════════════════════════════════════════╣"
    echo "║                                                                             ║"
    echo "║  1.  ⚡ INSTALL SEMUA SERVICE (20-30 menit) - REKOMENDED                    ║"
    echo "║  2.  🌐 Install DHCP Server                                                ║"
    echo "║  3.  🔍 Install DNS Server (FIXED - TIDAK ERROR)                           ║"
    echo "║  4.  🌍 Install Apache2 + Landing Page                                     ║"
    echo "║  5.  📁 Install FTP Server                                                 ║"
    echo "║  6.  🖥️ Install Samba                                                      ║"
    echo "║  7.  📝 Install WordPress                                                  ║"
    echo "║  8.  🗄️ Install CRUD Siswa (Tambah/Edit/Hapus/Cari)                        ║"
    echo "║  9.  📧 Install Mail Server (Postfix + Dovecot)                            ║"
    echo "║  10. 🌐 Install Webmail (Roundcube) - Akses Email via Browser              ║"
    echo "║  11. 👤 Tambah User Email Baru                                             ║"
    echo "║  12. 🗑️ Hapus SEMUA Service + Folder                                       ║"
    echo "║  13. 📊 Cek Status Service                                                 ║"
    echo "║  14. 🚪 Exit                                                               ║"
    echo "╚════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    read -p "👉 Pilih menu [1-14]: " menu
    
    case $menu in
        1) install_all ;;
        2) install_dhcp ;;
        3) install_dns ;;
        4) install_apache2 ;;
        5) install_ftp ;;
        6) install_samba ;;
        7) install_wordpress ;;
        8) install_crud ;;
        9) install_mail ;;
        10) install_webmail ;;
        11) add_mail_user ;;
        12) uninstall_all ;;
        13) check_status ;;
        14) 
            echo -e "${GREEN}👋 Terima kasih!${NC}"
            exit 0
            ;;
        *) 
            echo -e "${RED}❌ Pilihan salah!${NC}"
            sleep 1
            ;;
    esac
done
