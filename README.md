# Private Server Stack

Personal privacy-focused server with VPN, ad blocking, password management, and Telegram bot.

## Services

| Service | Purpose |
|---------|---------|
| **WireGuard** | VPN |
| **AdGuard Home** | Ad blocking (DNS) |
| **Vaultwarden** | Password manager |
| **Telegram Bot** | Remote VPN management |

## Architecture

```
┌─────────────────────────────────────────────┐
│                   VPS                        │
│                                              │
│  WireGuard (:51820)     Docker               │
│       │                 ├─ AdGuard (:53)     │
│       ▼                 ├─ Vaultwarden       │
│  VPN Clients ──DNS────► └─ Caddy (HTTPS)     │
│  (10.66.66.x)                                │
│                                              │
│  Telegram Bot (VPN management)               │
└──────────────────────────────────────────────┘
```

## Quick Start

```bash
git clone https://github.com/yourusername/private-server.git
cd private-server
cp .env.example .env
nano .env
./setup.sh root@YOUR_SERVER_IP
```

See [SETUP.md](SETUP.md) for detailed instructions.

## Bot Commands

| Command | Description |
|---------|-------------|
| `/add <name>` | Add VPN client |
| `/list` | List clients |
| `/remove <name>` | Remove client |
| `/status` | Who's connected |

## Files

```
├── setup.sh          # Main install script
├── .env.example      # Config template
├── scripts/          # Server scripts
├── bot/              # Telegram bot
└── docker/           # Docker services
```

## License

MIT
