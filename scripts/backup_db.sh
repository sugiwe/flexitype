#!/bin/bash
# Typnix データベースバックアップスクリプト
# 用途: PostgreSQLデータベースの定期バックアップ
# 実行: cron で毎日深夜3時に自動実行

set -e

# 設定
DB_NAME="flexitype_production"
DB_USER="flexitype"
BACKUP_DIR="/home/ubuntu/backups/flexitype"
RETENTION_DAYS=7
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/flexitype_${DATE}.sql.gz"
LOG_FILE="/home/ubuntu/backups/flexitype_backup.log"

# バックアップディレクトリが存在しない場合は作成
mkdir -p "$BACKUP_DIR"

# バックアップ実行
echo "[$(date)] Starting backup..." >> "$LOG_FILE"
pg_dump -U "$DB_USER" -h localhost "$DB_NAME" | gzip > "$BACKUP_FILE"

# バックアップファイルのサイズを確認
BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
echo "[$(date)] Backup completed: $BACKUP_FILE (Size: $BACKUP_SIZE)" >> "$LOG_FILE"

# 古いバックアップを削除（7日以上前）
DELETED_COUNT=$(find "$BACKUP_DIR" -name "flexitype_*.sql.gz" -mtime +$RETENTION_DAYS -delete -print | wc -l)
if [ "$DELETED_COUNT" -gt 0 ]; then
  echo "[$(date)] Deleted $DELETED_COUNT old backup(s)" >> "$LOG_FILE"
fi

# バックアップファイル数を確認
BACKUP_COUNT=$(find "$BACKUP_DIR" -name "flexitype_*.sql.gz" | wc -l)
echo "[$(date)] Total backups: $BACKUP_COUNT" >> "$LOG_FILE"

echo "[$(date)] Backup process completed successfully" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"
