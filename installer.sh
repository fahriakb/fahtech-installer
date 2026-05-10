#!/bin/bash

# ============================================================
#   FAHTECH - MULTI-SERVICE INSTALLER PRO v8.0
#   CRUD LENGKAP (TAMBAH, EDIT, HAPUS, CARI)
#   MAIL SERVER + WEBMAIL (LOGIN & KIRIM EMAIL)
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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
echo "║                 MULTI-SERVICE INSTALLER PROFESSIONAL                         ║"
echo "║              CRUD LENGKAP + MAIL SERVER + WEBMAIL                           ║"
echo "║                       VERSI 8.0 - 2026                                      ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
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
    echo -e "\n${BLUE}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│                    📡 NETWORK INTERFACE                      │${NC}"
    echo -e "${BLUE}├─────┬─────────────────────┬─────────────────────────────────┤${NC}"
    printf "${BLUE}│${NC} ${WHITE}No${NC} │ ${WHITE}Interface${NC}          │ ${WHITE}IP Address${NC}                       │\n"
    echo -e "${BLUE}├─────┼─────────────────────┼─────────────────────────────────┤${NC}"
    for i in "${!INTERFACES[@]}"; do
        IFS='|' read -r iface ip <<< "${INTERFACES[$i]}"
        printf "${BLUE}│${NC} ${YELLOW}%2d${NC} │ ${CYAN}%-19s${NC} │ ${GREEN}%-31s${NC} │\n" "$((i+1))" "$iface" "$ip"
    done
    echo -e "${BLUE}└─────┴─────────────────────┴─────────────────────────────────┘${NC}"
}

# Fix database
fix_database() {
    echo -e "${YELLOW}🔧 Mengecek database...${NC}"
    if systemctl is-active --quiet mariadb; then
        if ! mysql -u root -e "SELECT 1" 2>/dev/null; then
            echo -e "${YELLOW}⚠️ Reset password database...${NC}"
            systemctl stop mariadb
            mysqld_safe --skip-grant-tables --skip-networking &
            sleep 3
            mysql -u root -e "FLUSH PRIVILEGES; ALTER USER 'root'@'localhost' IDENTIFIED BY ''; FLUSH PRIVILEGES;" 2>/dev/null
            pkill mysqld_safe
            sleep 2
            systemctl restart mariadb
            echo -e "${GREEN}✅ Database berhasil direset!${NC}"
        fi
    fi
}

# ======================= 1. APACHE2 =======================
install_apache2() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    🌍 INSTALL APACHE2                      ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    
    apt update -qq
    apt install apache2 php libapache2-mod-php php-mysql php-curl php-gd php-xml php-mbstring php-zip php-sqlite3 -y -qq
    
    SERVER_IP=$(hostname -I | awk '{print $1}')
    
    cat > /var/www/html/index.html <<'EOF'
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
<p style="color:white;">Server IP: <?php echo $_SERVER['SERVER_ADDR']; ?></p>
<div class="services">
<div class="service">🌐 Web Server</div><div class="service">📧 Mail Server</div>
<div class="service">📝 WordPress</div><div class="service">🗄️ CRUD App</div>
<div class="service">🌍 Webmail</div>
</div>
<p style="color:white;">Powered by FahTech Auto Installer v8.0</p>
</body>
</html>
EOF
    
    systemctl restart apache2
    echo -e "\n${GREEN}✅ APACHE2 BERHASIL! Akses: http://$SERVER_IP${NC}"
    echo -e "\n${YELLOW}Tekan Enter...${NC}"
    read
}

# ======================= 2. DHCP =======================
install_dhcp() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    🌐 INSTALL DHCP SERVER                  ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    
    show_interfaces
    echo -e "\n${YELLOW}👉 Pilih interface untuk DHCP:${NC}"
    read -p "Nomor [1-${#INTERFACES[@]}]: " choice
    
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
        echo -e "\n${GREEN}✅ DHCP BERHASIL! Interface: $SELECTED_IFACE${NC}"
    fi
    echo -e "\n${YELLOW}Tekan Enter...${NC}"
    read
}

