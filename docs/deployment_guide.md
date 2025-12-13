# デプロイガイド

## 概要

このドキュメントは、TypnixアプリケーションをさくらVPSにデプロイするための手順をまとめたものです。

## 前提条件

### ローカル環境
- Ruby 3.4.4
- Docker（イメージビルド用）
- Kamal 2.9.0以上

### サーバー環境（さくらVPS）
- Ubuntu 22.04 LTS以上
- Docker Engine インストール済み
- PostgreSQL インストール済み
- SSH接続設定済み

## 必要な環境変数

### 1. RAILS_MASTER_KEY
- **用途**: Rails credentialsの暗号化キー
- **取得方法**: `config/master.key` の内容
- **設定場所**: `.kamal/secrets` ファイル

### 2. FLEXITYPE_DATABASE_PASSWORD
- **用途**: PostgreSQLデータベースのパスワード
- **設定場所**: `.kamal/secrets` ファイル、VPSのPostgreSQL設定

### 3. GOOGLE_CLIENT_ID（credentials.yml.enc内）
- **用途**: Google認証用のクライアントID
- **取得方法**: Google Cloud Console
- **設定場所**: `rails credentials:edit` で暗号化

### 4. GOOGLE_CLIENT_SECRET（credentials.yml.enc内）
- **用途**: Google認証用のクライアントシークレット
- **取得方法**: Google Cloud Console
- **設定場所**: `rails credentials:edit` で暗号化

### 5. ALLOWED_EMAILS
- **用途**: ログイン許可するメールアドレスのリスト
- **形式**: カンマ区切り（例: `user1@example.com,user2@example.com`）
- **設定場所**: 本番環境では環境変数、ベータ版では空文字列

### 6. DATABASE_URL（オプション）
- **用途**: PostgreSQL接続URL（database.ymlの代替）
- **形式**: `postgres://username:password@host:5432/database_name`
- **設定場所**: `.kamal/secrets` ファイル

## デプロイ前チェックリスト

### ローカル環境

- [ ] `bundle exec rubocop` が通ること
- [ ] `bundle exec brakeman --no-pager` でセキュリティ警告がないこと
- [ ] `config/master.key` が存在すること
- [ ] Google Cloud Consoleで本番用のOAuth認証情報が設定済みであること
- [ ] 本番ドメイン（取得予定）がGoogle認証のリダイレクトURIに登録されていること

### サーバー環境（さくらVPS）

- [ ] SSHで接続できること
- [ ] Dockerがインストールされていること (`docker --version`)
- [ ] PostgreSQLがインストールされていること (`psql --version`)
- [ ] PostgreSQLで本番用のユーザーとデータベースが作成されていること
- [ ] ファイアウォール設定でHTTP(80)、HTTPS(443)ポートが開いていること

### デプロイ設定ファイル

- [ ] `config/deploy.yml` の `servers.web` にVPSのIPアドレスが設定されていること
- [ ] `config/deploy.yml` の `proxy.host` に本番ドメインが設定されていること（SSL有効化時）
- [ ] `.kamal/secrets` ファイルが作成され、必要な環境変数が設定されていること
- [ ] `.kamal/secrets` が `.gitignore` に含まれていること

## デプロイ手順

### 1. VPSの準備

#### Dockerのインストール
```bash
# VPSにSSH接続
ssh user@your-vps-ip

# Dockerのインストール
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# ユーザーをdockerグループに追加
sudo usermod -aG docker $USER

# ログアウト・再ログインして変更を反映
exit
ssh user@your-vps-ip

# Dockerの動作確認
docker --version
```

#### PostgreSQLのセットアップ
```bash
# PostgreSQLのインストール（Ubuntuの場合）
sudo apt update
sudo apt install postgresql postgresql-contrib

# PostgreSQLの起動確認
sudo systemctl status postgresql

# PostgreSQLユーザーとデータベースの作成
sudo -u postgres psql

-- PostgreSQLコンソール内で実行
CREATE USER flexitype WITH PASSWORD 'your-secure-password';
CREATE DATABASE flexitype_production OWNER flexitype;
CREATE DATABASE flexitype_production_cache OWNER flexitype;
CREATE DATABASE flexitype_production_queue OWNER flexitype;
CREATE DATABASE flexitype_production_cable OWNER flexitype;
\q
```

