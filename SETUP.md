# Setup Guide

## Requirements

- Fresh VPS with Ubuntu 22.04/24.04 (1GB RAM minimum)
- Domain for Vaultwarden (e.g., pass.yourdomain.com)
- SSH access to server
- Telegram account

## Installation

### 1. Prepare

```bash
git clone https://github.com/yourusername/private-server.git
cd private-server
cp .env.example .env
```

### 2. Create Telegram Bot

1. Open @BotFather in Telegram
2. Send `/newbot`
3. Copy the token

### 3. Get Your Telegram ID

1. Open @userinfobot in Telegram
2. Copy your ID

### 4. Edit Config

```bash
nano .env
```

```env
SERVER_IP=your.server.ip
DOMAIN=pass.yourdomain.com
TELEGRAM_TOKEN=123456:ABC-DEF...
ADMIN_ID=123456789
```

### 5. Run Setup

```bash
./setup.sh root@YOUR_SERVER_IP
```

This installs everything automatically.

---

## Post-Setup (Manual Steps)

### 1. Connect to VPN

Save the config shown after setup. Import to WireGuard client.

### 2. Setup AdGuard Home

Via VPN only:
```
http://SERVER_IP:3000
```

- Create admin account
- Filters → DNS Blocklists → Add blocklist
- Recommended: AdGuard DNS filter, OISD

### 3. Add DNS Record

At your domain registrar, create A record:
```
pass.yourdomain.com → SERVER_IP
```

### 4. Setup Vaultwarden

```
https://pass.yourdomain.com
```

- Create your account
- Disable signups after: Admin panel → `SIGNUPS_ALLOWED=false`

### 5. Setup Cloud Backups (Optional)

```bash
ssh root@SERVER

# Install rclone
apt install rclone
rclone config
# Choose: n → gdrive → Google Drive → follow prompts

# Create backup password
openssl rand -base64 32 > /root/.backup-password

# Test
backup-vaultwarden
```

### 6. Save Secrets

Store in Vaultwarden for disaster recovery:
- `.env` contents
- Backup password (`/root/.backup-password`)
- VPN configs

---

## IP Allocation

| Range | Purpose |
|-------|---------|
| 10.66.66.1 | Server (DNS) |
| 10.66.66.2-9 | Your devices |
| 10.66.66.10+ | Friends |

---

## SSH Commands

```bash
# Add VPN client
ssh root@SERVER "vpn-add phone"

# Check VPN status
ssh root@SERVER "wg show"

# Bot logs
ssh root@SERVER "journalctl -u vpn-bot -f"

# Restart bot
ssh root@SERVER "systemctl restart vpn-bot"

# Manual backup
ssh root@SERVER "backup-vaultwarden"
```

---

## Updating

```bash
# Update everything
./setup.sh root@SERVER

# Update Docker only
ssh root@SERVER "cd /root/setup/docker && docker compose pull && docker compose up -d"
```

---

## Disaster Recovery

### Restore Vaultwarden

```bash
# 1. Download backup
rclone copy gdrive:vps-backups/vaultwarden-backup.tar.gz.gpg ./

# 2. Decrypt
gpg -d vaultwarden-backup.tar.gz.gpg > vaultwarden.tar.gz

# 3. Extract
tar -xzf vaultwarden.tar.gz

# 4. Copy to new server (before setup)
scp -r ./data root@NEW_SERVER:/root/setup/docker/

# 5. Run setup
./setup.sh root@NEW_SERVER
```

### Migration Checklist

- [ ] Clone repo, edit `.env`
- [ ] Run `./setup.sh`
- [ ] Restore Vaultwarden data
- [ ] Setup rclone
- [ ] Update DNS record
- [ ] Test all services

---

## Troubleshooting

### Bot not responding

```bash
ssh root@SERVER "systemctl status vpn-bot"
ssh root@SERVER "journalctl -u vpn-bot -n 50"
```

### VPN not connecting

```bash
ssh root@SERVER "wg show"
ssh root@SERVER "systemctl status wg-quick@wg0"
```

### AdGuard not blocking

- Check DNS = 10.66.66.1 in VPN config
- Verify running: `docker ps`

---

## Security

- Bot requires VPN + Telegram ID (double auth)
- AdGuard admin only via VPN
- Vaultwarden uses HTTPS (Caddy)
- UFW firewall enabled
