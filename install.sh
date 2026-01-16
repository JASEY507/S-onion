#!/bin/bash
set -euo pipefail

[[ $EUID -ne 0 ]] && exit 1

apt update -y
apt install -y tor nginx ufw apparmor apparmor-utils curl

useradd -r -s /usr/sbin/nologin -d /var/www/onion onionweb || true

mkdir -p /var/www/onion
chown -R onionweb:onionweb /var/www/onion
chmod 750 /var/www/onion

mkdir -p /var/lib/tor/onion-service
chown debian-tor:debian-tor /var/lib/tor/onion-service
chmod 700 /var/lib/tor/onion-service

cp files/torrc.add /etc/tor/torrc.add
grep -q "S-onion" /etc/tor/torrc || cat /etc/tor/torrc.add >> /etc/tor/torrc

cp files/nginx.conf /etc/nginx/nginx.conf
cp files/onion.site /etc/nginx/sites-available/onion
ln -sf /etc/nginx/sites-available/onion /etc/nginx/sites-enabled/onion
rm -f /etc/nginx/sites-enabled/default

cp files/index.html /var/www/onion/index.html
chown onionweb:onionweb /var/www/onion/index.html

mkdir -p /etc/systemd/system/nginx.service.d
mkdir -p /etc/systemd/system/tor.service.d

cp files/nginx.hardening /etc/systemd/system/nginx.service.d/hardening.conf
cp files/tor.hardening /etc/systemd/system/tor.service.d/hardening.conf

cp files/ufw.rules /tmp/ufw.rules
ufw --force reset
bash /tmp/ufw.rules

systemctl daemon-reexec
systemctl daemon-reload

systemctl enable tor nginx ufw
systemctl restart tor
sleep 12
systemctl restart nginx

cat /var/lib/tor/onion-service/hostname
