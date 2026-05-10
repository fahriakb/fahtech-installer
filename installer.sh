#!/bin/bash

# ============================================================
#   FAHTECH - MULTI-SERVICE INSTALLER PRO v10.0
#   LENGKAP: MAIL SERVER + WEBMAIL + CRUD
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
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║                                                                    ║"
echo "║   ███████╗ █████╗ ██╗  ██╗████████╗███████╗ ██████╗██╗  ██╗       ║"
echo "║   ██╔════╝██╔══██╗██║  ██║╚══██╔══╝██╔════╝██╔════╝██║  ██║       ║"
echo "║   █████╗  ███████║███████║   ██║   █████╗  ██║     ███████║       ║"
echo "║   ██╔══╝  ██╔══██║██╔══██║   ██║   ██╔══╝  ██║     ██╔══██║       ║"
echo "║   ██║     ██║  ██║██║  ██║   ██║   ███████╗╚██████╗██║  ██║       ║"
echo "║   ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝ ╚═════╝╚═╝  ╚═╝       ║"
echo "║                                                                    ║"
echo "║           MULTI-SERVICE INSTALLER PROFESSIONAL v10.0              ║"
echo "║              MAIL SERVER + WEBMAIL + CRUD LENGKAP                 ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
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

# ======================= INSTALL MAIL SERVER LENGKAP =======================
install_mail() {
    clear
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    📧 INSTALL MAIL SERVER                        ║${NC}"
    echo -e "${GREEN}║              POSTFIX + DOVECOT + WEBMAIL READY                   ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    
    # Tampilkan interface
    show_interfaces
    
    echo -e "\n${YELLOW}👉 Pilih interface untuk Mail Server:${NC}"
    read -p "Nomor [1-${#INTERFACES[@]}]: " choice
    
    if [[ $choice -ge 1 && $choice -le ${#INTERFACES[@]} ]]; then
        IFS='|' read -r SELECTED_IFACE SELECTED_IP <<< "${INTERFACES[$((choice-1))]}"
        DNS_IP=$SELECTED_IP
        echo -e "\n${GREEN}✅ Terpilih: $SELECTED_IFACE (IP: $DNS_IP)${NC}"
    else
        DNS_IP=$(hostname -I | awk '{print $1}')
        echo -e "\n${YELLOW}⚠️ Menggunakan IP default: $DNS_IP${NC}"
    fi
    
    # INPUT DOMAIN
    echo -e "\n${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  📝 MASUKKAN DOMAIN UNTUK EMAIL                                   ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║                                                                   ║${NC}"
    echo -e "${CYAN}║  📌 CONTOH DOMAIN:                                                ║${NC}"
    echo -e "${CYAN}║     • fahrinih.net                                                ║${NC}"
    echo -e "${CYAN}║     • perusahaan.com                                              ║${NC}"
    echo -e "${CYAN}║     • toko123.id                                                  ║${NC}"
    echo -e "${CYAN}║                                                                   ║${NC}"
    echo -e "${CYAN}║  💡 NANTI EMAIL AKAN: nama@domain-anda.com                        ║${NC}"
    echo -e "${CYAN}║     Contoh: admin@fahrinih.net                                    ║${NC}"
    echo -e "${CYAN}║                                                                   ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo -e "\n${YELLOW}👉 Masukkan domain Anda (contoh: fahrinih.net):${NC}"
    read -p "📝 Domain: " MAIN_DOMAIN
    
    while [[ -z "$MAIN_DOMAIN" ]]; do
        echo -e "${RED}❌ Domain tidak boleh kosong!${NC}"
        read -p "📝 Domain (contoh: fahrinih.net): " MAIN_DOMAIN
    done
    
    # INPUT USERNAME
    echo -e "\n${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  👤 BUAT AKUN EMAIL ADMIN                                         ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║                                                                   ║${NC}"
    echo -e "${CYAN}║  📌 CONTOH USERNAME:                                              ║${NC}"
    echo -e "${CYAN}║     • admin                                                       ║${NC}"
    echo -e "${CYAN}║     • info                                                        ║${NC}"
    echo -e "${CYAN}║     • support                                                     ║${NC}"
    echo -e "${CYAN}║                                                                   ║${NC}"
    echo -e "${CYAN}║  💡 NANTI LOGIN: $EMAIL_USER@$MAIN_DOMAIN                         ║${NC}"
    echo -e "${CYAN}║                                                                   ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo -e "\n${YELLOW}👉 Masukkan username email (contoh: admin):${NC}"
    read -p "👤 Username: " EMAIL_USER
    EMAIL_USER=${EMAIL_USER:-admin}
    
    # INPUT PASSWORD
    echo -e "\n${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  🔑 BUAT PASSWORD                                                  ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║                                                                   ║${NC}"
    echo -e "${CYAN}║  📌 CONTOH PASSWORD:                                              ║${NC}"
    echo -e "${CYAN}║     • admin123                                                    ║${NC}"
    echo -e "${CYAN}║     • rahasia123                                                  ║${NC}"
    echo -e "${CYAN}║     • FahTech2024                                                 ║${NC}"
    echo -e "${CYAN}║                                                                   ║${NC}"
    echo -e "${CYAN}║  ⚠️  PASSWORD TIDAK AKAN TAMPIL SAAT DIKETIK                      ║${NC}"
    echo -e "${CYAN}║                                                                   ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo -e "\n${YELLOW}👉 Masukkan password untuk $EMAIL_USER@$MAIN_DOMAIN:${NC}"
    read -s -p "🔑 Password: " EMAIL_PASS
    echo ""
    read -s -p "🔑 Konfirmasi password: " EMAIL_PASS_CONFIRM
    echo ""
    
    if [[ "$EMAIL_PASS" != "$EMAIL_PASS_CONFIRM" ]] || [[ -z "$EMAIL_PASS" ]]; then
        EMAIL_PASS="admin123"
        echo -e "\n${YELLOW}⚠️ Menggunakan password default: admin123${NC}"
    fi
    
    MAIL_DOMAIN="mail.$MAIN_DOMAIN"
    
    echo -e "\n${CYAN}📦 Menginstall Mail Server...${NC}"
    echo -e "${YELLOW}   ⏳ Mohon tunggu 2-3 menit...${NC}"
    
    # Set hostname
    hostnamectl set-hostname $MAIL_DOMAIN
    echo "$DNS_IP $MAIL_DOMAIN" >> /etc/hosts
    
    # Install packages
    apt update -qq
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
    
    # Simpan data
    echo "$MAIN_DOMAIN" > /etc/maildomain.conf
    echo "$DNS_IP" > /etc/mailip.conf
    echo "$EMAIL_USER" > /etc/mailuser.conf
    echo "$EMAIL_PASS" > /etc/mailpass.conf
    
    echo -e "\n${GREEN}╔════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   ✅ MAIL SERVER BERHASIL DIINSTALL!                                                 ║${NC}"
    echo -e "${GREEN}╠════════════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║                                                                                    ║${NC}"
    echo -e "${GREEN}║   📧 LOGIN EMAIL:                                                                  ║${NC}"
    echo -e "${GREEN}║      👤 Username: $EMAIL_USER@$MAIN_DOMAIN                                        ║${NC}"
    echo -e "${GREEN}║      🔑 Password: $EMAIL_PASS                                                      ║${NC}"
    echo -e "${GREEN}║                                                                                    ║${NC}"
    echo -e "${GREEN}║   🌐 AKSES WEBMAIL (Setelah install menu 9):                                       ║${NC}"
    echo -e "${GREEN}║      👉 http://$DNS_IP/roundcube/                                                  ║${NC}"
    echo -e "${GREEN}║                                                                                    ║${NC}"
    echo -e "${GREEN}║   📌 LANJUTKAN KE MENU 9 UNTUK INSTALL WEBMAIL!                                    ║${NC}"
    echo -e "${GREEN}║                                                                                    ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${YELLOW}Tekan Enter untuk kembali ke menu...${NC}"
    read
}

# ======================= INSTALL WEBMAIL =======================
install_webmail() {
    clear
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    📧 INSTALL WEBMAIL (ROUNDCUBE)               ║${NC}"
    echo -e "${GREEN}║              BISA LOGIN & KIRIM EMAIL VIA BROWSER               ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    
    # Baca dari mail server
    if [[ -f /etc/maildomain.conf ]]; then
        MAIN_DOMAIN=$(cat /etc/maildomain.conf)
        DNS_IP=$(cat /etc/mailip.conf)
        EMAIL_USER=$(cat /etc/mailuser.conf 2>/dev/null)
        EMAIL_PASS=$(cat /etc/mailpass.conf 2>/dev/null)
        echo -e "\n${GREEN}✅ Mendeteksi konfigurasi Mail Server:${NC}"
        echo -e "   📝 Domain: $MAIN_DOMAIN"
        echo -e "   🌐 IP: $DNS_IP"
        echo -e "   👤 User: $EMAIL_USER@$MAIN_DOMAIN"
    else
        echo -e "\n${RED}❌ Mail Server belum diinstall! Install dulu lewat menu 7.${NC}"
        echo -e "\n${YELLOW}Tekan Enter...${NC}"
        read
        return
    fi
    
    echo -e "\n${CYAN}📦 Menginstall Roundcube Webmail...${NC}"
    
    apt install roundcube roundcube-mysql roundcube-plugins roundcube-core php-mysql -y -qq
    
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
\$config['plugins'] = array('archive', 'zipdownload');
\$config['skin'] = 'elastic';
EOF
    
    ln -sf /etc/roundcube/apache.conf /etc/apache2/conf-available/roundcube.conf
    a2enconf roundcube
    a2enmod rewrite
    systemctl restart apache2
    systemctl restart postfix dovecot
    
    WEBMAIL_URL="http://$DNS_IP/roundcube/"
    
    echo -e "\n${GREEN}╔════════════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   ✅ WEBMAIL (ROUNDCUBE) BERHASIL DIINSTALL!                                                 ║${NC}"
    echo -e "${GREEN}╠════════════════════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║                                                                                            ║${NC}"
    echo -e "${GREEN}║   🌐 AKSES WEBMAIL:                                                                       ║${NC}"
    echo -e "${GREEN}║      👉 ${WEBMAIL_URL}${NC}"
    echo -e "${GREEN}║                                                                                            ║${NC}"
    echo -e "${GREEN}║   📝 LOGIN MENGGUNAKAN:                                                                    ║${NC}"
    echo -e "${GREEN}║      👤 Username: $EMAIL_USER@$MAIN_DOMAIN                                                ║${NC}"
    echo -e "${GREEN}║      🔑 Password: $EMAIL_PASS                                                              ║${NC}"
    echo -e "${GREEN}║                                                                                            ║${NC}"
    echo -e "${GREEN}║   📌 CARA MENCOBA KIRIM EMAIL:                                                             ║${NC}"
    echo -e "${GREEN}║      1. Buka link webmail di atas                                                          ║${NC}"
    echo -e "${GREEN}║      2. Login dengan username & password di atas                                          ║${NC}"
    echo -e "${GREEN}║      3. Klik \"Compose\" atau \"Tulis Email\"                                                ║${NC}"
    echo -e "${GREEN}║      4. Isi tujuan: $EMAIL_USER@$MAIN_DOMAIN                                              ║${NC}"
    echo -e "${GREEN}║      5. Tulis subjek dan pesan                                                             ║${NC}"
    echo -e "${GREEN}║      6. Klik \"Send\" - Email akan terkirim! ✅                                             ║${NC}"
    echo -e "${GREEN}║                                                                                            ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${YELLOW}Tekan Enter untuk kembali ke menu...${NC}"
    read
}

# ======================= INSTALL CRUD WEB =======================
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
    <title>FahTech CRUD</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); font-family: Arial, sans-serif; padding: 40px; }
        .container { max-width: 1200px; margin: auto; background: white; border-radius: 20px; padding: 30px; }
        h1 { color: #667eea; }
        .form-add { background: #f8f9fa; padding: 20px; border-radius: 10px; margin: 20px 0; display: flex; gap: 10px; flex-wrap: wrap; }
        .form-add input, .form-add select { padding: 10px; border: 1px solid #ddd; border-radius: 5px; flex: 1; }
        button { background: #667eea; color: white; border: none; padding: 10px 20px; border-radius: 5px; cursor: pointer; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #667eea; color: white; }
        .edit-btn { background: #3498db; color: white; padding: 5px 10px; border-radius: 5px; text-decoration: none; }
        .delete-btn { background: #e74c3c; color: white; padding: 5px 10px; border-radius: 5px; text-decoration: none; }
        .edit-form { background: #fff3cd; padding: 20px; border-radius: 10px; margin-top: 20px; }
        .success { background: #d4edda; color: #155724; padding: 10px; border-radius: 5px; margin: 10px 0; }
    </style>
</head>
<body>
<div class="container">
    <h1>⚡ FahTech CRUD Application</h1>
    <p>Fitur: Tambah, Edit, Hapus, dan Cari Data</p>
    
    <?php
    $db = new SQLite3('/var/www/html/crud/data.db');
    $db->exec("CREATE TABLE IF NOT EXISTS items (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, description TEXT, category TEXT, created_at DATETIME DEFAULT CURRENT_TIMESTAMP)");
    
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
    
    <form method="post" class="form-add">
        <input type="text" name="name" placeholder="Nama Item *" required>
        <input type="text" name="description" placeholder="Deskripsi">
        <input type="text" name="category" placeholder="Kategori">
        <button type="submit" name="add">➕ Tambah</button>
    </form>
    
    <div style="margin: 20px 0; display: flex; gap: 10px;">
        <form method="get" style="display: flex; gap: 10px; flex: 1;">
            <input type="text" name="search" placeholder="Cari data..." value="<?= htmlspecialchars($search) ?>" style="flex: 1; padding: 10px; border-radius: 5px; border: 1px solid #ddd;">
            <button type="submit">🔍 Cari</button>
            <?php if($search): ?><a href="?">Reset</a><?php endif; ?>
        </form>
    </div>
    
    <h2>📋 Data Items</h2>
    <table>
        <tr><th>ID</th><th>Nama</th><th>Deskripsi</th><th>Kategori</th><th>Tanggal</th><th>Aksi</th></tr>
        <?php while ($row = $result->fetchArray()): ?>
        <tr>
            <td><?= $row['id'] ?></td>
            <td><strong><?= htmlspecialchars($row['name']) ?></strong></td>
            <td><?= htmlspecialchars($row['description']) ?></td>
            <td><?= htmlspecialchars($row['category']) ?></td>
            <td><?= $row['created_at'] ?></td>
            <td>
                <a href="?edit=<?= $row['id'] ?>" class="edit-btn">✏️ Edit</a>
                <a href="?delete=<?= $row['id'] ?>" class="delete-btn" onclick="return confirm('Yakin hapus?')">🗑️ Hapus</a>
            </td>
        </tr>
        <?php endwhile; ?>
    </table>
    
    <?php if (isset($_GET['edit'])): 
        $id = (int)$_GET['edit'];
        $edit = $db->query("SELECT * FROM items WHERE id=$id")->fetchArray();
        if ($edit):
    ?>
    <div class="edit-form">
        <h3>✏️ Edit Data</h3>
        <form method="post" style="display: flex; gap: 10px; flex-wrap: wrap;">
            <input type="hidden" name="id" value="<?= $edit['id'] ?>">
            <input type="text" name="name" value="<?= htmlspecialchars($edit['name']) ?>" required>
            <input type="text" name="description" value="<?= htmlspecialchars($edit['description']) ?>">
            <input type="text" name="category" value="<?= htmlspecialchars($edit['category']) ?>">
            <button type="submit" name="update">💾 Update</button>
            <a href="?">Batal</a>
        </form>
    </div>
    <?php endif; endif; ?>
</div>
</body>
</html>
EOF
    
    chown -R www-data:www-data /var/www/html/crud
    systemctl restart apache2
    
    SERVER_IP=$(hostname -I | awk '{print $1}')
    
    echo -e "\n${GREEN}✅ CRUD WEB BERHASIL! Akses: http://$SERVER_IP/crud/${NC}"
    echo -e "\n${YELLOW}Tekan Enter...${NC}"
    read
}

# ======================= INSTALL APACHE2 =======================
install_apache2() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    🌍 INSTALL APACHE2                      ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    
    apt update -qq
    apt install apache2 php libapache2-mod-php php-mysql php-curl php-gd php-xml php-mbstring php-zip php-sqlite3 -y -qq
    
    SERVER_IP=$(hostname -I | awk '{print $1}')
    
    cat > /var/www/html/index.html <<EOF
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
<p style="color:white;">Server IP: <?php echo \$_SERVER['SERVER_ADDR']; ?></p>
<p style="color:white;">Powered by FahTech Auto Installer v10.0</p>
</body>
</html>
EOF
    
    systemctl restart apache2
    echo -e "\n${GREEN}✅ APACHE2 BERHASIL! Akses: http://$SERVER_IP${NC}"
    echo -e "\n${YELLOW}Tekan Enter...${NC}"
    read
}

# ======================= INSTALL DHCP =======================
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

# ======================= INSTALL DNS =======================
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
        echo -e "${YELLOW}   Contoh: fahrinih.net${NC}"
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

# ======================= INSTALL FTP =======================
install_ftp() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    📁 INSTALL FTP SERVER                   ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    
    apt install vsftpd -y -qq
    systemctl restart vsftpd
    systemctl enable vsftpd
    
    echo -e "\n${GREEN}✅ FTP BERHASIL!${NC}"
    echo -e "\n${YELLOW}Tekan Enter...${NC}"
    read
}

# ======================= INSTALL SAMBA =======================
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

# ======================= INSTALL WORDPRESS =======================
install_wordpress() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    📝 INSTALL WORDPRESS                    ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    
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
    
    SERVER_IP=$(hostname -I | awk '{print $1}')
    
    echo -e "\n${GREEN}✅ WORDPRESS BERHASIL! Akses: http://$SERVER_IP/wp-admin/install.php${NC}"
    echo -e "\n${YELLOW}Tekan Enter...${NC}"
    read
}

# ======================= MENU UTAMA =======================
while true; do
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║            🚀 FAHTECH MULTI-SERVICE INSTALLER v10.0             ║"
    echo "║         MAIL SERVER + WEBMAIL + CRUD LENGKAP                     ║"
    echo "╠══════════════════════════════════════════════════════════════════╣"
    echo "║                                                                  ║"
    echo "║  1.  ⚡ INSTALL SEMUA SERVICE LENGKAP (15-20 menit)              ║"
    echo "║  2.  🌐 Install DHCP Server                                     ║"
    echo "║  3.  🔍 Install DNS Server                                      ║"
    echo "║  4.  🌍 Install Apache2                                         ║"
    echo "║  5.  📁 Install FTP Server                                      ║"
    echo "║  6.  🖥️  Install Samba                                          ║"
    echo "║  7.  📧 Install MAIL SERVER + Buat Akun Email                   ║"
    echo "║  8.  📝 Install WordPress                                       ║"
    echo "║  9.  🗄️  Install CRUD WEB (Tambah/Edit/Hapus/Cari)              ║"
    echo "║  10. 🌐 Install WEBMAIL (Login & Kirim Email via Browser)       ║"
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
