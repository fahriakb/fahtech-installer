#!/bin/bash

# ============================================================
#   FAHTECH - MULTI-SERVICE INSTALLER PRO v6.0
#   FULL MAIL SERVER + WEBMAIL + CRUD + SEMUA SERVICE
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
echo "║               FULL MAIL SERVER + WEBMAIL                   ║"
echo "║              SEMUA SERVICE BISA AKSES WEB                  ║"
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

# ======================= INSTALL APACHE2 =======================
install_apache2() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         🌍 INSTALL APACHE2 + LANDING PAGE      ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
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
.service { background: white; padding: 15px; border-radius: 10px; min-width: 150px; }
</style>
</head>
<body>
<h1>⚡ FAHTECH SERVER ⚡</h1>
<div class="status">✅ ALL SERVICES RUNNING</div>
<p style="color:white;">Server IP: <?php echo $_SERVER['SERVER_ADDR']; ?></p>
<div class="services">
<div class="service">🌐 Web<br>Apache2</div>
<div class="service">📧 Mail<br>Postfix+Dovecot</div>
<div class="service">📝 CMS<br>WordPress</div>
<div class="service">📁 CRUD<br>SQLite</div>
<div class="service">🌍 Webmail<br>Roundcube</div>
</div>
<p style="color:white;">Powered by FahTech Auto Installer v6.0</p>
</body>
</html>
EOF
    
    systemctl restart apache2
    echo -e "\n${GREEN}✅ APACHE2 BERHASIL! Akses: http://$SERVER_IP${NC}"
    read -p "Tekan Enter..."
}

# ======================= INSTALL DHCP =======================
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
        systemctl enable isc-dhcp-server
        echo -e "\n${GREEN}✅ DHCP BERHASIL!${NC}"
    fi
    read -p "Tekan Enter..."
}

# ======================= INSTALL DNS =======================
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

# ======================= INSTALL FTP =======================
install_ftp() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         📁 INSTALL FTP SERVER                  ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    apt install vsftpd -y -qq
    systemctl restart vsftpd
    systemctl enable vsftpd
    echo -e "\n${GREEN}✅ FTP BERHASIL!${NC}"
    read -p "Tekan Enter..."
}

# ======================= INSTALL SAMBA =======================
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
    systemctl enable smbd
    echo -e "\n${GREEN}✅ SAMBA BERHASIL!${NC}"
    read -p "Tekan Enter..."
}

# ======================= INSTALL MAIL SERVER (FULL) =======================
install_mail() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         📧 INSTALL MAIL SERVER (POSTFIX + DOVECOT)     ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
    
    read -p "Masukkan Domain Utama (contoh: fahritech.net): " MAIN_DOMAIN
    read -p "Masukkan Hostname Mail (contoh: mail): " MAIL_HOSTNAME
    MAIL_DOMAIN="${MAIL_HOSTNAME}.${MAIN_DOMAIN}"
    
    # Set hostname
    hostnamectl set-hostname $MAIL_DOMAIN
    echo "127.0.0.1 $MAIL_DOMAIN localhost" >> /etc/hosts
    
    # Install packages
    apt install postfix postfix-mysql dovecot-core dovecot-imapd dovecot-pop3d dovecot-lmtpd dovecot-mysql mailutils -y -qq
    
    # Konfigurasi Postfix
    postconf -e "myhostname = $MAIL_DOMAIN"
    postconf -e "mydomain = $MAIN_DOMAIN"
    postconf -e "myorigin = \$mydomain"
    postconf -e "inet_interfaces = all"
    postconf -e "inet_protocols = ipv4"
    postconf -e "mydestination = localhost, localhost.localdomain"
    postconf -e "home_mailbox = Maildir/"
    postconf -e "mailbox_command = "
    postconf -e "smtpd_sasl_type = dovecot"
    postconf -e "smtpd_sasl_path = private/auth"
    postconf -e "smtpd_sasl_auth_enable = yes"
    postconf -e "smtpd_tls_auth_only = no"
    postconf -e "smtpd_recipient_restrictions = permit_sasl_authenticated, permit_mynetworks, reject_unauth_destination"
    postconf -e "mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128"
    
    # Konfigurasi Dovecot
    cat > /etc/dovecot/dovecot.conf <<EOF
