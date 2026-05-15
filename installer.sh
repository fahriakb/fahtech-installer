#!/bin/bash

# ============================================================
#   FAHTECH - MULTI-SERVICE INSTALLER PRO v14.0
#   14 KONFIGURASI LENGKAP | HAPUS SEMUA FOLDER
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
echo "║                   MULTI-SERVICE INSTALLER PROFESSIONAL                       ║"
echo "║                   14 KONFIGURASI | HAPUS SEMUA FOLDER                        ║"
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
        echo -e "\n${GREEN}✅ DHCP BERHASIL! Interface: $SELECTED_IFACE${NC}"
        echo -e "${GREEN}   Subnet: $SUBNET/24 | Range: $RANGE_START - $RANGE_END${NC}"
    else
        echo -e "${RED}❌ Pilihan tidak valid!${NC}"
    fi
    read -p "Tekan Enter..."
}

# ======================= 2. DNS SERVER (1 DOMAIN) =======================
install_dns_single() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║              🔍 INSTALL DNS SERVER             ║${NC}"
    echo -e "${BLUE}║                (1 DOMAIN SAJA)                 ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
    
    show_interfaces
    echo -e "\n${YELLOW}👉 Pilih interface untuk DNS Server:${NC}"
    read -p "Nomor [1-${#INTERFACES[@]}]: " choice
    
    if [[ $choice -ge 1 && $choice -le ${#INTERFACES[@]} ]]; then
        IFS='|' read -r IFACE IP <<< "${INTERFACES[$((choice-1))]}"
        echo -e "\n${MAGENTA}📝 Masukkan nama domain (contoh: fahtech.com):${NC}"
        read -p "Domain: " DOMAIN
        
        apt update -qq
        apt install -y bind9 bind9utils
        
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
mail    IN      A       $IP
EOF
        
        systemctl restart bind9
        systemctl enable bind9
        
        echo -e "\n${GREEN}✅ DNS BERHASIL! Domain: $DOMAIN -> $IP${NC}"
    else
        echo -e "${RED}❌ Pilihan tidak valid!${NC}"
    fi
    read -p "Tekan Enter..."
}

# ======================= 3. DNS SERVER (3 TAMPILAN) =======================
install_dns_three() {
    clear
    echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║           🔍 DNS SERVER (3 TAMPILAN BERBEDA)                     ║${NC}"
    echo -e "${MAGENTA}║           1. Tutorial DHCP | 2. Tutorial CRUD | 3. Tutorial Apache2 ║${NC}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${YELLOW}Pilih jenis tutorial:${NC}"
    echo -e "  ${GREEN}1.${NC} Tutorial DHCP Server"
    echo -e "  ${GREEN}2.${NC} Tutorial CRUD Siswa"
    echo -e "  ${GREEN}3.${NC} Tutorial Apache2 Web Server"
    read -p "Pilih [1-3]: " tutorial_choice
    
    show_interfaces
    echo -e "\n${YELLOW}👉 Pilih interface untuk DNS Server:${NC}"
    read -p "Nomor [1-${#INTERFACES[@]}]: " choice
    
    if [[ $choice -ge 1 && $choice -le ${#INTERFACES[@]} ]]; then
        IFS='|' read -r IFACE IP <<< "${INTERFACES[$((choice-1))]}"
        echo -e "\n${MAGENTA}📝 Masukkan nama domain (contoh: tutorial.fahtech.com):${NC}"
        read -p "Domain: " DOMAIN
        
        apt update -qq
        apt install -y bind9 bind9utils
        
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
        
        systemctl restart bind9
        systemctl enable bind9
        
        echo -e "\n${GREEN}✅ DNS BERHASIL! Domain: $DOMAIN -> $IP${NC}"
        
        # Tampilkan tutorial sesuai pilihan
        echo -e "\n${CYAN}════════════════════════════════════════════════════════════════════${NC}"
        
        if [[ $tutorial_choice -eq 1 ]]; then
            echo -e "${CYAN}           📖 TUTORIAL DHCP SERVER LENGKAP${NC}"
            echo -e "${CYAN}════════════════════════════════════════════════════════════════════${NC}"
            echo -e ""
            echo -e "📌 LANGKAH 1: INSTALL DHCP SERVER"
            echo -e "   sudo apt install isc-dhcp-server -y"
            echo -e ""
            echo -e "📌 LANGKAH 2: KONFIGURASI INTERFACE"
            echo -e "   sudo nano /etc/default/isc-dhcp-server"
            echo -e "   INTERFACESv4=\"$IFACE\""
            echo -e ""
            echo -e "📌 LANGKAH 3: KONFIGURASI DHCP"
            echo -e "   sudo nano /etc/dhcp/dhcpd.conf"
            echo -e "   subnet ${IP%.*}.0 netmask 255.255.255.0 {"
            echo -e "       range ${IP%.*}.100 ${IP%.*}.200;"
            echo -e "       option routers ${IP%.*}.1;"
            echo -e "       option domain-name-servers $IP, 8.8.8.8;"
            echo -e "   }"
            echo -e ""
            echo -e "📌 LANGKAH 4: START DHCP SERVER"
            echo -e "   sudo systemctl restart isc-dhcp-server"
            echo -e "   sudo systemctl enable isc-dhcp-server"
            echo -e ""
            echo -e "📌 LANGKAH 5: CEK STATUS"
            echo -e "   sudo systemctl status isc-dhcp-server"
            echo -e "   sudo cat /var/lib/dhcp/dhcpd.leases"
        elif [[ $tutorial_choice -eq 2 ]]; then
            echo -e "${CYAN}           📖 TUTORIAL CRUD SISWA LENGKAP${NC}"
            echo -e "${CYAN}════════════════════════════════════════════════════════════════════${NC}"
            echo -e ""
            echo -e "📌 LANGKAH 1: INSTALL APACHE2 & PHP"
            echo -e "   sudo apt install apache2 php libapache2-mod-php php-sqlite3 -y"
            echo -e ""
            echo -e "📌 LANGKAH 2: BUAT FOLDER CRUD"
            echo -e "   sudo mkdir -p /var/www/html/crud"
            echo -e ""
            echo -e "📌 LANGKAH 3: FITUR CRUD"
            echo -e "   ➕ CREATE: INSERT INTO siswa (nama, rombel, nis) VALUES (...)"
            echo -e "   📖 READ: SELECT * FROM siswa ORDER BY id DESC"
            echo -e "   ✏️ UPDATE: UPDATE siswa SET nama='...' WHERE id=..."
            echo -e "   🗑️ DELETE: DELETE FROM siswa WHERE id=..."
            echo -e "   🔍 SEARCH: SELECT * FROM siswa WHERE nama LIKE '%...%'"
            echo -e ""
            echo -e "📌 LANGKAH 4: AKSES CRUD"
            echo -e "   Buka browser: http://$IP/crud/"
        else
            echo -e "${CYAN}           📖 TUTORIAL APACHE2 WEB SERVER LENGKAP${NC}"
            echo -e "${CYAN}════════════════════════════════════════════════════════════════════${NC}"
            echo -e ""
            echo -e "📌 LANGKAH 1: INSTALL APACHE2"
            echo -e "   sudo apt install apache2 -y"
            echo -e ""
            echo -e "📌 LANGKAH 2: KONFIGURASI VIRTUAL HOST"
            echo -e "   sudo nano /etc/apache2/sites-available/$DOMAIN.conf"
            echo -e "   <VirtualHost *:80>"
            echo -e "       ServerName $DOMAIN"
            echo -e "       ServerAlias www.$DOMAIN"
            echo -e "       DocumentRoot /var/www/html/$DOMAIN"
            echo -e "   </VirtualHost>"
            echo -e ""
            echo -e "📌 LANGKAH 3: AKTIFKAN SITE"
            echo -e "   sudo a2ensite $DOMAIN.conf"
            echo -e "   sudo a2dissite 000-default.conf"
            echo -e "   sudo systemctl reload apache2"
            echo -e ""
            echo -e "📌 LANGKAH 4: AKSES WEBSITE"
            echo -e "   Buka browser: http://$IP"
        fi
        echo -e "${CYAN}════════════════════════════════════════════════════════════════════${NC}"
    else
        echo -e "${RED}❌ Pilihan tidak valid!${NC}"
    fi
    read -p "Tekan Enter..."
}

# ======================= 4. APACHE2 =======================
install_apache2() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              🌍 INSTALL APACHE2                ║${NC}"
    echo -e "${GREEN}║           + LANDING PAGE KEREN                 ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
    apt update -qq
    apt install -y apache2 php libapache2-mod-php
    
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
<div class="service">📝 WP</div><div class="service">🗄️ CRUD</div><div class="service">🌍 Webmail</div>
</div>
<p style="color:white;">Powered by FahTech Installer v14.0</p>
</body>
</html>
EOF
    
    systemctl restart apache2
    echo -e "\n${GREEN}✅ APACHE2 BERHASIL! Akses: http://$SERVER_IP${NC}"
    read -p "Tekan Enter..."
}

# ======================= 5. FTP SERVER =======================
install_ftp() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              📁 INSTALL FTP SERVER             ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
    apt update -qq
    apt install -y vsftpd
    systemctl restart vsftpd
    systemctl enable vsftpd
    
    echo -e "\n${GREEN}✅ FTP BERHASIL! Akses: ftp://$SERVER_IP${NC}"
    echo -e "${YELLOW}   📌 Login pakai user Linux (contoh: root)${NC}"
    read -p "Tekan Enter..."
}

# ======================= 6. SAMBA =======================
install_samba() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              🖥️ INSTALL SAMBA                  ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
    read -p "📝 Nama Share (Enter untuk 'public'): " share_name
    share_name=${share_name:-public}
    
    apt update -qq
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

# ======================= 7. MAIL SERVER =======================
install_mail() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              📧 INSTALL MAIL SERVER            ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
    show_interfaces
    echo -e "\n${YELLOW}👉 Pilih interface untuk Mail Server:${NC}"
    read -p "Nomor [1-${#INTERFACES[@]}]: " choice
    if [[ $choice -ge 1 && $choice -le ${#INTERFACES[@]} ]]; then
        IFS='|' read -r MAIL_IFACE MAIL_IP <<< "${INTERFACES[$((choice-1))]}"
    else
        MAIL_IP=$SERVER_IP
    fi
    
    echo -e "\n${YELLOW}📝 Masukkan domain (contoh: fahtech.com):${NC}"
    read -p "Domain: " MAIN_DOMAIN
    echo -e "\n${YELLOW}📝 Buat akun email:${NC}"
    read -p "Username: " EMAIL_USER
    EMAIL_USER=${EMAIL_USER:-admin}
    read -s -p "Password: " EMAIL_PASS
    echo ""
    EMAIL_PASS=${EMAIL_PASS:-admin123}
    
    MAIL_DOMAIN="mail.$MAIN_DOMAIN"
    hostnamectl set-hostname $MAIL_DOMAIN
    echo "$MAIL_IP $MAIL_DOMAIN" >> /etc/hosts
    
    apt update -qq
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

passdb {
  driver = passwd-file
  args = scheme=PLAIN /etc/dovecot/users
}

userdb {
  driver = passwd
}

protocols = imap pop3

service auth {
  unix_listener /var/spool/postfix/private/auth {
    mode = 0660
    user = postfix
    group = postfix
  }
}

ssl = no
EOF
    
    mkdir -p /etc/dovecot
    echo "$EMAIL_USER@$MAIN_DOMAIN:$EMAIL_PASS" > /etc/dovecot/users
    chmod 600 /etc/dovecot/users
    useradd -m -s /bin/false $EMAIL_USER 2>/dev/null
    echo "$EMAIL_USER:$EMAIL_PASS" | chpasswd
    mkdir -p /home/$EMAIL_USER/Maildir/{cur,new,tmp}
    chown -R $EMAIL_USER:$EMAIL_USER /home/$EMAIL_USER/Maildir
    
    systemctl restart postfix dovecot
    systemctl enable postfix dovecot
    
    echo "$MAIN_DOMAIN" > /etc/maildomain.conf
    echo "$MAIL_IP" > /etc/mailip.conf
    echo "$EMAIL_USER" > /etc/mailuser.conf
    echo "$EMAIL_PASS" > /etc/mailpass.conf
    
    echo -e "\n${GREEN}✅ MAIL SERVER BERHASIL! $EMAIL_USER@$MAIN_DOMAIN / $EMAIL_PASS${NC}"
    read -p "Tekan Enter..."
}

# ======================= 8. WORDPRESS =======================
install_wordpress() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              📝 INSTALL WORDPRESS              ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
    apt update -qq
    apt install -y mariadb-server
    systemctl restart mariadb
    
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

# ======================= 9. CRUD SISWA =======================
install_crud() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         🗄️ INSTALL CRUD SISWA                 ║${NC}"
    echo -e "${GREEN}║   (Nama + Rombel + NIS) - Tambah/Edit/Hapus/Cari ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
    apt update -qq
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
    echo -e "${GREEN}   📌 Fitur: ✨ Tambah | ✏️ Edit | 🗑️ Hapus | 🔍 Cari${NC}"
    read -p "Tekan Enter..."
}

# ======================= 10. WEBMAIL =======================
install_webmail() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         🌐 INSTALL WEBMAIL (ROUNDCUBE)         ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
    if [[ -f /etc/maildomain.conf ]]; then
        MAIN_DOMAIN=$(cat /etc/maildomain.conf 2>/dev/null)
        MAIL_IP=$(cat /etc/mailip.conf 2>/dev/null)
        EMAIL_USER=$(cat /etc/mailuser.conf 2>/dev/null)
        EMAIL_PASS=$(cat /etc/mailpass.conf 2>/dev/null)
    else
        echo -e "\n${RED}❌ Mail Server belum diinstall! Install dulu menu 7.${NC}"
        read -p "Tekan Enter..."
        return
    fi
    
    apt update -qq
    apt remove --purge -y roundcube* php-roundcube* dbconfig-common 2>/dev/null
    rm -rf /etc/roundcube /var/lib/roundcube /usr/share/roundcube
    apt install -y roundcube roundcube-mysql roundcube-core php-mysql dbconfig-common
    
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
Alias /webmail /usr/share/roundcube
<Directory /usr/share/roundcube/>
    Options +FollowSymLinks
    AllowOverride All
    Require all granted
</Directory>
APACHE
    
    a2enconf roundcube
    a2enmod rewrite
    systemctl restart apache2 postfix dovecot
    
    echo -e "\n${GREEN}✅ WEBMAIL BERHASIL! Akses: http://$MAIL_IP/roundcube/${NC}"
    echo -e "${GREEN}   📧 Login: $EMAIL_USER@$MAIN_DOMAIN / $EMAIL_PASS${NC}"
    read -p "Tekan Enter..."
}

# ======================= 11. INSTALL SEMUA =======================
install_all() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         ⚡ INSTALL SEMUA SERVICE LENGKAP       ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${YELLOW}⚠️ Proses akan memakan waktu 15-20 menit. Lanjutkan? (y/n):${NC}"
    read confirm
    if [[ "$confirm" == "y" ]]; then
        install_apache2
        install_dhcp
        install_ftp
        install_samba
        install_wordpress
        install_crud
        install_mail
        install_webmail
        
        echo -e "\n${GREEN}════════════════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}   🎉 SEMUA SERVICE BERHASIL DIINSTALL! 🎉${NC}"
        echo -e "${GREEN}════════════════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}   🌐 Landing: http://$SERVER_IP${NC}"
        echo -e "${GREEN}   📚 CRUD: http://$SERVER_IP/crud/${NC}"
        echo -e "${GREEN}   📧 Webmail: http://$SERVER_IP/roundcube/${NC}"
        echo -e "${GREEN}   📝 WordPress: http://$SERVER_IP/wp-admin${NC}"
        echo -e "${GREEN}   📁 FTP: ftp://$SERVER_IP${NC}"
        echo -e "${GREEN}   🖥️ Samba: \\\\$SERVER_IP\\public${NC}"
        echo -e "${GREEN}════════════════════════════════════════════════════════════════════${NC}"
    fi
    read -p "Tekan Enter..."
}

# ======================= 12. HAPUS SERVICE =======================
uninstall_service() {
    clear
    echo -e "${RED}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║              🗑️ HAPUS SERVICE                  ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${YELLOW}Pilih service yang akan dihapus:${NC}"
    echo -e "  ${GREEN}1.${NC} Hapus DHCP Server"
    echo -e "  ${GREEN}2.${NC} Hapus DNS Server"
    echo -e "  ${GREEN}3.${NC} Hapus Apache2"
    echo -e "  ${GREEN}4.${NC} Hapus FTP Server"
    echo -e "  ${GREEN}5.${NC} Hapus Samba"
    echo -e "  ${GREEN}6.${NC} Hapus Mail Server"
    echo -e "  ${GREEN}7.${NC} Hapus WordPress"
    echo -e "  ${GREEN}8.${NC} Hapus CRUD"
    echo -e "  ${GREEN}9.${NC} Hapus Webmail"
    echo -e "  ${GREEN}10.${NC} Hapus SEMUA Service + Folder"
    read -p "Pilih [1-10]: " uninstall_choice
    
    case $uninstall_choice in
        1) 
            apt remove --purge -y isc-dhcp-server
            rm -rf /etc/dhcp /var/lib/dhcp
            echo "✅ DHCP dihapus!"
            ;;
        2) 
            apt remove --purge -y bind9 bind9utils
            rm -rf /etc/bind /var/lib/bind
            echo "✅ DNS dihapus!"
            ;;
        3) 
            apt remove --purge -y apache2 apache2-bin apache2-data
            rm -rf /etc/apache2 /var/www/html
            echo "✅ Apache2 dihapus!"
            ;;
        4) 
            apt remove --purge -y vsftpd
            rm -rf /etc/vsftpd.conf
            echo "✅ FTP dihapus!"
            ;;
        5) 
            apt remove --purge -y samba samba-common
            rm -rf /etc/samba /home/share /var/lib/samba
            echo "✅ Samba dihapus!"
            ;;
        6) 
            apt remove --purge -y postfix dovecot-core dovecot-imapd dovecot-pop3d mailutils
            rm -rf /etc/postfix /etc/dovecot /home/*/Maildir /var/mail
            echo "✅ Mail Server dihapus!"
            ;;
        7) 
            rm -rf /var/www/html/wp-* /var/www/html/wordpress
            mysql -u root -e "DROP DATABASE IF EXISTS wordpress;" 2>/dev/null
            mysql -u root -e "DROP USER IF EXISTS 'wpuser'@'localhost';" 2>/dev/null
            echo "✅ WordPress dihapus!"
            ;;
        8) 
            rm -rf /var/www/html/crud
            echo "✅ CRUD dihapus!"
            ;;
        9) 
            apt remove --purge -y roundcube* php-roundcube* dbconfig-common
            rm -rf /etc/roundcube /var/lib/roundcube /usr/share/roundcube
            mysql -u root -e "DROP DATABASE IF EXISTS roundcubemail;" 2>/dev/null
            mysql -u root -e "DROP USER IF EXISTS 'roundcube'@'localhost';" 2>/dev/null
            echo "✅ Webmail dihapus!"
            ;;
        10)
            echo -e "${RED}🗑️ Menghapus SEMUA Service dan Folder...${NC}"
            # Stop semua service
            systemctl stop apache2 bind9 isc-dhcp-server postfix dovecot samba smbd vsftpd mariadb mysql 2>/dev/null
            systemctl disable apache2 bind9 isc-dhcp-server postfix dovecot samba smbd vsftpd mariadb mysql 2>/dev/null
            
            # Hapus semua paket
            apt remove --purge -y apache2* bind9* isc-dhcp-server* postfix* dovecot* samba* vsftpd* mariadb* mysql* roundcube* php* 2>/dev/null
            
            # Hapus semua folder
            rm -rf /var/www/html /var/www/*
            rm -rf /etc/apache2 /etc/bind /etc/dhcp /etc/postfix /etc/dovecot /etc/samba /etc/mysql /etc/roundcube
            rm -rf /var/lib/mysql /var/lib/dhcp /var/lib/bind /var/lib/roundcube
            rm -rf /var/log/apache2 /var/log/bind /var/log/mysql /var/log/postfix
            rm -rf /home/share /home/*/Maildir
            rm -rf /etc/dbconfig-common /var/lib/dbconfig-common
            
            # Hapus user
            userdel -r admin 2>/dev/null
            userdel -r ftpuser 2>/dev/null
            userdel -r wpuser 2>/dev/null
            
            # Hapus database
            rm -rf /var/lib/mysql
            rm -rf /etc/mysql
            
            # Bersihkan
            apt autoremove --purge -y
            apt autoclean
            apt clean
            
            echo -e "${GREEN}✅ SEMUA SERVICE DAN FOLDER BERHASIL DIHAPUS!${NC}"
            echo -e "${GREEN}📁 Server sekarang bersih seperti baru pertama install.${NC}"
            ;;
        *)
            echo -e "${RED}❌ Pilihan salah!${NC}"
            ;;
    esac
    read -p "Tekan Enter..."
}

