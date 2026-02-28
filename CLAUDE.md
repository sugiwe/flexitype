# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## プロジェクト概要

**Typnix（タイプニックス）** - 分割型キーボード向けタイピング練習アプリ

分割型・カラムスタッガード配列キーボード（Cornix等）のタイピング練習を支援するWebアプリケーション。
ユーザーが自分専用のキーマップで練習し、レイヤー機能に慣れることを目的とする。

**本番環境**: https://typnix.com

---

## 技術スタック

- **Ruby**: 3.4.4
- **Rails**: 8.1.1
- **Database**: PostgreSQL
- **Frontend**: Hotwire (Turbo + Stimulus), Slim, Tailwind CSS v4
- **Authentication**: Google OAuth (google-id-token gem)
- **Deployment**: Kamal (さくらVPS)
- **Domain**: typnix.com (SSL/TLS対応)

---

## 開発コマンド

```bash
# セットアップ
bin/setup

# 開発サーバー起動
bin/dev

# テスト実行
bundle exec rspec

# 品質チェック
bundle exec rubocop
bundle exec brakeman --no-pager

# デプロイ（自動テスト付き）
./bin/deploy

# デプロイ（緊急時、テストスキップ）
kamal deploy
```

---

## URL設計

### 公開ページ

- `/` - トップページ（レッスン一覧）
- `/lessons/:id` - レッスンページ
- `/@:username` - ユーザープロフィール
- `/shares/:token` - シェアページ
- `/terms` - 利用規約
- `/privacy` - プライバシーポリシー
- `/about` - About

### 個人ページ（`/my/*`）

- `/my` - マイページ
- `/my/account/edit` - アカウント設定
- `/my/keymaps` - キーマップ一覧
- `/my/keymaps/:slug/edit` - キーマップ編集
- `/my/history` - 練習履歴

### 管理者ページ（`/admin/*`）

- `/admin` - 管理者ダッシュボード
- `/admin/users` - ユーザー一覧
- `/admin/allowed_emails` - 許可メール管理

---

## ディレクトリ構造

```
app/
├── controllers/
│   ├── admin/              # 管理者機能
│   ├── my/                 # 個人ページ
│   └── ...
├── models/                 # モデル
├── views/                  # Slimテンプレート
└── javascript/
    └── controllers/        # Stimulusコントローラー

config/
├── deploy.yml              # Kamalデプロイ設定
├── default_keymaps/        # デフォルトキーマップ（YAML）
├── initializers/
│   ├── keyboard_types.rb   # キーボードタイプ定義
│   └── reserved_usernames.rb # 予約語リスト
└── routes.rb

docs/
├── design/                 # 設計ドキュメント
├── operations/             # 運用ドキュメント
├── development/            # 開発ドキュメント
├── future/                 # 将来実装予定の設計
└── archive/                # 日付付きドキュメント（記録）

spec/
├── factories/              # FactoryBot
├── models/                 # モデルテスト
└── system/                 # システムテスト（E2E）
```

---

## ドキュメント索引

### 設計ドキュメント

- [機能仕様](docs/design/features.md) - 実装済み機能の詳細
- [キーボードタイプ設計](docs/design/keyboard_types.md) - キーボードレイアウト対応
- [セキュリティ設計](docs/design/security.md) - セキュリティ対策

### 運用ドキュメント

- [デプロイガイド](docs/operations/deployment.md) - 初回セットアップ〜日常的なデプロイ
- [バックアップ設定](docs/operations/backup.md) - DB自動バックアップ
- [監視設定](docs/operations/monitoring.md) - Sentryエラートラッキング
- [運用・メンテナンス](docs/operations/maintenance.md) - 安定稼働のための施策

### 開発ドキュメント

- [テスト戦略](docs/development/testing.md) - RSpec、モデル・システムテスト
- [コード品質](docs/development/code_quality.md) - RuboCop、Brakeman、規約
- [国際化対応](docs/development/i18n.md) - 日英バイリンガル対応（将来実装）

### 将来実装予定

- [Vial連携](docs/future/vial_integration.md) - Vial形式キーマップインポート
- [指配置カスタマイズ](docs/future/finger_assignment.md) - 指配置の柔軟なカスタマイズ

---

## 開発方針

### RESTful設計

- Rails wayに沿った実装
- リソースベースで表現、CRUD操作を基本とする

