# Typnix（タイプニックス）

垂直配列タイピング練習アプリ

## 概要

Typnixは、Cornixなどの分割型・カラムスタッガード配列キーボードのタイピング練習を支援するWebアプリケーションです。

### 主な機能

- **カスタムキーマップ登録**: 自分専用のキーマップを登録して練習できます
- **レイヤー対応**: 最大6レイヤー（Layer 0-5）に対応
- **リアルタイムガイド**: 次に押すべきキーと指をリアルタイムでハイライト表示
- **多彩なレッスン**: 10カテゴリ・20+レッスンから選択可能
- **Google認証**: 安全なGoogle Identity Servicesを使用
- **ダークモード**: Light/Dark/Systemの3つのテーマから選択可能

## 技術スタック

### バックエンド
- Ruby 3.4.4
- Rails 8.1.1
- PostgreSQL
- Google Identity Services (google-id-token gem)

### フロントエンド
- Slim テンプレートエンジン
- Tailwind CSS v4
- Hotwire (Turbo + Stimulus)

### インフラ
- Kamal (デプロイツール)
- Docker
- さくらVPS

## 開発環境セットアップ

### 必要な環境
- Ruby 3.4.4
- PostgreSQL
- Node.js (Tailwind CSSビルド用)

### 初期セットアップ

```bash
# 依存関係のインストール
bundle install

# データベースのセットアップ
rails db:create
rails db:migrate

# 開発サーバーの起動
bin/dev
```

ブラウザで `http://localhost:3000` にアクセス。

### Google認証の設定

1. [Google Cloud Console](https://console.cloud.google.com/) でプロジェクトを作成
2. OAuth 2.0クライアントIDを作成（Webアプリケーション）
3. 認証情報を暗号化ファイルに保存：

```bash
rails credentials:edit
```

以下の内容を追加：

```yaml
google:
  client_id: YOUR_CLIENT_ID
  client_secret: YOUR_CLIENT_SECRET
```

4. 開発環境では環境変数 `ALLOWED_EMAILS` を設定（任意）：

```bash
export ALLOWED_EMAILS="your-email@example.com"
```

## デプロイ

本番環境へのデプロイ方法については、[デプロイガイド](docs/deployment_guide.md)を参照してください。

### クイックスタート

```bash
# デプロイ前チェック
./scripts/pre_deploy_check.sh

# 初回デプロイ
kamal setup

# 2回目以降のデプロイ
kamal deploy
```

詳細は [docs/deployment_guide.md](docs/deployment_guide.md) を確認してください。

## 開発ガイドライン

開発に関する詳細な仕様やルールは、[CLAUDE.md](CLAUDE.md)を参照してください。

### 主なルール

- **ブランチ運用**: 必ずブランチを切って作業（mainへの直接コミット禁止）
- **コミット**: 意味のある単位で分割、日本語でメッセージを記述
- **プッシュ前チェック**: RuboCopとBrakemanを実行

```bash
# コード品質チェック
bundle exec rubocop

# セキュリティチェック
bundle exec brakeman --no-pager
```

## プロジェクト構造

```
flexitype/
├── app/
│   ├── controllers/      # コントローラー
│   ├── models/           # モデル
│   ├── views/            # Slimテンプレート
│   └── javascript/       # Stimulusコントローラー
├── config/
│   ├── deploy.yml        # Kamalデプロイ設定
│   ├── database.yml      # DB設定
│   └── typing_words.yml  # タイピング練習用単語データ
├── docs/
│   ├── deployment_guide.md    # デプロイガイド
│   └── daily_reports/         # 日報
└── scripts/
    ├── pre_deploy_check.sh    # デプロイ前チェック
    └── vps_setup.sh           # VPS初期セットアップ
```

## 開発者向け情報

### プロジェクトの性質

このプロジェクトは、Ruby/Railsの学習と実践を目的として開発されています。プライベートリポジトリとして管理され、許可されたメンバーのみがアクセス可能です。

### コントリビューション

開発に参加する場合は、以下のガイドラインに従ってください：

- [CLAUDE.md](CLAUDE.md)の開発ルールを遵守
- ブランチ運用ルールに従った開発フロー
- プッシュ前のRuboCop・Brakemanチェック必須

### バグ報告・機能要望

バグ報告や機能要望は、GitHubのIssueまたはプロジェクトメンバーへの直接連絡でお願いします。
