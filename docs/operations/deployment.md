# デプロイガイド

**作成日:** 2025-01-04
**最終更新:** 2025-01-06
**目的:** 初回セットアップから日常的なデプロイまで、安全で確実なデプロイ手順を標準化する

---

## 目次

1. [概要](#概要)
2. [前提条件](#前提条件)
3. [初回セットアップ](#初回セットアップ)
4. [日常的なデプロイ](#日常的なデプロイ)
5. [デプロイ後の確認](#デプロイ後の確認)
6. [トラブルシューティング](#トラブルシューティング)
7. [ベストプラクティス](#ベストプラクティス)
8. [よく使うKamalコマンド](#よく使うkamalコマンド)

---

## 概要

このドキュメントは、Typnixアプリケーションをさくら VPS にデプロイするための完全なガイドです。

**デプロイ方式:**
- **Kamal**: Docker ベースのゼロダウンタイムデプロイ
- **PostgreSQL**: VPS 内で直接稼働
- **SSL/TLS**: Let's Encrypt（Kamal で自動設定）

---

## 前提条件

### ローカル環境

- Ruby 3.4.4
- Docker（イメージビルド用）
- Kamal 2.9.0 以上
- Git

### サーバー環境（さくら VPS）

- Ubuntu 22.04 LTS 以上
- Docker Engine インストール済み
- PostgreSQL インストール済み
- SSH 接続設定済み

### 必要な環境変数

| 変数名 | 用途 | 設定場所 |
|--------|------|----------|
| `RAILS_MASTER_KEY` | Rails credentials の暗号化キー | `.kamal/secrets` |
| `FLEXITYPE_DATABASE_PASSWORD` | PostgreSQL のパスワード | `.kamal/secrets`, VPS の PostgreSQL |
| `GOOGLE_CLIENT_ID` | Google 認証のクライアント ID | `credentials.yml.enc` |
| `GOOGLE_CLIENT_SECRET` | Google 認証のシークレット | `credentials.yml.enc` |
| `ALLOWED_EMAILS` | ログイン許可メールアドレス | 環境変数（カンマ区切り） |
| `DATABASE_URL` | PostgreSQL 接続 URL（オプション） | `.kamal/secrets` |

---

## 初回セットアップ

### 1. VPS の準備

#### Docker のインストール

```bash
# VPS に SSH 接続
ssh user@your-vps-ip

# Docker のインストール
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# ユーザーを docker グループに追加
sudo usermod -aG docker $USER

# ログアウト・再ログインして変更を反映
exit
ssh user@your-vps-ip

# Docker の動作確認
docker --version
```

#### PostgreSQL のセットアップ

```bash
# PostgreSQL のインストール（Ubuntu の場合）
sudo apt update
sudo apt install postgresql postgresql-contrib

# PostgreSQL の起動確認
sudo systemctl status postgresql

# PostgreSQL ユーザーとデータベースの作成
sudo -u postgres psql
```

PostgreSQL コンソール内で実行:

```sql
CREATE USER flexitype WITH PASSWORD 'your-secure-password';
CREATE DATABASE flexitype_production OWNER flexitype;
CREATE DATABASE flexitype_production_cache OWNER flexitype;
CREATE DATABASE flexitype_production_queue OWNER flexitype;
CREATE DATABASE flexitype_production_cable OWNER flexitype;
\q
```

### 2. ローカル環境での準備

#### .kamal/secrets ファイルの作成

```bash
# プロジェクトルートで実行
mkdir -p .kamal
touch .kamal/secrets
chmod 600 .kamal/secrets
```

`.kamal/secrets` の内容例:

```bash
RAILS_MASTER_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxx
FLEXITYPE_DATABASE_PASSWORD=your-secure-password
```

#### config/deploy.yml の更新

必要に応じて以下の項目を更新:
- `servers.web`: VPS の IP アドレス
- `proxy.host`: 本番ドメイン（独自ドメイン取得後）
- `proxy.ssl`: SSL 有効化（Let's Encrypt）

### 3. デプロイ前チェックリスト

#### ローカル環境

- [ ] `bundle exec rubocop` が通ること
- [ ] `bundle exec brakeman --no-pager` でセキュリティ警告がないこと
- [ ] `config/master.key` が存在すること
- [ ] Google Cloud Console で本番用の OAuth 認証情報が設定済みであること
- [ ] 本番ドメインが Google 認証のリダイレクト URI に登録されていること

#### サーバー環境

- [ ] SSH で接続できること
- [ ] Docker がインストールされていること (`docker --version`)
- [ ] PostgreSQL がインストールされていること (`psql --version`)
- [ ] PostgreSQL で本番用のユーザーとデータベースが作成されていること
- [ ] ファイアウォール設定で HTTP(80)、HTTPS(443) ポートが開いていること

#### デプロイ設定ファイル

- [ ] `config/deploy.yml` の `servers.web` に VPS の IP アドレスが設定されていること
- [ ] `config/deploy.yml` の `proxy.host` に本番ドメインが設定されていること（SSL 有効化時）
- [ ] `.kamal/secrets` ファイルが作成され、必要な環境変数が設定されていること
- [ ] `.kamal/secrets` が `.gitignore` に含まれていること

### 4. 初回デプロイの実行

```bash
# Kamal のセットアップ（初回のみ）
kamal setup

# デプロイ
kamal deploy
```

### 5. 初回デプロイ後の動作確認

**注意:** マイグレーションは自動実行されます。Dockerコンテナ起動時に `bin/docker-entrypoint` が `rails db:prepare` を実行するため、手動でのマイグレーション実行は不要です。

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

### 7. SSL/HTTPS 設定（独自ドメイン取得後）

#### config/deploy.yml の更新

```yaml
proxy:
  ssl: true
  host: your-domain.com
```

#### production.rb の更新

```ruby
# config/environments/production.rb
config.assume_ssl = true
config.force_ssl = true
```

#### 再デプロイ

```bash
kamal deploy
```

---

## 日常的なデプロイ

### 推奨方法: デプロイスクリプト使用（自動テスト付き）

```bash
./bin/deploy
```

このスクリプトは以下を自動実行します:

1. **RSpec**: 全テストを実行
2. **RuboCop**: コード品質チェック
3. **Brakeman**: セキュリティ脆弱性チェック
4. **Kamal deploy**: 本番環境へのデプロイ

**メリット:**
- デプロイ前に自動で品質チェック
- テスト失敗時は自動的にデプロイ中止
- 人的ミスを防止
- ブランチ確認（main ブランチ以外は警告）

### 緊急時のデプロイ（テストスキップ）

テストに時間がかかる場合や緊急の修正が必要な場合のみ:

```bash
kamal deploy
```

**注意:** テストをスキップするため、本番環境に不具合が混入するリスクがあります。

### コード更新後のデプロイ手順

```bash
# 変更をコミット
git add .
git commit -m "変更内容"

# デプロイ
./bin/deploy

# ログ確認
kamal app logs -f
```

---

## デプロイ後の確認

### 1. サイトにアクセスして動作確認

```bash
open https://typnix.com
```

**確認項目:**
- ✅ トップページが表示される
- ✅ ログインが正常に動作する
- ✅ タイピング練習が正常に動作する
- ✅ 管理者ダッシュボードにアクセスできる（管理者のみ）

### 2. ログを確認

```bash
# アプリケーションログをリアルタイムで確認
kamal app logs --follow

# 最新 100 行のログを表示
kamal app logs --lines 100

# エラーログのみ表示
kamal app logs | grep ERROR
```

### 3. ヘルスチェック確認

```bash
curl https://typnix.com/up
# 期待される出力: OK
```

---

## マイグレーションについて

### 自動実行される仕組み

通常、マイグレーションは**自動的に実行されます**。デプロイ時の流れ：

1. `kamal deploy` を実行
2. 新しいDockerコンテナが起動
3. コンテナ起動時に `bin/docker-entrypoint` が実行される
4. `rails db:prepare` が自動実行され、未実行のマイグレーションが適用される
5. Railsサーバーが起動

### 手動実行が必要なケース

以下の場合のみ、手動でのマイグレーション操作が必要です：

**マイグレーション状況の確認:**
```bash
kamal app exec bin/rails db:migrate:status
```

**ロールバックが必要な場合:**
```bash
# 1つ前のマイグレーションに戻す
kamal app exec bin/rails db:rollback

# 特定のバージョンまで戻す
kamal app exec bin/rails db:rollback STEP=3
```

**データマイグレーションの手動実行（通常は不要）:**
```bash
kamal app exec bin/rails db:migrate
```

### 注意事項

- **複雑なマイグレーション**: 時間がかかる場合、コンテナ起動タイムアウトの可能性があります
- **ロールバック**: 問題が発生した場合は上記の手動コマンドでロールバック可能です
- **複数サーバー**: 現在は1台構成のため問題ありませんが、将来複数サーバーになる場合は競合に注意が必要です

---

## ロールバック手順（問題が発生した場合）

### 方法 1: 前のバージョンにロールバック

```bash
# 直前のバージョンにロールバック
kamal rollback
```

### 方法 2: 特定のコミットにロールバック

```bash
# ロールバックしたいコミットをチェックアウト
git checkout <commit-hash>

# デプロイ
kamal deploy

# 終わったら main に戻る
git checkout main
```

---

## トラブルシューティング

### デプロイが失敗する場合

**原因 1: テストが通らない**
```bash
# ローカルでテストを実行
bundle exec rspec

# 失敗したテストを修正してから再デプロイ
```

**原因 2: VPS への接続失敗**
```bash
# SSH 接続を確認
ssh ubuntu@153.120.65.157

# Kamal の接続を確認
kamal app exec echo "Connection OK"
```

**原因 3: ディスク容量不足**
```bash
# ディスク使用状況を確認
kamal app exec df -h

# 古い Docker イメージを削除
kamal app exec docker system prune -af
```

### アプリが起動しない場合

```bash
# コンテナの状態を確認
kamal app exec docker ps -a

# コンテナログを確認
kamal app logs --lines 500

# コンテナを再起動
kamal app restart
```

### データベース接続エラーが出る場合

```bash
# データベースの状態を確認
ssh ubuntu@153.120.65.157
sudo systemctl status postgresql

# PostgreSQL が起動していない場合は起動
sudo systemctl start postgresql
```

**接続情報の確認:**
- `config/database.yml` の設定
- `.kamal/secrets` の `FLEXITYPE_DATABASE_PASSWORD`
- VPS 上の PostgreSQL ユーザー・データベース

### アセットが読み込まれない

```bash
# アセットのプリコンパイル確認
kamal app exec 'ls -la public/assets'

# 再デプロイ
kamal deploy
```

---

## ベストプラクティス

### 1. デプロイ前のチェックリスト

- [ ] ローカルで全テストが通る（`bundle exec rspec`）
- [ ] RuboCop でコード品質チェック（`bundle exec rubocop`）
- [ ] Brakeman でセキュリティチェック（`bundle exec brakeman`）
- [ ] main ブランチにマージ済み
- [ ] マイグレーションファイルがある場合は確認済み

### 2. デプロイタイミング

**推奨時間帯:**
- 平日の営業時間外（深夜または早朝）
- ユーザーアクセスが少ない時間帯

**避けるべき時間帯:**
- 週末のピーク時間
- イベント開催中

### 3. デプロイ後の監視

**最初の 30 分:**
- ログを監視（`kamal app logs --follow`）
- エラーが発生していないか確認
- ヘルスチェック確認（`curl https://typnix.com/up`）

**最初の 24 時間:**
- ユーザーからのフィードバックを確認
- Sentry でエラーを監視（導入後）
- パフォーマンス確認

---

## よく使う Kamal コマンド

```bash
# デプロイ
kamal deploy

# アプリケーションの再起動
kamal app restart

# ログの確認
kamal app logs
kamal app logs -f  # リアルタイム
kamal app logs --lines 100  # 最新 100 行

# Rails コンソール
kamal app exec -i 'bin/rails console'

# コンテナのシェル
kamal app exec -i 'bash'

# 環境変数の確認
kamal app exec 'env | sort'

# データベースコンソール
kamal app exec -i 'bin/rails dbconsole'

# コンテナの状態確認
kamal app details

# ロールバック
kamal rollback
```

---

## セキュリティ注意事項

- `.kamal/secrets` は絶対に Git にコミットしない
- `config/master.key` も Git にコミットしない（.gitignore に含まれている）
- PostgreSQL のパスワードは強力なものを使用する
- VPS の SSH ポートは 22 以外に変更することを推奨
- SSH 鍵認証を使用し、パスワード認証は無効化することを推奨
- ファイアウォール（ufw 等）で不要なポートを閉じる

---

## CI/CD（将来実装予定）

GitHub Actions を導入すると、以下が自動化されます:

1. **PR 作成時:**
   - 自動テスト実行
   - RuboCop 実行
   - Brakeman 実行

2. **main ブランチへのマージ時:**
   - 自動デプロイ（オプション）

詳細は `TODO.md` の「GitHub Actions CI/CD 設定」を参照。

---

## まとめ

**デプロイの基本フロー:**
1. ローカルでテスト・品質チェック
2. `./bin/deploy` でデプロイ
3. サイトで動作確認
4. ログ監視

**問題が発生した場合:**
1. `kamal app logs` でログ確認
2. 必要に応じてロールバック（`kamal rollback`）
3. 問題を修正して再デプロイ

---

## 参考リンク

- [Kamal 公式ドキュメント](https://kamal-deploy.org/)
- [Rails 本番環境ガイド](https://guides.rubyonrails.org/configuring.html#running-in-production)
- [さくら VPS](https://vps.sakura.ad.jp/)
