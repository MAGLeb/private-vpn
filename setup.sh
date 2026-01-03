#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "Usage: ./setup.sh root@SERVER_IP"
    exit 1
fi

SERVER=$1

if [ ! -f .env ]; then
    echo "Error: .env file not found"
    echo "Run: cp .env.example .env && nano .env"
    exit 1
fi

source .env

if [ "$SERVER_IP" = "your.server.ip" ]; then
    echo "Error: Edit .env and set SERVER_IP"
    exit 1
fi

echo "=== Uploading files to server ==="
scp -r scripts docker .env $SERVER:/root/setup/

echo "=== Running setup on server ==="
ssh $SERVER "cd /root/setup && chmod +x scripts/*.sh && ./scripts/install-all.sh"

echo ""
echo "=== Setup complete! ==="
echo ""
echo "Next steps:"
echo "1. Add DNS record: $DOMAIN -> $SERVER_IP"
echo "2. Connect to VPN and open http://$SERVER_IP:3000 to setup AdGuard"
echo "3. Open https://$DOMAIN to create Vaultwarden account"
echo "4. Run: ssh $SERVER 'vpn-add phone' to add more devices"