disable_plaintext_auth = no
mail_privileged_group = mail
mail_location = maildir:~/Maildir
passdb {
  driver = passwd-file
  args = scheme=CRYPT username_format=%u /etc/dovecot/users
}
userdb {
  driver = passwd
}
protocols = imap pop3 lmtp
service auth {
  unix_listener /var/spool/postfix/private/auth {
    mode = 0660
    user = postfix
    group = postfix
  }
}
ssl = no
EOF
    
    # Buat user email pertama (admin)
    mkdir -p /etc/dovecot
    echo "admin@$MAIN_DOMAIN:{PLAIN}admin123" > /etc/dovecot/users
    
    # Buat Maildir untuk user admin
    useradd -m -s /bin/false admin 2>/dev/null
    echo "admin:admin123" | chpasswd
    mkdir -p /home/admin/Maildir/{cur,new,tmp}
    chown -R admin:admin /home/admin/Maildir
    
    systemctl restart postfix
    systemctl restart dovecot
    systemctl enable postfix dovecot
    
    SERVER_IP=$(hostname -I | awk '{print $1}')
    
    echo -e "\n${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   ✅ MAIL SERVER BERHASIL!                                 ║${NC}"
    echo -e "${GREEN}╠════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║   📧 Domain: $MAIN_DOMAIN                                 ║${NC}"
    echo -e "${GREEN}║   🌐 Hostname: $MAIL_DOMAIN                               ║${NC}"
    echo -e "${GREEN}║   👤 User Email: admin@$MAIN_DOMAIN                       ║${NC}"
    echo -e "${GREEN}║   🔑 Password: admin123                                    ║${NC}"
    echo -e "${GREEN}║                                                            ║${NC}"
    echo -e "${GREEN}║   📌 LANJUTKAN INSTALL WEBMAIL (Menu 8) AGAR BISA AKSES   ║${NC}"
    echo -e "${GREEN}║      VIA BROWSER!                                         ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    
    read -p "Tekan Enter untuk kembali..."
}

# ======================= INSTALL WORDPRESS =======================
install_wordpress() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         📝 INSTALL WORDPRESS                   ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
    apt install mariadb-server -y -qq
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
    read -p "Tekan Enter..."
}

