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

if [ "$TELEGRAM_TOKEN" = "your_bot_token" ]; then
    echo "Error: Edit .env and set TELEGRAM_TOKEN (create bot via @BotFather)"
    exit 1
fi

echo "=== Uploading files to server ==="
ssh $SERVER "mkdir -p /root/setup"
scp -r scripts bot docker .env $SERVER:/root/setup/

echo "=== Running setup on server ==="
ssh $SERVER "cd /root/setup && chmod +x scripts/*.sh && ./scripts/install-all.sh"

echo ""
echo "=========================================="
echo "            SETUP COMPLETE!"
echo "=========================================="
echo ""
echo "Next steps:"
echo ""
echo "1. SAVE VPN CONFIG (shown above) - you'll need it to connect"
echo ""
echo "2. Connect to VPN using the config"
echo ""
echo "3. Setup AdGuard Home:"
echo "   http://$SERVER_IP:3000 (via VPN only)"
echo ""
echo "4. Add DNS record for Vaultwarden:"
echo "   $DOMAIN -> $SERVER_IP"
echo ""
echo "5. Create Vaultwarden account:"
echo "   https://$DOMAIN"
echo ""
echo "6. Test Telegram bot:"
echo "   Send /start to your bot"
echo ""
echo "Commands:"
echo "  vpn-add <name>     - Add VPN client (via bot or SSH)"
echo "  backup-vaultwarden - Manual backup"
echo ""
