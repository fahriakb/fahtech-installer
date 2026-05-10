#!/bin/bash

# ============================================================
#   FAHTECH - MULTI-SERVICE INSTALLER PRO FINAL
#   AUTO DETECT IP | CRUD SISWA | WEBMAIL | ALL SERVICE
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Deteksi IP otomatis
SERVER_IP=$(hostname -I | awk '{print $1}')
clear

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                                                                  ║"
echo "║   ███████╗ █████╗ ██╗  ██╗████████╗███████╗ ██████╗██╗  ██╗     ║"
echo "║   ██╔════╝██╔══██╗██║  ██║╚══██╔══╝██╔════╝██╔════╝██║  ██║     ║"
echo "║   █████╗  ███████║███████║   ██║   █████╗  ██║     ███████║     ║"
echo "║   ██╔══╝  ██╔══██║██╔══██║   ██║   ██╔══╝  ██║     ██╔══██║     ║"
echo "║   ██║     ██║  ██║██║  ██║   ██║   ███████╗╚██████╗██║  ██║     ║"
echo "║   ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝ ╚═════╝╚═╝  ╚═╝     ║"
echo "║                                                                  ║"
echo "║              MULTI-SERVICE INSTALLER PROFESSIONAL                ║"
echo "║                   AUTO DETECT IP: ${GREEN}$SERVER_IP${CYAN}                    ║"
echo "║              CRUD SISWA + WEBMAIL + MAIL SERVER                  ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
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

# ======================= APACHE2 =======================
install_apache2() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              🌍 INSTALL APACHE2                ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
    apt update -qq
    apt install apache2 php libapache2-mod-php php-mysql php-curl php-gd php-xml php-mbstring php-zip php-sqlite3 -y -qq
    
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
<div class="service">🌐 Web Server</div><div class="service">📧 Mail Server</div>
<div class="service">📝 WordPress</div><div class="service">🗄️ CRUD</div><div class="service">🌍 Webmail</div>
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
    read -p "Tekan Enter..."
}

