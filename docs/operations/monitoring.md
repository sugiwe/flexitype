# Sentry導入ガイド

**作成日:** 2025-01-04
**目的:** 本番環境のエラーをリアルタイムで検知し、ユーザー影響を最小化する

---

## Sentryとは

Sentryは、アプリケーションのエラートラッキング（監視）サービスです。

**主な機能:**
- エラーの自動検知とリアルタイム通知
- スタックトレース（エラー発生箇所）の詳細表示
- ユーザー情報やリクエスト情報の記録
- エラーの発生頻度やトレンドの可視化
- パフォーマンス監視（レスポンスタイムなど）

**無料プラン:**
- 月間5,000エラーまで無料
- 小規模アプリには十分

---

## セットアップ手順

### 1. Sentryアカウント作成

1. https://sentry.io/ にアクセス
2. 「Get Started」をクリック
3. GitHubアカウントでサインアップ（推奨）
4. 無料プラン（Developer）を選択

### 2. プロジェクト作成

1. 「Create Project」をクリック
2. プラットフォーム選択: **Rails** を選択
3. プロジェクト名: `typnix-production`
4. チーム: デフォルトでOK
5. 「Create Project」をクリック

### 3. DSN（Data Source Name）を取得

プロジェクト作成後、以下のような画面が表示されます:

```
DSN: https://xxxxxxxxxxxxxxxxxxxxxxxxxx@o123456.ingest.sentry.io/7890123
```

このDSNをコピーしておきます。

---

## 環境変数設定

### ローカル環境（テスト用、任意）

```bash
# .env ファイルを作成（ローカル環境でテストする場合のみ）
echo "SENTRY_DSN=https://xxxxxxxxxxxxxxxxxxxxxxxxxx@o123456.ingest.sentry.io/7890123" >> .env
```

**注意:** `.env` ファイルは `.gitignore` に含まれているため、Gitにコミットされません。

### 本番環境（VPS）

```bash
# VPSにSSH接続
ssh ubuntu@153.120.65.157

# .kamal/secrets ファイルを編集
nano ~/.kamal/secrets

# 以下の行を追加（既存の内容は残す）
SENTRY_DSN=https://xxxxxxxxxxxxxxxxxxxxxxxxxx@o123456.ingest.sentry.io/7890123

# 保存して終了（Ctrl+X → Y → Enter）
```

**重要:** `.kamal/secrets` ファイルは秘密情報を含むため、絶対にGitにコミットしないでください。

---

## デプロイ

環境変数を設定したら、デプロイします:

```bash
# ローカル環境で実行
./bin/deploy
```

または

```bash
kamal deploy
```

---

## 動作確認

### 1. テストエラーを発生させる

Railsコンソールでテストエラーを発生させます:

```bash
# ローカル環境で実行
kamal app exec bin/rails console

# Railsコンソール内で実行
Sentry.capture_message("Test message from Typnix!")

# 終了
exit
```

### 2. Sentryダッシュボードで確認

1. https://sentry.io/ にログイン
2. プロジェクト「typnix-production」を選択
3. 「Issues」タブで「Test message from Typnix!」が表示されることを確認

### 3. 本番環境でエラーを確認

本番環境で実際にエラーが発生すると、Sentryに自動的に記録されます。

**確認手順:**
1. Sentryダッシュボードの「Issues」タブを開く
2. エラー一覧が表示される
3. エラーをクリックすると詳細情報が表示される
   - スタックトレース
   - リクエスト情報（URL、HTTPメソッド、パラメータ）
   - ユーザー情報（ログインユーザーの場合）
   - ブレッドクラム（エラー発生前の操作履歴）

---

## Sentryの設定

### エラー通知設定

1. Sentryダッシュボードで「Settings」→「Alerts」を開く
2. 「Create Alert Rule」をクリック
3. 通知条件を設定:
   - **条件:** 新しいエラーが発生したとき
   - **通知先:** メール、Slack、Discordなど
4. 「Save Rule」をクリック

**推奨設定:**
- 新しいエラーが発生したときにメール通知
- 同じエラーが10回発生したときに通知