# ======================= INSTALL CRUD WEB LENGKAP =======================
install_crud() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         🗄️ INSTALL CRUD WEB LENGKAP           ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
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
        .container { max-width: 1000px; margin: auto; background: white; border-radius: 20px; padding: 30px; box-shadow: 0 20px 60px rgba(0,0,0,0.3); }
        h1 { color: #667eea; margin-bottom: 10px; }
        .status { background: #4CAF50; color: white; padding: 5px 10px; border-radius: 5px; display: inline-block; font-size: 12px; }
        form { display: flex; gap: 10px; margin: 20px 0; background: #f8f9fa; padding: 20px; border-radius: 10px; }
        input { flex: 1; padding: 12px; border: 1px solid #ddd; border-radius: 10px; font-size: 16px; }
        button { background: #667eea; color: white; border: none; padding: 12px 24px; border-radius: 10px; cursor: pointer; font-size: 16px; }
        button:hover { background: #5a67d8; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #667eea; color: white; }
        .delete { color: #e74c3c; text-decoration: none; font-weight: bold; }
        .edit { color: #3498db; text-decoration: none; margin-right: 10px; }
        .success { background: #d4edda; color: #155724; padding: 12px; border-radius: 10px; margin: 10px 0; }
        .search { margin-bottom: 20px; }
        .search input { width: 300px; }
        .footer { margin-top: 30px; text-align: center; color: #888; font-size: 12px; }
    </style>
</head>
<body>
<div class="container">
    <h1>⚡ FahTech CRUD Application</h1>
    <div class="status">✅ DATABASE ACTIVE</div>
    <p>Sistem Manajemen Data Lengkap dengan SQLite</p>
    
    <?php
    $db = new SQLite3('/var/www/html/crud/data.db');
    $db->exec("CREATE TABLE IF NOT EXISTS items (
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        name TEXT NOT NULL, 
        description TEXT,
        category TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )");
    
    // Handle Add
    if (isset($_POST['add']) && !empty($_POST['name'])) {
        $name = SQLite3::escapeString($_POST['name']);
        $desc = SQLite3::escapeString($_POST['description']);
        $cat = SQLite3::escapeString($_POST['category']);
        $db->exec("INSERT INTO items (name, description, category) VALUES ('$name', '$desc', '$cat')");
        echo "<div class='success'>✅ Data berhasil ditambahkan!</div>";
    }
    
    // Handle Delete
    if (isset($_GET['delete'])) {
        $id = (int)$_GET['delete'];
        $db->exec("DELETE FROM items WHERE id = $id");
        echo "<div class='success'>✅ Data berhasil dihapus!</div>";
    }
    
    // Handle Edit
    if (isset($_POST['update'])) {
        $id = (int)$_POST['id'];
        $name = SQLite3::escapeString($_POST['name']);
        $desc = SQLite3::escapeString($_POST['description']);
        $cat = SQLite3::escapeString($_POST['category']);
        $db->exec("UPDATE items SET name='$name', description='$desc', category='$cat' WHERE id=$id");
        echo "<div class='success'>✅ Data berhasil diupdate!</div>";
    }
    
    // Search
    $search = isset($_GET['search']) ? SQLite3::escapeString($_GET['search']) : '';
    $where = $search ? "WHERE name LIKE '%$search%' OR description LIKE '%$search%'" : "";
    $result = $db->query("SELECT * FROM items $where ORDER BY id DESC");
    ?>
    
    <!-- Form Tambah Data -->
    <form method="post">
        <input type="text" name="name" placeholder="Nama Item *" required style="flex:1">
        <input type="text" name="description" placeholder="Deskripsi" style="flex:2">
        <input type="text" name="category" placeholder="Kategori" style="flex:1">
        <button type="submit" name="add">➕ Tambah</button>
    </form>
    
    <!-- Form Search -->
    <div class="search">
        <form method="get">
            <input type="text" name="search" placeholder="Cari data..." value="<?= htmlspecialchars($search) ?>">
            <button type="submit">🔍 Cari</button>
            <?php if($search): ?>
                <a href="?">Reset</a>
            <?php endif; ?>
        </form>
    </div>
    
    <!-- Tabel Data -->
    <h2>📋 Daftar Items</h2>
    <table>
        <tr>
            <th>ID</th>
            <th>Nama Item</th>
            <th>Deskripsi</th>
            <th>Kategori</th>
            <th>Tanggal</th>
            <th>Aksi</th>
        </tr>
        <?php while ($row = $result->fetchArray()): ?>
        <tr>
            <td><?= $row['id'] ?></td>
            <td><?= htmlspecialchars($row['name']) ?></td>
            <td><?= htmlspecialchars($row['description']) ?></td>
            <td><?= htmlspecialchars($row['category']) ?></td>
            <td><?= $row['created_at'] ?></td>
            <td>
                <a href="?edit=<?= $row['id'] ?>" class="edit">✏️ Edit</a>
                <a href="?delete=<?= $row['id'] ?>" class="delete" onclick="return confirm('Yakin hapus?')">🗑️ Hapus</a>
            </td>
        </tr>
        <?php endwhile; ?>
    </table>
    
    <?php
    // Handle Edit Form
    if (isset($_GET['edit'])) {
        $id = (int)$_GET['edit'];
        $edit_result = $db->query("SELECT * FROM items WHERE id=$id");
        $edit_row = $edit_result->fetchArray();
        if ($edit_row):
    ?>
    <div style="margin-top: 30px; padding: 20px; background: #f8f9fa; border-radius: 10px;">
        <h3>✏️ Edit Data</h3>
        <form method="post">
            <input type="hidden" name="id" value="<?= $edit_row['id'] ?>">
            <input type="text" name="name" value="<?= htmlspecialchars($edit_row['name']) ?>" required>
            <input type="text" name="description" value="<?= htmlspecialchars($edit_row['description']) ?>">
            <input type="text" name="category" value="<?= htmlspecialchars($edit_row['category']) ?>">
            <button type="submit" name="update">💾 Update</button>
        </form>
    </div>
    <?php endif; } ?>
    
    <div class="footer">
        Powered by <strong>FahTech Auto Installer v6.0</strong> | Total Data: <?= $db->querySingle("SELECT COUNT(*) FROM items") ?>
    </div>
</div>
</body>
</html>
EOF
    
    chown -R www-data:www-data /var/www/html/crud
    systemctl restart apache2
    
    SERVER_IP=$(hostname -I | awk '{print $1}')
    
    echo -e "\n${GREEN}✅ CRUD WEB LENGKAP BERHASIL!${NC}"
    echo -e "   🔗 Akses: http://$SERVER_IP/crud/"
    echo -e "   📌 Fitur: Tambah, Edit, Hapus, Cari, Kategori"
    read -p "Tekan Enter..."
}

# ======================= INSTALL WEBMAIL (ROUNDCUBE) LENGKAP =======================
install_webmail() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         📧 INSTALL WEBMAIL (ROUNDCUBE)                     ║${NC}"
    echo -e "${GREEN}║         BISA LOGIN & KIRIM EMAIL DARI BROWSER              ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    
    # Cek mail server
    if ! systemctl is-active --quiet postfix; then
        echo -e "${YELLOW}⚠️ Mail Server belum terinstall! Install dulu lewat menu 7.${NC}"
        read -p "Tekan Enter..."
        return
    fi
    
    # Baca domain dari postfix
    MAIN_DOMAIN=$(postconf -h mydomain)
    if [[ -z "$MAIN_DOMAIN" ]]; then
        read -p "Masukkan Domain Email (contoh: fahritech.net): " MAIN_DOMAIN
    fi
    
    SERVER_IP=$(hostname -I | awk '{print $1}')
    
    echo -e "\n${CYAN}📦 Installing Roundcube Webmail...${NC}"
    
    # Install Roundcube
    apt install roundcube roundcube-mysql roundcube-plugins roundcube-core php-mysql dbconfig-common -y -qq
    
    # Konfigurasi Database
    DB_PASS=$(openssl rand -base64 12 | tr -d "=/+" | cut -c1-16)
    
    mysql <<MYSQL_SCRIPT
CREATE DATABASE IF NOT EXISTS roundcubemail;
CREATE USER IF NOT EXISTS 'roundcube'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON roundcubemail.* TO 'roundcube'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT
    
    # Import database
    if [ -f /usr/share/roundcube/SQL/mysql.initial.sql ]; then
        mysql roundcubemail < /usr/share/roundcube/SQL/mysql.initial.sql 2>/dev/null
    fi
    
    # Konfigurasi Roundcube
    cat > /etc/roundcube/config.inc.php <<EOF
<?php
\$config = array();
\$config['db_dsnw'] = 'mysql://roundcube:$DB_PASS@localhost/roundcubemail';
\$config['default_host'] = '$SERVER_IP';
\$config['smtp_server'] = '$SERVER_IP';
\$config['smtp_port'] = 25;
\$config['smtp_user'] = '%u';
\$config['smtp_pass'] = '%p';
\$config['support_url'] = '';
\$config['product_name'] = 'FahTech Webmail';
\$config['des_key'] = '$(openssl rand -base64 24)';
\$config['plugins'] = array('archive', 'zipdownload', 'markasjunk');
\$config['skin'] = 'elastic';
EOF
    
    # Konfigurasi Apache untuk Roundcube
    ln -sf /etc/roundcube/apache.conf /etc/apache2/conf-available/roundcube.conf
    a2enconf roundcube
    a2enmod rewrite
    systemctl restart apache2
    systemctl restart postfix dovecot
    
    echo -e "\n${GREEN}╔═══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   ✅ WEBMAIL (ROUNDCUBE) BERHASIL!                                  ║${NC}"
    echo -e "${GREEN}╠═══════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║   🌐 Akses Webmail: http://$SERVER_IP/roundcube/                  ║${NC}"
    echo -e "${GREEN}║                                                                   ║${NC}"
    echo -e "${GREEN}║   📝 LOGIN MENGGUNAKAN:                                            ║${NC}"
    echo -e "${GREEN}║      👤 Username: admin@$MAIN_DOMAIN                              ║${NC}"
    echo -e "${GREEN}║      🔑 Password: admin123                                         ║${NC}"
    echo -e "${GREEN}║                                                                   ║${NC}"
    echo -e "${GREEN}║   💡 ATAU bisa pakai user Linux lain: username@$MAIN_DOMAIN       ║${NC}"
    echo -e "${GREEN}║      contoh: root@$MAIN_DOMAIN (dengan password root)             ║${NC}"
    echo -e "${GREEN}║                                                                   ║${NC}"
    echo -e "${GREEN}║   📌 Untuk KIRIM EMAIL KE LUAR:                                    ║${NC}"
    echo -e "${GREEN}║      - Domain harus punya DNS record MX & A ke IP $SERVER_IP      ║${NC}"
    echo -e "${GREEN}║      - Bisa kirim ke sesama user lokal tanpa DNS                 ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════════╝${NC}"
    
    read -p "Tekan Enter untuk kembali..."
}

# ======================= INSTALL SEMUA LENGKAP =======================
install_all() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║      ⚡ INSTALL SEMUA SERVICE LENGKAP          ║${NC}"
    echo -e "${GREEN}║   + MAIL SERVER + WEBMAIL + CRUD LENGKAP      ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${YELLOW}⚠️ Proses akan memakan waktu 10-15 menit. Lanjutkan? (y/n):${NC}"
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
        
        SERVER_IP=$(hostname -I | awk '{print $1}')
        MAIN_DOMAIN=$(postconf -h mydomain 2>/dev/null || echo "domain-anda.com")
        
        echo -e "\n${GREEN}╔═══════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║   🎉 SELAMAT! SEMUA SERVICE BERHASIL DIINSTALL! 🎉               ║${NC}"
        echo -e "${GREEN}╠═══════════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${GREEN}║                                                                   ║${NC}"
        echo -e "${GREEN}║   🌐 LANDING PAGE:    http://$SERVER_IP                           ║${NC}"
        echo -e "${GREEN}║   📧 WEBMAIL:         http://$SERVER_IP/roundcube/               ║${NC}"
        echo -e "${GREEN}║   📝 WORDPRESS:       http://$SERVER_IP/wp-admin                 ║${NC}"
        echo -e "${GREEN}║   🗄️  CRUD:           http://$SERVER_IP/crud/                    ║${NC}"
        echo -e "${GREEN}║                                                                   ║${NC}"
        echo -e "${GREEN}║   📧 LOGIN WEBMAIL:                                               ║${NC}"
        echo -e "${GREEN}║      👤 Username: admin@$MAIN_DOMAIN                             ║${NC}"
        echo -e "${GREEN}║      🔑 Password: admin123                                        ║${NC}"
        echo -e "${GREEN}║                                                                   ║${NC}"
        echo -e "${GREEN}║   ✨ FITUR CRUD: TAMBAH, EDIT, HAPUS, CARI, KATEGORI ✨          ║${NC}"
        echo -e "${GREEN}║                                                                   ║${NC}"
        echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════════╝${NC}"
    fi
    
    read -p "Tekan Enter untuk kembali..."
}

# ======================= MENU UTAMA =======================
while true; do
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║            🚀 FAHTECH MULTI-SERVICE INSTALLER v6.0              ║"
    echo "║         ⚡ FULL MAIL SERVER + WEBMAIL + CRUD LENGKAP ⚡          ║"
    echo "╠══════════════════════════════════════════════════════════════════╣"
    echo "║                                                                  ║"
    echo "║  1.  ⚡ INSTALL SEMUA SERVICE LENGKAP (10-15 menit)              ║"
    echo "║  2.  🌐 Install DHCP Server (Otomatis Deteksi)                   ║"
    echo "║  3.  🔍 Install DNS Server                                       ║"
    echo "║  4.  🌍 Install Apache2 + Landing Page                           ║"
    echo "║  5.  📁 Install FTP Server                                       ║"
    echo "║  6.  🖥️  Install Samba File Server                               ║"
    echo "║  7.  📧 Install MAIL SERVER (Postfix + Dovecot) + User Admin    ║"
    echo "║  8.  📝 Install WordPress + Database Auto Setup                  ║"
    echo "║  9.  🗄️  Install CRUD WEB LENGKAP (Tambah/Edit/Hapus/Cari)       ║"
    echo "║  10. 🌐 Install WEBMAIL (Roundcube) - Bisa Login & Kirim Email   ║"
    echo "║  11. 🚪 Exit                                                     ║"
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