# ======================= DNS =======================
install_dns() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              🔍 INSTALL DNS SERVER             ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
    show_interfaces
    echo -e "\n${YELLOW}👉 Pilih interface untuk DNS:${NC}"
    read -p "Nomor [1-${#INTERFACES[@]}]: " choice
    
    if [[ $choice -ge 1 && $choice -le ${#INTERFACES[@]} ]]; then
        IFS='|' read -r DNS_IFACE DNS_IP <<< "${INTERFACES[$((choice-1))]}"
        
        echo -e "\n${YELLOW}📝 Masukkan domain utama (contoh: fahrinih.net):${NC}"
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
    read -p "Tekan Enter..."
}

# ======================= FTP =======================
install_ftp() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              📁 INSTALL FTP SERVER             ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
    apt install vsftpd -y -qq
    systemctl restart vsftpd
    systemctl enable vsftpd
    
    echo -e "\n${GREEN}✅ FTP BERHASIL! Akses: ftp://$SERVER_IP${NC}"
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
    echo -e "\n${GREEN}✅ SAMBA BERHASIL! Akses: \\\\$SERVER_IP\\$share_name${NC}"
    read -p "Tekan Enter..."
}

# ======================= MAIL SERVER =======================
install_mail() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              📧 INSTALL MAIL SERVER            ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
    if [[ -f /etc/maildomain.conf ]]; then
        MAIN_DOMAIN=$(cat /etc/maildomain.conf)
        DNS_IP=$(cat /etc/mailip.conf)
        echo -e "\n${GREEN}✅ Domain dari DNS: $MAIN_DOMAIN${NC}"
    else
        show_interfaces
        echo -e "\n${YELLOW}👉 Pilih interface untuk Mail Server:${NC}"
        read -p "Nomor [1-${#INTERFACES[@]}]: " choice
        if [[ $choice -ge 1 && $choice -le ${#INTERFACES[@]} ]]; then
            IFS='|' read -r DNS_IFACE DNS_IP <<< "${INTERFACES[$((choice-1))]}"
        else
            DNS_IP=$SERVER_IP
        fi
        
        echo -e "\n${YELLOW}📝 Masukkan domain (contoh: fahrinih.net):${NC}"
        read -p "Domain: " MAIN_DOMAIN
    fi
    
    echo -e "\n${YELLOW}📝 Buat akun email:${NC}"
    read -p "Username (contoh: admin): " EMAIL_USER
    EMAIL_USER=${EMAIL_USER:-admin}
    read -s -p "Password (contoh: admin123): " EMAIL_PASS
    echo ""
    EMAIL_PASS=${EMAIL_PASS:-admin123}
    
    MAIL_DOMAIN="mail.$MAIN_DOMAIN"
    
    hostnamectl set-hostname $MAIL_DOMAIN
    echo "$DNS_IP $MAIL_DOMAIN" >> /etc/hosts
    
    apt install postfix dovecot-core dovecot-imapd dovecot-pop3d mailutils -y -qq
    
    postconf -e "myhostname = $MAIL_DOMAIN"
    postconf -e "mydomain = $MAIN_DOMAIN"
    postconf -e "myorigin = \$mydomain"
    postconf -e "inet_interfaces = all"
    postconf -e "home_mailbox = Maildir/"
    postconf -e "smtpd_sasl_type = dovecot"
    postconf -e "smtpd_sasl_path = private/auth"
    postconf -e "smtpd_sasl_auth_enable = yes"
    
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
    
    mkdir -p /etc/dovecot
    ENCRYPTED_PASS=$(openssl passwd -1 "$EMAIL_PASS")
    echo "$EMAIL_USER@$MAIN_DOMAIN:$ENCRYPTED_PASS" > /etc/dovecot/users
    
    useradd -m -s /bin/false $EMAIL_USER 2>/dev/null
    echo "$EMAIL_USER:$EMAIL_PASS" | chpasswd
    mkdir -p /home/$EMAIL_USER/Maildir/{cur,new,tmp}
    chown -R $EMAIL_USER:$EMAIL_USER /home/$EMAIL_USER/Maildir
    
    systemctl restart postfix
    systemctl restart dovecot
    systemctl enable postfix dovecot
    
    echo "$MAIN_DOMAIN" > /etc/maildomain.conf
    echo "$DNS_IP" > /etc/mailip.conf
    echo "$EMAIL_USER" > /etc/mailuser.conf
    echo "$EMAIL_PASS" > /etc/mailpass.conf
    
    echo -e "\n${GREEN}✅ MAIL SERVER BERHASIL!${NC}"
    echo -e "   📧 Email: $EMAIL_USER@$MAIN_DOMAIN"
    echo -e "   🔑 Password: $EMAIL_PASS"
    read -p "Tekan Enter..."
}

# ======================= WORDPRESS =======================
install_wordpress() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              📝 INSTALL WORDPRESS              ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
    apt install mariadb-server -y -qq
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
    read -p "Tekan Enter..."
}

# ======================= CRUD SISWA LENGKAP =======================
install_crud() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         🗄️ INSTALL CRUD SISWA                 ║${NC}"
    echo -e "${GREEN}║      (Nama + Rombel + NIS)                    ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    
    mkdir -p /var/www/html/crud
    
    cat > /var/www/html/crud/index.php <<'EOF'
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>FahTech CRUD - Data Siswa</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); font-family: 'Segoe UI', Arial, sans-serif; min-height: 100vh; padding: 40px; }
        .container { max-width: 1200px; margin: auto; background: white; border-radius: 20px; padding: 35px; box-shadow: 0 25px 50px -12px rgba(0,0,0,0.25); }
        h1 { color: #667eea; margin-bottom: 10px; }
        .subtitle { color: #666; margin-bottom: 20px; }
        .status { background: #4CAF50; color: white; padding: 5px 15px; border-radius: 20px; display: inline-block; font-size: 12px; }
        .form-card { background: #f8f9fa; padding: 25px; border-radius: 15px; margin: 20px 0; }
        .form-group { display: flex; gap: 15px; flex-wrap: wrap; }
        .form-group input { flex: 1; padding: 12px; border: 1px solid #ddd; border-radius: 10px; font-size: 14px; }
        button { background: #667eea; color: white; border: none; padding: 12px 30px; border-radius: 10px; cursor: pointer; font-size: 14px; font-weight: bold; }
        button:hover { background: #5a67d8; }
        .search-box { margin: 20px 0; display: flex; gap: 10px; }
        .search-box input { flex: 1; padding: 12px; border: 1px solid #ddd; border-radius: 10px; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #eee; }
        th { background: #667eea; color: white; }
        tr:hover { background: #f5f5f5; }
        .edit-btn { background: #3498db; color: white; padding: 6px 15px; border-radius: 8px; text-decoration: none; margin-right: 5px; display: inline-block; }
        .delete-btn { background: #e74c3c; color: white; padding: 6px 15px; border-radius: 8px; text-decoration: none; display: inline-block; }
        .edit-form { background: #fff3cd; padding: 20px; border-radius: 15px; margin-top: 30px; border-left: 5px solid #ffc107; }
        .success { background: #d4edda; color: #155724; padding: 12px; border-radius: 10px; margin: 15px 0; }
        .error { background: #f8d7da; color: #721c24; padding: 12px; border-radius: 10px; margin: 15px 0; }
        .footer { margin-top: 30px; text-align: center; color: #888; font-size: 12px; }
        @media (max-width: 768px) { .form-group { flex-direction: column; } }
    </style>
</head>
<body>
<div class="container">
    <h1>📚 FahTech CRUD - Data Siswa</h1>
    <div class="subtitle">Sistem Manajemen Data Siswa (Nama, Rombel, NIS)</div>
    <div class="status">✅ DATABASE ACTIVE | SQLite</div>
    
    <?php
    $db = new SQLite3('/var/www/html/crud/data.db');
    $db->exec("CREATE TABLE IF NOT EXISTS siswa (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        rombel TEXT NOT NULL,
        nis TEXT NOT NULL UNIQUE,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )");
    
    // TAMBAH DATA
    if (isset($_POST['add']) && !empty($_POST['nama']) && !empty($_POST['rombel']) && !empty($_POST['nis'])) {
        $nama = SQLite3::escapeString($_POST['nama']);
        $rombel = SQLite3::escapeString($_POST['rombel']);
        $nis = SQLite3::escapeString($_POST['nis']);
        $check = $db->querySingle("SELECT COUNT(*) FROM siswa WHERE nis = '$nis'");
        if ($check > 0) {
            echo "<div class='error'>❌ Gagal! NIS $nis sudah terdaftar!</div>";
        } else {
            $db->exec("INSERT INTO siswa (nama, rombel, nis) VALUES ('$nama', '$rombel', '$nis')");
            echo "<div class='success'>✅ Data siswa berhasil ditambahkan!</div>";
        }
    }
    
    // HAPUS DATA
    if (isset($_GET['delete'])) {
        $id = (int)$_GET['delete'];
        $db->exec("DELETE FROM siswa WHERE id = $id");
        echo "<div class='success'>✅ Data berhasil dihapus!</div>";
    }
    
    // UPDATE DATA
    if (isset($_POST['update'])) {
        $id = (int)$_POST['id'];
        $nama = SQLite3::escapeString($_POST['nama']);
        $rombel = SQLite3::escapeString($_POST['rombel']);
        $nis = SQLite3::escapeString($_POST['nis']);
        $check = $db->querySingle("SELECT COUNT(*) FROM siswa WHERE nis = '$nis' AND id != $id");
        if ($check > 0) {
            echo "<div class='error'>❌ Gagal! NIS $nis sudah terdaftar untuk siswa lain!</div>";
        } else {
            $db->exec("UPDATE siswa SET nama='$nama', rombel='$rombel', nis='$nis' WHERE id=$id");
            echo "<div class='success'>✅ Data siswa berhasil diupdate!</div>";
        }
    }
    
    // PENCARIAN
    $search = isset($_GET['search']) ? SQLite3::escapeString($_GET['search']) : '';
    $where = $search ? "WHERE nama LIKE '%$search%' OR nis LIKE '%$search%' OR rombel LIKE '%$search%'" : "";
    $result = $db->query("SELECT * FROM siswa $where ORDER BY id DESC");
    ?>
    
    <!-- FORM TAMBAH DATA -->
    <div class="form-card">
        <h3 style="margin-bottom: 15px;">➕ Tambah Data Siswa</h3>
        <form method="post">
            <div class="form-group">
                <input type="text" name="nama" placeholder="Nama Lengkap *" required>
                <input type="text" name="rombel" placeholder="Rombel / Kelas *" required>
                <input type="text" name="nis" placeholder="NIS (Nomor Induk Siswa) *" required>
                <button type="submit" name="add">💾 Simpan Data</button>
            </div>
        </form>
    </div>
    
    <!-- FORM PENCARIAN -->
    <div class="search-box">
        <form method="get" style="display: flex; gap: 10px; width: 100%;">
            <input type="text" name="search" placeholder="🔍 Cari berdasarkan Nama / NIS / Rombel..." value="<?= htmlspecialchars($search) ?>">
            <button type="submit">Cari</button>
            <?php if($search): ?>
                <a href="?" style="background: #6c757d; color: white; padding: 12px 20px; border-radius: 10px; text-decoration: none;">Reset</a>
            <?php endif; ?>
        </form>
    </div>
    
    <!-- TABEL DATA -->
    <h3 style="margin: 20px 0 10px;">📋 Daftar Siswa</h3>
    <table>
        <thead>
            <tr>
                <th>ID</th>
                <th>Nama Lengkap</th>
                <th>Rombel / Kelas</th>
                <th>NIS</th>
                <th>Tanggal Dibuat</th>
                <th>Aksi</th>
            </tr>
        </thead>
        <tbody>
            <?php while ($row = $result->fetchArray()): ?>
            <tr>
                <td><strong><?= $row['id'] ?></strong></td>
                <td><?= htmlspecialchars($row['nama']) ?></td>
                <td><?= htmlspecialchars($row['rombel']) ?></td>
                <td><code><?= htmlspecialchars($row['nis']) ?></code></td>
                <td><?= date('d/m/Y H:i', strtotime($row['created_at'])) ?></td>
                <td>
                    <a href="?edit=<?= $row['id'] ?>" class="edit-btn">✏️ Edit</a>
                    <a href="?delete=<?= $row['id'] ?>" class="delete-btn" onclick="return confirm('Yakin hapus data ini?')">🗑️ Hapus</a>
                </td>
            </tr>
            <?php endwhile; ?>
        </tbody>
    </table>
    
    <?php if (isset($_GET['edit'])): 
        $id = (int)$_GET['edit'];
        $edit = $db->query("SELECT * FROM siswa WHERE id=$id")->fetchArray();
        if ($edit):
    ?>
    <div class="edit-form">
        <h3>✏️ Edit Data Siswa (ID: <?= $edit['id'] ?>)</h3>
        <form method="post">
            <input type="hidden" name="id" value="<?= $edit['id'] ?>">
            <div class="form-group">
                <input type="text" name="nama" value="<?= htmlspecialchars($edit['nama']) ?>" required>
                <input type="text" name="rombel" value="<?= htmlspecialchars($edit['rombel']) ?>" required>
                <input type="text" name="nis" value="<?= htmlspecialchars($edit['nis']) ?>" required>
                <button type="submit" name="update">💾 Update Data</button>
                <a href="?" style="background: #6c757d; color: white; padding: 12px 20px; border-radius: 10px; text-decoration: none;">Batal</a>
            </div>
        </form>
    </div>
    <?php endif; endif; ?>
    
    <div class="footer">
        <strong>FahTech CRUD - Data Siswa</strong> | Total Data: <?= $db->querySingle("SELECT COUNT(*) FROM siswa") ?> siswa
    </div>
</div>
</body>
</html>
EOF
    
    chown -R www-data:www-data /var/www/html/crud
    systemctl restart apache2
    
    echo -e "\n${GREEN}✅ CRUD SISWA BERHASIL!${NC}"
    echo -e "   🌐 Akses: http://$SERVER_IP/crud/"
    echo -e "   📌 Fitur: ✨ Tambah Data | ✏️ Edit Data | 🗑️ Hapus Data | 🔍 Cari Data"
    read -p "Tekan Enter..."
}

# ======================= WEBMAIL =======================
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
        echo -e "\n${GREEN}✅ Domain: $MAIN_DOMAIN | IP: $DNS_IP${NC}"
    else
        echo -e "\n${RED}❌ Mail Server belum diinstall! Install dulu menu 7.${NC}"
        read -p "Tekan Enter..."
        return
    fi
    
    apt install roundcube roundcube-mysql roundcube-core php-mysql -y -qq
    
    DB_PASS=$(openssl rand -base64 12 | tr -d "=/+" | cut -c1-16)
    
    mysql -u root <<MYSQL_SCRIPT 2>/dev/null
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
\$config['plugins'] = array('archive', 'zipdownload');
\$config['skin'] = 'elastic';
EOF
    
    ln -sf /etc/roundcube/apache.conf /etc/apache2/conf-available/roundcube.conf
    a2enconf roundcube
    a2enmod rewrite
    systemctl restart apache2
    systemctl restart postfix dovecot
    
    echo -e "\n${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   ✅ WEBMAIL (ROUNDCUBE) BERHASIL!                                 ║${NC}"
    echo -e "${GREEN}╠══════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║                                                                    ║${NC}"
    echo -e "${GREEN}║   🌐 AKSES VIA IP:                                                ║${NC}"
    echo -e "${GREEN}║      http://$DNS_IP/roundcube/                                    ║${NC}"
    echo -e "${GREEN}║                                                                    ║${NC}"
    echo -e "${GREEN}║   🌐 AKSES VIA DOMAIN (Setting hosts dulu):                        ║${NC}"
    echo -e "${GREEN}║      http://mail.$MAIN_DOMAIN/roundcube/                          ║${NC}"
    echo -e "${GREEN}║                                                                    ║${NC}"
    echo -e "${GREEN}║   📝 LOGIN:                                                        ║${NC}"
    echo -e "${GREEN}║      👤 Username: $EMAIL_USER@$MAIN_DOMAIN                        ║${NC}"
    echo -e "${GREEN}║      🔑 Password: $EMAIL_PASS                                      ║${NC}"
    echo -e "${GREEN}║                                                                    ║${NC}"
    echo -e "${GREEN}║   💡 CARA SETTING DOMAIN:                                          ║${NC}"
    echo -e "${GREEN}║      Windows: C:\\Windows\\System32\\drivers\\etc\\hosts              ║${NC}"
    echo -e "${GREEN}║      Linux/Mac: /etc/hosts                                        ║${NC}"
    echo -e "${GREEN}║      Tambahkan: $DNS_IP mail.$MAIN_DOMAIN                         ║${NC}"
    echo -e "${GREEN}║                                                                    ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    
    read -p "Tekan Enter..."
}

# ======================= MENU =======================
while true; do
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║            🚀 FAHTECH MULTI-SERVICE INSTALLER FINAL             ║"
    echo "║         AUTO DETECT IP: ${GREEN}$SERVER_IP${CYAN}                              ║"
    echo "╠══════════════════════════════════════════════════════════════════╣"
    echo "║                                                                  ║"
    echo "║  1.  ⚡ INSTALL SEMUA SERVICE (REKOMENDED)                       ║"
    echo "║  2.  🌐 Install DHCP Server                                     ║"
    echo "║  3.  🔍 Install DNS Server                                      ║"
    echo "║  4.  🌍 Install Apache2                                         ║"
    echo "║  5.  📁 Install FTP Server                                      ║"
    echo "║  6.  🖥️  Install Samba                                          ║"
    echo "║  7.  📧 Install Mail Server                                     ║"
    echo "║  8.  📝 Install WordPress                                       ║"
    echo "║  9.  🗄️  Install CRUD SISWA (Nama + Rombel + NIS)               ║"
    echo "║  10. 🌐 Install WEBMAIL (Roundcube) - Akses Email via Browser   ║"
    echo "║  11. 🚪 Exit                                                    ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    read -p "👉 Pilih menu [1-11]: " menu
    
    case $menu in
        1) 
            install_apache2
            install_dhcp
            install_dns
            install_ftp
            install_samba
            install_mail
            install_wordpress
            install_crud
            install_webmail
            echo -e "\n${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${GREEN}║   🎉 SEMUA SERVICE BERHASIL DIINSTALL! 🎉                         ║${NC}"
            echo -e "${GREEN}╠══════════════════════════════════════════════════════════════════╣${NC}"
            echo -e "${GREEN}║                                                                    ║${NC}"
            echo -e "${GREEN}║   🌐 LANDING PAGE:  http://$SERVER_IP                              ║${NC}"
            echo -e "${GREEN}║   🗄️  CRUD SISWA:   http://$SERVER_IP/crud/                       ║${NC}"
            echo -e "${GREEN}║   📧 WEBMAIL:       http://$SERVER_IP/roundcube/                  ║${NC}"
            echo -e "${GREEN}║   📝 WORDPRESS:     http://$SERVER_IP/wp-admin                    ║${NC}"
            echo -e "${GREEN}║                                                                    ║${NC}"
            echo -e "${GREEN}║   📧 LOGIN WEBMAIL: $EMAIL_USER@$MAIN_DOMAIN / $EMAIL_PASS        ║${NC}"
            echo -e "${GREEN}║                                                                    ║${NC}"
            echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
            ;;
        2) install_dhcp ;;
        3) install_dns ;;
        4) install_apache2 ;;
        5) install_ftp ;;
        6) install_samba ;;
        7) install_mail ;;
        8) install_wordpress ;;
        9) install_crud ;;
        10) install_webmail ;;
        11) echo -e "${GREEN}👋 Terima kasih!${NC}"; exit 0 ;;
        *) echo -e "${RED}❌ Pilihan salah!${NC}"; sleep 1 ;;
    esac
done
