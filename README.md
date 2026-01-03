# Private Server Stack

Personal privacy-focused server with VPN, ad blocking, and password management.

## What's Included

| Service | Purpose |
|---------|---------|
| **WireGuard** | VPN with Iceland IP |
| **AdGuard Home** | DNS-based ad blocking |
| **Vaultwarden** | Self-hosted Bitwarden |
| **Caddy** | Automatic HTTPS |

## Requirements

- VPS with Ubuntu 22.04/24.04 (1GB RAM minimum)
- Domain for Vaultwarden (e.g., pass.yourdomain.com)
- SSH access to server

## Quick Start

```bash
# 1. Clone this repo
git clone https://github.com/yourusername/private-server.git
cd private-server

# 2. Copy and edit config
cp .env.example .env
nano .env

# 3. Run setup
./setup.sh root@YOUR_SERVER_IP
```

## Architecture

```
┌─────────────────────────────────────────────┐
│              Your VPS                       │
│                                             │
│  ┌─────────────┐  ┌─────────────────────┐  │
│  │  WireGuard  │  │  Docker             │  │
│  │  :51820/udp │  │  ┌───────────────┐  │  │
│  └──────┬──────┘  │  │  AdGuard Home │  │  │
│         │         │  │  :53, :3000   │  │  │
│         ▼         │  └───────────────┘  │  │
│   VPN Clients     │  ┌───────────────┐  │  │
│   DNS → AdGuard   │  │  Vaultwarden  │  │  │
│                   │  │  + Caddy      │  │  │
│                   │  │  :80, :443    │  │  │
│                   │  └───────────────┘  │  │
│                   └─────────────────────┘  │
└─────────────────────────────────────────────┘
```

## Configuration

Edit `.env` before running setup:

```env
DOMAIN=pass.yourdomain.com
SERVER_IP=your.server.ip
```

## Post-Setup

1. Add DNS record: `pass.yourdomain.com` → `SERVER_IP`
2. Open AdGuard: `http://SERVER_IP:3000` (via VPN)
3. Open Vaultwarden: `https://pass.yourdomain.com`

## Commands

```bash
# Add VPN client
ssh root@SERVER "vpn-add device-name"

# Manual backup
ssh root@SERVER "backup-vaultwarden"

# Check VPN status
ssh root@SERVER "wg show"
```

## Backup

- Vaultwarden data: Daily to Google Drive (encrypted)
- Server snapshot: Manual via hosting panel

## Cost

~€7-8/month (1984.is, Hetzner, etc.)

## License

MIT
