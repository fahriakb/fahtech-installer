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
echo "║   ███████╗ █████╗ ██╗  ██╗████████╗███████╗ ██████╗██╗  ██╗                 ║"
echo "║   ██╔════╝██╔══██╗██║  ██║╚══██╔══╝██╔════╝██╔════╝██║  ██║                 ║"
echo "║   █████╗  ███████║███████║   ██║   █████╗  ██║     ███████║                 ║"
echo "║   ██╔══╝  ██╔══██║██╔══██║   ██║   ██╔══╝  ██║     ██╔══██║                 ║"
echo "║   ██║     ██║  ██║██║  ██║   ██║   ███████╗╚██████╗██║  ██║                 ║"
echo "║   ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝ ╚═════╝╚═╝  ╚═╝                 ║"
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
        
        echo -e "\n${GREEN}✅ DNS SERVER 1 BERHASIL! Domain: $DOMAIN | IP: $IP${NC}"
        
        echo -e "\n${CYAN}════════════════════════════════════════════════════════════════════${NC}"
        echo -e "${CYAN}           📖 TUTORIAL DHCP SERVER LENGKAP${NC}"
        echo -e "${CYAN}════════════════════════════════════════════════════════════════════${NC}"
        echo -e ""
        echo -e "📌 LANGKAH 1: INSTALL DHCP SERVER"
        echo -e "   sudo apt update"
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
        echo -e ""
        echo -e "📌 LANGKAH 6: LIHAT CLIENT"
        echo -e "   sudo cat /var/lib/dhcp/dhcpd.leases"
        echo -e ""
        echo -e "📌 LANGKAH 7: TEST DARI CLIENT"
        echo -e "   Windows: ipconfig /renew"
        echo -e "   Linux: sudo dhclient $IFACE"
        echo -e "${CYAN}════════════════════════════════════════════════════════════════════${NC}"
    fi
    echo ""
    read -p "Tekan Enter untuk kembali..."
}

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
        
        echo -e "\n${GREEN}✅ DNS SERVER 2 BERHASIL! Domain: $DOMAIN | IP: $IP${NC}"
        
        echo -e "\n${CYAN}════════════════════════════════════════════════════════════════════${NC}"
        echo -e "${CYAN}           📖 TUTORIAL CRUD SISWA LENGKAP${NC}"
        echo -e "${CYAN}════════════════════════════════════════════════════════════════════${NC}"
        echo -e ""
        echo -e "📌 LANGKAH 1: INSTALL APACHE2 & PHP"
        echo -e "   sudo apt update"
        echo -e "   sudo apt install apache2 php libapache2-mod-php php-sqlite3 -y"
        echo -e ""
        echo -e "📌 LANGKAH 2: BUAT FOLDER CRUD"
        echo -e "   sudo mkdir -p /var/www/html/crud"
        echo -e ""
        echo -e "📌 LANGKAH 3: BUAT FILE INDEX.PHP"
        echo -e "   sudo nano /var/www/html/crud/index.php"
        echo -e ""
        echo -e "📌 LANGKAH 4: STRUKTUR DATABASE (SQLite)"
        echo -e "   CREATE TABLE siswa ("
        echo -e "       id INTEGER PRIMARY KEY AUTOINCREMENT,"
        echo -e "       nama TEXT NOT NULL,"
        echo -e "       rombel TEXT NOT NULL,"
        echo -e "       nis TEXT NOT NULL UNIQUE"
        echo -e "   );"
        echo -e ""
        echo -e "📌 LANGKAH 5: FITUR CRUD"
        echo -e "   ➕ CREATE: INSERT INTO siswa (nama, rombel, nis) VALUES (...)"
        echo -e "   📖 READ: SELECT * FROM siswa ORDER BY id DESC"
        echo -e "   ✏️ UPDATE: UPDATE siswa SET nama='...' WHERE id=..."
        echo -e "   🗑️ DELETE: DELETE FROM siswa WHERE id=..."
        echo -e "   🔍 SEARCH: SELECT * FROM siswa WHERE nama LIKE '%...%'"
        echo -e ""
        echo -e "📌 LANGKAH 6: SET PERMISSION"
        echo -e "   sudo chown -R www-data:www-data /var/www/html/crud"
        echo -e ""
        echo -e "📌 LANGKAH 7: RESTART APACHE"
        echo -e "   sudo systemctl restart apache2"
        echo -e ""
        echo -e "📌 LANGKAH 8: AKSES CRUD"
        echo -e "   Buka browser: http://$IP/crud/"
        echo -e "${CYAN}════════════════════════════════════════════════════════════════════${NC}"
    fi
    echo ""
    read -p "Tekan Enter untuk kembali..."
}

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
        
        echo -e "\n${GREEN}✅ DNS SERVER 3 BERHASIL! Domain: $DOMAIN | IP: $IP${NC}"
        
        echo -e "\n${CYAN}════════════════════════════════════════════════════════════════════${NC}"
        echo -e "${CYAN}           📖 TUTORIAL APACHE2 WEB SERVER LENGKAP${NC}"
        echo -e "${CYAN}════════════════════════════════════════════════════════════════════${NC}"
        echo -e ""
        echo -e "📌 LANGKAH 1: INSTALL APACHE2"
        echo -e "   sudo apt update"
        echo -e "   sudo apt install apache2 -y"
        echo -e ""
        echo -e "📌 LANGKAH 2: CEK STATUS APACHE2"
        echo -e "   sudo systemctl status apache2"
        echo -e "   sudo systemctl enable apache2"
        echo -e ""
        echo -e "📌 LANGKAH 3: KONFIGURASI VIRTUAL HOST"
        echo -e "   sudo nano /etc/apache2/sites-available/$DOMAIN.conf"
        echo -e ""
        echo -e "   <VirtualHost *:80>"
        echo -e "       ServerName $DOMAIN"
        echo -e "       ServerAlias www.$DOMAIN"
        echo -e "       DocumentRoot /var/www/html/$DOMAIN"
        echo -e "   </VirtualHost>"
        echo -e ""
        echo -e "📌 LANGKAH 4: AKTIFKAN SITE"
        echo -e "   sudo a2ensite $DOMAIN.conf"
        echo -e "   sudo a2dissite 000-default.conf"
        echo -e "   sudo systemctl reload apache2"
        echo -e ""
        echo -e "📌 LANGKAH 5: BUAT FILE INDEX.HTML"
        echo -e "   sudo mkdir -p /var/www/html/$DOMAIN"
        echo -e "   sudo nano /var/www/html/$DOMAIN/index.html"
        echo -e ""
        echo -e "📌 LANGKAH 6: INSTALL PHP (Opsional)"
        echo -e "   sudo apt install php libapache2-mod-php -y"
        echo -e "   sudo systemctl restart apache2"
        echo -e ""
        echo -e "📌 LANGKAH 7: TEST PHP"
        echo -e "   echo '<?php phpinfo(); ?>' | sudo tee /var/www/html/$DOMAIN/info.php"
        echo -e ""
        echo -e "📌 LANGKAH 8: AKSES WEBSITE"
        echo -e "   Buka browser: http://$IP"
        echo -e "   atau http://$DOMAIN (jika sudah setting DNS)"
        echo -e "${CYAN}════════════════════════════════════════════════════════════════════${NC}"
    fi
    echo ""
    read -p "Tekan Enter untuk kembali..."
}

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
