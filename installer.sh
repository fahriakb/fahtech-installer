#!/bin/bash

# ============================================================
#   FAHTECH - MULTI-SERVICE INSTALLER PRO v7.0
#   DNS + MAIL SERVER + WEBMAIL FULL INTEGRASI
#   SEMUA OTOMATIS, TINGGAL PILIH INTERFACE & DOMAIN
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
echo "║               FULL INTEGRASI DNS + MAIL                     ║"
echo "║          TINGGAL PILIH INTERFACE & INPUT DOMAIN             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ Jalankan sebagai root!${NC}"
    exit 1
fi

# Variabel global untuk menyimpan konfigurasi
SELECTED_IP=""
SELECTED_IFACE=""
MAIN_DOMAIN=""

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

# ======================= 1. INSTALL APACHE2 =======================
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
</style>
</head>
<body>
<h1>⚡ FAHTECH SERVER ⚡</h1>
<div class="status">✅ ALL SERVICES RUNNING</div>
<p style="color:white;">Server IP: <?php echo $_SERVER['SERVER_ADDR']; ?></p>
<p style="color:white;">Powered by FahTech Auto Installer v7.0</p>
</body>
</html>
EOF
    
    systemctl restart apache2
    echo -e "\n${GREEN}✅ APACHE2 BERHASIL! Akses: http://$SERVER_IP${NC}"
    echo -e "\n${YELLOW}Tekan Enter untuk kembali...${NC}"
    read
}

# ======================= 2. INSTALL DHCP =======================
install_dhcp() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         🌐 INSTALL DHCP SERVER                  ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
    show_interfaces
    echo -e "\n${YELLOW}👉 Pilih interface untuk DHCP Server:${NC}"
    read -p "Masukkan nomor: " choice
    
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
    option domain-name-servers $SELECTED_IP, 8.8.8.8;
}
EOF
        systemctl restart isc-dhcp-server
        systemctl enable isc-dhcp-server
        
        echo -e "\n${GREEN}✅ DHCP BERHASIL!${NC}"
        echo -e "   Interface: $SELECTED_IFACE"
        echo -e "   Subnet: $SUBNET/24"
        echo -e "   Range IP: $RANGE_START - $RANGE_END"
    fi
    echo -e "\n${YELLOW}Tekan Enter untuk kembali...${NC}"
    read
}

# ======================= 3. INSTALL DNS + MAIL DOMAIN =======================
install_dns() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         🔍 INSTALL DNS SERVER (BIND9)                      ║${NC}"
    echo -e "${GREEN}║         Domain yang dibuat OTOMATIS kebaca oleh Mail       ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    
    show_interfaces
    echo -e "\n${YELLOW}👉 Pilih interface untuk DNS Server:${NC}"
    read -p "Masukkan nomor: " choice
    
    if [[ $choice -ge 1 && $choice -le ${#INTERFACES[@]} ]]; then
        IFS='|' read -r DNS_IFACE DNS_IP <<< "${INTERFACES[$((choice-1))]}"
        SELECTED_IP=$DNS_IP
        SELECTED_IFACE=$DNS_IFACE
        
        echo -e "\n${GREEN}✅ Terpilih: $DNS_IFACE (IP: $DNS_IP)${NC}"
        echo -e "\n${YELLOW}📝 Masukkan nama domain utama (contoh: fahrinih.net):${NC}"
        read -p "Domain: " MAIN_DOMAIN
        
        apt install bind9 bind9utils -y -qq
        
        # Konfigurasi DNS
        cat > /etc/bind/named.conf.local <<EOF
zone "$MAIN_DOMAIN" {
    type master;
    file "/etc/bind/db.$MAIN_DOMAIN";
};
EOF
        
        cat > /etc/bind/db.$MAIN_DOMAIN <<EOF
\$TTL    604800
@       IN      SOA     ns1.$MAIN_DOMAIN. admin.$MAIN_DOMAIN. (
                  2026010501         ; Serial
                  604800         ; Refresh
                  86400         ; Retry
                  2419200        ; Expire
                  604800 )       ; Negative Cache TTL
;
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
        
        # Simpan konfigurasi ke file untuk dibaca mail server nanti
        echo "$MAIN_DOMAIN" > /etc/maildomain.conf
        echo "$DNS_IP" > /etc/mailip.conf
        
        echo -e "\n${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║   ✅ DNS BERHASIL!                                         ║${NC}"
        echo -e "${GREEN}╠════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${GREEN}║   📝 Domain: $MAIN_DOMAIN                                  ║${NC}"
        echo -e "${GREEN}║   🌐 IP Server: $DNS_IP                                    ║${NC}"
        echo -e "${GREEN}║   📧 Mail Domain: mail.$MAIN_DOMAIN                        ║${NC}"
        echo -e "${GREEN}║   📧 Email akan menggunakan: @$MAIN_DOMAIN                 ║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    fi
    echo -e "\n${YELLOW}Tekan Enter untuk kembali...${NC}"
    read
}

# ======================= 4. INSTALL FTP =======================
install_ftp() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         📁 INSTALL FTP SERVER                  ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    apt install vsftpd -y -qq
    systemctl restart vsftpd
    systemctl enable vsftpd
    echo -e "\n${GREEN}✅ FTP BERHASIL!${NC}"
    echo -e "\n${YELLOW}Tekan Enter untuk kembali...${NC}"
    read
}

# ======================= 5. INSTALL SAMBA =======================
install_samba() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         🖥️ INSTALL SAMBA                      ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    read -p "📝 Nama Share (Enter untuk 'public'): " share_name
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
    SERVER_IP=$(hostname -I | awk '{print $1}')
    echo -e "\n${GREEN}✅ SAMBA BERHASIL!${NC}"
    echo -e "   Akses: //$SERVER_IP/$share_name"
    echo -e "\n${YELLOW}Tekan Enter untuk kembali...${NC}"
    read
}