# ======================= 3. DNS =======================
install_dns() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    🔍 INSTALL DNS SERVER                   ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    
    show_interfaces
    echo -e "\n${YELLOW}👉 Pilih interface untuk DNS:${NC}"
    read -p "Nomor [1-${#INTERFACES[@]}]: " choice
    
    if [[ $choice -ge 1 && $choice -le ${#INTERFACES[@]} ]]; then
        IFS='|' read -r DNS_IFACE DNS_IP <<< "${INTERFACES[$((choice-1))]}"
        
        echo -e "\n${CYAN}📝 Masukkan domain utama:${NC}"
        echo -e "${YELLOW}   Contoh: fahrinih.net, perusahaan.com${NC}"
        read -p "Domain: " MAIN_DOMAIN
        
        apt install bind9 bind9utils -y -qq
        
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
        
        echo -e "\n${GREEN}✅ DNS BERHASIL! Domain: $MAIN_DOMAIN -> $DNS_IP${NC}"
    fi
    echo -e "\n${YELLOW}Tekan Enter...${NC}"
    read
}

# ======================= 4. FTP =======================
install_ftp() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    📁 INSTALL FTP SERVER                   ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    
    apt install vsftpd -y -qq
    systemctl restart vsftpd
    systemctl enable vsftpd
    
    echo -e "\n${GREEN}✅ FTP BERHASIL! Gunakan user Linux untuk login${NC}"
    echo -e "\n${YELLOW}Tekan Enter...${NC}"
    read
}

# ======================= 5. SAMBA =======================
install_samba() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    🖥️ INSTALL SAMBA                        ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    
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
    SERVER_IP=$(hostname -I | awk '{print $1}')
    
    echo -e "\n${GREEN}✅ SAMBA BERHASIL! Akses: //$SERVER_IP/$share_name${NC}"
    echo -e "\n${YELLOW}Tekan Enter...${NC}"
    read
}

# ======================= 6. MAIL SERVER (LENGKAP + LOGIN WEBMAIL) =======================
install_mail() {
    clear
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    📧 INSTALL MAIL SERVER                        ║${NC}"
    echo -e "${GREEN}║              POSTFIX + DOVECOT + WEBMAIL READY                   ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    
    # Baca dari DNS atau input manual
    if [[ -f /etc/maildomain.conf ]]; then
        MAIN_DOMAIN=$(cat /etc/maildomain.conf)
        DNS_IP=$(cat /etc/mailip.conf)
        echo -e "\n${GREEN}✅ Domain terdeteksi dari DNS: $MAIN_DOMAIN${NC}"
        echo -e "${YELLOW}Gunakan domain ini? (y/n):${NC}"
        read -p "" use_domain
        [[ "$use_domain" != "y" ]] && read -p "Domain baru: " MAIN_DOMAIN
    else
        echo -e "\n${CYAN}📝 Masukkan domain utama:${NC}"
        echo -e "${YELLOW}   Contoh: fahrinih.net, perusahaan.com${NC}"
        read -p "Domain: " MAIN_DOMAIN
        DNS_IP=$(hostname -I | awk '{print $1}')
    fi
    
    # Input username & password email
    echo -e "\n${CYAN}📝 Buat akun email admin:${NC}"
    echo -e "${YELLOW}   Contoh: admin, info, support${NC}"
    read -p "Username: " EMAIL_USER
    EMAIL_USER=${EMAIL_USER:-admin}
    
    echo -e "\n${CYAN}📝 Buat password untuk $EMAIL_USER@$MAIN_DOMAIN:${NC}"
    echo -e "${YELLOW}   Minimal 5 karakter, contoh: admin123${NC}"
    read -s -p "Password: " EMAIL_PASS
    echo ""
    read -s -p "Konfirmasi password: " EMAIL_PASS_CONFIRM
    echo ""
    
    if [[ "$EMAIL_PASS" != "$EMAIL_PASS_CONFIRM" ]] || [[ -z "$EMAIL_PASS" ]]; then
        EMAIL_PASS="admin123"
        echo -e "${YELLOW}⚠️ Menggunakan password default: admin123${NC}"
    fi
    
    MAIL_DOMAIN="mail.$MAIN_DOMAIN"
    
    echo -e "\n${CYAN}📦 Menginstall Mail Server...${NC}"
    
    # Set hostname
    hostnamectl set-hostname $MAIL_DOMAIN
    echo "$DNS_IP $MAIL_DOMAIN" >> /etc/hosts
    
    # Install packages
    apt install postfix dovecot-core dovecot-imapd dovecot-pop3d mailutils -y -qq
    
    # Konfigurasi Postfix
    postconf -e "myhostname = $MAIL_DOMAIN"
    postconf -e "mydomain = $MAIN_DOMAIN"
    postconf -e "myorigin = \$mydomain"
    postconf -e "inet_interfaces = all"
    postconf -e "home_mailbox = Maildir/"
    postconf -e "smtpd_sasl_type = dovecot"
    postconf -e "smtpd_sasl_path = private/auth"
    postconf -e "smtpd_sasl_auth_enable = yes"
    postconf -e "smtpd_recipient_restrictions = permit_sasl_authenticated,permit_mynetworks,reject_unauth_destination"
    
    # Konfigurasi Dovecot
    cat > /etc/dovecot/dovecot.conf <<EOF
disable_plaintext_auth = no
mail_location = maildir:~/Maildir
passdb {
  driver = passwd-file
  args = scheme=CRYPT username_format=%u /etc/dovecot/users
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
    ENCRYPTED_PASS=$(openssl passwd -1 "$EMAIL_PASS")
    echo "$EMAIL_USER@$MAIN_DOMAIN:$ENCRYPTED_PASS" > /etc/dovecot/users
    
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
    
    echo -e "\n${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   ✅ MAIL SERVER BERHASIL!                                        ║${NC}"
    echo -e "${GREEN}╠══════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║   📧 Email: $EMAIL_USER@$MAIN_DOMAIN                             ║${NC}"
    echo -e "${GREEN}║   🔑 Password: $EMAIL_PASS                                       ║${NC}"
    echo -e "${GREEN}║                                                                   ║${NC}"
    echo -e "${GREEN}║   📌 LANJUTKAN INSTALL WEBMAIL (Menu 10)                         ║${NC}"
    echo -e "${GREEN}║      Agar bisa akses email via browser!                         ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${YELLOW}Tekan Enter untuk kembali...${NC}"
    read
}

# ======================= 7. WORDPRESS =======================
install_wordpress() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    📝 INSTALL WORDPRESS                    ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    
    fix_database
    
    if ! command -v mysql &> /dev/null; then
        apt install mariadb-server -y -qq
    fi
    
    systemctl restart mariadb
    fix_database
    
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
    echo -e "\n${YELLOW}Tekan Enter...${NC}"
    read
}