### Viewファースト開発

- ビューを先に作り、完成イメージを明確にする
- モデル・コントローラは必要になったタイミングで実装

### セキュリティ重視

- Brakeman 0警告を維持
- Strong Parameters、CSRF対策、XSS対策
- 環境変数管理（credentials.yml.enc、.kamal/secrets）

### テスト駆動

- 「あるべき姿」をテストで定義し、実装を合わせる
- RSpec: 158 examples, 0 failures, 30 pending
- RuboCop: 0 offenses
- Brakeman: 0 warnings

---

## Git運用

### ブランチ戦略

- **main**: 本番環境と同期
- **feature/**: 新機能開発
- **bugfix/**: バグ修正
- **refactor/**: リファクタリング

**必ずブランチを切って作業**（mainへの直接コミット禁止）

### コミットメッセージ

日本語で、変更内容を明確に記述：

```
Google 認証機能の実装を完了

- SessionsControllerを作成
- IDトークン検証ロジックを追加
- ログイン/ログアウト機能を実装

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>
```

### デプロイ前チェック

```bash
# 自動実行される（./bin/deploy使用時）
bundle exec rspec
bundle exec rubocop
bundle exec brakeman --no-pager
```

---

## 主要機能

1. **ユーザー認証**: Google OAuth、許可メールリスト制
2. **キーマップ管理**: 複数管理、6レイヤー、キーボードタイプ対応
3. **タイピング練習**: レッスンシステム、指ガイド、レイヤー自動判定
4. **練習履歴**: 無制限保存、期間フィルター、統計表示
5. **成績評価**: 5段階カワウソグレード（正答率 × WPM）
6. **シェア機能**: X/Twitter連携、OGP対応
7. **管理者ダッシュボード**: ユーザー統計、人気レッスンランキング
8. **レスポンシブ対応**: モバイル・PC両対応、ダークモード

詳細: [機能仕様](docs/design/features.md)

---

## データモデル

### User

ユーザー情報（Google OAuth認証）

- google_uid, email, name, icon_url
- username（24時間変更制限、予約語チェック）
- admin判定、ログイン追跡

### KeymapSet / Keymap

キーマップ管理（複数セット、6レイヤー）

- slug自動生成、keyboard_type対応
- デフォルトキーマップ自動コピー

### Category / Lesson

レッスンシステム（タブ化、公開制御）

- items (JSONB配列)、visible_toスコープ
- premium、requires_login フラグ

### LessonRecord

練習履歴（無制限保存）

- WPM自動計算、5段階グレード判定
- 期間フィルター、統計情報

### Share

シェア機能（X/Twitter連携）

- token自動生成、OGP対応ランディングページ
- delegate パターン（lesson_record → lesson → category）

### AllowedEmail

許可メール管理（ベータ版）

- フィーチャーフラグ（RESTRICT_LOGIN）で制御
- 管理者画面CRUD

---

## よく使うKamalコマンド

```bash
# デプロイ
kamal deploy

# アプリ再起動
kamal app restart

# ログ確認
kamal app logs -f

# Railsコンソール
kamal app exec -i 'bin/rails console'

# コンテナ状態確認
kamal app details

# ロールバック
kamal rollback
```

---

## トラブルシューティング

### デプロイが失敗する

```bash
# テストが通らない
bundle exec rspec

# VPS接続確認
ssh ubuntu@153.120.65.157
```

### アプリが起動しない

```bash
# ログ確認
kamal app logs --lines 500

# コンテナ再起動
kamal app restart
```

### データベース接続エラー

```bash
# PostgreSQL状態確認
ssh ubuntu@153.120.65.157
sudo systemctl status postgresql
```

詳細: [デプロイガイド](docs/operations/deployment.md)

---

## セキュリティ

- **Brakeman**: 0 warnings
- **bundler-audit**: 0 vulnerabilities
- **HTTPS**: Full SSL (Let's Encrypt)
- **CSRF保護**: Rails標準
- **XSS対策**: 自動HTMLエスケープ
- **SQL Injection対策**: Active Record使用

詳細: [セキュリティ設計](docs/design/security.md)

---

## 参考リンク

- [Kamal公式ドキュメント](https://kamal-deploy.org/)
- [Rails Guides](https://guides.rubyonrails.org/)
- [Hotwire](https://hotwired.dev/)
