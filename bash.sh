#!/bin/bash
# =================================================
# S-onion v2.4 - Ubuntu 24.04 Noble Özel Sürüm
# Tam otomatik .onion site kurucu (2025 güncel)
# by SOYTARI
# =================================================

clear
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║     S-onion v2.4 - Ubuntu 24.04 Edition   
echo "║                      
echo "╚══════════════════════════════════════════╝"
echo ""

if [[ $EUID -ne 0 ]]; then
   echo "[-] Root lazım! sudo ile çalıştır."
   exit 1
fi

echo "[+] Sistem güncelleniyor ve paketler kuruluyor (24.04 uyumlu)..."
apt update -y > /dev/null 2>&1
apt upgrade -y > /dev/null 2>&1
apt install -y tor nginx ufw curl nano > /dev/null 2>&1

echo "[+] Güvenlik duvarı kapanıyor (sadece Tor’a güveniyoruz)"
ufw reset > /dev/null 2>&1
ufw allow ssh > /dev/null 2>&1
ufw --force enable > /dev/null 2>&1

echo "[+] Tor Hidden Service (v3) oluşturuluyor..."
mkdir -p /var/lib/tor/onion-service/
chown debian-tor:debian-tor /var/lib/tor/onion-service/
chmod 700 /var/lib/tor/onion-service/

cat > /etc/tor/torrc <<EOF
SocksPort 0
ControlPort 9051
CookieAuthentication 1

HiddenServiceDir /var/lib/tor/onion-service/
HiddenServiceVersion 3
HiddenServicePort 80 127.0.0.1:80
EOF

systemctl restart tor
sleep 10

ONION=$(cat /var/lib/tor/onion-service/hostname 2>/dev/null || echo "oluşuyor...")
while [[ $ONION == "oluşuyor..." ]]; do
    sleep 2
    ONION=$(cat /var/lib/tor/onion-service/hostname 2>/dev/null || echo "oluşuyor...")
done

echo "[+] Onion adresin hazır: $ONION"

echo "[+] Web klasörü hazırlanıyor..."
rm -rf /var/www/onion
mkdir -p /var/www/onion
chown www-data:www-data /var/www/onion

echo ""
echo "[+] Şimdi HTML içeriğini yaz. Bitirince Ctrl+D bas aga!"
echo "    (Boş bırakırsan default şık sayfa gelir)"

cat > /var/www/onion/index.html <<'DEFAULT'
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>S-onion Site</title>
  <style>
    body {background:#000;color:#0f0;font-family:monospace;text-align:center;padding:50px;}
    h1 {font-size:4em;text-shadow:0 0 10px #0f0;}
    .blink {animation:blink 1s infinite;} @keyframes blink{50%{opacity:0;}}
  </style>
</head>
<body>
  <h1>█ S-ONION ÇALIŞIYOR █</h1>
  <p class="blink">Site başarıyla kuruldu!</p>
  <hr>
  <small>S-onion v2.4 by Aga - 2025</small>
</body>
</html>
DEFAULT

cat > /dev/stdin <<EOF > /var/www/onion/index.html
$(cat)
EOF

echo "[+] Nginx yapılandırılıyor (24.04 uyumlu)..."
cat > /etc/nginx/sites-available/onion <<EOF
server {
    listen 127.0.0.1:80;
    server_name localhost;
    root /var/www/onion;
    index index.html index.htm;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

ln -sf /etc/nginx/sites-available/onion /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║           KURULUM TAMAM AĞA!            ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "   Onion Adresin → $ONION"
echo ""
echo "   Tor Browser’dan hemen gir: $ONION"
echo ""
echo "   Dosyaları düzenlemek istersen:"
echo "   nano /var/www/onion/index.html"
echo ""
echo "   Anahtar yedeğini mutlaka al!"
echo "   cp -r /var/lib/tor/onion-service ~/onion-backup/"
echo ""
echo "   S-onion v2.4 - Ubuntu 24.04 Noble | by Aga"
echo ""

exit 0
