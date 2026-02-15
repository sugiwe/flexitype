# セキュリティ設計

Typnixのセキュリティ対策の実装状況と方針をまとめたドキュメント。

---

## セキュリティスコア

**総合評価**: ✅ 良好

- Brakeman警告: **0件**
- bundler-audit脆弱性: **0件**
- HTTPS: **✅ Full SSL**
- 認証: **✅ Google OAuth**
- CSRF対策: **✅ 有効**
- XSS対策: **✅ 有効**
- SQL Injection対策: **✅ 有効**

---

## 1. 認証・認可

### Google OAuth認証

- `GoogleIDToken::Validator`でトークン検証
- 実装箇所: `SessionsController#create`

### メール許可リスト制御

- AllowedEmail モデルでDB管理
- フィーチャーフラグ（`RESTRICT_LOGIN`環境変数）で制御
- 本番環境ではログイン制限が有効

### セッション管理

- Rails標準のセッション管理
- セキュアなCookie設定（HTTPS環境）

---

## 2. CSRF対策

### Rails標準のCSRF保護

- `ApplicationController`でデフォルト有効
- `protect_from_forgery with: :exception`

### Google認証エンドポイントの例外

- `SessionsController`: `protect_from_forgery except: :create`
- 理由: Google Identity ServicesはPOSTリクエストでCSRFトークンを送信しない
- 代替対策: GoogleIDトークン検証により認証の正当性を保証

---

## 3. XSS対策

### 自動HTMLエスケープ

- Rails 8デフォルトで有効
- Slimテンプレートでも自動エスケープ有効

### ユーザー入力のサニタイズ

- キーマップの文字入力（20文字制限）
- ユーザー名（30文字制限）
- メールアドレス（254文字制限）

### Content Security Policy（CSP）

- `config/initializers/content_security_policy.rb`で設定済み
- Googleログインとの互換性確保（nonce無効化、`:unsafe_inline`有効化）
- インラインスタイル（`style=`属性）は使用禁止

---

## 4. SQL Injection対策

### パラメータ化クエリ

- Active Record使用により自動的に保護
- 生SQLの使用なし

### Strong Parameters

- 全コントローラで適切に実装
- ユーザー入力を厳密にフィルタリング

---

## 5. SSL/TLS設定

### HTTPS強制

- `config.force_ssl = true`（production.rb）
- Let's Encrypt証明書（kamal-proxy経由）

### Cloudflare Full SSL

- エンドツーエンド暗号化
- Cloudflare ↔ VPS間もHTTPS

### HSTS有効化

- `force_ssl = true`で自動的に有効化
- Strict-Transport-Securityヘッダー送信

---

## 6. セッション・Cookie設定

### セキュアCookie

- `config.assume_ssl = true`
- `config.force_ssl = true`
- HTTPSでのみCookie送信

### HttpOnlyフラグ

- Railsデフォルトで有効（JavaScriptからアクセス不可）

### SameSite属性

- Rails 8デフォルト: `SameSite=Lax`
- CSRF攻撃の追加防御

---

## 7. 機密情報管理

### 環境変数の適切な管理

- RAILS_MASTER_KEY: `.kamal/secrets`（Git管理外）
- DB_PASSWORD: `.kamal/secrets`（Git管理外）
- ALLOWED_EMAILS: 環境変数（DB移行後は不要）

### credentials.yml.encの使用

- Google Client ID/Secret: `config/credentials.yml.enc`
- RAILS_MASTER_KEYで暗号化

### .gitignoreの確認

- `.kamal/secrets`
- `.env`
- `config/master.key`

---

## 8. 依存関係の脆弱性管理

### Brakeman（静的解析）

- 実行結果: **警告0件**
- 実装済み: `bundle exec brakeman`

### bundler-audit（依存gem監査）

- 実行結果: **脆弱性なし**
- 実装済み: `bundle exec bundler-audit check`

### 定期的な更新

- Gemfile.lock更新の習慣化
- セキュリティパッチの適用

---

## 9. ロギング・監視

### 本番ログレベル

- `config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")`
- 個人情報をログに出力しない設定

### ログ出力先

- STDOUT出力（Dockerコンテナ向け）
- `config.logger = ActiveSupport::TaggedLogging.logger(STDOUT)`

### エラートラッキング

- Sentry導入済み（[運用ガイド](../operations/monitoring.md)参照）

---

## 10. HTTPヘッダーセキュリティ

### X-Frame-Options

- Railsデフォルト: SAMEORIGIN
- クリックジャッキング対策

### X-Content-Type-Options

- Railsデフォルト: nosniff
- MIMEタイプスニッフィング防止

### X-XSS-Protection

- Railsデフォルトで設定済み

---

## 11. データベースセキュリティ

### PostgreSQL認証

- パスワード認証有効
- 環境変数管理

### データベース接続制限

- VPS内からのみ接続可能
- `pg_hba.conf`設定済み

### データバックアップ

- cron設定で毎日深夜3時に自動バックアップ
- 7日間保持
- 詳細: [バックアップ設定](../operations/backup.md)

---

## 12. ユーザー入力の制限

### ユーザー名変更制限

- 24時間冷却期間（`username_changed_at`カラム）
- 予約語チェック（100+ の予約語、`config/initializers/reserved_usernames.rb`）

### Mass Assignment対策

- Strong Parameters使用
- 実装確認: 各コントローラー

### Open Redirect対策

- ログアウト時: `allow_other_host: false`
- Google認証後: `root_path`（固定）

---

## 13. その他のセキュリティ対策

### モダンブラウザのみ許可

- `allow_browser versions: :modern`
- 古いブラウザの脆弱性を回避

### DNS Rebinding保護

- Rails 8デフォルトで有効
- `config.hosts`設定（コメントアウト状態）

---

## 定期的な確認事項

### 毎月

- `bundle exec bundler-audit check`
- `bundle exec brakeman`
- `bundle update`（セキュリティパッチ）

### 毎週

- 本番ログの確認
- 異常なアクセスパターンのチェック

### デプロイ前

- Rubocop実行
- Brakeman実行
- テスト実行

---

## 将来的な検討事項

### Rate Limiting（レート制限）

**推奨ツール**: Rack::Attack

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

## 関連ドキュメント

- [運用・監視](../operations/monitoring.md)
- [バックアップ設定](../operations/backup.md)
