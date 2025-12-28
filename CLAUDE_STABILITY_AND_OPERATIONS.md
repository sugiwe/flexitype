# アプリの安定稼働と運用効率化ガイド

**作成日:** 2025-12-28
**目的:** Typnixアプリの安定稼働を確保し、運用の効率化を図るための設計・実装ガイド

---

## 背景と課題

### 現状の問題点

**1. ALLOWED_EMAILSの管理**
- 環境変数（`.kamal/secrets`）に依存しているため、ユーザー追加のたびにデプロイが必要
- デプロイのたびに短時間のダウンタイムリスクが発生
- 頻繁なデプロイはアプリの安定性に悪影響を及ぼす可能性

**2. 安定稼働への懸念**
- ユーザー数が増加し、アプリの安定稼働が重要になってきた
- タイピング練習中にアプリが落ちると記録が狂う可能性
- データ整合性の問題が発生するリスク

---

## 解決策の全体像

### 優先順位と実装タイムライン

#### 🔴 高優先度（今すぐ実装）

1. **ALLOWED_EMAILSのDB化**
   - 実装時間: 2-3時間
   - 効果: デプロイ頻度の劇的削減、運用効率化

2. **データベースバックアップ自動化**
   - 実装時間: 10分
   - 効果: データロス防止、災害復旧対策

#### 🟡 中優先度（今週〜来週中）

3. **エラートラッキング（Sentry導入）**
   - 実装時間: 1-2時間
   - 効果: エラーの早期検出、ユーザー影響の最小化

4. **デプロイ前の自動テスト実行**
   - 実装時間: 30分
   - 効果: デプロイの品質向上

#### 🟢 低優先度（将来的に検討）

5. Rate Limiting（レート制限）
6. パフォーマンス監視
7. 複数サーバー構成（ユーザー1000+で検討）

---

## 1. ALLOWED_EMAILSのDB化（最優先）

### 設計方針

**目的:**
- デプロイ不要でリアルタイムにユーザー追加/削除
- 管理者ダッシュボードから簡単に操作
- 監査ログの記録（誰がいつ追加したか）
- **将来的な削除を容易にする（フィーチャーフラグパターン）**

**将来の展望:**
- ベータ版終了後、全ユーザーにログインを開放する予定
- その際、ログイン制限機能を簡単にON/OFF切り替えられるよう設計
- 環境変数 `RESTRICT_LOGIN` で制御（デプロイ不要で切り替え可能）

### フィーチャーフラグ設定

```ruby
# config/initializers/authentication.rb
module Authentication
  # ログイン制限を有効にするか
  # 将来的に全員ログインOKにする場合は RESTRICT_LOGIN=false に設定
  # NOTE: ベータ版終了後に false に切り替える予定
  def self.restrict_login?
    ENV.fetch("RESTRICT_LOGIN", "true") == "true"
  end
end
```

### データモデル

```ruby
# app/models/allowed_email.rb
class AllowedEmail < ApplicationRecord
  # バリデーション
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  # スコープ
  scope :active, -> { where(active: true) }

  # ログイン許可チェック
  # NOTE: このメソッドは将来的に削除予定（全員ログインOKになる予定）
  def self.allowed?(email)
    # ログイン制限が無効なら常にtrue
    return true unless Authentication.restrict_login?

    active.exists?(email: email)
  end
end
```

### マイグレーション

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_allowed_emails.rb
class CreateAllowedEmails < ActiveRecord::Migration[8.1]
  def change
    create_table :allowed_emails do |t|
      t.string :email, null: false, index: { unique: true }
      t.boolean :active, default: true, null: false
      t.text :note # 管理者メモ（誰の依頼で追加したか等）

      t.timestamps
    end
  end
end
```

### コントローラー

```ruby
# app/controllers/admin/allowed_emails_controller.rb
class Admin::AllowedEmailsController < Admin::ApplicationController
  def index
    @allowed_emails = AllowedEmail.order(created_at: :desc).page(params[:page])
  end

  def new
    @allowed_email = AllowedEmail.new
  end

  def create
    @allowed_email = AllowedEmail.new(allowed_email_params)

    if @allowed_email.save
      redirect_to admin_allowed_emails_path, notice: "#{@allowed_email.email} を追加しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @allowed_email = AllowedEmail.find(params[:id])
    @allowed_email.destroy!
    redirect_to admin_allowed_emails_path, notice: "#{@allowed_email.email} を削除しました"
  end

  private

  def allowed_email_params
    params.require(:allowed_email).permit(:email, :note)
  end
