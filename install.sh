#!/usr/bin/env bash
# =================================================
# S-onion ULTIMATE INSTALLER
# WSL / systemd / non-systemd uyumlu
# Root algılayan, hatasız tek parça kurulum
# =================================================

set -e

clear
echo "=========================================="
echo "   S-onion - Ultimate One-Click Installer"
echo "=========================================="
echo

# -------- ROOT CHECK --------
if [ "$EUID" -ne 0 ]; then
  echo "[!] Root gerekli. sudo ile tekrar çalıştır."
  exit 1
fi

# -------- ENV DETECT --------
if command -v systemctl >/dev/null 2>&1 && systemctl list-units >/dev/null 2>&1; then
  INIT="systemd"
else
  INIT="service"
fi

echo "[+] Init sistemi: $INIT"

# -------- UPDATE & INSTALL --------
echo "[+] Paketler kuruluyor..."
apt update -y
apt install -y tor nginx ufw curl

# -------- TOR CONFIG --------
echo "[+] Tor yapılandırılıyor..."
mkdir -p /var/lib/tor/hidden_service
chmod 700 /var/lib/tor/hidden_service
chown -R debian-tor:debian-tor /var/lib/tor

cat > /etc/tor/torrc <<'EOF'
HiddenServiceDir /var/lib/tor/hidden_service/
HiddenServicePort 80 127.0.0.1:80
Log notice file /var/log/tor/notices.log
EOF

# -------- NGINX CONFIG --------
echo "[+] Nginx yapılandırılıyor..."
rm -f /etc/nginx/sites-enabled/default

cat > /etc/nginx/sites-available/s-onion <<'EOF'
server {
    listen 127.0.0.1:80 default_server;
    server_name localhost;

    location / {
        root /var/www/s-onion;
        index index.html;
    }
}
EOF

ln -sf /etc/nginx/sites-available/s-onion /etc/nginx/sites-enabled/s-onion

mkdir -p /var/www/s-onion
cat > /var/www/s-onion/index.html <<'EOF'
<!DOCTYPE html>
<html>
<head>
<title>S-onion Active</title>
<style>
body { background:#000;color:#0f0;font-family:monospace;text-align:center;padding-top:20%; }
</style>
</head>
<body>
<h1>S-onion is ONLINE</h1>
<p>Tor Hidden Service Active</p>
</body>
</html>
EOF

# -------- FIREWALL --------
echo "[+] UFW ayarlanıyor..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 9050
ufw allow 80
ufw --force enable || true

# -------- SERVICE START --------
echo "[+] Servisler başlatılıyor..."
if [ "$INIT" = "systemd" ]; then
  systemctl restart tor || true
  systemctl restart nginx || true
else
  service tor restart || true
  service nginx restart || true
fi

sleep 3

# -------- ONION ADDRESS --------
echo
echo "=========================================="
if [ -f /var/lib/tor/hidden_service/hostname ]; then
  echo "[✓] ONION ADRESİN:"
  cat /var/lib/tor/hidden_service/hostname
else
  echo "[!] Onion adresi üretilemedi. Tor loglarını kontrol et."
fi
echo "=========================================="
echo
echo "[✓] Kurulum tamamlandı."