### 通知先の追加（Slack連携など）

1. Sentryダッシュボードで「Settings」→「Integrations」を開く
2. Slackを選択して「Install」
3. Slack Workspaceを選択して認証
4. 通知先のチャンネルを選択

---

## トラブルシューティング

### エラーがSentryに記録されない場合

**原因1: DSNが設定されていない**

```bash
# 環境変数を確認
kamal app exec printenv | grep SENTRY_DSN

# 出力例:
# SENTRY_DSN=https://xxxxxxxxxxxxxxxxxxxxxxxxxx@o123456.ingest.sentry.io/7890123
```

設定されていない場合は、`.kamal/secrets` に追加して再デプロイ。

**原因2: 本番環境でのみ有効化されている**

Sentryは本番環境でのみ有効化されています。ローカル環境では動作しません。

```ruby
# config/initializers/sentry.rb
config.enabled_environments = %w[production]
```

**原因3: 除外設定に該当している**

404エラー（`ActionController::RoutingError`）やレコードが見つからない（`ActiveRecord::RecordNotFound`）は除外されています。

```ruby
# config/initializers/sentry.rb
config.excluded_exceptions += [
  "ActionController::RoutingError",
  "ActiveRecord::RecordNotFound"
]
```

### エラー通知が多すぎる場合

**対処法1: サンプリングレートを下げる**

```ruby
# config/initializers/sentry.rb
config.traces_sample_rate = 0.5  # 50%のエラーのみ送信
```

**対処法2: 特定のエラーを除外**

```ruby
# config/initializers/sentry.rb
config.excluded_exceptions += [
  "YourCustomError"
]
```

---

## パフォーマンス監視（オプション）

Sentryはパフォーマンス監視（APM: Application Performance Monitoring）にも対応しています。

**現在の設定:**
- 10%のリクエストのみ追跡（`config.traces_sample_rate = 0.1`）
- レスポンスタイムやデータベースクエリの実行時間を記録

**パフォーマンス監視を無効化する場合:**

```ruby
# config/initializers/sentry.rb
config.traces_sample_rate = 0.0  # パフォーマンス監視を無効化
```

---

## リリースバージョンの追跡

現在の設定では、環境変数 `GIT_COMMIT_SHA` を使用してリリースバージョンを追跡しています。

**Kamalでの設定方法:**

```yaml
# config/deploy.yml
env:
  clear:
    GIT_COMMIT_SHA: <%= `git rev-parse HEAD`.strip %>
```

これにより、デプロイ時のGitコミットハッシュがSentryに記録され、どのバージョンでエラーが発生したかを追跡できます。

---

## セキュリティとプライバシー

### 個人情報の送信を防ぐ

現在の設定では、個人情報（PII: Personally Identifiable Information）は送信されません:

```ruby
# config/initializers/sentry.rb
config.send_default_pii = false
```

**送信される情報:**
- エラーメッセージ
- スタックトレース
- リクエストURL
- HTTPメソッド
- ユーザーエージェント

**送信されない情報:**
- メールアドレス
- パスワード
- セッション情報

### 機密情報のマスキング

パラメータに機密情報が含まれる場合は、自動的にマスキングされます:

```ruby
# config/initializers/filter_parameter_logging.rb
Rails.application.config.filter_parameters += [
  :password, :password_confirmation, :secret, :token
]
```

---

## まとめ

**Sentry導入のメリット:**
1. ✅ エラーをリアルタイムで検知
2. ✅ ユーザーに影響が出る前に修正可能
3. ✅ スタックトレースで原因を素早く特定
4. ✅ エラーの発生頻度やトレンドを可視化

**次のステップ:**
1. Sentryアカウントを作成
2. DSNを `.kamal/secrets` に追加
3. デプロイ
4. Sentryダッシュボードでエラーを監視

**定期的な確認（週1回推奨）:**
- Sentryダッシュボードでエラー一覧を確認
- 新しいエラーが発生していないか確認
- 発生頻度の高いエラーを優先的に修正

**最終更新:** 2025-01-04
