# データベースバックアップ自動化セットアップ手順

**作成日:** 2025-01-04
**最終更新:** 2025-01-05
**目的:** PostgreSQLデータベースの定期バックアップを自動化し、データロスを防止する

---

## セットアップ手順

### 1. VPSにSSH接続

```bash
ssh ubuntu@153.120.65.157
```

### 2. バックアップディレクトリを作成

```bash
# ホームディレクトリ配下にバックアップディレクトリを作成
mkdir -p ~/backups/flexitype

# パーミッション確認
ls -ld ~/backups/flexitype
# 出力例: drwxrwxr-x 2 ubuntu ubuntu 4096 Jan  5 12:00 /home/ubuntu/backups/flexitype
```

### 3. PostgreSQLパスワードファイルを作成

cron実行時にパスワード入力ができないため、`.pgpass`ファイルでパスワードを管理します。

```bash
# PostgreSQLのパスワードファイルを作成
cat > ~/.pgpass <<EOF
localhost:5432:flexitype_production:flexitype:YOUR_PASSWORD_HERE
EOF

# パーミッションを600に設定（必須：600でないと無視される）
chmod 600 ~/.pgpass
```

**重要:** `YOUR_PASSWORD_HERE`の部分を、実際の`flexitype`ユーザーのパスワードに置き換えてください。

### 4. バックアップスクリプトを作成

```bash
# ホームディレクトリにスクリプトを作成
cat > ~/backup_db.sh <<'EOF'
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
EOF

# 実行権限を付与
chmod +x ~/backup_db.sh
```

### 5. 手動テスト実行

```bash
# スクリプトを手動で実行してテスト（パスワードが聞かれないことを確認）
~/backup_db.sh

# バックアップファイルが作成されたか確認
ls -lh ~/backups/flexitype/

# ログを確認
cat ~/backups/flexitype_backup.log
```

**期待される出力例:**
```
total 72K
-rw-rw-r-- 1 ubuntu ubuntu 69K Jan  5 17:24 flexitype_20250105_172402.sql.gz

[Mon Jan  5 17:24:02 JST 2026] Starting backup...
[Mon Jan  5 17:24:18 JST 2026] Backup completed: /home/ubuntu/backups/flexitype/flexitype_20250105_172402.sql.gz (Size: 72K)
[Mon Jan  5 17:24:18 JST 2026] Total backups: 1
[Mon Jan  5 17:24:18 JST 2026] Backup process completed successfully
```

### 6. cron設定（毎日深夜3時に自動実行）

```bash
# crontabを編集
crontab -e

# 以下の行を追加（エディタが開いたら最終行に追加）
0 3 * * * /home/ubuntu/backup_db.sh

# 保存して終了（vimの場合: :wq、nanoの場合: Ctrl+X → Y → Enter）
```

**crontab書式の説明:**
```
# ┌───────────── 分 (0 - 59)
# │ ┌───────────── 時 (0 - 23)
# │ │ ┌───────────── 日 (1 - 31)
# │ │ │ ┌───────────── 月 (1 - 12)
# │ │ │ │ ┌───────────── 曜日 (0 - 6) (0は日曜日)
# │ │ │ │ │
# * * * * * 実行するコマンド
  0 3 * * * /home/ubuntu/backup_db.sh
  ↑ ↑
  深夜3時0分
```

### 6. cron設定の確認

```bash
# crontabの内容を確認
crontab -l

# 期待される出力:
# 0 3 * * * /home/ubuntu/backup_db.sh
```

---

## バックアップの確認方法

### バックアップファイル一覧

```bash
# バックアップファイルの一覧表示
ls -lh ~/backups/flexitype/

# 日付順でソート（最新が最後）
ls -lht ~/backups/flexitype/
```

### ログ確認

```bash
# ログファイルの内容を表示
cat ~/backups/flexitype_backup.log

# 最新の10行のみ表示
tail -10 ~/backups/flexitype_backup.log

# リアルタイムでログを監視（バックアップ実行中）
tail -f ~/backups/flexitype_backup.log
```

---

## リストア手順（緊急時）

### 1. 最新のバックアップファイルを確認

```bash
# 最新5件のバックアップファイルを表示
ls -lt ~/backups/flexitype/ | head -n 6
```

### 2. リストア実行

```bash
# データベースをリストア（例: 2025年1月5日17時のバックアップ）
gunzip < ~/backups/flexitype/flexitype_20250105_172402.sql.gz | psql -U flexitype -h localhost flexitype_production
```

**警告:** リストアは既存のデータを上書きします。必ず事前にバックアップを取ってください。

### 3. リストア後の確認

```bash
# データベースに接続
psql flexitype_production

# テーブル一覧を確認
\dt

# レコード数を確認（例: usersテーブル）
SELECT COUNT(*) FROM users;

# 終了
\q
```

---

## トラブルシューティング

### バックアップが作成されない場合

**原因1: pg_dumpコマンドが見つからない**
```bash
# PostgreSQLクライアントがインストールされているか確認
which pg_dump

# インストールされていない場合はインストール
sudo apt-get install postgresql-client-14
```

**原因2: データベースへの接続権限がない**
```bash
# PostgreSQLの認証設定を確認
sudo cat /etc/postgresql/14/main/pg_hba.conf

# ローカル接続が trust または peer になっているか確認
# local   all             all                                     trust
```

**原因3: ディスク容量不足**
```bash
# ディスク使用状況を確認
df -h ~
```

**原因4: .pgpassファイルのパーミッションが正しくない**
```bash
# パーミッションを確認（600である必要がある）
ls -l ~/.pgpass

# 正しくない場合は修正
chmod 600 ~/.pgpass
```

### cronが実行されない場合

**原因1: cronサービスが起動していない**
```bash
# cronサービスの状態を確認
sudo systemctl status cron

# 起動していない場合は起動
sudo systemctl start cron
```

**原因2: スクリプトのパスが間違っている**
```bash
# crontabで絶対パスを使用しているか確認
crontab -l

# スクリプトが存在するか確認
ls -l /home/ubuntu/backup_db.sh
```

**原因3: cronのログを確認**
```bash
# cronのログを確認（Ubuntuの場合）
sudo grep CRON /var/log/syslog | tail -20
```

---

## バックアップの保持期間変更

デフォルトは7日間保持ですが、変更したい場合:

```bash
# スクリプトを編集
nano ~/backup_db.sh

# RETENTION_DAYS の値を変更（例: 30日間保持）
RETENTION_DAYS=30

# 保存して終了
```

---

## まとめ

**実装完了後の状態:**
- ✅ 毎日深夜3時に自動バックアップが実行される
- ✅ バックアップファイルは `~/backups/flexitype/` に保存される
- ✅ 7日間以上古いバックアップは自動削除される
- ✅ バックアップログは `~/backups/flexitype_backup.log` に記録される
- ✅ `.pgpass`でパスワード管理（cron実行時にパスワード不要）

**定期的な確認（月1回推奨）:**
1. バックアップファイルが正常に作成されているか確認：`ls -lh ~/backups/flexitype/`
2. ログにエラーが記録されていないか確認：`tail -20 ~/backups/flexitype_backup.log`
3. ディスク容量が十分にあるか確認：`df -h ~`

**最終更新:** 2025-01-05