end
```

### 認証ロジックの変更

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :authenticate_user!, unless: :public_action?

  private

  def authenticate_user!
    return if logged_in?
    redirect_to root_path, alert: "ログインが必要です"
  end

  def logged_in?
    return false unless session[:user_id]

    @current_user ||= User.find_by(id: session[:user_id])
    return false unless @current_user

    # 🔑 ログイン制限チェック（将来的に削除予定）
    # RESTRICT_LOGIN=falseの場合、この制限はスキップされる
    if Authentication.restrict_login?
      unless AllowedEmail.allowed?(@current_user.email)
        Rails.logger.info "Login restricted: #{@current_user.email} is not in allowed list"
        return false
      end
    end

    true
  end
end
```

### 既存データのマイグレーション

```ruby
# db/migrate/YYYYMMDDHHMMSS_migrate_allowed_emails_from_env.rb
class MigrateAllowedEmailsFromEnv < ActiveRecord::Migration[8.1]
  def up
    # 環境変数からメールアドレスを読み込み
    allowed_emails = ENV["ALLOWED_EMAILS"]&.split(",")&.map(&:strip) || []

    allowed_emails.each do |email|
      AllowedEmail.find_or_create_by!(email: email) do |record|
        record.note = "環境変数から自動移行"
      end
    end

    puts "✅ #{allowed_emails.size}件のメールアドレスをDBに移行しました"
  end

  def down
    AllowedEmail.where(note: "環境変数から自動移行").destroy_all
  end
end
```

### ビュー（管理者画面）

```slim
/ app/views/admin/allowed_emails/index.html.slim
.container.mx-auto.px-4.py-8
  .flex.justify-between.items-center.mb-6
    h1.text-2xl.font-bold 許可メールアドレス管理
    = link_to "新規追加", new_admin_allowed_email_path, class: "btn btn-primary"

  table.table-auto.w-full
    thead
      tr
        th メールアドレス
        th メモ
        th 登録日時
        th 操作
    tbody
      - @allowed_emails.each do |allowed_email|
        tr
          td= allowed_email.email
          td= allowed_email.note
          td= allowed_email.created_at.strftime("%Y-%m-%d %H:%M")
          td
            = link_to "削除", admin_allowed_email_path(allowed_email),
                      data: { turbo_method: :delete, turbo_confirm: "本当に削除しますか？" },
                      class: "text-red-600 hover:text-red-800"

  = paginate @allowed_emails
```

### 実装手順

1. **ブランチ作成**
   ```bash
   git checkout -b feature/allowed-emails-db-migration
   ```

2. **フィーチャーフラグ初期化ファイル作成**
   ```bash
   # config/initializers/authentication.rb を作成
   ```

3. **モデル作成**
   ```bash
   rails g model AllowedEmail email:string:uniq active:boolean note:text
   ```

4. **マイグレーション実行**
   ```bash
   rails db:migrate
   ```

5. **既存データ移行**
   - 環境変数からDBへのマイグレーションスクリプト実行

6. **管理者画面実装**
   - コントローラー、ビュー作成

7. **認証ロジック変更**
   - `ApplicationController`を更新（フィーチャーフラグ対応）

8. **テスト**
   - RSpec追加
   - 手動テスト

9. **デプロイ**
   - PRマージ
   - 本番デプロイ

### 将来の移行手順（ベータ版終了後、全員ログインOKにする場合）

**Phase 1: ログイン制限を無効化（デプロイ不要）**

```bash
# .kamal/secrets に追加（または変更）
RESTRICT_LOGIN=false
```

この時点で、`AllowedEmail` テーブルは参照されなくなり、全員がログイン可能になる。

**Phase 2: 様子見期間（1-2週間）**