# ======================= 13. CEK STATUS =======================
check_status() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              📊 CEK STATUS SERVICE             ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}  SERVICE            | STATUS${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # DHCP
    if systemctl is-active --quiet isc-dhcp-server; then
        echo -e "  🌐 DHCP Server       | ${GREEN}✅ ACTIVE${NC}"
    else
        echo -e "  🌐 DHCP Server       | ${RED}❌ INACTIVE${NC}"
    fi
    
    # DNS
    if systemctl is-active --quiet bind9; then
        echo -e "  🔍 DNS Server        | ${GREEN}✅ ACTIVE${NC}"
    else
        echo -e "  🔍 DNS Server        | ${RED}❌ INACTIVE${NC}"
    fi
    
    # Apache2
    if systemctl is-active --quiet apache2; then
        echo -e "  🌍 Apache2           | ${GREEN}✅ ACTIVE${NC}"
    else
        echo -e "  🌍 Apache2           | ${RED}❌ INACTIVE${NC}"
    fi
    
    # FTP
    if systemctl is-active --quiet vsftpd; then
        echo -e "  📁 FTP Server        | ${GREEN}✅ ACTIVE${NC}"
    else
        echo -e "  📁 FTP Server        | ${RED}❌ INACTIVE${NC}"
    fi
    
    # Samba
    if systemctl is-active --quiet smbd; then
        echo -e "  🖥️ Samba             | ${GREEN}✅ ACTIVE${NC}"
    else
        echo -e "  🖥️ Samba             | ${RED}❌ INACTIVE${NC}"
    fi
    
    # Postfix
    if systemctl is-active --quiet postfix; then
        echo -e "  📧 Postfix (Mail)    | ${GREEN}✅ ACTIVE${NC}"
    else
        echo -e "  📧 Postfix (Mail)    | ${RED}❌ INACTIVE${NC}"
    fi
    
    # Dovecot
    if systemctl is-active --quiet dovecot; then
        echo -e "  📧 Dovecot (IMAP)    | ${GREEN}✅ ACTIVE${NC}"
    else
        echo -e "  📧 Dovecot (IMAP)    | ${RED}❌ INACTIVE${NC}"
    fi
    
    # MariaDB
    if systemctl is-active --quiet mariadb; then
        echo -e "  🗄️ MariaDB           | ${GREEN}✅ ACTIVE${NC}"
    else
        echo -e "  🗄️ MariaDB           | ${RED}❌ INACTIVE${NC}"
    fi
    
    # Roundcube
    if [ -d /usr/share/roundcube ]; then
        echo -e "  🌐 Webmail           | ${GREEN}✅ INSTALLED${NC}"
    else
        echo -e "  🌐 Webmail           | ${RED}❌ NOT INSTALLED${NC}"
    fi
    
    # CRUD
    if [ -d /var/www/html/crud ]; then
        echo -e "  📚 CRUD Siswa        | ${GREEN}✅ INSTALLED${NC}"
    else
        echo -e "  📚 CRUD Siswa        | ${RED}❌ NOT INSTALLED${NC}"
    fi
    
    # WordPress
    if [ -f /var/www/html/wp-config.php ]; then
        echo -e "  📝 WordPress         | ${GREEN}✅ INSTALLED${NC}"
    else
        echo -e "  📝 WordPress         | ${RED}❌ NOT INSTALLED${NC}"
    fi
    
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -p "Tekan Enter..."
}