# ======================= 8. CRUD WEB LENGKAP (TAMBAH, EDIT, HAPUS, CARI) =======================
install_crud() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         🗄️ INSTALL CRUD WEB LENGKAP                       ║${NC}"
    echo -e "${GREEN}║         FITUR: TAMBAH | EDIT | HAPUS | CARI               ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    
    apt install php-sqlite3 -y -qq
    
    mkdir -p /var/www/html/crud
    
    cat > /var/www/html/crud/index.php <<'EOF'
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>FahTech CRUD - Database Manager</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); font-family: 'Segoe UI', Arial, sans-serif; min-height: 100vh; padding: 40px; }
        .container { max-width: 1200px; margin: auto; background: white; border-radius: 20px; padding: 30px; box-shadow: 0 20px 60px rgba(0,0,0,0.3); }
        h1 { color: #667eea; margin-bottom: 10px; }
        .status { background: #4CAF50; color: white; padding: 5px 15px; border-radius: 20px; display: inline-block; font-size: 12px; margin-bottom: 20px; }
        .form-add { background: #f8f9fa; padding: 20px; border-radius: 15px; margin: 20px 0; display: flex; gap: 10px; flex-wrap: wrap; }
        .form-add input, .form-add select { padding: 12px; border: 1px solid #ddd; border-radius: 8px; flex: 1; min-width: 150px; }
        button { background: #667eea; color: white; border: none; padding: 12px 25px; border-radius: 8px; cursor: pointer; font-size: 16px; }
        button:hover { background: #5a67d8; }
        .search-box { margin: 20px 0; display: flex; gap: 10px; }
        .search-box input { flex: 1; padding: 12px; border: 1px solid #ddd; border-radius: 8px; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #eee; }
        th { background: #667eea; color: white; }
        tr:hover { background: #f5f5f5; }
        .edit-btn { background: #3498db; color: white; padding: 5px 12px; border-radius: 5px; text-decoration: none; margin-right: 5px; display: inline-block; }
        .delete-btn { background: #e74c3c; color: white; padding: 5px 12px; border-radius: 5px; text-decoration: none; display: inline-block; }
        .edit-form { background: #fff3cd; padding: 20px; border-radius: 15px; margin-top: 30px; border: 1px solid #ffecb3; }
        .success { background: #d4edda; color: #155724; padding: 12px; border-radius: 8px; margin: 10px 0; }
        .footer { margin-top: 30px; text-align: center; color: #888; font-size: 12px; }
        @media (max-width: 768px) { .form-add { flex-direction: column; } }
    </style>
</head>
<body>
<div class="container">
    <h1>⚡ FahTech CRUD Application</h1>
    <div class="status">✅ DATABASE ACTIVE | SQLite</div>
    <p>Sistem Manajemen Data Lengkap dengan fitur Tambah, Edit, Hapus, dan Cari</p>
    
    <?php
    $db = new SQLite3('/var/www/html/crud/data.db');
    $db->exec("CREATE TABLE IF NOT EXISTS items (
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        name TEXT NOT NULL, 
        description TEXT,
        category TEXT,
        price INTEGER DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )");
    
    // Tambah Data
    if (isset($_POST['add']) && !empty($_POST['name'])) {
        $name = SQLite3::escapeString($_POST['name']);
        $desc = SQLite3::escapeString($_POST['description']);
        $cat = SQLite3::escapeString($_POST['category']);
        $price = (int)$_POST['price'];
        $db->exec("INSERT INTO items (name, description, category, price) VALUES ('$name', '$desc', '$cat', $price)");
        echo "<div class='success'>✅ Data berhasil ditambahkan!</div>";
    }
    
    // Hapus Data
    if (isset($_GET['delete'])) {
        $id = (int)$_GET['delete'];
        $db->exec("DELETE FROM items WHERE id = $id");
        echo "<div class='success'>✅ Data berhasil dihapus!</div>";
    }
    
    // Update Data
    if (isset($_POST['update'])) {
        $id = (int)$_POST['id'];
        $name = SQLite3::escapeString($_POST['name']);
        $desc = SQLite3::escapeString($_POST['description']);
        $cat = SQLite3::escapeString($_POST['category']);
        $price = (int)$_POST['price'];
        $db->exec("UPDATE items SET name='$name', description='$desc', category='$cat', price=$price WHERE id=$id");
        echo "<div class='success'>✅ Data berhasil diupdate!</div>";
    }
    
    // Pencarian
    $search = isset($_GET['search']) ? SQLite3::escapeString($_GET['search']) : '';
    $where = $search ? "WHERE name LIKE '%$search%' OR description LIKE '%$search%' OR category LIKE '%$search%'" : "";
    $result = $db->query("SELECT * FROM items $where ORDER BY id DESC");
    ?>
    
    <!-- Form Tambah Data -->
    <form method="post" class="form-add">
        <input type="text" name="name" placeholder="Nama Item *" required>
        <input type="text" name="description" placeholder="Deskripsi">
        <input type="text" name="category" placeholder="Kategori">
        <input type="number" name="price" placeholder="Harga">
        <button type="submit" name="add">➕ Tambah Data</button>
    </form>
    
    <!-- Form Pencarian -->
    <div class="search-box">
        <form method="get" style="display: flex; gap: 10px; width: 100%;">
            <input type="text" name="search" placeholder="Cari data..." value="<?= htmlspecialchars($search) ?>">
            <button type="submit">🔍 Cari</button>
            <?php if($search): ?>
                <a href="?" style="background: #6c757d; color: white; padding: 12px 20px; border-radius: 8px; text-decoration: none;">Reset</a>
            <?php endif; ?>
        </form>
    </div>
    
    <!-- Tabel Data -->
    <h2>📋 Data Items</h2>
    <table>
        <tr>
            <th>ID</th>
            <th>Nama Item</th>
            <th>Deskripsi</th>
            <th>Kategori</th>
            <th>Harga</th>
            <th>Tanggal</th>
            <th>Aksi</th>
        </tr>
        <?php while ($row = $result->fetchArray()): ?>
        <tr>
            <td><?= $row['id'] ?></td>
            <td><strong><?= htmlspecialchars($row['name']) ?></strong></td>
            <td><?= htmlspecialchars($row['description']) ?></td>
            <td><?= htmlspecialchars($row['category']) ?></td>
            <td>Rp <?= number_format($row['price'], 0, ',', '.') ?></td>
            <td><?= $row['created_at'] ?></td>
            <td>
                <a href="?edit=<?= $row['id'] ?>" class="edit-btn">✏️ Edit</a>
                <a href="?delete=<?= $row['id'] ?>" class="delete-btn" onclick="return confirm('Yakin hapus data ini?')">🗑️ Hapus</a>
            </td>
        </tr>
        <?php endwhile; ?>
    </table>
    
    <?php if (isset($_GET['edit'])): 
        $id = (int)$_GET['edit'];
        $edit_result = $db->query("SELECT * FROM items WHERE id=$id");
        $edit_row = $edit_result->fetchArray();
        if ($edit_row):
    ?>
    <div class="edit-form">
        <h3>✏️ Edit Data ID: <?= $edit_row['id'] ?></h3>
        <form method="post" style="display: flex; gap: 10px; flex-wrap: wrap; margin-top: 15px;">
            <input type="hidden" name="id" value="<?= $edit_row['id'] ?>">
            <input type="text" name="name" value="<?= htmlspecialchars($edit_row['name']) ?>" required style="flex:2; padding: 10px; border-radius: 8px; border: 1px solid #ddd;">
            <input type="text" name="description" value="<?= htmlspecialchars($edit_row['description']) ?>" style="flex:3; padding: 10px; border-radius: 8px; border: 1px solid #ddd;">
            <input type="text" name="category" value="<?= htmlspecialchars($edit_row['category']) ?>" style="flex:1; padding: 10px; border-radius: 8px; border: 1px solid #ddd;">
            <input type="number" name="price" value="<?= $edit_row['price'] ?>" style="flex:1; padding: 10px; border-radius: 8px; border: 1px solid #ddd;">
            <button type="submit" name="update" style="background: #28a745;">💾 Update</button>
            <a href="?" style="background: #6c757d; color: white; padding: 10px 20px; border-radius: 8px; text-decoration: none;">Batal</a>
        </form>
    </div>
    <?php endif; endif; ?>
    
    <div class="footer">
        FahTech CRUD Application | Total Data: <?= $db->querySingle("SELECT COUNT(*) FROM items") ?> | 
        <a href="https://github.com/fahriakb/fahtech-installer" style="color: #667eea;">FahTech Installer v8.0</a>
    </div>
</div>
</body>
</html>
EOF
    
    chown -R www-data:www-data /var/www/html/crud
    systemctl restart apache2
    
    SERVER_IP=$(hostname -I | awk '{print $1}')
    
    echo -e "\n${GREEN}✅ CRUD WEB LENGKAP BERHASIL!${NC}"
    echo -e "${GREEN}   🔗 Akses: http://$SERVER_IP/crud/${NC}"
    echo -e "${GREEN}   📌 Fitur: ✨ Tambah Data | ✏️ Edit Data | 🗑️ Hapus Data | 🔍 Cari Data${NC}"
    echo -e "\n${YELLOW}Tekan Enter...${NC}"
    read
}

# ======================= 9. WEBMAIL (ROUNDCUBE) =======================
install_webmail() {
    clear
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    📧 INSTALL WEBMAIL (ROUNDCUBE)               ║${NC}"
    echo -e "${GREEN}║              BISA LOGIN & KIRIM EMAIL VIA BROWSER               ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    
    # Baca konfigurasi dari mail server
    if [[ -f /etc/maildomain.conf ]]; then
        MAIN_DOMAIN=$(cat /etc/maildomain.conf)
        DNS_IP=$(cat /etc/mailip.conf)
        EMAIL_USER=$(cat /etc/mailuser.conf 2>/dev/null)
        echo -e "\n${GREEN}✅ Domain terdeteksi: $MAIN_DOMAIN${NC}"
    else
        echo -e "\n${CYAN}📝 Masukkan domain utama:${NC}"
        read -p "Domain: " MAIN_DOMAIN
        DNS_IP=$(hostname -I | awk '{print $1}')
        EMAIL_USER="admin"
    fi
    
    # Cek mail server
    if ! systemctl is-active --quiet postfix; then
        echo -e "\n${RED}❌ Mail Server belum terinstall! Install dulu lewat menu 7.${NC}"
        echo -e "\n${YELLOW}Tekan Enter...${NC}"
        read
        return
    fi
    
    echo -e "\n${CYAN}📦 Menginstall Roundcube Webmail...${NC}"
    
    apt install roundcube roundcube-mysql roundcube-plugins roundcube-core php-mysql dbconfig-common -y -qq
    
    DB_PASS=$(openssl rand -base64 12 | tr -d "=/+" | cut -c1-16)
    
    mysql <<MYSQL_SCRIPT 2>/dev/null
CREATE DATABASE IF NOT EXISTS roundcubemail;
CREATE USER IF NOT EXISTS 'roundcube'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON roundcubemail.* TO 'roundcube'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT
    
    if [ -f /usr/share/roundcube/SQL/mysql.initial.sql ]; then
        mysql roundcubemail < /usr/share/roundcube/SQL/mysql.initial.sql 2>/dev/null
    fi
    
    cat > /etc/roundcube/config.inc.php <<EOF
<?php
\$config = array();
\$config['db_dsnw'] = 'mysql://roundcube:$DB_PASS@localhost/roundcubemail';
\$config['default_host'] = '$DNS_IP';
\$config['smtp_server'] = '$DNS_IP';
\$config['smtp_port'] = 25;
\$config['smtp_user'] = '%u';
\$config['smtp_pass'] = '%p';
\$config['product_name'] = 'FahTech Webmail - $MAIN_DOMAIN';
\$config['des_key'] = '$(openssl rand -base64 24)';
\$config['plugins'] = array('archive', 'zipdownload');
\$config['skin'] = 'elastic';
EOF
    
    ln -sf /etc/roundcube/apache.conf /etc/apache2/conf-available/roundcube.conf
    a2enconf roundcube
    a2enmod rewrite
    systemctl restart apache2
    systemctl restart postfix dovecot
    
    WEBMAIL_URL="http://$DNS_IP/roundcube/"
    
    echo -e "\n${GREEN}╔════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   ✅ WEBMAIL (ROUNDCUBE) BERHASIL DIINSTALL!                                    ║${NC}"
    echo -e "${GREEN}╠════════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║                                                                                ║${NC}"
    echo -e "${GREEN}║   🌐 AKSES WEBMAIL:                                                           ║${NC}"
    echo -e "${GREEN}║      👉 $WEBMAIL_URL${NC}"
    echo -e "${GREEN}║                                                                                ║${NC}"
    echo -e "${GREEN}║   📝 LOGIN DENGAN:                                                            ║${NC}"
    echo -e "${GREEN}║      👤 Username: $EMAIL_USER@$MAIN_DOMAIN                                    ║${NC}"
    echo -e "${GREEN}║      🔑 Password: [password yang kamu buat saat install mail server]           ║${NC}"
    echo -e "${GREEN}║                                                                                ║${NC}"
    echo -e "${GREEN}║   💡 CARA MENCOBA KIRIM EMAIL:                                                 ║${NC}"
    echo -e "${GREEN}║      1. Login ke webmail di atas                                              ║${NC}"
    echo -e "${GREEN}║      2. Klik tombol \"Compose\" atau \"Tulis Email\"                            ║${NC}"
    echo -e "${GREEN}║      3. Isi tujuan: $EMAIL_USER@$MAIN_DOMAIN (atau user lain)                ║${NC}"
    echo -e "${GREEN}║      4. Tulis subjek dan pesan                                               ║${NC}"
    echo -e "${GREEN}║      5. Klik \"Send\" - Email akan terkirim!                                  ║${NC}"
    echo -e "${GREEN}║                                                                                ║${NC}"
    echo -e "${GREEN}║   📌 CATATAN:                                                                 ║${NC}"
    echo -e "${GREEN}║      - Kirim email ke sesama user lokal pasti berhasil                        ║${NC}"
    echo -e "${GREEN}║      - Kirim ke email luar (Gmail/Yahoo) perlu konfigurasi DNS tambahan      ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${YELLOW}Tekan Enter untuk kembali ke menu...${NC}"
    read
}

# ======================= 10. INSTALL SEMUA LENGKAP =======================
install_all() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║      ⚡ INSTALL SEMUA SERVICE LENGKAP                     ║${NC}"
    echo -e "${GREEN}║   DNS + MAIL + WEBMAIL + CRUD + SEMUA                     ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${YELLOW}⚠️ Proses akan memakan waktu 15-20 menit. Lanjutkan? (y/n):${NC}"
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
        install_webmail
        
        DNS_IP=$(cat /etc/mailip.conf 2>/dev/null || hostname -I | awk '{print $1}')
        MAIN_DOMAIN=$(cat /etc/maildomain.conf 2>/dev/null || echo "domain-anda.com")
        EMAIL_USER=$(cat /etc/mailuser.conf 2>/dev/null || echo "admin")
        
        echo -e "\n${GREEN}╔════════════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║   🎉 SELAMAT! SEMUA SERVICE BERHASIL DIINSTALL! 🎉                             ║${NC}"
        echo -e "${GREEN}╠════════════════════════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${GREEN}║                                                                                ║${NC}"
        echo -e "${GREEN}║   🌐 LANDING PAGE:    http://$DNS_IP                                           ║${NC}"
        echo -e "${GREEN}║   📧 WEBMAIL:         http://$DNS_IP/roundcube/                               ║${NC}"
        echo -e "${GREEN}║   📝 WORDPRESS:       http://$DNS_IP/wp-admin                                 ║${NC}"
        echo -e "${GREEN}║   🗄️  CRUD:           http://$DNS_IP/crud/                                    ║${NC}"
        echo -e "${GREEN}║                                                                                ║${NC}"
        echo -e "${GREEN}║   📧 LOGIN WEBMAIL:                                                            ║${NC}"
        echo -e "${GREEN}║      👤 Username: $EMAIL_USER@$MAIN_DOMAIN                                    ║${NC}"
        echo -e "${GREEN}║      🔑 Password: [password yang sudah dibuat]                                ║${NC}"
        echo -e "${GREEN}║                                                                                ║${NC}"
        echo -e "${GREEN}║   🗄️  CRUD FITUR LENGKAP:                                                      ║${NC}"
        echo -e "${GREEN}║      ✨ Tambah Data | ✏️ Edit Data | 🗑️ Hapus Data | 🔍 Cari Data             ║${NC}"
        echo -e "${GREEN}║                                                                                ║${NC}"
        echo -e "${GREEN}║   📌 CARA AKSES PAKAI DOMAIN:                                                  ║${NC}"
        echo -e "${GREEN}║      Tambahkan ke file hosts:                                                 ║${NC}"
        echo -e "${GREEN}║      Windows: C:\\Windows\\System32\\drivers\\etc\\hosts                        ║${NC}"
        echo -e "${GREEN}║      Linux/Mac: /etc/hosts                                                    ║${NC}"
        echo -e "${GREEN}║      Isi: $DNS_IP mail.$MAIN_DOMAIN                                           ║${NC}"
        echo -e "${GREEN}║      Lalu akses: http://mail.$MAIN_DOMAIN/roundcube/                         ║${NC}"
        echo -e "${GREEN}║                                                                                ║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════════════════╝${NC}"
    fi
    
    echo -e "\n${YELLOW}Tekan Enter untuk kembali...${NC}"
    read
}

# ======================= MENU UTAMA =======================
while true; do
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║            🚀 FAHTECH MULTI-SERVICE INSTALLER v8.0              ║"
    echo "║         CRUD LENGKAP + MAIL SERVER + WEBMAIL                     ║"
    echo "╠══════════════════════════════════════════════════════════════════╣"
    echo "║                                                                  ║"
    echo "║  1.  ⚡ INSTALL SEMUA SERVICE LENGKAP (15-20 menit)              ║"
    echo "║  2.  🌐 Install DHCP Server                                     ║"
    echo "║  3.  🔍 Install DNS Server + Buat Domain                        ║"
    echo "║  4.  🌍 Install Apache2 + Landing Page                          ║"
    echo "║  5.  📁 Install FTP Server                                      ║"
    echo "║  6.  🖥️  Install Samba File Server                              ║"
    echo "║  7.  📧 Install MAIL SERVER + Buat Akun Email                   ║"
    echo "║  8.  📝 Install WordPress                                       ║"
    echo "║  9.  🗄️  Install CRUD WEB LENGKAP (Tambah/Edit/Hapus/Cari)      ║"
    echo "║  10. 🌐 Install WEBMAIL (Roundcube) - Login & Kirim Email       ║"
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
        7) install_mail ;;
        8) install_wordpress ;;
        9) install_crud ;;
        10) install_webmail ;;
        11) 
            echo -e "${GREEN}👋 Terima kasih! Semua service sudah siap!${NC}"
            exit 0
            ;;
        *) 
            echo -e "${RED}❌ Pilihan salah!${NC}"
            sleep 1
            ;;
    esac
done