- ログイン制限なしで問題がないか確認
- スパムや不正アクセスの有無をチェック
- 問題があれば `RESTRICT_LOGIN=true` に戻すだけで復旧可能

**Phase 3: コード削除（安定稼働確認後）**

問題なければ、以下のコードを削除:

1. `config/initializers/authentication.rb` - ファイル削除
2. `app/models/allowed_email.rb` - ファイル削除
3. `app/controllers/admin/allowed_emails_controller.rb` - ファイル削除
4. `app/views/admin/allowed_emails/` - ディレクトリ削除
5. `app/controllers/application_controller.rb` - 認証チェック部分を削除
6. `config/routes.rb` - Admin::AllowedEmailsController のルート削除
7. `db/migrate/YYYYMMDDHHMMSS_create_allowed_emails.rb` - 削除用マイグレーション作成

```ruby
# db/migrate/YYYYMMDDHHMMSS_drop_allowed_emails.rb
class DropAllowedEmails < ActiveRecord::Migration[8.1]
  def up
    drop_table :allowed_emails
  end

  def down
    # 復旧用（念のため）
    create_table :allowed_emails do |t|
      t.string :email, null: false, index: { unique: true }
      t.boolean :active, default: true, null: false
      t.text :note
      t.timestamps
    end
  end
end
```

---

## 2. データベースバックアップ自動化

### 設計方針

**目的:**
- データロスの防止
- 災害復旧（DR: Disaster Recovery）対策
- 定期的な自動バックアップ

### 実装方法

#### VPS上でcron設定

```bash
# VPSにSSH接続
ssh user@153.120.65.157

# バックアップディレクトリ作成
sudo mkdir -p /var/backups/flexitype
sudo chown $USER:$USER /var/backups/flexitype

# バックアップスクリプト作成
cat > /home/$USER/backup_db.sh <<'EOF'
#!/bin/bash
# Typnix データベースバックアップスクリプト

# 設定
DB_NAME="flexitype_production"
BACKUP_DIR="/var/backups/flexitype"
RETENTION_DAYS=7
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/flexitype_${DATE}.sql.gz"

# バックアップ実行
pg_dump $DB_NAME | gzip > $BACKUP_FILE

# 古いバックアップを削除（7日以上前）
find $BACKUP_DIR -name "flexitype_*.sql.gz" -mtime +$RETENTION_DAYS -delete

# ログ出力
echo "[$(date)] Backup completed: $BACKUP_FILE" >> /var/log/flexitype_backup.log
EOF

# 実行権限付与
chmod +x /home/$USER/backup_db.sh

# cron設定（毎日深夜3時に実行）
(crontab -l 2>/dev/null; echo "0 3 * * * /home/$USER/backup_db.sh") | crontab -
```

### バックアップの確認

```bash
# バックアップファイル一覧
ls -lh /var/backups/flexitype/

# ログ確認
tail -f /var/log/flexitype_backup.log
```

### リストア手順（緊急時）

```bash
# 最新のバックアップファイルを確認
ls -lt /var/backups/flexitype/ | head -n 5

# リストア実行
gunzip < /var/backups/flexitype/flexitype_YYYYMMDD_HHMMSS.sql.gz | psql flexitype_production
```

---

## 3. ゼロダウンタイムデプロイの確保

### 現状確認

Kamalは既にローリングデプロイに対応しています。

### ヘルスチェック設定の確認

```yaml
# config/deploy.yml
healthcheck:
  path: /up
  interval: 10s
  timeout: 5s
  max_attempts: 10
```

### ヘルスチェックエンドポイントの強化

```ruby
# app/controllers/rails/health_controller.rb
class Rails::HealthController < ActionController::Base
  def show
    # DB接続確認
    ActiveRecord::Base.connection.execute("SELECT 1")

    # ディスク容量確認（オプション）
    # disk_usage = `df -h / | tail -1 | awk '{print $5}'`.to_i
    # raise "Disk usage critical" if disk_usage > 90

    render plain: "OK", status: :ok
  rescue => e
    Rails.logger.error "Health check failed: #{e.message}"
    render plain: "UNHEALTHY: #{e.message}", status: :service_unavailable
  end
end
```

---

## 4. エラートラッキング（Sentry導入）

