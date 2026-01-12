#!/usr/bin/env python3
import os
import subprocess
import re
from dotenv import load_dotenv
from telegram import Update
from telegram.ext import Application, CommandHandler, ContextTypes

load_dotenv()

TELEGRAM_TOKEN = os.getenv("TELEGRAM_TOKEN")
ADMIN_ID = int(os.getenv("ADMIN_ID", "0"))
ADMIN_IPS = ["10.66.66.2", "10.66.66.3", "10.66.66.4", "10.66.66.5",
             "10.66.66.6", "10.66.66.7", "10.66.66.8", "10.66.66.9"]

def is_admin_connected() -> bool:
    """Check if any admin IP (10.66.66.2-9) is connected to VPN."""
    try:
        result = subprocess.run(["wg", "show", "wg0", "latest-handshakes"],
                                capture_output=True, text=True)
        if result.returncode != 0:
            return False

        for line in result.stdout.strip().split("\n"):
            if not line:
                continue
            parts = line.split("\t")
            if len(parts) >= 2:
                pubkey, timestamp = parts[0], int(parts[1])
                if timestamp > 0:
                    peer_ip = get_peer_ip(pubkey)
                    if peer_ip in ADMIN_IPS:
                        return True
        return False
    except Exception:
        return False

def get_peer_ip(pubkey: str) -> str:
    """Get IP address for a peer by public key."""
    try:
        with open("/etc/wireguard/wg0.conf", "r") as f:
            content = f.read()

        pattern = rf"\[Peer\][^\[]*PublicKey\s*=\s*{re.escape(pubkey)}[^\[]*AllowedIPs\s*=\s*([\d.]+)"
        match = re.search(pattern, content, re.IGNORECASE)
        if match:
            return match.group(1)
    except Exception:
        pass
    return ""

def auth_required(func):
    """Decorator: check Telegram ID and VPN connection."""
    async def wrapper(update: Update, context: ContextTypes.DEFAULT_TYPE):
        user_id = update.effective_user.id

        if user_id != ADMIN_ID:
            await update.message.reply_text("Access denied.")
            return

        if not is_admin_connected():
            await update.message.reply_text("VPN not connected. Connect to VPN first.")
            return

        return await func(update, context)
    return wrapper

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user_id = update.effective_user.id
    if user_id != ADMIN_ID:
        await update.message.reply_text("Access denied.")
        return

    await update.message.reply_text(
        "VPN Manager Bot\n\n"
        "Commands:\n"
        "/add <name> - Add new client\n"
        "/list - List all clients\n"
        "/remove <name> - Remove client\n"
        "/status - Show connected clients"
    )

@auth_required
async def add_client(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not context.args:
        await update.message.reply_text("Usage: /add <device-name>")
        return

    name = context.args[0]
    if not re.match(r'^[a-zA-Z0-9_-]+$', name):
        await update.message.reply_text("Invalid name. Use only letters, numbers, - and _")
        return

    await update.message.reply_text(f"Creating client: {name}...")

    result = subprocess.run(["/usr/local/bin/vpn-add", name],
                            capture_output=True, text=True)

    if result.returncode == 0:
        config_path = f"/etc/wireguard/{name}.conf"
        try:
            with open(config_path, "r") as f:
                config = f.read()
            await update.message.reply_text(f"Client {name} created!\n\n```\n{config}\n```",
                                            parse_mode="Markdown")
        except Exception:
            await update.message.reply_text(f"Client {name} created! Config: {config_path}")
    else:
        await update.message.reply_text(f"Error: {result.stderr or result.stdout}")

@auth_required
async def list_clients(update: Update, context: ContextTypes.DEFAULT_TYPE):
    try:
        with open("/etc/wireguard/wg0.conf", "r") as f:
            content = f.read()

        clients = []
        pattern = r'#\s*(\S+)\s*\n\[Peer\][^\[]*AllowedIPs\s*=\s*([\d./]+)'
        for match in re.finditer(pattern, content):
            name, ip = match.groups()
            clients.append(f"- {name}: {ip}")

        if clients:
            await update.message.reply_text("Clients:\n" + "\n".join(clients))
        else:
            await update.message.reply_text("No clients found.")
    except Exception as e:
        await update.message.reply_text(f"Error: {e}")

@auth_required
async def remove_client(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not context.args:
        await update.message.reply_text("Usage: /remove <device-name>")
        return

    name = context.args[0]

    if name in ["linux", "iphone"]:
        await update.message.reply_text(f"Cannot remove reserved client: {name}")
        return

    try:
        with open("/etc/wireguard/wg0.conf", "r") as f:
            content = f.read()

        pattern = rf'\n#\s*{re.escape(name)}\s*\n\[Peer\][^\[]*'
        if not re.search(pattern, content):
            await update.message.reply_text(f"Client {name} not found.")
            return

        new_content = re.sub(pattern, '\n', content)

        with open("/etc/wireguard/wg0.conf", "w") as f:
            f.write(new_content)

        for ext in [".conf", "_private.key", "_public.key"]:
            path = f"/etc/wireguard/{name}{ext}"
            if os.path.exists(path):
                os.remove(path)

        subprocess.run(["systemctl", "restart", "wg-quick@wg0"])

        await update.message.reply_text(f"Client {name} removed.")
    except Exception as e:
        await update.message.reply_text(f"Error: {e}")

@auth_required
async def status(update: Update, context: ContextTypes.DEFAULT_TYPE):
    try:
        result = subprocess.run(["wg", "show", "wg0"], capture_output=True, text=True)

        if result.returncode != 0:
            await update.message.reply_text("Error getting status")
            return

        with open("/etc/wireguard/wg0.conf", "r") as f:
            config = f.read()

        pubkey_to_name = {}
        pattern = r'#\s*(\S+)\s*\n\[Peer\][^\[]*PublicKey\s*=\s*(\S+)'
        for match in re.finditer(pattern, config):
            name, pubkey = match.groups()
            pubkey_to_name[pubkey] = name

        lines = result.stdout.split("\n")
        connected = []
        current_peer = None

        for line in lines:
            if line.startswith("peer:"):
                current_peer = line.split(":")[1].strip()
            elif "latest handshake:" in line and current_peer:
                name = pubkey_to_name.get(current_peer, "unknown")
                handshake = line.split(":", 1)[1].strip()
                connected.append(f"- {name}: {handshake}")
                current_peer = None

        if connected:
            await update.message.reply_text("Connected:\n" + "\n".join(connected))
        else:
            await update.message.reply_text("No active connections.")
    except Exception as e:
        await update.message.reply_text(f"Error: {e}")

def main():
    if not TELEGRAM_TOKEN:
        print("Error: TELEGRAM_TOKEN not set")
        return
    if not ADMIN_ID:
        print("Error: ADMIN_ID not set")
        return

    app = Application.builder().token(TELEGRAM_TOKEN).build()

    app.add_handler(CommandHandler("start", start))
    app.add_handler(CommandHandler("add", add_client))
    app.add_handler(CommandHandler("list", list_clients))
    app.add_handler(CommandHandler("remove", remove_client))
    app.add_handler(CommandHandler("status", status))

    print(f"Bot started. Admin ID: {ADMIN_ID}")
    app.run_polling(allowed_updates=Update.ALL_TYPES)

if __name__ == "__main__":
    main()
