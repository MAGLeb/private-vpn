#!/bin/bash
set -e

source /root/setup/.env

apt install -y wireguard qrencode

cd /etc/wireguard
umask 077

wg genkey | tee server_private.key | wg pubkey > server_public.key

cat > wg0.conf << EOF
[Interface]
Address = 10.66.66.1/24
ListenPort = 51820
PrivateKey = $(cat server_private.key)
PostUp = sysctl -w net.ipv4.ip_forward=1
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT
PostUp = iptables -t nat -A POSTROUTING -o \$(ip route | grep default | awk '{print \$5}') -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT
PostDown = iptables -t nat -D POSTROUTING -o \$(ip route | grep default | awk '{print \$5}') -j MASQUERADE
EOF

systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0

echo "WireGuard installed"
