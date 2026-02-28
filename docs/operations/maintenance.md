# 運用・メンテナンス

Typnixの安定稼働を確保し、運用効率を高めるためのガイド。

---

## 運用効率化施策

### ALLOWED_EMAILSのDB化

**目的:**
- デプロイ不要でリアルタイムにユーザー追加/削除
- 管理者ダッシュボードから簡単に操作

**実装状況**: ✅ 完了

- AllowedEmail モデルでDB管理
- フィーチャーフラグ（`RESTRICT_LOGIN`環境変数）で制御
- 管理者画面CRUD（`/admin/allowed_emails`）

**将来の展望:**
- ベータ版終了後、全ユーザーにログインを開放予定
- 環境変数 `RESTRICT_LOGIN=false` で簡単に切り替え可能

---

## データベースバックアップ

### 自動バックアップ設定

**実装状況**: ✅ 完了

- cron設定で毎日深夜3時に自動実行
- バックアップ先: `/home/ubuntu/backups/flexitype/`
- 保持期間: 7日間
- ログ: `/home/ubuntu/backups/flexitype_backup.log`

**詳細**: [バックアップ設定](backup.md)

### バックアップ確認（月1回推奨）

```bash
# バックアップファイル一覧
ls -lh ~/backups/flexitype/

# ログ確認
tail -20 ~/backups/flexitype_backup.log

# ディスク容量確認
df -h ~
```

---

## ゼロダウンタイムデプロイ

### Kamal のローリングデプロイ

Kamalは既にローリングデプロイに対応しています。

**ヘルスチェック設定:**

```yaml
# config/deploy.yml
healthcheck:
  path: /up
  interval: 10s
  timeout: 5s
  max_attempts: 10
```

**ヘルスチェックエンドポイント:**

[app/controllers/rails/health_controller.rb](../../app/controllers/rails/health_controller.rb)

```ruby
class Rails::HealthController < ActionController::Base
  def show
    # DB接続確認
    ActiveRecord::Base.connection.execute("SELECT 1")
    render plain: "OK", status: :ok
  rescue => e
    Rails.logger.error "Health check failed: #{e.message}"
    render plain: "UNHEALTHY: #{e.message}", status: :service_unavailable
  end
end
```

---

## エラートラッキング

### Sentry導入

**実装状況**: ✅ 完了

- 本番環境のエラーをリアルタイムで検知
- スタックトレース、リクエスト情報の記録
- メール・Slack通知

**詳細**: [監視設定](monitoring.md)

**定期的な確認（週1回推奨）:**
- Sentryダッシュボードでエラー一覧を確認
- 新しいエラーが発生していないか確認
- 発生頻度の高いエラーを優先的に修正

---

## デプロイ前の自動チェック

### デプロイスクリプト

**実装状況**: ✅ 完了

`bin/deploy` スクリプトで以下を自動実行:

1. RSpec: 全テスト実行
2. RuboCop: コード品質チェック
3. Brakeman: セキュリティ脆弱性チェック
4. Kamal deploy: 本番環境へのデプロイ

**使用方法:**

```bash
# 推奨: 自動テスト付きデプロイ
./bin/deploy

# 緊急時: テストスキップ
kamal deploy
```

---

## セキュリティチェック

### 定期的な確認（毎月）

```bash
# 依存関係の脆弱性チェック
bundle exec bundler-audit check

# セキュリティ静的解析
bundle exec brakeman --no-pager

# セキュリティパッチの適用
bundle update
```

### デプロイ前（必須）

```bash
# コード品質チェック
bundle exec rubocop

# セキュリティチェック
bundle exec brakeman

# テスト実行
bundle exec rspec
```

---

## PostgreSQL定期メンテナンス

### VACUUM実行（月1回推奨）

```bash
# VPSにSSH接続
ssh ubuntu@153.120.65.157

# PostgreSQLに接続
sudo -u postgres psql flexitype_production

# VACUUM実行
VACUUM ANALYZE;

# 終了
\q
```

**効果:**
- 不要なデータの削除
- インデックスの再構築
- クエリパフォーマンスの向上

---

## 監視・アラート

### ログ監視

```bash
# アプリケーションログ（リアルタイム）
kamal app logs --follow

# 最新100行
kamal app logs --lines 100

# エラーログのみ
kamal app logs | grep ERROR
```

### ヘルスチェック

```bash
# 手動確認
curl https://typnix.com/up

# 期待される出力: OK
```

---

## パフォーマンス監視（将来検討）

### 推奨ツール

- **New Relic**（有料だが無料トライアルあり）
- **Scout APM**（Rails特化）
- **Skylight**（Rails専用、14日間無料トライアル）

**優先度**: 低（ユーザー数が1000+になったら検討）

---

## Rate Limiting（将来検討）

### Rack::Attack導入

**目的**: 悪意あるアクセスからの保護

```ruby
# Gemfile
gem "rack-attack"

# config/initializers/rack_attack.rb
class Rack::Attack
  # 同一IPから1分間に60リクエストまで
  throttle('req/ip', limit: 60, period: 1.minute) do |req|
    req.ip
  end
end
```

**優先度**: 低（小規模サービスのため）

---

## CDN設定確認

Cloudflare既に使用中なので、静的アセット（CSS/JS/画像）のキャッシュ設定を確認。

```ruby
# config/environments/production.rb
config.public_file_server.headers = {
  "Cache-Control" => "public, max-age=31536000, immutable"
}
```

---

## トラブルシューティング

### アプリが起動しない場合

```bash
# コンテナの状態を確認
kamal app exec docker ps -a

# コンテナログを確認
kamal app logs --lines 500

# コンテナを再起動
kamal app restart
```

### データベース接続エラー

```bash
# データベースの状態を確認
ssh ubuntu@153.120.65.157
sudo systemctl status postgresql

# PostgreSQL が起動していない場合は起動
sudo systemctl start postgresql
```

### ディスク容量不足

```bash
# ディスク使用状況を確認
kamal app exec df -h

# 古い Docker イメージを削除
kamal app exec docker system prune -af
```

---

## 関連ドキュメント

- [デプロイガイド](deployment.md)
- [バックアップ設定](backup.md)
- [監視設定](monitoring.md)