# ======================= 6. INSTALL MAIL SERVER (TERINTEGRASI DNS) =======================
install_mail() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         📧 INSTALL MAIL SERVER (POSTFIX + DOVECOT)         ║${NC}"
    echo -e "${GREEN}║         OTOMATIS BACA DOMAIN DARI DNS                      ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    
    # Baca domain dari file yang dibuat DNS
    if [[ -f /etc/maildomain.conf ]]; then
        MAIN_DOMAIN=$(cat /etc/maildomain.conf)
        DNS_IP=$(cat /etc/mailip.conf)
        echo -e "\n${GREEN}✅ Mendeteksi domain dari DNS: $MAIN_DOMAIN${NC}"
        echo -e "✅ IP Server: $DNS_IP"
    else
        echo -e "\n${YELLOW}⚠️ DNS belum diinstall. Install DNS dulu (menu 3) atau input manual:${NC}"
        read -p "Masukkan Domain (contoh: fahrinih.net): " MAIN_DOMAIN
        read -p "Masukkan IP Server: " DNS_IP
    fi
    
    MAIL_DOMAIN="mail.$MAIN_DOMAIN"
    
    echo -e "\n${CYAN}📦 Mengkonfigurasi Mail Server untuk domain: $MAIN_DOMAIN${NC}"
    
    # Set hostname
    hostnamectl set-hostname $MAIL_DOMAIN
    echo "$DNS_IP $MAIL_DOMAIN mail" >> /etc/hosts
    
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
    
    # Buat user email admin
    mkdir -p /etc/dovecot
    echo "admin@$MAIN_DOMAIN:{PLAIN}admin123" > /etc/dovecot/users
    
    # Buat user system untuk email
    useradd -m -s /bin/false admin 2>/dev/null
    echo "admin:admin123" | chpasswd
    mkdir -p /home/admin/Maildir/{cur,new,tmp}
    chown -R admin:admin /home/admin/Maildir
    
    systemctl restart postfix
    systemctl restart dovecot
    systemctl enable postfix dovecot
    
    echo -e "\n${GREEN}╔═══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   ✅ MAIL SERVER BERHASIL!                                         ║${NC}"
    echo -e "${GREEN}╠═══════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║   📧 Domain Email: @$MAIN_DOMAIN                                  ║${NC}"
    echo -e "${GREEN}║   🌐 Hostname: $MAIL_DOMAIN                                       ║${NC}"
    echo -e "${GREEN}║   👤 User Admin: admin@$MAIN_DOMAIN                               ║${NC}"
    echo -e "${GREEN}║   🔑 Password: admin123                                            ║${NC}"
    echo -e "${GREEN}║                                                                   ║${NC}"
    echo -e "${GREEN}║   📌 LANJUTKAN KE MENU 9 UNTUK INSTALL WEBMAIL!                   ║${NC}"
    echo -e "${GREEN}║      Supaya bisa akses email lewat browser                        ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${YELLOW}Tekan Enter untuk kembali...${NC}"
    read
}

