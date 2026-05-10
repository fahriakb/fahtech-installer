#!/bin/bash

# ============================================================
#   FAHTECH - MULTI-SERVICE INSTALLER PRO
#   LENGKAP DENGAN PILIHAN INTERFACE & DOMAIN
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
echo "║                MULTI-SERVICE INSTALLER PROFESSIONAL              ║"
echo "║         DHCP + DNS + FTP + SAMBA + MAIL + WEBMAIL + CRUD         ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ Jalankan sebagai root!${NC}"
    exit 1
fi

# Variabel global
SELECTED_IP=""
SELECTED_IFACE=""
MAIN_DOMAIN=""
EMAIL_USER=""
EMAIL_PASS=""

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

# ======================= APACHE2 =======================
install_apache2() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              🌍 INSTALL APACHE2                ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
    apt update -qq
    apt install -y apache2 php libapache2-mod-php php-mysql php-sqlite3 php-curl php-gd php-xml php-mbstring php-zip
    
    SERVER_IP=$(hostname -I | awk '{print $1}')
    
    cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html>
<head><title>FahTech Server</title>
<style>
body { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); font-family: Arial; text-align: center; padding: 50px; }
h1 { color: white; font-size: 48px; }
.status { background: #4CAF50; padding: 10px; border-radius: 10px; color: white; }
.services { display: flex; justify-content: center; gap: 20px; margin-top: 30px; flex-wrap: wrap; }
.service { background: white; padding: 15px; border-radius: 10px; min-width: 120px; }
</style>
</head>
<body>
<h1>⚡ FAHTECH SERVER ⚡</h1>
<div class="status">✅ ALL SERVICES RUNNING</div>
<p style="color:white;">Server IP: <?php echo \$_SERVER['SERVER_ADDR']; ?></p>
<div class="services">
<div class="service">🌐 Web</div><div class="service">📧 Mail</div>
<div class="service">📝 WP</div><div class="service">🗄️ CRUD</div><div class="service">🌍 Webmail</div>
</div>
<p style="color:white;">Powered by FahTech Installer</p>
</body>
</html>
EOF
    
    systemctl restart apache2
    echo -e "\n${GREEN}✅ APACHE2 BERHASIL! Akses: http://$SERVER_IP${NC}"
    read -p "Tekan Enter..."
}

