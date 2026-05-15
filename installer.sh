# ======================= FUNGSI TAMBAHAN =======================

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
    fi
    read -p "Tekan Enter..."
}

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
    echo -e "\n${GREEN}✅ SAMBA BERHASIL! Akses: \\\\$SERVER_IP\\$share_name${NC}"
    read -p "Tekan Enter..."
}

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
    echo -e "\n${GREEN}✅ CRUD SISWA BERHASIL! Akses: http://$SERVER_IP/crud/${NC}"
    read -p "Tekan Enter..."
}

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
    echo -e "\n${YELLOW}📝 Masukkan domain (contoh: fahriakbar.net):${NC}"
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
    apt install -y postfix dovecot-core dovecot-imapd dovecot-pop3d mailutils
    postconf -e "myhostname = $MAIL_DOMAIN"
    postconf -e "mydomain = $MAIN_DOMAIN"
    postconf -e "myorigin = \$mydomain"
    postconf -e "inet_interfaces = all"
    postconf -e "home_mailbox = Maildir/"
    postconf -e "smtpd_sasl_type = dovecot"
    postconf -e "smtpd_sasl_path = private/auth"
    postconf -e "smtpd_sasl_auth_enable = yes"
    rm -rf /etc/dovecot /etc/dovecot.conf
    cat > /etc/dovecot/dovecot.conf <<EOF
disable_plaintext_auth = no
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
    systemctl restart postfix dovecot
    systemctl enable postfix dovecot
    echo "$MAIN_DOMAIN" > /etc/maildomain.conf
    echo "$MAIL_IP" > /etc/mailip.conf
    echo "$EMAIL_USER" > /etc/mailuser.conf
    echo "$EMAIL_PASS" > /etc/mailpass.conf
    echo -e "\n${GREEN}✅ MAIL SERVER BERHASIL! $EMAIL_USER@$MAIN_DOMAIN / $EMAIL_PASS${NC}"
    read -p "Tekan Enter..."
}

install_webmail() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         🌐 INSTALL WEBMAIL (ROUNDCUBE)         ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    if [[ -f /etc/maildomain.conf ]]; then
        MAIN_DOMAIN=$(cat /etc/maildomain.conf)
        MAIL_IP=$(cat /etc/mailip.conf)
        EMAIL_USER=$(cat /etc/mailuser.conf 2>/dev/null)
        EMAIL_PASS=$(cat /etc/mailpass.conf 2>/dev/null)
    else
        echo -e "\n${RED}❌ Mail Server belum diinstall! Install dulu menu 10 bagian 1.${NC}"
        read -p "Tekan Enter..."
        return
    fi
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
<?php \$config = []; \$config['db_dsnw'] = 'mysql://roundcube:rcube123@localhost/roundcubemail'; \$config['default_host'] = 'localhost'; \$config['smtp_server'] = 'localhost'; \$config['smtp_port'] = 25; \$config['smtp_user'] = '%u'; \$config['smtp_pass'] = '%p'; \$config['product_name'] = 'FahTech Webmail - $MAIN_DOMAIN'; \$config['plugins'] = ['archive', 'zipdownload']; \$config['skin'] = 'elastic';
PHP
    cat > /etc/apache2/conf-available/roundcube.conf <<APACHE
Alias /roundcube /usr/share/roundcube
<Directory /usr/share/roundcube/> Options +FollowSymLinks AllowOverride All Require all granted </Directory>
APACHE
    a2enconf roundcube
    a2enmod rewrite
    systemctl restart apache2 postfix dovecot
    echo -e "\n${GREEN}✅ WEBMAIL BERHASIL! Akses: http://$MAIL_IP/roundcube/${NC}"
    echo -e "${GREEN}   Login: $EMAIL_USER@$MAIN_DOMAIN / $EMAIL_PASS${NC}"
    read -p "Tekan Enter..."
}

install_all() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         ⚡ INSTALL SEMUA SERVICE LENGKAP       ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    echo -e "\n${YELLOW}⚠️ Proses akan memakan waktu 15-20 menit. Lanjutkan? (y/n):${NC}"
    read confirm
    if [[ "$confirm" == "y" ]]; then
        # Install semua service dasar
        apt update -qq
        apt install -y apache2 php libapache2-mod-php php-mysql php-sqlite3 mariadb-server
        install_dhcp
        install_ftp
        install_samba
        install_wordpress
        install_crud
        install_mail
        install_webmail
        echo -e "\n${GREEN}✅ SEMUA SERVICE BERHASIL DIINSTALL!${NC}"
    fi
    read -p "Tekan Enter..."
}