# ======================= 7. INSTALL WORDPRESS =======================
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
    echo -e "\n${YELLOW}Tekan Enter untuk kembali...${NC}"
    read
}

# ======================= 8. INSTALL CRUD LENGKAP =======================
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
        .container { max-width: 1200px; margin: auto; background: white; border-radius: 20px; padding: 30px; box-shadow: 0 20px 60px rgba(0,0,0,0.3); }
        h1 { color: #667eea; }
        .status { background: #4CAF50; color: white; padding: 5px 10px; border-radius: 5px; display: inline-block; }
        form { display: flex; gap: 10px; margin: 20px 0; background: #f8f9fa; padding: 20px; border-radius: 10px; flex-wrap: wrap; }
        input, select { padding: 10px; border: 1px solid #ddd; border-radius: 5px; }
        button { background: #667eea; color: white; border: none; padding: 10px 20px; border-radius: 5px; cursor: pointer; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #667eea; color: white; }
        .delete { color: #e74c3c; text-decoration: none; }
        .edit { color: #3498db; text-decoration: none; margin-right: 10px; }
        .success { background: #d4edda; color: #155724; padding: 10px; border-radius: 5px; margin: 10px 0; }
    </style>
</head>
<body>
<div class="container">
    <h1>⚡ FahTech CRUD Application</h1>
    <div class="status">✅ DATABASE ACTIVE</div>
    <p>Sistem Manajemen Data Lengkap (Tambah, Edit, Hapus, Cari)</p>
    
    <?php
    $db = new SQLite3('/var/www/html/crud/data.db');
    $db->exec("CREATE TABLE IF NOT EXISTS items (
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        name TEXT NOT NULL, 
        description TEXT,
        category TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )");
    
    if (isset($_POST['add']) && !empty($_POST['name'])) {
        $name = SQLite3::escapeString($_POST['name']);
        $desc = SQLite3::escapeString($_POST['description']);
        $cat = SQLite3::escapeString($_POST['category']);
        $db->exec("INSERT INTO items (name, description, category) VALUES ('$name', '$desc', '$cat')");
        echo "<div class='success'>✅ Data berhasil ditambahkan!</div>";
    }
    
    if (isset($_GET['delete'])) {
        $id = (int)$_GET['delete'];
        $db->exec("DELETE FROM items WHERE id = $id");
        echo "<div class='success'>✅ Data berhasil dihapus!</div>";
    }
    
    if (isset($_POST['update'])) {
        $id = (int)$_POST['id'];
        $name = SQLite3::escapeString($_POST['name']);
        $desc = SQLite3::escapeString($_POST['description']);
        $cat = SQLite3::escapeString($_POST['category']);
        $db->exec("UPDATE items SET name='$name', description='$desc', category='$cat' WHERE id=$id");
        echo "<div class='success'>✅ Data berhasil diupdate!</div>";
    }
    
    $search = isset($_GET['search']) ? SQLite3::escapeString($_GET['search']) : '';
    $where = $search ? "WHERE name LIKE '%$search%' OR description LIKE '%$search%'" : "";
    $result = $db->query("SELECT * FROM items $where ORDER BY id DESC");
    ?>
    
    <form method="post">
        <input type="text" name="name" placeholder="Nama Item *" required>
        <input type="text" name="description" placeholder="Deskripsi">
        <input type="text" name="category" placeholder="Kategori">
        <button type="submit" name="add">➕ Tambah</button>
    </form>
    
    <form method="get" style="background: #e9ecef;">
        <input type="text" name="search" placeholder="Cari data..." value="<?= htmlspecialchars($search) ?>" style="flex:2">
        <button type="submit">🔍 Cari</button>
        <?php if($search): ?><a href="?">Reset</a><?php endif; ?>
    </form>
    
    <h2>📋 Daftar Items</h2>
    <table>
        <tr><th>ID</th><th>Nama</th><th>Deskripsi</th><th>Kategori</th><th>Tanggal</th><th>Aksi</th></tr>
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
            </tr>
        </tr>
        <?php endwhile; ?>
    </table>
    
    <?php if (isset($_GET['edit'])): $id=(int)$_GET['edit']; $edit=$db->query("SELECT * FROM items WHERE id=$id")->fetchArray(); if($edit): ?>
    <div style="margin-top: 20px; padding: 20px; background: #f8f9fa; border-radius: 10px;">
        <h3>✏️ Edit Data</h3>
        <form method="post">
            <input type="hidden" name="id" value="<?= $edit['id'] ?>">
            <input type="text" name="name" value="<?= htmlspecialchars($edit['name']) ?>" required>
            <input type="text" name="description" value="<?= htmlspecialchars($edit['description']) ?>">
            <input type="text" name="category" value="<?= htmlspecialchars($edit['category']) ?>">
            <button type="submit" name="update">💾 Update</button>
        </form>
    </div>
    <?php endif; endif; ?>
    
    <div class="footer" style="margin-top: 20px; text-align: center; color: #888;">
        Powered by FahTech Auto Installer | Total Data: <?= $db->querySingle("SELECT COUNT(*) FROM items") ?>
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
    echo -e "\n${YELLOW}Tekan Enter untuk kembali...${NC}"
    read
}

# ======================= 9. INSTALL WEBMAIL (TERINTEGRASI DNS & MAIL) =======================
install_webmail() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         📧 INSTALL WEBMAIL (ROUNDCUBE)                     ║${NC}"
    echo -e "${GREEN}║         BISA AKSES EMAIL VIA BROWSER                       ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    
    # Baca konfigurasi dari DNS
    if [[ -f /etc/maildomain.conf ]]; then
        MAIN_DOMAIN=$(cat /etc/maildomain.conf)
        DNS_IP=$(cat /etc/mailip.conf)
        echo -e "\n${GREEN}✅ Mendeteksi domain dari DNS: $MAIN_DOMAIN${NC}"
        echo -e "✅ IP Server: $DNS_IP"
    else
        echo -e "\n${YELLOW}⚠️ DNS belum terdeteksi. Input manual:${NC}"
        read -p "Masukkan Domain (contoh: fahrinih.net): " MAIN_DOMAIN
        DNS_IP=$(hostname -I | awk '{print $1}')
    fi
    
    # Cek mail server
    if ! systemctl is-active --quiet postfix; then
        echo -e "\n${YELLOW}⚠️ Mail Server belum terinstall! Install dulu lewat menu 6.${NC}"
        echo -e "\n${YELLOW}Tekan Enter untuk kembali...${NC}"
        read
        return
    fi
    
    echo -e "\n${CYAN}📦 Menginstall Roundcube Webmail untuk domain: $MAIN_DOMAIN${NC}"
    
    apt install roundcube roundcube-mysql roundcube-plugins roundcube-core php-mysql dbconfig-common -y -qq
    
    DB_PASS=$(openssl rand -base64 12 | tr -d "=/+" | cut -c1-16)
    
    mysql <<MYSQL_SCRIPT
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
    
    MAIL_URL="http://$DNS_IP/roundcube/"
    MAIL_DOMAIN_URL="http://mail.$MAIN_DOMAIN/roundcube/"
    
    echo -e "\n${GREEN}╔════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   ✅ WEBMAIL (ROUNDCUBE) BERHASIL!                                     ║${NC}"
    echo -e "${GREEN}╠════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║                                                                        ║${NC}"
    echo -e "${GREEN}║   🌐 AKSES VIA IP:                                                     ║${NC}"
    echo -e "${GREEN}║      👉 $MAIL_URL${NC}"
    echo -e "${GREEN}║                                                                        ║${NC}"
    echo -e "${GREEN}║   🌐 AKSES VIA DOMAIN (Jika sudah setting hosts):                      ║${NC}"
    echo -e "${GREEN}║      👉 $MAIL_DOMAIN_URL${NC}"
    echo -e "${GREEN}║                                                                        ║${NC}"
    echo -e "${GREEN}║   📝 LOGIN MENGGUNAKAN:                                                ║${NC}"
    echo -e "${GREEN}║      👤 Username: admin@$MAIN_DOMAIN                                  ║${NC}"
    echo -e "${GREEN}║      🔑 Password: admin123                                             ║${NC}"
    echo -e "${GREEN}║                                                                        ║${NC}"
    echo -e "${GREEN}║   💡 CARA AKSES PAKAI DOMAIN (mail.domain.com):                        ║${NC}"
    echo -e "${GREEN}║      1. Edit file hosts di komputer kamu:                              ║${NC}"
    echo -e "${GREEN}║         Windows: C:\\Windows\\System32\\drivers\\etc\\hosts               ║${NC}"
    echo -e "${GREEN}║         Linux/Mac: /etc/hosts                                         ║${NC}"
    echo -e "${GREEN}║      2. Tambahkan baris:                                              ║${NC}"
    echo -e "${GREEN}║         $DNS_IP mail.$MAIN_DOMAIN                                     ║${NC}"
    echo -e "${GREEN}║      3. Simpan, lalu akses $MAIL_DOMAIN_URL                          ║${NC}"
    echo -e "${GREEN}║                                                                        ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${YELLOW}Tekan Enter untuk kembali...${NC}"
    read
}

# ======================= 10. INSTALL SEMUA =======================
install_all() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║      ⚡ INSTALL SEMUA SERVICE LENGKAP          ║${NC}"
    echo -e "${GREEN}║   DNS + MAIL + WEBMAIL + CRUD + SEMUA         ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
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
        
        echo -e "\n${GREEN}╔════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║   🎉 SELAMAT! SEMUA SERVICE BERHASIL DIINSTALL! 🎉                     ║${NC}"
        echo -e "${GREEN}╠════════════════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${GREEN}║                                                                        ║${NC}"
        echo -e "${GREEN}║   🌐 LANDING PAGE:    http://$DNS_IP                                   ║${NC}"
        echo -e "${GREEN}║   📧 WEBMAIL:         http://$DNS_IP/roundcube/                       ║${NC}"
        echo -e "${GREEN}║   📝 WORDPRESS:       http://$DNS_IP/wp-admin                         ║${NC}"
        echo -e "${GREEN}║   🗄️  CRUD:           http://$DNS_IP/crud/                            ║${NC}"
        echo -e "${GREEN}║                                                                        ║${NC}"
        echo -e "${GREEN}║   📧 LOGIN WEBMAIL:                                                   ║${NC}"
        echo -e "${GREEN}║      👤 Username: admin@$MAIN_DOMAIN                                  ║${NC}"
        echo -e "${GREEN}║      🔑 Password: admin123                                             ║${NC}"
        echo -e "${GREEN}║                                                                        ║${NC}"
        echo -e "${GREEN}║   💡 Cara akses pakai domain:                                         ║${NC}"
        echo -e "${GREEN}║      Tambahkan ke file hosts:                                         ║${NC}"
        echo -e "${GREEN}║      $DNS_IP mail.$MAIN_DOMAIN                                        ║${NC}"
        echo -e "${GREEN}║      Lalu akses: http://mail.$MAIN_DOMAIN/roundcube/                 ║${NC}"
        echo -e "${GREEN}║                                                                        ║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════════╝${NC}"
    fi
    
    echo -e "\n${YELLOW}Tekan Enter untuk kembali...${NC}"
    read
}

# ======================= MENU UTAMA =======================
while true; do
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║            🚀 FAHTECH MULTI-SERVICE INSTALLER v7.0              ║"
    echo "║         DNS + MAIL SERVER + WEBMAIL FULL INTEGRASI               ║"
    echo "╠══════════════════════════════════════════════════════════════════╣"
    echo "║                                                                  ║"
    echo "║  1.  ⚡ INSTALL SEMUA SERVICE LENGKAP (15-20 menit)              ║"
    echo "║  2.  🌐 Install DHCP Server                                     ║"
    echo "║  3.  🔍 Install DNS Server + Buat Domain untuk Mail             ║"
    echo "║  4.  🌍 Install Apache2 + Landing Page                          ║"
    echo "║  5.  📁 Install FTP Server                                      ║"
    echo "║  6.  🖥️  Install Samba File Server                              ║"
    echo "║  7.  📧 Install MAIL SERVER (Baca Domain dari DNS)             ║"
    echo "║  8.  📝 Install WordPress                                      ║"
    echo "║  9.  🗄️  Install CRUD WEB LENGKAP (Tambah/Edit/Hapus/Cari)      ║"
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
