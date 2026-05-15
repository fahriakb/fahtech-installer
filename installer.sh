#!/bin/bash

# ============================================================
#   FAHTECH - MULTI-SERVICE INSTALLER PRO v17.0
#   ALL SERVICE + MAIL SERVER TERINTEGRASI DENGAN DNS
#   EMAIL PAKAI DOMAIN | WEBMAIL PAKAI SUBDOMAIN MAIL
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
echo "║              MULTI-SERVICE INSTALLER PROFESSIONAL v17.0                      ║"
echo "║     DHCP + DNS + FTP + SAMBA + WORDPRESS + CRUD + MAIL + WEBMAIL            ║"
echo "║              MAIL SERVER TERINTEGRASI DENGAN DNS                            ║"
echo "║              EMAIL: user@domain.com | WEBMAIL: mail.domain.com              ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ Jalankan sebagai root!${NC}"
    exit 1
fi

SERVER_IP=$(hostname -I | awk '{print $1}')
MAIN_DOMAIN=""
EMAIL_USER=""
EMAIL_PASS=""

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
    fi
    read -p "Tekan Enter..."
}

# ======================= 2. DNS SERVER =======================
install_dns() {
    clear
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║              🔍 INSTALL DNS SERVER (WAJIB SEBELUM MAIL)          ║${NC}"
    echo -e "${BLUE}║   Domain yang dibuat akan digunakan untuk:                       ║${NC}"
    echo -e "${BLUE}║   - Email: user@domain-anda.com                                  ║${NC}"
    echo -e "${BLUE}║   - Webmail: http://mail.domain-anda.com/roundcube/             ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
    
    show_interfaces
    echo -e "\n${YELLOW}👉 Pilih interface untuk DNS Server:${NC}"
    read -p "Nomor [1-${#INTERFACES[@]}]: " choice
    
    if [[ $choice -ge 1 && $choice -le ${#INTERFACES[@]} ]]; then
        IFS='|' read -r DNS_IFACE DNS_IP <<< "${INTERFACES[$((choice-1))]}"
        
        echo -e "\n${MAGENTA}╔══════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${MAGENTA}║  📝 MASUKKAN DOMAIN UTAMA                                         ║${NC}"
        echo -e "${MAGENTA}╠══════════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${MAGENTA}║                                                                   ║${NC}"
        echo -e "${MAGENTA}║  📌 CONTOH:                                                        ║${NC}"
        echo -e "${MAGENTA}║     • fahritech.net                                               ║${NC}"
        echo -e "${MAGENTA}║     • perusahaan.com                                              ║${NC}"
        echo -e "${MAGENTA}║     • toko123.id                                                  ║${NC}"
        echo -e "${MAGENTA}║                                                                   ║${NC}"
        echo -e "${MAGENTA}║  💡 NANTI EMAIL AKAN: nama@domain-anda.com                        ║${NC}"
        echo -e "${MAGENTA}║  💡 WEBMAIL AKAN: http://mail.domain-anda.com/roundcube/         ║${NC}"
        echo -e "${MAGENTA}║                                                                   ║${NC}"
        echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════════╝${NC}"
        echo -e "\n${YELLOW}👉 Masukkan domain Anda:${NC}"
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
        
        echo -e "\n${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║   ✅ DNS SERVER BERHASIL!                                          ║${NC}"
        echo -e "${GREEN}╠══════════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${GREEN}║   📝 Domain: $MAIN_DOMAIN                                         ║${NC}"
        echo -e "${GREEN}║   🌐 IP Server: $DNS_IP                                           ║${NC}"
        echo -e "${GREEN}║   📧 Subdomain Mail: mail.$MAIN_DOMAIN                            ║${NC}"
        echo -e "${GREEN}║   🌐 Subdomain WWW: www.$MAIN_DOMAIN                              ║${NC}"
        echo -e "${GREEN}║                                                                   ║${NC}"
        echo -e "${GREEN}║   📌 LANJUTKAN KE INSTALL MAIL SERVER (Menu 8)                    ║${NC}"
        echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
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
    
    cat > /var/www/html/index.html <<EOF
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
<p style="color:white;">Server IP: <?php echo \$_SERVER['SERVER_ADDR']; ?></p>
<div class="services">
<div class="service">🌐 Web</div><div class="service">📧 Mail</div>
<div class="service">📝 WP</div><div class="service">🗄️ CRUD</div>
<div class="service">🌍 Webmail</div><div class="service">📁 FTP</div>
</div>
<p style="color:white;">Powered by FahTech Installer v17.0</p>
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
    read -p "Tekan Enter..."
}

# ======================= 8. MAIL SERVER (TERINTEGRASI DENGAN DNS) =======================
install_mail() {
    clear
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   📧 INSTALL MAIL SERVER (TERINTEGRASI DENGAN DNS)              ║${NC}"
    echo -e "${BLUE}║   Menggunakan domain dari DNS yang sudah dibuat                  ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
    
    if [[ -f /etc/maildomain.conf ]]; then
        MAIN_DOMAIN=$(cat /etc/maildomain.conf)
        DNS_IP=$(cat /etc/mailip.conf)
        echo -e "\n${GREEN}✅ Domain terdeteksi dari DNS: $MAIN_DOMAIN${NC}"
        echo -e "✅ IP Server: $DNS_IP"
    else
        echo -e "\n${RED}❌ DNS belum diinstall! Install DNS dulu (Menu 3).${NC}"
        read -p "Tekan Enter..."
        return
    fi
    
    MAIL_DOMAIN="mail.$MAIN_DOMAIN"
    
    echo -e "\n${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  👤 BUAT AKUN EMAIL ADMIN                                          ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║                                                                   ║${NC}"
    echo -e "${CYAN}║  📌 CONTOH USERNAME: admin, info, support, fahri                  ║${NC}"
    echo -e "${CYAN}║  💡 Nanti login: username@$MAIN_DOMAIN                            ║${NC}"
    echo -e "${CYAN}║                                                                   ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo -e "\n${YELLOW}👉 Masukkan username email:${NC}"
    read -p "Username: " EMAIL_USER
    EMAIL_USER=${EMAIL_USER:-admin}
    
    echo -e "\n${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  🔑 BUAT PASSWORD                                                  ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║  📌 CONTOH: admin123, rahasia123, FahTech2024                     ║${NC}"
    echo -e "${CYAN}║  ⚠️  PASSWORD TIDAK AKAN TAMPIL SAAT DIKETIK                      ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo -e "\n${YELLOW}👉 Masukkan password:${NC}"
    read -s -p "Password: " EMAIL_PASS
    echo ""
    read -s -p "Konfirmasi password: " EMAIL_PASS_CONFIRM
    echo ""
    
    if [[ "$EMAIL_PASS" != "$EMAIL_PASS_CONFIRM" ]] || [[ -z "$EMAIL_PASS" ]]; then
        EMAIL_PASS="admin123"
        echo -e "${YELLOW}⚠️ Menggunakan password default: admin123${NC}"
    fi
    
    echo -e "\n${CYAN}📦 Menginstall Mail Server...${NC}"
    
    # Set hostname
    hostnamectl set-hostname $MAIL_DOMAIN
    echo "$DNS_IP $MAIL_DOMAIN mail" >> /etc/hosts
    
    # Install packages
    apt install -y postfix dovecot-core dovecot-imapd dovecot-pop3d mailutils
    
    # Konfigurasi Postfix
    postconf -e "myhostname = $MAIL_DOMAIN"
    postconf -e "mydomain = $MAIN_DOMAIN"
    postconf -e "myorigin = \$mydomain"
    postconf -e "inet_interfaces = all"
    postconf -e "inet_protocols = ipv4"
    postconf -e "mydestination = localhost, localhost.localdomain"
    postconf -e "home_mailbox = Maildir/"
    postconf -e "smtpd_sasl_type = dovecot"
    postconf -e "smtpd_sasl_path = private/auth"
    postconf -e "smtpd_sasl_auth_enable = yes"
    postconf -e "smtpd_recipient_restrictions = permit_sasl_authenticated, permit_mynetworks, reject_unauth_destination"
    postconf -e "mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128"
    
    # Konfigurasi Dovecot
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
    
    # Simpan data untuk webmail
    echo "$MAIN_DOMAIN" > /etc/maildomain.conf
    echo "$DNS_IP" > /etc/mailip.conf
    echo "$EMAIL_USER" > /etc/mailuser.conf
    echo "$EMAIL_PASS" > /etc/mailpass.conf
    
    echo -e "\n${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   ✅ MAIL SERVER BERHASIL!                                         ║${NC}"
    echo -e "${GREEN}╠══════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║                                                                   ║${NC}"
    echo -e "${GREEN}║   📧 EMAIL: $EMAIL_USER@$MAIN_DOMAIN                              ║${NC}"
    echo -e "${GREEN}║   🔑 PASSWORD: $EMAIL_PASS                                        ║${NC}"
    echo -e "${GREEN}║                                                                   ║${NC}"
    echo -e "${GREEN}║   🌐 WEBMAIL (setelah install menu 10):                           ║${NC}"
    echo -e "${GREEN}║      http://$DNS_IP/roundcube/                                   ║${NC}"
    echo -e "${GREEN}║      http://mail.$MAIN_DOMAIN/roundcube/ (setting hosts)         ║${NC}"
    echo -e "${GREEN}║                                                                   ║${NC}"
    echo -e "${GREEN}║   💡 KIRIM EMAIL KE SESAMA USER:                                  ║${NC}"
    echo -e "${GREEN}║      Bisa kirim ke: nama@$MAIN_DOMAIN (bukan @localhost!)        ║${NC}"
    echo -e "${GREEN}║                                                                   ║${NC}"
    echo -e "${GREEN}║   📌 LANJUTKAN KE MENU 10 UNTUK INSTALL WEBMAIL                   ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    
    read -p "Tekan Enter..."
}

# ======================= 9. TAMBAH USER EMAIL =======================
add_mail_user() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              👤 TAMBAH USER EMAIL BARU         ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
    if [[ ! -f /etc/maildomain.conf ]]; then
        echo -e "\n${RED}❌ Mail Server belum diinstall! Install dulu menu 8.${NC}"
        read -p "Tekan Enter..."
        return
    fi
    
    MAIN_DOMAIN=$(cat /etc/maildomain.conf)
    DNS_IP=$(cat /etc/mailip.conf)
    
    echo -e "\n${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  👤 BUAT USER EMAIL BARU                                           ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║  📌 CONTOH USERNAME: fahri, customer1, support, info              ║${NC}"
    echo -e "${CYAN}║  💡 Nanti login: username@$MAIN_DOMAIN                            ║${NC}"
    echo -e "${CYAN}║  💡 Bisa kirim email ke: $EMAIL_USER@$MAIN_DOMAIN                 ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo -e "\n${YELLOW}👉 Masukkan username:${NC}"
    read -p "Username: " NEW_USER
    
    echo -e "\n${YELLOW}👉 Masukkan password untuk $NEW_USER@$MAIN_DOMAIN:${NC}"
    read -s -p "Password: " NEW_PASS
    echo ""
    read -s -p "Konfirmasi password: " NEW_PASS_CONFIRM
    echo ""
    
    if [[ "$NEW_PASS" != "$NEW_PASS_CONFIRM" ]] || [[ -z "$NEW_PASS" ]]; then
        NEW_PASS="12345"
        echo -e "${YELLOW}⚠️ Menggunakan password default: 12345${NC}"
    fi
    
    # Tambahkan ke dovecot
    echo "$NEW_USER@$MAIN_DOMAIN:$NEW_PASS" >> /etc/dovecot/users
    
    # Buat user system
    useradd -m -s /bin/false $NEW_USER 2>/dev/null
    echo "$NEW_USER:$NEW_PASS" | chpasswd
    mkdir -p /home/$NEW_USER/Maildir/{cur,new,tmp}
    chown -R $NEW_USER:$NEW_USER /home/$NEW_USER/Maildir
    
    systemctl restart dovecot
    
    echo -e "\n${GREEN}✅ USER EMAIL BERHASIL DITAMBAHKAN!${NC}"
    echo -e "   📧 Email: $NEW_USER@$MAIN_DOMAIN"
    echo -e "   🔑 Password: $NEW_PASS"
    echo -e "\n💡 User ini bisa login ke Webmail: http://$DNS_IP/roundcube/"
    read -p "Tekan Enter..."
}

# ======================= 10. WEBMAIL =======================
install_webmail() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         🌐 INSTALL WEBMAIL (ROUNDCUBE)         ║${NC}"
    echo -e "${GREEN}║   Terintegrasi dengan DNS & Mail Server        ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
    if [[ -f /etc/maildomain.conf ]]; then
        MAIN_DOMAIN=$(cat /etc/maildomain.conf)
        DNS_IP=$(cat /etc/mailip.conf)
        EMAIL_USER=$(cat /etc/mailuser.conf 2>/dev/null)
        EMAIL_PASS=$(cat /etc/mailpass.conf 2>/dev/null)
        echo -e "\n${GREEN}✅ Mendeteksi dari Mail Server:${NC}"
        echo -e "   📝 Domain: $MAIN_DOMAIN"
        echo -e "   🌐 IP: $DNS_IP"
        echo -e "   👤 User: $EMAIL_USER@$MAIN_DOMAIN"
    else
        echo -e "\n${RED}❌ Mail Server belum diinstall! Install dulu menu 8.${NC}"
        read -p "Tekan Enter..."
        return
    fi
    
    echo -e "\n${CYAN}📦 Menginstall Roundcube Webmail...${NC}"
    
    # Hapus yang lama total
    apt remove --purge -y roundcube* php-roundcube* dbconfig-common 2>/dev/null
    rm -rf /etc/roundcube /var/lib/roundcube /usr/share/roundcube
    apt install -y roundcube roundcube-mysql roundcube-core php-mysql
    
    # Konfigurasi database
    DB_PASS="rcube123"
    mysql -u root <<MYSQL 2>/dev/null
DROP DATABASE IF EXISTS roundcubemail;
CREATE DATABASE roundcubemail;
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
Alias /email /usr/share/roundcube
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
    
    echo -e "\n${GREEN}╔════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   ✅ WEBMAIL (ROUNDCUBE) BERHASIL!                                           ║${NC}"
    echo -e "${GREEN}╠════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║                                                                             ║${NC}"
    echo -e "${GREEN}║   🌐 AKSES WEBMAIL VIA IP:                                                  ║${NC}"
    echo -e "${GREEN}║      👉 http://$DNS_IP/roundcube/                                          ║${NC}"
    echo -e "${GREEN}║                                                                             ║${NC}"
    echo -e "${GREEN}║   🌐 AKSES WEBMAIL VIA DOMAIN (Setting hosts dulu):                         ║${NC}"
    echo -e "${GREEN}║      👉 http://mail.$MAIN_DOMAIN/roundcube/                                ║${NC}"
    echo -e "${GREEN}║                                                                             ║${NC}"
    echo -e "${GREEN}║   📝 LOGIN WEBMAIL:                                                         ║${NC}"
    echo -e "${GREEN}║      👤 Username: $EMAIL_USER@$MAIN_DOMAIN                                 ║${NC}"
    echo -e "${GREEN}║      🔑 Password: $EMAIL_PASS                                               ║${NC}"
    echo -e "${GREEN}║                                                                             ║${NC}"
    echo -e "${GREEN}║   📧 CARA KIRIM EMAIL KE SESAMA USER:                                       ║${NC}"
    echo -e "${GREEN}║      Bisa kirim ke: nama_user_lain@$MAIN_DOMAIN                            ║${NC}"
    echo -e "${GREEN}║      Contoh: admin@$MAIN_DOMAIN, fahri@$MAIN_DOMAIN, info@$MAIN_DOMAIN    ║${NC}"
    echo -e "${GREEN}║      ⚠️  BUKAN @localhost! TAPI @$MAIN_DOMAIN!                             ║${NC}"
    echo -e "${GREEN}║                                                                             ║${NC}"
    echo -e "${GREEN}║   💡 CARA SETTING DOMAIN (agar bisa akses pakai mail.domain.com):           ║${NC}"
    echo -e "${GREEN}║      Windows: C:\\Windows\\System32\\drivers\\etc\\hosts                      ║${NC}"
    echo -e "${GREEN}║      Linux/Mac: /etc/hosts                                                 ║${NC}"
    echo -e "${GREEN}║      Tambahkan: $DNS_IP mail.$MAIN_DOMAIN                                   ║${NC}"
    echo -e "${GREEN}║                                                                             ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════════════╝${NC}"
    
    read -p "Tekan Enter..."
}

# ======================= 11. INSTALL SEMUA =======================
install_all() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         ⚡ INSTALL SEMUA SERVICE LENGKAP       ║${NC}"
    echo -e "${GREEN}║   DHCP + DNS + Apache2 + FTP + Samba + WP     ║${NC}"
    echo -e "${GREEN}║   + CRUD + MAIL SERVER + WEBMAIL              ║${NC}"
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
        
        echo -e "\n${GREEN}════════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}   🎉 SEMUA SERVICE BERHASIL DIINSTALL! 🎉                                    ║${NC}"
        echo -e "${GREEN}════════════════════════════════════════════════════════════════════════════║${NC}"
        echo -e "${GREEN}                                                                             ║${NC}"
        echo -e "${GREEN}   🌐 LANDING PAGE:  http://$DNS_IP                                          ║${NC}"
        echo -e "${GREEN}   📚 CRUD:          http://$DNS_IP/crud/                                   ║${NC}"
        echo -e "${GREEN}   📧 WEBMAIL:       http://$DNS_IP/roundcube/                              ║${NC}"
        echo -e "${GREEN}   📝 WORDPRESS:     http://$DNS_IP/wp-admin                                ║${NC}"
        echo -e "${GREEN}   📁 FTP:           ftp://$DNS_IP                                          ║${NC}"
        echo -e "${GREEN}   🖥️ SAMBA:         \\\\$DNS_IP\\public                                      ║${NC}"
        echo -e "${GREEN}                                                                             ║${NC}"
        echo -e "${GREEN}   📧 LOGIN WEBMAIL:                                                         ║${NC}"
        echo -e "${GREEN}      👤 Username: $EMAIL_USER@$MAIN_DOMAIN                                 ║${NC}"
        echo -e "${GREEN}      🔑 Password: $EMAIL_PASS                                               ║${NC}"
        echo -e "${GREEN}                                                                             ║${NC}"
        echo -e "${GREEN}   💡 KIRIM EMAIL KE SESAMA USER:                                            ║${NC}"
        echo -e "${GREEN}      Gunakan format: nama_user@$MAIN_DOMAIN                                ║${NC}"
        echo -e "${GREEN}      BUKAN @localhost!                                                     ║${NC}"
        echo -e "${GREEN}                                                                             ║${NC}"
        echo -e "${GREEN}════════════════════════════════════════════════════════════════════════════╝${NC}"
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
    echo -e "${WHITE}  SERVICE            | STATUS${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
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
        echo -e "   🌐 Webmail Domain: http://mail.$MAIN_DOMAIN/roundcube/"
    fi
    
    read -p "Tekan Enter..."
}