# ======================= 14. MENU UTAMA =======================
while true; do
    clear
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                             ║"
    echo "║            🚀 FAHTECH MULTI-SERVICE INSTALLER v14.0                        ║"
    echo "║                    14 KONFIGURASI | HAPUS SEMUA FOLDER                      ║"
    echo "║                                                                             ║"
    echo "╠════════════════════════════════════════════════════════════════════════════╣"
    echo "║                                                                             ║"
    echo "║  🌐 LAYANAN UTAMA                                                          ║"
    echo "║  ───────────────────────────────────────────────────────────────────────── ║"
    echo "║    1.  🌐 Install DHCP Server (Otomatis Deteksi Interface)                 ║"
    echo "║    2.  🔍 Install DNS Server (1 Domain Saja)                               ║"
    echo "║    3.  🔍 Install DNS Server (3 Tampilan Berbeda + Tutorial)               ║"
    echo "║    4.  🌍 Install Apache2 + Landing Page Keren                             ║"
    echo "║    5.  📁 Install FTP Server (vsftpd)                                      ║"
    echo "║    6.  🖥️ Install Samba File Server                                        ║"
    echo "║    7.  📧 Install Mail Server (Postfix + Dovecot)                          ║"
    echo "║    8.  📝 Install WordPress + Database Auto Setup                          ║"
    echo "║    9.  🗄️ Install CRUD Siswa (Nama+Rombel+NIS) - Tambah/Edit/Hapus/Cari   ║"
    echo "║    10. 🌐 Install Webmail (Roundcube) - Akses Email via Browser            ║"
    echo "║                                                                             ║"
    echo "║  ⚡ FITUR TAMBAHAN                                                         ║"
    echo "║  ───────────────────────────────────────────────────────────────────────── ║"
    echo "║    11. ⚡ Install SEMUA Service (Otomatis)                                  ║"
    echo "║    12. 🗑️ Hapus Service (Pilih per service atau hapus semua)              ║"
    echo "║    13. 📊 Cek Status Service                                               ║"
    echo "║    14. 🚪 Exit                                                             ║"
    echo "╚════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    read -p "👉 Pilih menu [1-14]: " menu
    
    case $menu in
        1) install_dhcp ;;
        2) install_dns_single ;;
        3) install_dns_three ;;
        4) install_apache2 ;;
        5) install_ftp ;;
        6) install_samba ;;
        7) install_mail ;;
        8) install_wordpress ;;
        9) install_crud ;;
        10) install_webmail ;;
        11) install_all ;;
        12) uninstall_service ;;
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