# ======================= DHCP =======================
install_dhcp() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              🌐 INSTALL DHCP SERVER            ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
    show_interfaces
    echo -e "\n${YELLOW}👉 Pilih interface untuk DHCP Server:${NC}"
    read -p "Masukkan nomor [1-${#INTERFACES[@]}]: " choice
    
    if [[ $choice -ge 1 && $choice -le ${#INTERFACES[@]} ]]; then
        IFS='|' read -r SELECTED_IFACE SELECTED_IP <<< "${INTERFACES[$((choice-1))]}"
        SUBNET=$(echo $SELECTED_IP | cut -d. -f1-3).0
        GATEWAY=$(echo $SELECTED_IP | cut -d. -f1-3).1
        RANGE_START=$(echo $SELECTED_IP | cut -d. -f1-3).100
        RANGE_END=$(echo $SELECTED_IP | cut -d. -f1-3).200
        
        echo -e "\n${CYAN}📝 Konfigurasi otomatis:${NC}"
        echo -e "   Interface: ${GREEN}$SELECTED_IFACE${NC}"
        echo -e "   Subnet: ${GREEN}$SUBNET/24${NC}"
        echo -e "   Gateway: ${GREEN}$GATEWAY${NC}"
        echo -e "   Range IP: ${GREEN}$RANGE_START - $RANGE_END${NC}"
        
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
    fi
    read -p "Tekan Enter..."
}

# ======================= DNS =======================
install_dns() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              🔍 INSTALL DNS SERVER             ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
    show_interfaces
    echo -e "\n${YELLOW}👉 Pilih interface untuk DNS Server:${NC}"
    read -p "Masukkan nomor [1-${#INTERFACES[@]}]: " choice
    
    if [[ $choice -ge 1 && $choice -le ${#INTERFACES[@]} ]]; then
        IFS='|' read -r DNS_IFACE DNS_IP <<< "${INTERFACES[$((choice-1))]}"
        
        echo -e "\n${CYAN}📝 Masukkan nama domain utama:${NC}"
        echo -e "${YELLOW}   Contoh: fahriakbar.net, perusahaan.com, toko123.id${NC}"
        read -p "Domain: " MAIN_DOMAIN
        
        apt install -y bind9 bind9utils
        
        cat > /etc/bind/named.conf.local <<EOF
zone "$MAIN_DOMAIN" {
    type master;
    file "/etc/bind/db.$MAIN_DOMAIN";
};
EOF
        
        cat > /etc/bind/db.$MAIN_DOMAIN <<EOF
\$TTL    604800
@       IN      SOA     ns1.$MAIN_DOMAIN. admin.$MAIN_DOMAIN. ( 1 604800 86400 2419200 604800 )
@       IN      NS      ns1.$MAIN_DOMAIN.
@       IN      A       $DNS_IP
@       IN      MX 10   mail.$MAIN_DOMAIN.
ns1     IN      A       $DNS_IP
www     IN      A       $DNS_IP
mail    IN      A       $DNS_IP
EOF
        
        systemctl unmask bind9
        systemctl restart bind9
        systemctl enable bind9
        
        echo "$MAIN_DOMAIN" > /etc/maildomain.conf
        echo "$DNS_IP" > /etc/mailip.conf
        
        echo -e "\n${GREEN}✅ DNS BERHASIL!${NC}"
        echo -e "   📝 Domain: $MAIN_DOMAIN"
        echo -e "   🌐 IP: $DNS_IP"
        echo -e "   📧 Subdomain mail: mail.$MAIN_DOMAIN"
    fi
    read -p "Tekan Enter..."
}

# ======================= FTP =======================
install_ftp() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              📁 INSTALL FTP SERVER             ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
    apt install -y vsftpd
    systemctl restart vsftpd
    systemctl enable vsftpd
    
    SERVER_IP=$(hostname -I | awk '{print $1}')
    echo -e "\n${GREEN}✅ FTP BERHASIL! Akses: ftp://$SERVER_IP${NC}"
    echo -e "${YELLOW}   📌 Login pakai user Linux (contoh: root, fahri)${NC}"
    read -p "Tekan Enter..."
}

# ======================= SAMBA =======================
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
   directory mask = 0777
EOF
    
    systemctl restart smbd
    systemctl enable smbd
    
    SERVER_IP=$(hostname -I | awk '{print $1}')
    echo -e "\n${GREEN}✅ SAMBA BERHASIL! Akses: \\\\$SERVER_IP\\$share_name${NC}"
    read -p "Tekan Enter..."
}

# ======================= WORDPRESS =======================
install_wordpress() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              📝 INSTALL WORDPRESS              ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
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
    
    SERVER_IP=$(hostname -I | awk '{print $1}')
    
    echo -e "\n${GREEN}✅ WORDPRESS BERHASIL! Akses: http://$SERVER_IP/wp-admin/install.php${NC}"
    echo -e "${YELLOW}   🔑 DB Password: $DB_PASS${NC}"
    read -p "Tekan Enter..."
}

# ======================= CRUD SISWA =======================
install_crud() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         🗄️ INSTALL CRUD SISWA                 ║${NC}"
    echo -e "${GREEN}║      (Nama + Rombel + NIS)                    ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
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
input{border:1px solid #ddd}
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
    
    SERVER_IP=$(hostname -I | awk '{print $1}')
    echo -e "\n${GREEN}✅ CRUD SISWA BERHASIL! Akses: http://$SERVER_IP/crud/${NC}"
    read -p "Tekan Enter..."
}

# ======================= MAIL SERVER (LENGKAP DENGAN INPUT) =======================
install_mail() {
    clear
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    📧 INSTALL MAIL SERVER                        ║${NC}"
    echo -e "${GREEN}║              POSTFIX + DOVECOT + WEBMAIL READY                   ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    
    # Pilih interface
    show_interfaces
    echo -e "\n${YELLOW}👉 Pilih interface untuk Mail Server:${NC}"
    read -p "Masukkan nomor [1-${#INTERFACES[@]}]: " choice
    
    if [[ $choice -ge 1 && $choice -le ${#INTERFACES[@]} ]]; then
        IFS='|' read -r SELECTED_IFACE SELECTED_IP <<< "${INTERFACES[$((choice-1))]}"
        SELECTED_IP=$SELECTED_IP
        echo -e "\n${GREEN}✅ Terpilih: $SELECTED_IFACE (IP: $SELECTED_IP)${NC}"
    else
        SELECTED_IP=$(hostname -I | awk '{print $1}')
        echo -e "\n${YELLOW}⚠️ Menggunakan IP default: $SELECTED_IP${NC}"
    fi
    
    # Input domain
    echo -e "\n${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  📝 MASUKKAN DOMAIN UNTUK EMAIL                                   ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║  📌 CONTOH: fahriakbar.net, perusahaan.com, toko123.id            ║${NC}"
    echo -e "${CYAN}║  💡 Nanti email menggunakan format: nama@domain-anda.com          ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo -e "\n${YELLOW}👉 Masukkan domain Anda:${NC}"
    read -p "Domain: " MAIN_DOMAIN
    
    # Input username
    echo -e "\n${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  👤 BUAT AKUN EMAIL ADMIN                                         ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║  📌 CONTOH USERNAME: admin, info, support, fahri                  ║${NC}"
    echo -e "${CYAN}║  💡 Nanti login: username@$MAIN_DOMAIN                            ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo -e "\n${YELLOW}👉 Masukkan username email:${NC}"
    read -p "Username: " EMAIL_USER
    EMAIL_USER=${EMAIL_USER:-admin}
    
    # Input password
    echo -e "\n${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  🔑 BUAT PASSWORD                                                  ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║  📌 CONTOH PASSWORD: admin123, rahasia123, FahTech2024            ║${NC}"
    echo -e "${CYAN}║  ⚠️  PASSWORD TIDAK AKAN TAMPIL SAAT DIKETIK                      ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo -e "\n${YELLOW}👉 Masukkan password:${NC}"
    read -s -p "Password: " EMAIL_PASS
    echo ""
    read -s -p "Konfirmasi password: " EMAIL_CONFIRM
    echo ""
    
    if [[ "$EMAIL_PASS" != "$EMAIL_CONFIRM" ]] || [[ -z "$EMAIL_PASS" ]]; then
        EMAIL_PASS="admin123"
        echo -e "${YELLOW}⚠️ Menggunakan password default: admin123${NC}"
    fi
    
    MAIL_DOMAIN="mail.$MAIN_DOMAIN"
    
    echo -e "\n${CYAN}📦 Menginstall Mail Server...${NC}"
    
    # Set hostname
    hostnamectl set-hostname $MAIL_DOMAIN
    echo "$SELECTED_IP $MAIL_DOMAIN" >> /etc/hosts
    
    # Install packages
    apt install -y postfix dovecot-core dovecot-imapd dovecot-pop3d mailutils
    
    # Konfigurasi Postfix
    postconf -e "myhostname = $MAIL_DOMAIN"
    postconf -e "mydomain = $MAIN_DOMAIN"
    postconf -e "myorigin = \$mydomain"
    postconf -e "inet_interfaces = all"
    postconf -e "home_mailbox = Maildir/"
    postconf -e "smtpd_sasl_type = dovecot"
    postconf -e "smtpd_sasl_path = private/auth"
    postconf -e "smtpd_sasl_auth_enable = yes"
    
    # Konfigurasi Dovecot
    rm -rf /etc/dovecot /etc/dovecot.conf
    cat > /etc/dovecot/dovecot.conf <<EOF
disable_plaintext_auth = no
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
    
    # Buat user email
    mkdir -p /etc/dovecot
    echo "$EMAIL_USER@$MAIN_DOMAIN:$EMAIL_PASS" > /etc/dovecot/users
    chmod 600 /etc/dovecot/users
    
    # Buat user system
    useradd -m -s /bin/false $EMAIL_USER 2>/dev/null
    echo "$EMAIL_USER:$EMAIL_PASS" | chpasswd
    mkdir -p /home/$EMAIL_USER/Maildir/{cur,new,tmp}
    chown -R $EMAIL_USER:$EMAIL_USER /home/$EMAIL_USER/Maildir
    
    systemctl restart postfix
    systemctl restart dovecot
    systemctl enable postfix dovecot
    
    # Simpan konfigurasi
    echo "$MAIN_DOMAIN" > /etc/maildomain.conf
    echo "$SELECTED_IP" > /etc/mailip.conf
    echo "$EMAIL_USER" > /etc/mailuser.conf
    echo "$EMAIL_PASS" > /etc/mailpass.conf
    
    echo -e "\n${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   ✅ MAIL SERVER BERHASIL!                                         ║${NC}"
    echo -e "${GREEN}╠══════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║   📧 Email: $EMAIL_USER@$MAIN_DOMAIN                              ║${NC}"
    echo -e "${GREEN}║   🔑 Password: $EMAIL_PASS                                        ║${NC}"
    echo -e "${GREEN}║   🌐 Webmail nanti: http://$SELECTED_IP/roundcube/               ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    
    read -p "Tekan Enter untuk lanjut install Webmail..."
}

# ======================= WEBMAIL =======================
install_webmail() {
    clear
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    📧 INSTALL WEBMAIL (ROUNDCUBE)                ║${NC}"
    echo -e "${GREEN}║              BISA LOGIN & KIRIM EMAIL VIA BROWSER                ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    
    # Baca konfigurasi dari mail server
    if [[ -f /etc/maildomain.conf ]]; then
        MAIN_DOMAIN=$(cat /etc/maildomain.conf)
        DNS_IP=$(cat /etc/mailip.conf)
        EMAIL_USER=$(cat /etc/mailuser.conf 2>/dev/null)
        EMAIL_PASS=$(cat /etc/mailpass.conf 2>/dev/null)
        echo -e "\n${GREEN}✅ Mendeteksi konfigurasi dari Mail Server:${NC}"
        echo -e "   📝 Domain: $MAIN_DOMAIN"
        echo -e "   🌐 IP: $DNS_IP"
        echo -e "   👤 User: $EMAIL_USER@$MAIN_DOMAIN"
    else
        echo -e "\n${RED}❌ Mail Server belum diinstall! Install dulu menu 7.${NC}"
        read -p "Tekan Enter..."
        return
    fi
    
    # Hapus yang lama total
    echo -e "\n${CYAN}📦 Membersihkan instalasi lama...${NC}"
    systemctl stop apache2 2>/dev/null
    dpkg --remove --force-remove-reinstreq roundcube-core roundcube roundcube-mysql 2>/dev/null
    dpkg --purge roundcube-core roundcube roundcube-mysql 2>/dev/null
    rm -rf /etc/roundcube /var/lib/roundcube /usr/share/roundcube
    mysql -u root -e "DROP DATABASE IF EXISTS roundcubemail;" 2>/dev/null
    mysql -u root -e "DROP USER IF EXISTS 'roundcube'@'localhost';" 2>/dev/null
    apt --fix-broken install -y 2>/dev/null
    
    echo -e "\n${CYAN}📦 Menginstall Roundcube Webmail...${NC}"
    apt install -y roundcube roundcube-mysql roundcube-core php-mysql
    
    # Konfigurasi database
    DB_PASS="rcube123"
    mysql -u root <<MYSQL 2>/dev/null
CREATE DATABASE IF NOT EXISTS roundcubemail;
CREATE USER IF NOT EXISTS 'roundcube'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON roundcubemail.* TO 'roundcube'@'localhost';
FLUSH PRIVILEGES;
MYSQL
    
    # Import database
    if [ -f /usr/share/roundcube/SQL/mysql.initial.sql ]; then
        mysql roundcubemail < /usr/share/roundcube/SQL/mysql.initial.sql 2>/dev/null
    fi
    
    # Konfigurasi Roundcube
    cat > /etc/roundcube/config.inc.php <<PHP
<?php
\$config = [];
\$config['db_dsnw'] = 'mysql://roundcube:rcube123@localhost/roundcubemail';
\$config['default_host'] = 'localhost';
\$config['smtp_server'] = 'localhost';
\$config['smtp_port'] = 25;
\$config['smtp_user'] = '%u';
\$config['smtp_pass'] = '%p';
\$config['product_name'] = 'FahTech Webmail - $MAIN_DOMAIN';
\$config['plugins'] = ['archive', 'zipdownload'];
\$config['skin'] = 'elastic';
PHP
    
    # Konfigurasi Apache
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
    systemctl restart apache2
    systemctl restart postfix dovecot
    
    echo -e "\n${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   ✅ WEBMAIL (ROUNDCUBE) BERHASIL!                                 ║${NC}"
    echo -e "${GREEN}╠══════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║                                                                    ║${NC}"
    echo -e "${GREEN}║   🌐 AKSES WEBMAIL:                                               ║${NC}"
    echo -e "${GREEN}║      👉 http://$DNS_IP/roundcube/                                 ║${NC}"
    echo -e "${GREEN}║                                                                    ║${NC}"
    echo -e "${GREEN}║   📝 LOGIN MENGGUNAKAN:                                            ║${NC}"
    echo -e "${GREEN}║      👤 Username: $EMAIL_USER@$MAIN_DOMAIN                        ║${NC}"
    echo -e "${GREEN}║      🔑 Password: $EMAIL_PASS                                      ║${NC}"
    echo -e "${GREEN}║                                                                    ║${NC}"
    echo -e "${GREEN}║   🌐 AKSES VIA DOMAIN (Setting hosts dulu):                        ║${NC}"
    echo -e "${GREEN}║      Tambahkan ke file hosts: $DNS_IP mail.$MAIN_DOMAIN           ║${NC}"
    echo -e "${GREEN}║      Lalu akses: http://mail.$MAIN_DOMAIN/roundcube/              ║${NC}"
    echo -e "${GREEN}║                                                                    ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    
    read -p "Tekan Enter..."
}

# ======================= INSTALL SEMUA =======================
install_all() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              ⚡ INSTALL SEMUA SERVICE LENGKAP              ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${YELLOW}⚠️ Proses akan memakan waktu 15-20 menit. Lanjutkan? (y/n):${NC}"
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
        
        SERVER_IP=$(hostname -I | awk '{print $1}')
        MAIN_DOMAIN=$(cat /etc/maildomain.conf 2>/dev/null || echo "domain-anda.com")
        EMAIL_USER=$(cat /etc/mailuser.conf 2>/dev/null || echo "admin")
        
        echo -e "\n${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║   🎉 SELAMAT! SEMUA SERVICE BERHASIL DIINSTALL! 🎉                 ║${NC}"
        echo -e "${GREEN}╠══════════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${GREEN}║                                                                    ║${NC}"
        echo -e "${GREEN}║   🌐 LANDING PAGE:  http://$SERVER_IP                              ║${NC}"
        echo -e "${GREEN}║   📚 CRUD SISWA:    http://$SERVER_IP/crud/                       ║${NC}"
        echo -e "${GREEN}║   📧 WEBMAIL:       http://$SERVER_IP/roundcube/                  ║${NC}"
        echo -e "${GREEN}║   📝 WORDPRESS:     http://$SERVER_IP/wp-admin                    ║${NC}"
        echo -e "${GREEN}║   📁 FTP:           ftp://$SERVER_IP                               ║${NC}"
        echo -e "${GREEN}║   🖥️  SAMBA:        \\\\$SERVER_IP\\public                           ║${NC}"
        echo -e "${GREEN}║                                                                    ║${NC}"
        echo -e "${GREEN}║   📧 LOGIN WEBMAIL:                                               ║${NC}"
        echo -e "${GREEN}║      👤 Username: $EMAIL_USER@$MAIN_DOMAIN                        ║${NC}"
        echo -e "${GREEN}║      🔑 Password: (password yang sudah dibuat)                    ║${NC}"
        echo -e "${GREEN}║                                                                    ║${NC}"
        echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    fi
    
    read -p "Tekan Enter..."
}

# ======================= MENU UTAMA =======================
while true; do
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║            🚀 FAHTECH MULTI-SERVICE INSTALLER v10.0             ║"
    echo "║         LENGKAP: INTERFACE + DOMAIN + USER + PASSWORD            ║"
    echo "╠══════════════════════════════════════════════════════════════════╣"
    echo "║                                                                  ║"
    echo "║  1.  ⚡ INSTALL SEMUA SERVICE LENGKAP (15-20 menit)              ║"
    echo "║  2.  🌐 Install DHCP Server (Pilih Interface)                   ║"
    echo "║  3.  🔍 Install DNS Server (Pilih Interface + Domain)           ║"
    echo "║  4.  🌍 Install Apache2 + Landing Page                          ║"
    echo "║  5.  📁 Install FTP Server                                      ║"
    echo "║  6.  🖥️  Install Samba                                          ║"
    echo "║  7.  📝 Install WordPress                                       ║"
    echo "║  8.  🗄️  Install CRUD SISWA (Nama+Rombel+NIS)                   ║"
    echo "║  9.  📧 Install MAIL SERVER (Pilih Interface + Domain + User)   ║"
    echo "║  10. 🌐 Install WEBMAIL (Roundcube) - Akses Email via Browser   ║"
    echo "║  11. 🚪 Exit                                                    ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    read -p "👉 Pilih menu [1-11]: " menu
    
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
