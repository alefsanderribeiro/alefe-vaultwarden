#!/bin/bash
set -e
BACKUP_DIR="/home/alefsander/Documentos/Mega/alefe-vaultwarden-backup"
DATA_DIR="/home/alefsander/vaultwarden/vw-data"
TIMESTAMP=$(date +%Y-%m-%d_%H%M)
TEMP_DIR="/tmp/vw-backup-$TIMESTAMP"

mkdir -p "$TEMP_DIR" "$BACKUP_DIR"

# Safe SQLite backup using .backup
sqlite3 "$DATA_DIR/db.sqlite3" ".backup $TEMP_DIR/db.sqlite3"

# Verify integrity
INTEGRITY=$(sqlite3 "$TEMP_DIR/db.sqlite3" "PRAGMA integrity_check;")
if [ "$INTEGRITY" != "ok" ]; then
    echo "ERROR: Integrity check FAILED: $INTEGRITY" >&2
    exit 2
fi

# Copy other data
cp -r "$DATA_DIR/attachments" "$TEMP_DIR/" 2>/dev/null || true
cp -r "$DATA_DIR/sends" "$TEMP_DIR/" 2>/dev/null || true
cp "$DATA_DIR/config.json" "$TEMP_DIR/" 2>/dev/null || true
cp "$DATA_DIR/rsa_key" "$TEMP_DIR/" 2>/dev/null || true
cp "$DATA_DIR/rsa_key.pub" "$TEMP_DIR/" 2>/dev/null || true

# Create tar.gz (exclude .env)
cd "$TEMP_DIR"
tar -czf "$BACKUP_DIR/vw-$TIMESTAMP.tar.gz" .

# Cleanup temp
rm -rf "$TEMP_DIR"

# Rotation: remove backups older than 30 days
find "$BACKUP_DIR" -name "vw-*.tar.gz" -mtime +30 -delete

echo "Backup completed: vw-$TIMESTAMP.tar.gz"
