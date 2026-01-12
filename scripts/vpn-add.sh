#!/bin/bash
set -e

SERVER_IP="89.147.109.119"
MIN_FRIEND_IP=10  # IP 2-9 reserved for admin devices

if [ -z "$1" ]; then
    echo "Usage: vpn-add <device-name>"
    echo "Example: vpn-add friend-phone"
    exit 1
fi

NAME=$1
cd /etc/wireguard

# Find next available IP (starting from MIN_FRIEND_IP for friends)
LAST_IP=$(grep -h "AllowedIPs = 10.66.66" wg0.conf | tail -1 | grep -oP '10\.66\.66\.\K[0-9]+')
NEXT_IP=$((LAST_IP + 1))

# Ensure friends get IP >= MIN_FRIEND_IP
if [ "$NEXT_IP" -lt "$MIN_FRIEND_IP" ]; then
    NEXT_IP=$MIN_FRIEND_IP
fi

echo "Creating client: $NAME (IP: 10.66.66.$NEXT_IP)"

# Generate keys
wg genkey | tee ${NAME}_private.key | wg pubkey > ${NAME}_public.key

# Create client config
cat > ${NAME}.conf << CONF
[Interface]
PrivateKey = $(cat ${NAME}_private.key)
Address = 10.66.66.${NEXT_IP}/32
DNS = 10.66.66.1

[Peer]
PublicKey = $(cat server_public.key)
Endpoint = ${SERVER_IP}:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
CONF

# Add peer to server config
cat >> wg0.conf << CONF

# $NAME
[Peer]
PublicKey = $(cat ${NAME}_public.key)
AllowedIPs = 10.66.66.${NEXT_IP}/32
CONF

# Restart WireGuard
systemctl restart wg-quick@wg0

echo ""
echo "=== Done! ==="
echo "Config: /etc/wireguard/${NAME}.conf"
echo ""
echo "=== QR Code ==="
qrencode -t ansiutf8 < ${NAME}.conf
echo ""
echo "=== Or text config ==="
cat ${NAME}.conf