### 2. ローカル環境での準備

#### .kamal/secretsファイルの作成
```bash
# プロジェクトルートで実行
mkdir -p .kamal
touch .kamal/secrets
chmod 600 .kamal/secrets
```

`.kamal/secrets` の内容例：
```bash
RAILS_MASTER_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxx
FLEXITYPE_DATABASE_PASSWORD=your-secure-password
```

#### config/deploy.ymlの更新
必要に応じて以下の項目を更新：
- `servers.web`: VPSのIPアドレス
- `proxy.host`: 本番ドメイン（独自ドメイン取得後）
- `proxy.ssl`: SSL有効化（Let's Encrypt）

### 3. 初回デプロイ

```bash
# Kamalのセットアップ（初回のみ）
kamal setup

# デプロイ
kamal deploy
```

### 4. データベースのセットアップ

```bash
# マイグレーション実行
kamal app exec 'bin/rails db:migrate'

# Solid Queue、Solid Cache、Solid Cableのマイグレーション
kamal app exec 'bin/rails db:migrate:cache'
kamal app exec 'bin/rails db:migrate:queue'
kamal app exec 'bin/rails db:migrate:cable'
```

### 5. デプロイ後の動作確認

```bash
# アプリケーションのログ確認
kamal app logs

# アプリケーションの状態確認
kamal app details

# コンテナの動作確認
ssh user@your-vps-ip
docker ps
```

ブラウザで `http://your-vps-ip` にアクセスして動作確認。

### 6. SSL/HTTPS設定（独自ドメイン取得後）

#### config/deploy.ymlの更新
```yaml
proxy:
  ssl: true
  host: your-domain.com
```

#### production.rbの更新
```ruby
# config/environments/production.rb
config.assume_ssl = true
config.force_ssl = true
```

#### 再デプロイ
```bash
kamal deploy
```

## トラブルシューティング

### デプロイが失敗する場合

1. **ログの確認**
   ```bash
   kamal app logs
   ```

2. **SSH接続の確認**
   ```bash
   ssh user@your-vps-ip
   ```

3. **Docker接続の確認**
   ```bash
   kamal accessory details all
   ```

### データベース接続エラー

1. **PostgreSQLの起動確認**
   ```bash
   ssh user@your-vps-ip
   sudo systemctl status postgresql
   ```

2. **接続情報の確認**
   - `config/database.yml` の設定
   - `.kamal/secrets` の `FLEXITYPE_DATABASE_PASSWORD`
   - VPS上のPostgreSQLユーザー・データベース

### アセットが読み込まれない

1. **アセットのプリコンパイル確認**
   ```bash
   kamal app exec 'ls -la public/assets'
   ```

2. **再デプロイ**
   ```bash
   kamal deploy
   ```

## 更新デプロイ

コード更新後のデプロイ手順：

```bash
# 変更をコミット
git add .
git commit -m "変更内容"

# デプロイ
kamal deploy

# ログ確認
kamal app logs -f
```

## ロールバック

問題が発生した場合の緊急対応：

```bash
# 直前のバージョンにロールバック
kamal rollback
```

## よく使うKamalコマンド

```bash
# デプロイ
kamal deploy

# アプリケーションの再起動
kamal app restart

# ログの確認
kamal app logs
kamal app logs -f  # リアルタイム

# Railsコンソール
kamal app exec -i 'bin/rails console'

# コンテナのシェル
kamal app exec -i 'bash'

# 環境変数の確認
kamal app exec 'env | sort'

# データベースコンソール
kamal app exec -i 'bin/rails dbconsole'
```

## セキュリティ注意事項

- `.kamal/secrets` は絶対にGitにコミットしない
- `config/master.key` もGitにコミットしない（.gitignoreに含まれている）
- PostgreSQLのパスワードは強力なものを使用する
- VPSのSSHポートは22以外に変更することを推奨
- SSH鍵認証を使用し、パスワード認証は無効化することを推奨
- ファイアウォール（ufw等）で不要なポートを閉じる

## 参考リンク

- [Kamal公式ドキュメント](https://kamal-deploy.org/)
- [Rails本番環境ガイド](https://guides.rubyonrails.org/configuring.html#running-in-production)
- [さくらVPS](https://vps.sakura.ad.jp/)
