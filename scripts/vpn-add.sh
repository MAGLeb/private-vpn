#!/bin/bash
set -e

source /root/setup/.env

if [ -z "$1" ]; then
    echo "Usage: vpn-add <device-name>"
    exit 1
fi

NAME=$1
cd /etc/wireguard

LAST_IP=$(grep -h "AllowedIPs = 10.66.66" wg0.conf | tail -1 | grep -oP '10\.66\.66\.\K[0-9]+')
NEXT_IP=$((LAST_IP + 1))

wg genkey | tee ${NAME}_private.key | wg pubkey > ${NAME}_public.key

cat > ${NAME}.conf << EOF
[Interface]
PrivateKey = $(cat ${NAME}_private.key)
Address = 10.66.66.${NEXT_IP}/32
DNS = 10.66.66.1

[Peer]
PublicKey = $(cat server_public.key)
Endpoint = ${SERVER_IP}:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

cat >> wg0.conf << EOF

# $NAME
[Peer]
PublicKey = $(cat ${NAME}_public.key)
AllowedIPs = 10.66.66.${NEXT_IP}/32
EOF

systemctl restart wg-quick@wg0

echo ""
echo "=== Config for $NAME ==="
cat ${NAME}.conf
echo ""
echo "=== QR Code ==="
qrencode -t ansiutf8 < ${NAME}.conf
