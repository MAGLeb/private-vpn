#!/bin/bash
source /root/.backup-password

BACKUP_FILE="/root/backups/vaultwarden-latest.tar.gz"
ENCRYPTED_FILE="/tmp/vaultwarden-backup.tar.gz.gpg"
mkdir -p /root/backups

# Локальный бэкап
tar -czf $BACKUP_FILE -C /opt/vaultwarden/data .

# Шифруем
gpg --batch --yes --passphrase "$ENCRYPT_PASSWORD" --output $ENCRYPTED_FILE -c $BACKUP_FILE

# Загружаем в облако
rclone delete gdrive:vps-backups/ 2>/dev/null
rclone copy $ENCRYPTED_FILE gdrive:vps-backups/

# Чистим
rm -f $ENCRYPTED_FILE

echo "Done: local + cloud (latest only)"