### 目的

- 本番環境のエラーをリアルタイムで検知
- ユーザー影響を最小化
- エラー発生時の詳細情報（スタックトレース、ユーザー情報など）を取得

### 実装手順

#### 1. Sentryアカウント作成

- https://sentry.io/ で無料アカウント作成
- プロジェクト作成（Rails）
- DSN取得

#### 2. Gem追加

```ruby
# Gemfile
gem "sentry-ruby"
gem "sentry-rails"
```

```bash
bundle install
```

#### 3. 初期化

```bash
bundle exec rails generate sentry
```

#### 4. 設定

```ruby
# config/initializers/sentry.rb
Sentry.init do |config|
  config.dsn = Rails.application.credentials.dig(:sentry, :dsn)
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]

  # 環境設定
  config.environment = Rails.env
  config.enabled_environments = %w[production]

  # サンプリングレート（100% = 全エラーを送信）
  config.traces_sample_rate = 1.0
end
```

#### 5. Credentials設定

```bash
EDITOR="code --wait" rails credentials:edit
```

```yaml
sentry:
  dsn: https://your-sentry-dsn@sentry.io/project-id
```

---

## 5. デプロイ前の自動テスト実行

### デプロイスクリプト作成

```bash
# bin/deploy
#!/bin/bash
set -e

echo "🔍 Running tests..."
bundle exec rspec

echo "🔍 Running RuboCop..."
bundle exec rubocop

echo "🔍 Running Brakeman..."
bundle exec brakeman --no-pager

echo "✅ All checks passed!"

echo "🚀 Deploying to production..."
kamal deploy

echo "✅ Deploy completed!"
```

```bash
chmod +x bin/deploy
```

### 使用方法

```bash
# 通常のデプロイ
./bin/deploy

# テストスキップ（緊急時のみ）
kamal deploy
```

---

## 6. その他の推奨施策（中〜低優先度）

### Rate Limiting（レート制限）

**目的:** 悪意あるアクセスからの保護

```ruby
# Gemfile
gem "rack-attack"

# config/initializers/rack_attack.rb
class Rack::Attack
  # 同一IPから1分間に60リクエストまで
  throttle('req/ip', limit: 60, period: 1.minute) do |req|
    req.ip
  end

  # ログイン試行は1分間に5回まで
  throttle('logins/ip', limit: 5, period: 1.minute) do |req|
    if req.path == '/auth/google' && req.post?
      req.ip
    end
  end
end
```

### パフォーマンス監視

**推奨ツール:**
- **New Relic**（有料だが無料トライアルあり）
- **Scout APM**（Rails特化）
- **Datadog**（インフラ全体監視）

**無料で始められる:**
- **Skylight**（Rails専用、14日間無料トライアル）

### CDN設定確認

Cloudflare既に使用中なので、静的アセット（CSS/JS/画像）のキャッシュ設定を確認。

```ruby
# config/environments/production.rb
config.public_file_server.headers = {
  "Cache-Control" => "public, max-age=31536000, immutable"
}
```

---

## 実装チェックリスト

### 今日中（最優先）

- [ ] フィーチャーフラグ初期化ファイル作成（`config/initializers/authentication.rb`）
- [ ] AllowedEmailモデル作成
- [ ] マイグレーション実行
- [ ] 既存データ移行（環境変数→DB）
- [ ] 管理者画面CRUD実装
- [ ] 認証ロジック変更（フィーチャーフラグ対応）
- [ ] テスト作成
- [ ] デプロイ
- [ ] データベースバックアップ自動化（cron設定）

### 今週中

- [ ] Sentry導入
- [ ] デプロイスクリプト作成

### 来週以降

- [ ] Rate Limiting導入
- [ ] パフォーマンス監視検討

---

## 参考リソース

- [Rails Guides: Action Controller Overview](https://guides.rubyonrails.org/action_controller_overview.html)
- [Sentry Documentation](https://docs.sentry.io/platforms/ruby/guides/rails/)
- [Kamal Documentation](https://kamal-deploy.org/)
- [PostgreSQL Backup and Restore](https://www.postgresql.org/docs/current/backup.html)

---

**最終更新:** 2025-12-28