# ======================= MENU UTAMA =======================
while true; do
    clear
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════════════════════╗"
    echo "║            🚀 FAHTECH MULTI-SERVICE INSTALLER v17.0                        ║"
    echo "║     ALL SERVICE + MAIL SERVER TERINTEGRASI DENGAN DNS                      ║"
    echo "╠════════════════════════════════════════════════════════════════════════════╣"
    echo "║                                                                             ║"
    echo "║  📧 LAYANAN UTAMA                                                          ║"
    echo "║  ───────────────────────────────────────────────────────────────────────── ║"
    echo "║    1.  ⚡ INSTALL SEMUA SERVICE (20-30 menit)                              ║"
    echo "║    2.  🌐 Install DHCP Server                                             ║"
    echo "║    3.  🔍 Install DNS Server (WAJIB sebelum Mail)                         ║"
    echo "║    4.  🌍 Install Apache2 + Landing Page                                  ║"
    echo "║    5.  📁 Install FTP Server                                              ║"
    echo "║    6.  🖥️ Install Samba                                                   ║"
    echo "║    7.  📝 Install WordPress                                               ║"
    echo "║    8.  🗄️ Install CRUD Siswa (Tambah/Edit/Hapus/Cari)                     ║"
    echo "║    9.  📧 Install Mail Server (TERINTEGRASI DENGAN DNS)                   ║"
    echo "║    10. 🌐 Install Webmail (Roundcube) - Akses Email via Browser           ║"
    echo "║                                                                             ║"
    echo "║  👤 MANAJEMEN USER EMAIL                                                  ║"
    echo "║  ───────────────────────────────────────────────────────────────────────── ║"
    echo "║    11. 👤 Tambah User Email Baru                                          ║"
    echo "║                                                                             ║"
    echo "║  ⚡ FITUR TAMBAHAN                                                         ║"
    echo "║  ───────────────────────────────────────────────────────────────────────── ║"
    echo "║    12. 🗑️ Hapus SEMUA Service + Folder                                     ║"
    echo "║    13. 📊 Cek Status Service                                              ║"
    echo "║    14. 🚪 Exit                                                            ║"
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
