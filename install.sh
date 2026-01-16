rm -f bash.sh install.sh && cat > install.sh <<'EOF'
#!/bin/bash
set -e

clear
echo "=========================================="
echo "    S-onion CLEAN INSTALL"
echo "=========================================="

[ "$EUID" -ne 0 ] && echo "root gerekli" && exit 1

apt update -y
apt install -y tor nginx ufw curl

ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw --force enable

mkdir -p /var/lib/tor/onion-service
chown debian-tor:debian-tor /var/lib/tor/onion-service
chmod 700 /var/lib/tor/onion-service

cat >> /etc/tor/torrc <<EOT
HiddenServiceDir /var/lib/tor/onion-service
HiddenServiceVersion 3
HiddenServicePort 80 127.0.0.1:8080
EOT

systemctl restart tor
sleep 10

ONION=$(cat /var/lib/tor/onion-service/hostname)

mkdir -p /var/www/onion
echo "<h1>$ONION</h1>" > /var/www/onion/index.html

cat > /etc/nginx/sites-available/onion <<EOT
server {
    listen 127.0.0.1:8080;
    root /var/www/onion;
    index index.html;
}
EOT

ln -sf /etc/nginx/sites-available/onion /etc/nginx/sites-enabled/onion
rm -f /etc/nginx/sites-enabled/default

nginx -t
systemctl restart nginx

echo ""
echo "ONION ADRESI:"
echo "$ONION"
EOF
