#!/bin/bash
set -e

BACKUP_DIR="/root/backups"
BACKUP_FILE="$BACKUP_DIR/vaultwarden-latest.tar.gz"

mkdir -p $BACKUP_DIR

echo "Creating backup..."
tar -czf $BACKUP_FILE -C /root/setup/docker/data .

if [ -f /root/.backup-password ] && command -v rclone &> /dev/null; then
    source /root/.backup-password
    ENCRYPTED="/tmp/vaultwarden-backup.tar.gz.gpg"

    gpg --batch --yes --passphrase "$ENCRYPT_PASSWORD" --output $ENCRYPTED -c $BACKUP_FILE
    rclone delete gdrive:vps-backups/ 2>/dev/null || true
    rclone copy $ENCRYPTED gdrive:vps-backups/
    rm -f $ENCRYPTED

    echo "Backup uploaded to Google Drive"
fi

echo "Local backup: $BACKUP_FILE"
