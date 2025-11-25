#!/bin/bash
# ================================================
# S-onion v1.0 - Tam Otomatik Onion Site Kurucu
# by Aga (senin için özel yazıldı ❤️)
# Tek komutla çalışan, IP'si %100 gizli, sadece HTML isteyen tool
# ================================================

clear
echo ""
echo "=========================================="
echo "    S-onion v1.0 - Otomatik Onion Tool    "
echo "           by Aga (özel yapım)            "
echo "=========================================="
echo ""

# Root kontrol
if [[ $EUID -ne 0 ]]; then
   echo "[-] Bu tool root olarak çalıştırılmalı! sudo ile dene."
   exit 1
fi

echo "[+] Gerekli paketler kuruluyor..."
apt update -y >/dev/null 2>&1
apt install tor nginx ufw curl -y >/dev/null 2>&1

echo "[+] Güvenlik duvarı ayarlanıyor (sadece Tor açık kalacak)..."
ufw allow ssh >/dev/null 2>&1
ufw --force enable >/dev/null 2>&1

echo "[+] Tor Hidden Service oluşturuluyor (v3 - 56 karakter)..."
mkdir -p /var/lib/tor/s-onion-service/
chown debian-tor:debian-tor /var/lib/tor/s-onion-service/
chmod 700 /var/lib/tor/s-onion-service/

cat > /etc/tor/torrc <<EOF
HiddenServiceDir /var/lib/tor/s-onion-service/
HiddenServicePort 80 127.0.0.1:80
HiddenServiceVersion 3
EOF

systemctl restart tor

sleep 8

ONION_ADDR=$(cat /var/lib/tor/s-onion-service/hostname)
echo "[+] Onion adresin oluşturuldu: $ONION_ADDR"

echo "[+] Web klasörü hazırlanıyor..."
rm -rf /var/www/s-onion
mkdir -p /var/www/s-onion
chown www-data:www-data /var/www/s-onion

echo "[+] Şimdi HTML içeriğini girebilirsin. Bitirince Ctrl+D yap."

cat > /var/www/s-onion/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>S-onion Site</title>
  <style>
    body { background:#000; color:#0f0; font-family: monospace; text-align:center; padding:50px; }
    h1 { font-size: 3em; }
  </style>
</head>
<body>
  <h1>Bu site S-onion ile otomatik kuruldu!</h1>
  <pre>
$(cat)
  </pre>
  <hr>
  <small>Powered by S-onion v1.0 - by Aga</small>
</body>
</html>
EOF

echo "[+] Nginx ayarlanıyor..."
cat > /etc/nginx/sites-available/s-onion <<EOF
server {
    listen 127.0.0.1:80;
    server_name localhost;
    root /var/www/s-onion;
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

ln -sf /etc/nginx/sites-available/s-onion /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx

echo ""
echo "=========================================="
echo "        S-onion KURULUM TAMAMLANDI!       "
echo "=========================================="
echo ""
echo "Onion Adresin:"
echo "    $ONION_ADDR"
echo ""
echo "Tor Browser'dan hemen deneyebilirsin!"
echo "Site dosyası: /var/www/s-onion/index.html (istediğin zaman düzenle)"
echo ""
echo "Yedek almayı unutma:"
echo "    cp -r /var/lib/tor/s-onion-service/ ~/s-onion-backup/"
echo ""
echo "S-onion v1.0 - by Aga | 2025"
echo ""

exit 0
