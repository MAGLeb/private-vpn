# Setup Guide

## Requirements

- VPS: Ubuntu 22.04/24.04, 1GB RAM
- Domain для Vaultwarden
- Telegram аккаунт

## Installation

```bash
git clone https://github.com/yourusername/private-server.git
cd private-server
cp .env.example .env
nano .env  # заполнить конфиг
./setup.sh root@SERVER_IP
```

**Telegram Bot:** @BotFather → `/newbot` → скопировать токен
**Telegram ID:** @userinfobot → скопировать ID

## Post-Setup

### AdGuard Home (через VPN)

```
http://SERVER_IP:3000
```
Создать аккаунт → Filters → DNS Blocklists → AdGuard DNS filter, OISD

### Vaultwarden

1. DNS A-запись: `pass.yourdomain.com → SERVER_IP`
2. Открыть `https://pass.yourdomain.com`
3. Создать аккаунт → Admin panel → `SIGNUPS_ALLOWED=false`

### Cloud Backups (опционально)

```bash
ssh root@SERVER
apt install rclone && rclone config  # выбрать Google Drive
openssl rand -base64 32 > /root/.backup-password
backup-vaultwarden  # тест
```

## IP Allocation

| Range | Purpose |
|-------|---------|
| 10.66.66.1 | Server (DNS) |
| 10.66.66.2-9 | Your devices |
| 10.66.66.10+ | Friends |

## Commands

```bash
vpn-add phone              # добавить VPN клиент
wg show                    # статус VPN
journalctl -u vpn-bot -f   # логи бота
systemctl restart vpn-bot  # перезапуск бота
backup-vaultwarden         # бэкап
```

## Update

```bash
./setup.sh root@SERVER                    # полный апдейт
# или только Docker:
ssh root@SERVER "cd /root/setup/docker && docker compose pull && docker compose up -d"
```

## Disaster Recovery

```bash
rclone copy gdrive:vps-backups/vaultwarden-backup.tar.gz.gpg ./
gpg -d vaultwarden-backup.tar.gz.gpg > vaultwarden.tar.gz
tar -xzf vaultwarden.tar.gz
scp -r ./data root@NEW_SERVER:/root/setup/docker/
./setup.sh root@NEW_SERVER
```

## Troubleshooting

| Problem | Check |
|---------|-------|
| Bot не отвечает | `systemctl status vpn-bot` |
| VPN не подключается | `wg show`, `systemctl status wg-quick@wg0` |
| AdGuard не блокирует | DNS = 10.66.66.1, `docker ps` |
