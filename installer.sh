#!/bin/bash

# ============================================================
#   FAHTECH - MULTI-SERVICE INSTALLER PRO v11.0
#   3 DNS SERVER | 3 TAMPILAN | TUTORIAL LENGKAP
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
echo "║                3 DNS SERVER | 3 TAMPILAN | TUTORIAL LENGKAP                 ║"
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

# ============================================================
# MENU 1: DNS SERVER - TUTORIAL DHCP
# ============================================================
dns_dhcp() {
    clear
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║           🔍 DNS SERVER 1 - TUTORIAL DHCP SERVER                 ║${NC}"
    echo -e "${BLUE}║           📖 Tutorial Membuat DHCP Server di Debian              ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
    
    show_interfaces
    echo -e "\n${YELLOW}👉 Pilih interface untuk DNS Server 1:${NC}"
    read -p "Nomor [1-${#INTERFACES[@]}]: " choice
    
    if [[ $choice -ge 1 && $choice -le ${#INTERFACES[@]} ]]; then
        IFS='|' read -r IFACE IP <<< "${INTERFACES[$((choice-1))]}"
        echo -e "\n${MAGENTA}📝 Masukkan nama domain (contoh: dhcp.fahtech.local):${NC}"
        read -p "Domain: " DOMAIN
        
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
dhcp    IN      A       $IP
EOF
        
        systemctl restart bind9
        
        echo -e "\n${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║   ✅ DNS SERVER 1 BERHASIL!                                         ║${NC}"
        echo -e "${GREEN}║   📝 Domain: $DOMAIN                                               ║${NC}"
        echo -e "${GREEN}║   🌐 IP: $IP                                                       ║${NC}"
        echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
        
        # Tampilkan Tutorial DHCP
        echo -e "\n${CYAN}╔════════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║                    📖 TUTORIAL DHCP SERVER LENGKAP                          ║${NC}"
        echo -e "${CYAN}╠════════════════════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${CYAN}║                                                                             ║${NC}"
        echo -e "${CYAN}║  📌 LANGKAH 1: INSTALL DHCP SERVER                                         ║${NC}"
        echo -e "${CYAN}║     ─────────────────────────────────────────────────────────────────    ║${NC}"
        echo -e "${CYAN}║     $ sudo apt update                                                      ║${NC}"
        echo -e "${CYAN}║     $ sudo apt install isc-dhcp-server -y                                  ║${NC}"
        echo -e "${CYAN}║                                                                             ║${NC}"
        echo -e "${CYAN}║  📌 LANGKAH 2: KONFIGURASI INTERFACE                                       ║${NC}"
        echo -e "${CYAN}║     ─────────────────────────────────────────────────────────────────    ║${NC}"
        echo -e "${CYAN}║     $ sudo nano /etc/default/isc-dhcp-server                               ║${NC}"
        echo -e "${CYAN}║     Isi: INTERFACESv4=\"$IFACE\"                                            ║${NC}"
        echo -e "${CYAN}║                                                                             ║${NC}"
        echo -e "${CYAN}║  📌 LANGKAH 3: KONFIGURASI DHCP                                             ║${NC}"
        echo -e "${CYAN}║     ─────────────────────────────────────────────────────────────────    ║${NC}"
        echo -e "${CYAN}║     $ sudo nano /etc/dhcp/dhcpd.conf                                       ║${NC}"
        echo -e "${CYAN}║     subnet ${IP%.*}.0 netmask 255.255.255.0 {                              ║${NC}"
        echo -e "${CYAN}║         range ${IP%.*}.100 ${IP%.*}.200;                                   ║${NC}"
        echo -e "${CYAN}║         option routers ${IP%.*}.1;                                         ║${NC}"
        echo -e "${CYAN}║         option domain-name-servers $IP, 8.8.8.8;                           ║${NC}"
        echo -e "${CYAN}║     }                                                                      ║${NC}"
        echo -e "${CYAN}║                                                                             ║${NC}"
        echo -e "${CYAN}║  📌 LANGKAH 4: START DHCP SERVER                                           ║${NC}"
        echo -e "${CYAN}║     ─────────────────────────────────────────────────────────────────    ║${NC}"
        echo -e "${CYAN}║     $ sudo systemctl restart isc-dhcp-server                               ║${NC}"
        echo -e "${CYAN}║     $ sudo systemctl enable isc-dhcp-server                                ║${NC}"
        echo -e "${CYAN}║                                                                             ║${NC}"
        echo -e "${CYAN}║  📌 LANGKAH 5: CEK STATUS                                                  ║${NC}"
        echo -e "${CYAN}║     ─────────────────────────────────────────────────────────────────    ║${NC}"
        echo -e "${CYAN}║     $ sudo systemctl status isc-dhcp-server                                ║${NC}"
        echo -e "${CYAN}║                                                                             ║${NC}"
        echo -e "${CYAN}║  📌 LANGKAH 6: LIHAT CLIENT YANG TERHUBUNG                                 ║${NC}"
        echo -e "${CYAN}║     ─────────────────────────────────────────────────────────────────    ║${NC}"
        echo -e "${CYAN}║     $ sudo cat /var/lib/dhcp/dhcpd.leases                                  ║${NC}"
        echo -e "${CYAN}║                                                                             ║${NC}"
        echo -e "${CYAN}║  📌 LANGKAH 7: LOG DHCP                                                    ║${NC}"
        echo -e "${CYAN}║     ─────────────────────────────────────────────────────────────────    ║${NC}"
        echo -e "${CYAN}║     $ sudo tail -f /var/log/syslog | grep dhcp                             ║${NC}"
        echo -e "${CYAN}║                                                                             ║${NC}"
        echo -e "${CYAN}║  📌 LANGKAH 8: TEST DARI CLIENT                                             ║${NC}"
        echo -e "${CYAN}║     ─────────────────────────────────────────────────────────────────    ║${NC}"
        echo -e "${CYAN}║     Di Windows: ipconfig /renew                                           ║${NC}"
        echo -e "${CYAN}║     Di Linux: sudo dhclient $IFACE                                         ║${NC}"
        echo -e "${CYAN}║                                                                             ║${NC}"
        echo -e "${CYAN}╚════════════════════════════════════════════════════════════════════════════╝${NC}"
    fi
    echo ""
    read -p "Tekan Enter untuk kembali ke menu..."
}

# ============================================================
# MENU 2: DNS SERVER - TUTORIAL CRUD
# ============================================================
dns_crud() {
    clear
    echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║           🔍 DNS SERVER 2 - TUTORIAL CRUD SISWA                  ║${NC}"
    echo -e "${MAGENTA}║           📖 Tutorial Konfigurasi CRUD Lengkap                   ║${NC}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════════╝${NC}"
    
    show_interfaces
    echo -e "\n${YELLOW}👉 Pilih interface untuk DNS Server 2:${NC}"
    read -p "Nomor [1-${#INTERFACES[@]}]: " choice
    
    if [[ $choice -ge 1 && $choice -le ${#INTERFACES[@]} ]]; then
        IFS='|' read -r IFACE IP <<< "${INTERFACES[$((choice-1))]}"
        echo -e "\n${MAGENTA}📝 Masukkan nama domain (contoh: crud.fahtech.local):${NC}"
        read -p "Domain: " DOMAIN
        
        apt install -y bind9 bind9utils
        
        cat > /etc/bind/named.conf.local <<EOF
zone "$DOMAIN" {
    type master;
    file "/etc/bind/db.$DOMAIN";
};
EOF
        
        cat > /etc/bind/db.$DOMAIN <<EOF
\$TTL    604800
@       IN      SOA     ns1.$DOMAIN. admin.$DOMAIN. ( 2 604800 86400 2419200 604800 )
@       IN      NS      ns1.$DOMAIN.
@       IN      A       $IP
ns1     IN      A       $IP
www     IN      A       $IP
crud    IN      A       $IP
EOF
        
        systemctl restart bind9
        
        echo -e "\n${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║   ✅ DNS SERVER 2 BERHASIL!                                         ║${NC}"
        echo -e "${GREEN}║   📝 Domain: $DOMAIN                                               ║${NC}"
        echo -e "${GREEN}║   🌐 IP: $IP                                                       ║${NC}"
        echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
        
        # Tampilkan Tutorial CRUD
        echo -e "\n${CYAN}╔════════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║                    📖 TUTORIAL CRUD SISWA LENGKAP                           ║${NC}"
        echo -e "${CYAN}╠════════════════════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${CYAN}║                                                                             ║${NC}"
        echo -e "${CYAN}║  📌 LANGKAH 1: INSTALL APACHE2 & PHP                                        ║${NC}"
        echo -e "${CYAN}║     ─────────────────────────────────────────────────────────────────    ║${NC}"
        echo -e "${CYAN}║     $ sudo apt update                                                      ║${NC}"
        echo -e "${CYAN}║     $ sudo apt install apache2 php libapache2-mod-php php-sqlite3 -y       ║${NC}"
        echo -e "${CYAN}║                                                                             ║${NC}"
        echo -e "${CYAN}║  📌 LANGKAH 2: BUAT FOLDER CRUD                                            ║${NC}"
        echo -e "${CYAN}║     ─────────────────────────────────────────────────────────────────    ║${NC}"
        echo -e "${CYAN}║     $ sudo mkdir -p /var/www/html/crud                                     ║${NC}"
        echo -e "${CYAN}║                                                                             ║${NC}"
        echo -e "${CYAN}║  📌 LANGKAH 3: BUAT FILE INDEX.PHP                                          ║${NC}"
        echo -e "${CYAN}║     ─────────────────────────────────────────────────────────────────    ║${NC}"
        echo -e "${CYAN}║     $ sudo nano /var/www/html/crud/index.php                               ║${NC}"
        echo -e "${CYAN}║                                                                             ║${NC}"
        echo -e "${CYAN}║  📌 LANGKAH 4: STRUKTUR DATABASE (SQLite)                                   ║${NC}"
        echo -e "${CYAN}║     ─────────────────────────────────────────────────────────────────    ║${NC}"
        echo -e "${CYAN}║     CREATE TABLE siswa (                                                   ║${NC}"
        echo -e "${CYAN}║         id INTEGER PRIMARY KEY AUTOINCREMENT,                              ║${NC}"
        echo -e "${CYAN}║         nama TEXT NOT NULL,                                                ║${NC}"
        echo -e "${CYAN}║         rombel TEXT NOT NULL,                                              ║${NC}"
        echo -e "${CYAN}║         nis TEXT NOT NULL UNIQUE                                           ║${NC}"
        echo -e "${CYAN}║     );                                                                     ║${NC}"
        echo -e "${CYAN}║                                                                             ║${NC}"
        echo -e "${CYAN}║  📌 LANGKAH 5: FITUR CRUD                                                  ║${NC}"
        echo -e "${CYAN}║     ─────────────────────────────────────────────────────────────────    ║${NC}"
        echo -e "${CYAN}║     ➕ CREATE (Tambah Data)                                                ║${NC}"
        echo -e "${CYAN}║        INSERT INTO siswa (nama, rombel, nis) VALUES ('...', '...', '...') ║${NC}"
        echo -e "${CYAN}║                                                                             ║${NC}"
        echo -e "${CYAN}║     📖 READ (Tampilkan Data)                                               ║${NC}"
        echo -e "${CYAN}║        SELECT * FROM siswa ORDER BY id DESC                                ║${NC}"
        echo -e "${CYAN}║                                                                             ║${NC}"
        echo -e "${CYAN}║     ✏️ UPDATE (Edit Data)                                                  ║${NC}"
        echo -e "${CYAN}║        UPDATE siswa SET nama='...', rombel='...', nis='...' WHERE id=...  ║${NC}"
        echo -e "${CYAN}║                                                                             ║${NC}"
        echo -e "${CYAN}║     🗑️ DELETE (Hapus Data)                                                 ║${NC}"
        echo -e "${CYAN}║        DELETE FROM siswa WHERE id=...                                      ║${NC}"
        echo -e "${CYAN}║                                                                             ║${NC}"
        echo -e "${CYAN}║     🔍 SEARCH (Cari Data)                                                  ║${NC}"
        echo -e "${CYAN}║        SELECT * FROM siswa WHERE nama LIKE '%...%'                         ║${NC}"
        echo -e "${CYAN}║                                                                             ║${NC}"
        echo -e "${CYAN}║  📌 LANGKAH 6: SET PERMISSION                                              ║${NC}"
        echo -e "${CYAN}║     ─────────────────────────────────────────────────────────────────    ║${NC}"
        echo -e "${CYAN}║     $ sudo chown -R www-data:www-data /var/www/html/crud                   ║${NC}"
        echo -e "${CYAN}║                                                                             ║${NC}"
        echo -e "${CYAN}║  📌 LANGKAH 7: RESTART APACHE                                              ║${NC}"
        echo -e "${CYAN}║     ─────────────────────────────────────────────────────────────────    ║${NC}"
        echo -e "${CYAN}║     $ sudo systemctl restart apache2                                       ║${NC}"
        echo -e "${CYAN}║                                                                             ║${NC}"
        echo -e "${CYAN}║  📌 LANGKAH 8: AKSES CRUD                                                  ║${NC}"
        echo -e "${CYAN}║     ─────────────────────────────────────────────────────────────────    ║${NC}"
        echo -e "${CYAN}║     Buka browser: http://$IP/crud/                                         ║${NC}"
        echo -e "${CYAN}║                                                                             ║${NC}"
        echo -e "${CYAN}╚════════════════════════════════════════════════════════════════════════════╝${NC}"
    fi
    echo ""
    read -p "Tekan Enter untuk kembali ke menu..."
}

# ============================================================
# MENU 3: DNS SERVER - TUTORIAL APACHE2
# ============================================================
dns_apache() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           🔍 DNS SERVER 3 - TUTORIAL APACHE2                     ║${NC}"
    echo -e "${CYAN}║           📖 Tutorial Konfigurasi Apache2 Web Server             ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    
    show_interfaces
    echo -e "\n${YELLOW}👉 Pilih interface untuk DNS Server 3:${NC}"
    read -p "Nomor [1-${#INTERFACES[@]}]: " choice
    
    if [[ $choice -ge 1 && $choice -le ${#INTERFACES[@]} ]]; then
        IFS='|' read -r IFACE IP <<< "${INTERFACES[$((choice-1))]}"
        echo -e "\n${CYAN}📝 Masukkan nama domain (contoh: web.fahtech.local):${NC}"
        read -p "Domain: " DOMAIN
        
        apt install -y bind9 bind9utils
        
        cat > /etc/bind/named.conf.local <<EOF
zone "$DOMAIN" {
    type master;
    file "/etc/bind/db.$DOMAIN";
};
EOF
        
        cat > /etc/bind/db.$DOMAIN <<EOF
\$TTL    604800
@       IN      SOA     ns1.$DOMAIN. admin.$DOMAIN. ( 3 604800 86400 2419200 604800 )
@       IN      NS      ns1.$DOMAIN.
@       IN      A       $IP
ns1     IN      A       $IP
www     IN      A       $IP
web     IN      A       $IP
EOF
        
        systemctl restart bind9
        
        echo -e "\n${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║   ✅ DNS SERVER 3 BERHASIL!                                         ║${NC}"
        echo -e "${GREEN}║   📝 Domain: $DOMAIN                                               ║${NC}"
        echo -e "${GREEN}║   🌐 IP: $IP                                                       ║${NC}"
        echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
        
        # Tampilkan Tutorial Apache2
        echo -e "\n${CYAN}╔════════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║                 📖 TUTORIAL APACHE2 WEB SERVER LENGKAP                       ║${NC}"
        echo -e "${CYAN}╠════════════════════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${CYAN}║                                                                             ║${NC}"
        echo -e "${CYAN}║  📌 LANGKAH 1: INSTALL APACHE2                                              ║${NC}"
        echo -e "${CYAN}║     ─────────────────────────────────────────────────────────────────    ║${NC}"
        echo -e "${CYAN}║     $ sudo apt update                                                      ║${NC}"
        echo -e "${CYAN}║     $ sudo apt install apache2 -y                                          ║${NC}"
        echo -e "${CYAN}║                                                                             ║${NC}"
        echo -e "${CYAN}║  📌 LANGKAH 2: CEK STATUS APACHE2                                          ║${NC}"
        echo -e "${CYAN}║     ─────────────────────────────────────────────────────────────────    ║${NC}"
        echo -e "${CYAN}║     $ sudo systemctl status apache2                                        ║${NC}"
        echo -e "${CYAN}║     $ sudo systemctl enable apache2                                        ║${NC}"
        echo -e "${CYAN}║                                                                             ║${NC}"
        echo -e "${CYAN}║  📌 LANGKAH 3: KONFIGURASI VIRTUAL HOST                                     ║${NC}"
        echo -e "${CYAN}║     ─────────────────────────────────────────────────────────────────    ║${NC}"
        echo -e "${CYAN}║     $ sudo nano /etc/apache2/sites-available/$DOMAIN.conf                  ║${NC}"
        echo -e "${CYAN}║                                                                             ║${NC}"
        echo -e "${CYAN}║     <VirtualHost *:80>                                                     ║${NC}"
        echo -e "${CYAN}║         ServerName $DOMAIN                                                 ║${NC}"
        echo -e "${CYAN}║         ServerAlias www.$DOMAIN                                            ║${NC}"
        echo -e "${CYAN}║         DocumentRoot /var/www/html/$DOMAIN                                 ║${NC}"
        echo -e "${CYAN}║         ErrorLog \${APACHE_LOG_DIR}/error.log                               ║${NC}"
        echo -e "${CYAN}║         CustomLog \${APACHE_LOG_DIR}/access.log combined                    ║${NC}"
        echo -e "${CYAN}║     </VirtualHost>                                                          ║${NC}"
        echo -e "${CYAN}║                                                                             ║${NC}"
        echo -e "${CYAN}║  📌 LANGKAH 4: AKTIFKAN SITE                                                ║${NC}"
        echo -e "${CYAN}║     ─────────────────────────────────────────────────────────────────    ║${NC}"
        echo -e "${CYAN}║     $ sudo a2ensite $DOMAIN.conf                                            ║${NC}"
        echo -e "${CYAN}║     $ sudo a2dissite 000-default.conf                                      ║${NC}"
        echo -e "${CYAN}║     $ sudo systemctl reload apache2                                        ║${NC}"
        echo -e "${CYAN}║                                                                             ║${NC}"
        echo -e "${CYAN}║  📌 LANGKAH 5: BUAT FILE INDEX.HTML                                         ║${NC}"
        echo -e "${CYAN}║     ─────────────────────────────────────────────────────────────────    ║${NC}"
        echo -e "${CYAN}║     $ sudo mkdir -p /var/www/html/$DOMAIN                                   ║${NC}"
        echo -e "${CYAN}║     $ sudo nano /var/www/html/$DOMAIN/index.html                            ║${NC}"
        echo -e "${CYAN}║                                                                             ║${NC}"
        echo -e "${CYAN}║  📌 LANGKAH 6: INSTALL PHP (Opsional)                                       ║${NC}"
        echo -e "${CYAN}║     ─────────────────────────────────────────────────────────────────    ║${NC}"
        echo -e "${CYAN}║     $ sudo apt install php libapache2-mod-php -y                            ║${NC}"
        echo -e "${CYAN}║     $ sudo systemctl restart apache2                                        ║${NC}"
        echo -e "${CYAN}║                                                                             ║${NC}"
        echo -e "${CYAN}║  📌 LANGKAH 7: TEST PHP                                                    ║${NC}"
        echo -e "${CYAN}║     ─────────────────────────────────────────────────────────────────    ║${NC}"
        echo -e "${CYAN}║     $ echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/$DOMAIN/info.php ║${NC}"
        echo -e "${CYAN}║                                                                             ║${NC}"
        echo -e "${CYAN}║  📌 LANGKAH 8: INSTALL MODUL SSL (HTTPS)                                    ║${NC}"
        echo -e "${CYAN}║     ─────────────────────────────────────────────────────────────────    ║${NC}"
        echo -e "${CYAN}║     $ sudo a2enmod ssl                                                      ║${NC}"
        echo -e "${CYAN}║     $ sudo a2enmod rewrite                                                  ║${NC}"
        echo -e "${CYAN}║     $ sudo systemctl restart apache2                                        ║${NC}"
        echo -e "${CYAN}║                                                                             ║${NC}"
        echo -e "${CYAN}║  📌 LANGKAH 9: AKSES WEBSITE                                                ║${NC}"
        echo -e "${CYAN}║     ─────────────────────────────────────────────────────────────────    ║${NC}"
        echo -e "${CYAN}║     Buka browser: http://$IP                                                ║${NC}"
        echo -e "${CYAN}║     atau http://$DOMAIN (jika sudah setting DNS)                            ║${NC}"
        echo -e "${CYAN}║                                                                             ║${NC}"
        echo -e "${CYAN}║  📌 LANGKAH 10: LOG APACHE                                                  ║${NC}"
        echo -e "${CYAN}║     ─────────────────────────────────────────────────────────────────    ║${NC}"
        echo -e "${CYAN}║     $ sudo tail -f /var/log/apache2/access.log                              ║${NC}"
        echo -e "${CYAN}║     $ sudo tail -f /var/log/apache2/error.log                               ║${NC}"
        echo -e "${CYAN}║                                                                             ║${NC}"
        echo -e "${CYAN}╚════════════════════════════════════════════════════════════════════════════╝${NC}"
    fi
    echo ""
    read -p "Tekan Enter untuk kembali ke menu..."
}

# ============================================================
# MENU UTAMA
# ============================================================
while true; do
    clear
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════════════════════╗"
    echo "║            🚀 FAHTECH MULTI-SERVICE INSTALLER v11.0                       ║"
    echo "║        3 DNS SERVER | 3 TAMPILAN | TUTORIAL LENGKAP                        ║"
    echo "╠════════════════════════════════════════════════════════════════════════════╣"
    echo "║                                                                            ║"
    echo "║  🌐 DNS SERVER (3 Pilihan dengan Tutorial Berbeda)                         ║"
    echo "║  ───────────────────────────────────────────────────────────────────────   ║"
    echo "║    1.  🔍 DNS Server 1 - Tutorial DHCP (Lengkap dari awal ke client)       ║"
    echo "║    2.  🔍 DNS Server 2 - Tutorial CRUD (Konfigurasi CRUD Siswa)            ║"
    echo "║    3.  🔍 DNS Server 3 - Tutorial Apache2 (Konfigurasi Web Server)         ║"
    echo "║                                                                            ║"
    echo "║  ⚡ SERVICE LAINNYA (Belum termasuk dalam installer ini)                   ║"
    echo "║  ───────────────────────────────────────────────────────────────────────   ║"
    echo "║    4.  🚪 Exit                                                             ║"
    echo "╚════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    read -p "👉 Pilih menu [1-4]: " menu
    
    case $menu in
        1) dns_dhcp ;;
        2) dns_crud ;;
        3) dns_apache ;;
        4) 
            echo -e "${GREEN}👋 Terima kasih!${NC}"
            exit 0
            ;;
        *) 
            echo -e "${RED}❌ Pilihan salah!${NC}"
            sleep 1
            ;;
    esac
done
