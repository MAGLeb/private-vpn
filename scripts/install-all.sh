#!/bin/bash
set -e

source /root/setup/.env

echo "=== Updating system ==="
apt update && apt upgrade -y

echo "=== Installing WireGuard ==="
./scripts/install-wireguard.sh

echo "=== Installing Docker ==="
./scripts/install-docker.sh

echo "=== Disabling systemd-resolved (for AdGuard DNS) ==="
systemctl disable systemd-resolved
systemctl stop systemd-resolved
rm -f /etc/resolv.conf
echo "nameserver 1.1.1.1" > /etc/resolv.conf

echo "=== Starting services ==="
cd /root/setup/docker
export DOMAIN
envsubst < Caddyfile > Caddyfile.tmp && mv Caddyfile.tmp Caddyfile
docker compose up -d

echo "=== Installing utility scripts ==="
cp /root/setup/scripts/vpn-add.sh /usr/local/bin/vpn-add
cp /root/setup/scripts/backup-vaultwarden.sh /usr/local/bin/backup-vaultwarden
chmod +x /usr/local/bin/vpn-add /usr/local/bin/backup-vaultwarden

echo "=== Configuring firewall ==="
ufw allow 22/tcp
ufw allow 51820/udp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

echo "=== Creating first VPN client ==="
cd /etc/wireguard
vpn-add laptop

echo "=== Done! ==="
