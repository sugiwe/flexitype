# Rails Application Development Guide - Typnixプロジェクトから学ぶ実践的知識

**最終更新**: 2025-12-30
**対象読者**: Rails中級者〜上級者、実践的な設計を学びたい方
**推定読了時間**: 2〜3時間
**参照プロジェクト**: Typnix (Flexitype) - タイピング練習アプリ

---

## 📚 このガイドについて

このガイドは、29日間で開発・本番デプロイまで完了したTypnix（タイピング練習アプリ）プロジェクトから抽出した、Rails開発の実践的知識を体系的にまとめたものです。

**特徴:**
- 実際の本番稼働アプリケーションから抽出した知見
- 単なる理論ではなく、実装済みコードとその設計判断の背景を説明
- アンチパターンとベストプラクティスの対比
- Rails 8.1.1 + Hotwire (Turbo + Stimulus) の最新構成

**関連ドキュメント:**
- [CLAUDE.md](/CLAUDE.md) - プロジェクト全体の仕様書
- [CLAUDE_FEATURES.md](/CLAUDE_FEATURES.md) - 実装済み機能の詳細
- [日報](/docs/daily_reports/) - 29日間の開発記録

---

## 目次

1. [Rails基礎とプロジェクト設計](#chapter-1-rails基礎とプロジェクト設計)
2. [プロジェクト構造とディレクトリ設計](#chapter-2-プロジェクト構造とディレクトリ設計)
3. [データベース設計とモデル層](#chapter-3-データベース設計とモデル層)
4. [ルーティングとURL設計](#chapter-4-ルーティングとurl設計)
5. [コントローラーとビジネスロジック](#chapter-5-コントローラーとビジネスロジック)
6. [ビュー層の設計](#chapter-6-ビュー層の設計)
7. [Hotwire (Turbo + Stimulus)](#chapter-7-hotwire-turbo--stimulus)
8. [認証と認可](#chapter-8-認証と認可)
9. [テスト戦略](#chapter-9-テスト戦略)
10. [セキュリティ](#chapter-10-セキュリティ)
11. [デプロイと運用](#chapter-11-デプロイと運用)
12. [保守とリファクタリング](#chapter-12-保守とリファクタリング)

---

# Chapter 1: Rails基礎とプロジェクト設計

## 1.1 Rails Wayとは何か

### Convention over Configuration (CoC)

Railsの最も重要な哲学は「設定より規約」です。これは、開発者が設定ファイルを書く代わりに、Railsの規約に従うことで多くの動作が自動化されることを意味します。

**Typnixでの実践例:**

```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_many :lesson_records, dependent: :destroy
  has_many :keymaps, through: :keymap_sets
end
```

この単純なコードで以下が自動的に実現されます:
- `users`テーブルとの自動マッピング
- `lesson_records`テーブルとの関連付け（`user_id`カラムを探す）
- `dependent: :destroy`でユーザー削除時の関連レコード削除

**規約を守ることで得られるもの:**
- コード量の削減
- 可読性の向上（他のRails開発者が理解しやすい）
- Railsの機能との親和性（ジェネレーター、マイグレーションなど）

### RESTful設計の基本

Railsは**RESTful**（Representational State Transfer）なURL設計を推奨します。

**7つの標準アクション:**

| HTTP動詞 | パス | アクション | 用途 |
|---------|------|----------|------|
| GET | `/lessons` | index | 一覧表示 |
| GET | `/lessons/new` | new | 新規作成フォーム |
| POST | `/lessons` | create | 新規作成処理 |
| GET | `/lessons/:id` | show | 詳細表示 |
| GET | `/lessons/:id/edit` | edit | 編集フォーム |
| PATCH/PUT | `/lessons/:id` | update | 更新処理 |
| DELETE | `/lessons/:id` | destroy | 削除処理 |

**Typnixでの実装例:**

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # RESTfulな基本設計
  resources :lessons, only: [ :index, :show ]

  # 名前空間でグルーピング
  namespace :my do
    resources :lessons, only: [ :index, :new, :create, :edit, :update, :destroy ]
    resources :keymaps, only: [ :index, :edit, :update ]
    resources :history, only: [ :index ], controller: "lesson_records"
  end

  namespace :admin do
    resources :users, only: [ :index, :show ]
    resources :categories
  end
end
```

**設計のポイント:**
- 公開ページ（`/lessons`）は閲覧のみ（index, show）
- 個人ページ（`/my`配下）は認証必須でCRUD操作
- 管理者ページ（`/admin`配下）は管理者権限必須

### DRY原則（Don't Repeat Yourself）

**アンチパターン:**

```ruby
# ❌ 悪い例: コードの重複
class LessonRecordsController < ApplicationController
  def create
    @lesson_record = current_user.lesson_records.build(lesson_record_params)
    @lesson_record.completed_at = Time.current
    if @lesson_record.save
      render json: { success: true, message: "練習履歴を保存しました" }
    else
      render json: { success: false, errors: @lesson_record.errors.full_messages }
    end
  end

  private

  def lesson_record_params
    params.require(:lesson_record).permit(:lesson_id, :accuracy, :wpm, ...)
  end
end

class My::LessonRecordsController < My::ApplicationController
  def create
    # 👆と全く同じコード...
  end
end
```

**ベストプラクティス（Concernパターン）:**

```ruby
# ✅ 良い例: Concernで共通化
# app/controllers/concerns/lesson_record_creation.rb
module LessonRecordCreation
  extend ActiveSupport::Concern

  private

  def create_lesson_record_for(user)
    @lesson_record = user.lesson_records.build(lesson_record_params)
    @lesson_record.completed_at = Time.current

    if @lesson_record.save
      render json: { success: true, message: "練習履歴を保存しました", lesson_record_id: @lesson_record.id }
    else
      render json: { success: false, errors: @lesson_record.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def lesson_record_params
    params.require(:lesson_record).permit(
      :lesson_id, :lesson_name, :word_count, :correct_count,
      :mistake_count, :accuracy, :duration_seconds, :typed_chars
    )
  end
end

# app/controllers/lesson_records_controller.rb
class LessonRecordsController < ApplicationController
  include LessonRecordCreation

  def create
    user = logged_in? ? current_user : User.find_by!(username: "guest")
    create_lesson_record_for(user)
  end
end

# app/controllers/my/lesson_records_controller.rb
class My::LessonRecordsController < My::ApplicationController
  include LessonRecordCreation

  def create
    create_lesson_record_for(current_user)
  end
end
```

**DRY化の効果:**
- 元のコード: 約30行 × 2箇所 = 60行
- リファクタリング後: Concern 20行 + 各コントローラー 3行 × 2 = 26行
- **削減率: 約57%**

### Fat Model, Skinny Controller

ビジネスロジックはモデルに集約し、コントローラーは薄く保つのがRails wayです。

**アンチパターン:**

```ruby
# ❌ 悪い例: コントローラーにビジネスロジック
class My::LessonRecordsController < My::ApplicationController
  def index
    @lesson_records = current_user.lesson_records.order(completed_at: :desc)

    # 正答率の平均を計算
    total_accuracy = 0
    @lesson_records.each do |record|
      total_accuracy += record.accuracy
    end
    @average_accuracy = @lesson_records.any? ? (total_accuracy / @lesson_records.count).round(1) : 0

    # WPMの平均を計算
    wpm_records = @lesson_records.select { |r| r.wpm.present? }
    total_wpm = 0
    wpm_records.each do |record|
      total_wpm += record.wpm
    end
    @average_wpm = wpm_records.any? ? (total_wpm / wpm_records.count).round(1) : 0
  end
end
```

**ベストプラクティス:**

```ruby
# ✅ 良い例: モデルにビジネスロジック
# app/models/lesson_record.rb
class LessonRecord < ApplicationRecord
  scope :recent, -> { order(completed_at: :desc) }

  def self.average_accuracy
    average(:accuracy)&.round(1) || 0
  end

  def self.average_wpm
    where.not(wpm: nil).average(:wpm)&.round(1) || 0
  end
end

# app/controllers/my/lesson_records_controller.rb
class My::LessonRecordsController < My::ApplicationController
  def index
    @lesson_records = current_user.lesson_records.recent.page(params[:page]).per(20)
    @average_accuracy = current_user.lesson_records.average_accuracy
    @average_wpm = current_user.lesson_records.average_wpm
  end
end
```

**メリット:**
- コントローラーが薄く、読みやすい
- ビジネスロジックのテストがモデル単体で可能
- 他のコントローラーでも再利用可能

## 1.2 プロジェクトの初期設計

### 技術スタック選定の考え方

**Typnixの技術スタック:**

| レイヤー | 技術 | 選定理由 |
|---------|------|----------|
| Backend | Rails 8.1.1 | 最新の安定版、Turboの改善 |
| DB | PostgreSQL | JSON型サポート、本番での信頼性 |
| Frontend | Hotwire (Turbo + Stimulus) | SPAライクなUX、JS最小化 |
| CSS | Tailwind CSS v4 | ユーティリティファースト、高速開発 |
| Template | Slim | HTMLより簡潔、可読性高い |
| Deploy | Kamal | Docker化、VPSへの簡単デプロイ |
| Auth | Google Identity Services | 自前実装不要、信頼性高い |

**選定時の重要ポイント:**

1. **学習曲線**: 新しい技術は学習コストを考慮
2. **エコシステム**: コミュニティ、ドキュメント、Gem の充実度
3. **将来性**: メンテナンスされているか、枯れていないか
4. **本番運用**: 実績、パフォーマンス、セキュリティ

**Typnixで避けた技術とその理由:**

- **Devise**: 認証機能が過剰、Google認証のみで十分
- **React/Vue**: Hotwireで十分なUXが実現可能
- **Heroku**: コスト高、VPS（さくら）で十分

### 開発フローとブランチ戦略

**Typnixのブランチ運用:**

```
main
  ├─ feature/google-authentication-setup
  ├─ feature/lesson-db-migration
  ├─ bugfix/keymap-backslash-input
  └─ refactor/lesson-controller-naming
```

**ブランチ命名規則:**
- `feature/機能名`: 新機能追加
- `bugfix/バグ内容`: バグ修正
- `refactor/対象`: リファクタリング

**運用ルール:**
1. **mainブランチへの直接コミット禁止**（ドキュメントのみ例外）
2. PR作成 → レビュー → マージ
3. リモートプッシュ前の品質チェック:
   ```bash
   bundle exec rubocop          # コード品質
   bundle exec brakeman --no-pager  # セキュリティ
   bundle exec rspec            # テスト
   ```

### View ファーストな開発アプローチ

Typnixでは**View ファースト**な開発を採用しました。これは、まずビューを作成してブラウザで確認しながら、必要なモデル・コントローラーを後から実装する手法です。

**メリット:**
- 完成イメージが明確になる
- モチベーション向上（視覚的フィードバック）
- Tailwind CSSとの相性が良い（デザインをコードで直接書ける）
- 必要なデータ構造が自然に見えてくる

**実践例:**

```slim
/ 1. まずビューを作成（ダミーデータでOK）
/ app/views/lessons/show.html.slim
.container
  h1.text-2xl.font-bold = "Ruby基礎レッスン"

  .mt-4
    - words = ["def", "class", "module", "end"]
    - words.each do |word|
      .p-2.border.rounded = word

  button.mt-4.px-4.py-2.bg-blue-500.text-white.rounded
    | 練習開始

/ 2. ブラウザで確認しながら調整

/ 3. 必要なモデル・コントローラーを実装
/ app/models/lesson.rb
class Lesson < ApplicationRecord
  has_many :items, class_name: "LessonItem"
end
```

## 1.3 データ設計の基本方針

### JSONBを活用した柔軟な設計

PostgreSQLのJSONB型を使うことで、スキーマを頻繁に変更せずに柔軟なデータ構造を実現できます。

**Typnixでの活用例:**

```ruby
# app/models/lesson.rb
class Lesson < ApplicationRecord
  # items カラムは JSONB 型
  # [
  #   { "type": "word", "content": "def", "layer": 0 },
  #   { "type": "phrase", "content": "Hello, World!", "layer": 0 }
  # ]

  validates :items, presence: true
  validate :items_structure

  private

  def items_structure
    return if items.blank?
    return unless items.is_a?(Array)

    items.each do |item|
      unless item.is_a?(Hash) && item["type"].present? && item["content"].present?
        errors.add(:items, "must be an array of objects with type and content")
      end
    end
  end
end
```

**JSONB型のメリット:**
- スキーマレスで柔軟
- インデックスを貼れる（検索可能）
- PostgreSQLの豊富なJSON関数が使える

**JSONB型のデメリット:**
- 型安全性が低い（バリデーションが重要）
- リレーションが使えない
- 複雑なクエリが難しい

**使い分けの基準:**

- **JSONB を使う**: 構造が変化しやすい、ネストしたデータ、メタデータ
- **通常のカラム を使う**: リレーション、検索頻度が高い、型安全性が重要

### 削除戦略: 物理削除 vs 論理削除

**物理削除（Typnixの選択）:**

```ruby
class User < ApplicationRecord
  has_many :lesson_records, dependent: :destroy
  has_many :keymap_sets, dependent: :destroy
end
```

**メリット:**
- データベースが肥大化しない
- GDPR対応（完全削除）
- シンプル

**デメリット:**
- 復元不可
- 統計データが失われる可能性

**論理削除（`deleted_at`カラム）:**

```ruby
class User < ApplicationRecord
  # deleted_at カラムを追加
  scope :active, -> { where(deleted_at: nil) }

  def soft_delete
    update(deleted_at: Time.current)
  end
end
```

**メリット:**
- 復元可能
- 統計データを保持
- 監査ログとして活用

**デメリット:**
- データベース肥大化
- クエリが複雑化（常に`deleted_at IS NULL`を考慮）
- ユニーク制約が複雑化

**Typnixの判断:**
- ユーザーデータ: 物理削除（GDPR対応、シンプルさ優先）
- 練習履歴: 無制限保存（統計データとして重要）

---

# Chapter 2: プロジェクト構造とディレクトリ設計

## 2.1 Railsの標準ディレクトリ構造

### app/ ディレクトリ

```
app/
├── assets/           # アセット（画像、CSS、JSの一部）
├── channels/         # ActionCable（WebSocket）
├── controllers/      # コントローラー層
│   ├── concerns/     # 共通ロジック（Concern）
│   ├── admin/        # 管理者コントローラー
│   └── my/           # 個人ページコントローラー
├── helpers/          # ビューヘルパー
├── javascript/       # JavaScriptコード（Stimulus）
├── models/           # モデル層
│   └── concerns/     # モデルConcern
├── views/            # ビュー層
│   ├── layouts/      # レイアウトファイル
│   ├── shared/       # 共通パーシャル
│   ├── admin/        # 管理者ビュー
│   └── my/           # 個人ページビュー
└── mailers/          # メーラー
```

### config/ ディレクトリ

```
config/
├── application.rb    # アプリケーション設定
├── database.yml      # DB接続設定
├── routes.rb         # ルーティング定義
├── credentials.yml.enc  # 暗号化された秘密情報
├── environments/     # 環境別設定
│   ├── development.rb
│   ├── test.rb
│   └── production.rb
├── initializers/     # 初期化処理
│   ├── assets.rb
│   ├── cors.rb
│   ├── content_security_policy.rb
│   └── reserved_usernames.rb  # カスタム初期化
└── locales/          # 国際化ファイル
    ├── ja.yml
    └── en.yml
```

### Typnixでのカスタマイズ

**カスタム初期化ファイル:**

```ruby
# config/initializers/reserved_usernames.rb
module ReservedUsernames
  RESERVED_LIST = %w[
    admin administrator root system
    support help info contact
    api www mail ftp
    my account settings profile
    about terms privacy policy
    ...
  ].freeze

  def self.reserved?(username)
    RESERVED_LIST.include?(username.to_s.downcase)
  end
end
```

このような初期化ファイルは、アプリケーション起動時に読み込まれ、グローバルに利用可能になります。

## 2.2 名前空間によるコントローラーの整理

### 名前空間の設計方針

**Typnixのコントローラー構成:**

```
app/controllers/
├── application_controller.rb       # 基底コントローラー
├── concerns/
│   └── lesson_record_creation.rb   # 共通ロジック
├── lessons_controller.rb           # 公開レッスン
├── lesson_records_controller.rb    # 公開練習記録（未ログインユーザー）
├── shares_controller.rb            # シェアページ
├── admin/
│   ├── application_controller.rb   # 管理者基底（認証+権限チェック）
│   ├── dashboard_controller.rb
│   ├── users_controller.rb
│   ├── categories_controller.rb
│   └── allowed_emails_controller.rb
└── my/
    ├── application_controller.rb   # 個人ページ基底（認証のみ）
    ├── accounts_controller.rb
    ├── keymaps_controller.rb
    ├── lessons_controller.rb
    └── lesson_records_controller.rb
```

### 継承関係とbefore_action

**基底コントローラーの設計:**

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  helper_method :current_user, :logged_in?

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    current_user.present? && allowed_to_login?
  end

  def allowed_to_login?
    return true unless ENV["RESTRICT_LOGIN"] == "true"
    AllowedEmail.allowed?(current_user.email)
  end

  def require_login
    unless logged_in?
      redirect_to root_path, alert: "ログインが必要です"
    end
  end
end

# app/controllers/my/application_controller.rb
class My::ApplicationController < ApplicationController
  before_action :require_login

  # /my 配下のすべてのコントローラーで認証必須
end

# app/controllers/admin/application_controller.rb
class Admin::ApplicationController < ApplicationController
  before_action :require_login
  before_action :require_admin

  private

  def require_admin
    unless current_user&.admin?
      redirect_to root_path, alert: "管理者権限が必要です"
    end
  end
end
```

**ポイント:**
- `ApplicationController`: 全体で共通のロジック
- `My::ApplicationController`: 認証必須ページの基底
- `Admin::ApplicationController`: 認証+管理者権限必須

### ルーティングとの連携

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # 公開ページ（認証不要）
  root "lessons#index"
  resources :lessons, only: [ :index, :show ]
  resources :lesson_records, only: [ :create ]  # ゲストユーザー対応
  get "shares/:token", to: "shares#show", as: :share

  # 個人ページ（認証必須、My::ApplicationControllerが処理）
  namespace :my do
    get "/", to: "settings#index", as: :root
    resource :account, only: [ :edit, :update ]
    resources :keymaps, only: [ :index, :edit, :update ]
    resources :lessons, except: [ :show ]
    resources :history, only: [ :index ], controller: "lesson_records"
  end

  # 管理者ページ（認証+管理者権限必須）
  namespace :admin do
    get "/", to: "dashboard#index", as: :root
    resources :users, only: [ :index, :show ]
    resources :categories
    resources :allowed_emails
  end

  # 認証
  post "auth/google", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  # ユーザープロフィール（公開）
  get "@:username", to: "users#show", as: :user_profile
end
```

## 2.3 ビューの構造化とパーシャル

### レイアウトファイルの設計

**Typnixのレイアウト構成:**

```
app/views/layouts/
├── application.html.slim        # 全体の基本レイアウト
├── admin.html.slim              # 管理者ページ専用レイアウト
└── partials/
    ├── _head.html.slim          # <head>タグの共通化
    ├── _gtm_noscript.html.slim  # Google Tag Manager
    ├── _header.html.slim        # ヘッダー（モバイル対応）
    └── _footer.html.slim        # フッター
```

**application.html.slimの構成:**

```slim
doctype html
html lang="ja"
  = render "layouts/partials/head", title: content_for?(:title) ? yield(:title) : "Typnix - 分割キーボード特化タイピング練習"

  body class=body_class
    = render "layouts/partials/gtm_noscript"

    = render "layouts/partials/header"

    .flex.min-h-screen
      / サイドバー（PC）
      aside.hidden.md:block.w-80.bg-gray-50.dark:bg-gray-900
        = render "shared/sidebar"

      / メインコンテンツ
      main.flex-1.p-6
        / フラッシュメッセージ
        - if flash[:notice]
          .alert.alert-success = flash[:notice]
        - if flash[:alert]
          .alert.alert-error = flash[:alert]

        = yield

    = render "layouts/partials/footer"
```

**パーシャル化のメリット:**
- `_head.html.slim`を共通化することで、全レイアウトで統一
- OGP設定、Google Analytics設定が1箇所で管理可能
- 変更時の影響範囲が明確

### 共通パーシャルの設計パターン

**local_assignsを使った柔軟なパーシャル:**

```slim
/ app/views/shared/_lesson_records_table.html.slim
- if lesson_records.any?
  .hidden.md:block
    table.w-full.table-auto
      thead.bg-gray-100.dark:bg-gray-800
        tr
          th.px-4.py-2.text-left 日時

          / オプション: ユーザー名カラム
          - if local_assigns[:show_user]
            th.px-4.py-2.text-left ユーザー

          th.px-4.py-2.text-left レッスン
          th.px-4.py-2.text-right 正答率
          th.px-4.py-2.text-right WPM
          th.px-4.py-2.text-left グレード

      tbody
        - lesson_records.each do |record|
          tr.border-t.dark:border-gray-700
            td.px-4.py-2 = record.completed_at.strftime("%Y/%m/%d %H:%M")

            - if local_assigns[:show_user]
              td.px-4.py-2
                = link_to user_profile_path(record.user.username), class: "text-blue-600 hover:underline"
                  = record.user.username

            td.px-4.py-2 = record.lesson_name
            td.px-4.py-2.text-right
              span class="#{record.accuracy >= 95 ? 'text-green-600 font-semibold' : ''}"
                = "#{record.accuracy}%"
            td.px-4.py-2.text-right = record.wpm || "-"
            td.px-4.py-2
              = render "shared/grade_badge", grade: record.grade

  / ページネーション（オプション）
  - if local_assigns[:show_pagination]
    .mt-4
      = paginate lesson_records

- else
  .text-gray-500.text-center.py-8
    | 練習履歴がありません
```

**使用例:**

```slim
/ 管理者ダッシュボード（ユーザー名表示）
= render "shared/lesson_records_table",
  lesson_records: @recent_records,
  show_user: true

/ 個人履歴ページ（ページネーション）
= render "shared/lesson_records_table",
  lesson_records: @lesson_records,
  show_pagination: true

/ 管理者ユーザー詳細（シンプル）
= render "shared/lesson_records_table",
  lesson_records: @user.lesson_records.recent.limit(10)
```

**DRY化の効果（Day 24実装）:**
- 元のコード: 231行（3箇所で重複）
- リファクタリング後: 108行（共通パーシャル）
- **削減率: 53%**

---

# Chapter 3: データベース設計とモデル層

## 3.1 マイグレーション戦略

### 基本的なマイグレーション

**Typnixでの典型的なマイグレーション例:**

```ruby
# db/migrate/20251220123456_create_lessons.rb
class CreateLessons < ActiveRecord::Migration[8.1]
  def change
    create_table :lessons do |t|
      t.references :user, null: true, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.jsonb :items, null: false, default: []
      t.boolean :is_public, default: false, null: false

      t.timestamps
    end

    add_index :lessons, :is_public
    add_index :lessons, :items, using: :gin  # JSONB用のGINインデックス
  end
end
```

**ポイント:**
- `null: false`で必須カラムを明示
- 外部キー制約（`foreign_key: true`）でデータ整合性を保証
- インデックスで検索パフォーマンスを確保
- JSONB型にはGINインデックス

### 3段階マイグレーション戦略

本番環境でのデータ破壊を避けるため、Typnixでは**3段階アプローチ**を採用しました（Day 24実装）。

**背景:**
- `lesson_records.lesson_id`の型を`string`から`bigint`に変更
- 既存データを保持しながら外部キー制約を追加

**Phase 1: データクリーンアップ**

```ruby
# db/migrate/20251224010000_phase1_cleanup_lesson_records.rb
class Phase1CleanupLessonRecords < ActiveRecord::Migration[8.1]
  def up
    # 古いデータ（lesson_idがnilのレコード）を削除
    LessonRecord.where(lesson_id: nil).delete_all

    # lesson_idがstring型の既存データを、数値に変換可能か確認
    LessonRecord.find_each do |record|
      begin
        Integer(record.lesson_id)
      rescue ArgumentError, TypeError
        # 数値に変換できない場合は削除
        record.destroy
      end
    end
  end

  def down
    # ロールバック不要（データクリーンアップのため）
  end
end
```

**Phase 2: スキーマクリーンアップ**

```ruby
# db/migrate/20251224020000_phase2_change_lesson_id_to_bigint.rb
class Phase2ChangeLessonIdToBigint < ActiveRecord::Migration[8.1]
  def up
    # PostgreSQLのキャスト機能を使って型変更
    change_column :lesson_records, :lesson_id, :bigint, using: 'lesson_id::bigint'
  end

  def down
    change_column :lesson_records, :lesson_id, :string
  end
end
```

**Phase 3: データ整合性確保**

```ruby
# db/migrate/20251224030000_phase3_add_constraints_to_lesson_records.rb
class Phase3AddConstraintsToLessonRecords < ActiveRecord::Migration[8.1]
  def change
    # NOT NULL制約
    change_column_null :lesson_records, :lesson_id, false

    # 外部キー制約
    add_foreign_key :lesson_records, :lessons, column: :lesson_id

    # インデックス
    add_index :lesson_records, :lesson_id unless index_exists?(:lesson_records, :lesson_id)
  end
end
```

**3段階アプローチのメリット:**
1. 各ステップでロールバック可能
2. エラーが発生しても影響範囲が限定的
3. 本番環境でのデータ破壊リスクを最小化
4. 各段階で動作確認が可能

### ロールバック可能性の確保

**可逆的なマイグレーション:**

```ruby
# ✅ 良い例: upとdownを明示
class AddUsernameToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :username, :string
    add_index :users, :username, unique: true
  end

  def down
    remove_index :users, :username
    remove_column :users, :username
  end
end
```

**不可逆的なマイグレーション:**

```ruby
# ⚠️ データ削除は不可逆
class RemoveUnusedColumns < ActiveRecord::Migration[8.1]
  def up
    remove_column :users, :old_field
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
```

## 3.2 モデルの設計パターン

### バリデーション

**Typnixの実装例:**

```ruby
# app/models/user.rb
class User < ApplicationRecord
  # 存在チェック
  validates :email, presence: true, uniqueness: true
  validates :google_uid, presence: true, uniqueness: true

  # フォーマットチェック（正規表現）
  validates :username,
    format: {
      with: /\A[a-z0-9]([a-z0-9]|-(?=[a-z0-9])){0,38}\z/,
      message: "は小文字英数字とハイフンのみ使用可能です（先頭・末尾はハイフン不可）"
    },
    allow_nil: true

  # カスタムバリデーション
  validate :username_not_reserved
  validate :username_change_cooldown

  private

  def username_not_reserved
    return if username.blank?
    if ReservedUsernames.reserved?(username)
      errors.add(:username, "は予約されているため使用できません")
    end
  end

  def username_change_cooldown
    return if username_was.nil? || username == username_was
    return if username_changed_at.nil?

    if username_changed_at > 24.hours.ago
      next_change = username_changed_at + 24.hours
      errors.add(:username, "は#{next_change.strftime('%Y/%m/%d %H:%M')}以降に変更可能です")
    end
  end
end
```

**バリデーションの種類:**

| バリデーション | 用途 | 例 |
|--------------|------|-----|
| `presence` | 必須チェック | `validates :email, presence: true` |
| `uniqueness` | 一意性チェック | `validates :email, uniqueness: true` |
| `format` | 正規表現チェック | `validates :username, format: { with: /\A[a-z0-9-]+\z/ }` |
| `length` | 長さチェック | `validates :name, length: { maximum: 50 }` |
| `numericality` | 数値チェック | `validates :age, numericality: { greater_than: 0 }` |
| `inclusion` | 範囲チェック | `validates :status, inclusion: { in: %w[active inactive] }` |
| カスタム | 独自ロジック | `validate :custom_method` |

### 関連付け（Association）

**Typnixのモデル関連図:**

```
User (ユーザー)
  ├── has_many :lesson_records (練習履歴)
  ├── has_many :keymap_sets (キーマップセット)
  │     └── has_many :keymaps (キー配置)
  ├── has_many :lessons (自作レッスン)
  └── has_many :shares (シェア)

Category (カテゴリー)
  └── has_many :lessons

Lesson (レッスン)
  ├── belongs_to :category
  ├── belongs_to :user (optional)
  └── has_many :lesson_records

LessonRecord (練習履歴)
  ├── belongs_to :user
  ├── belongs_to :lesson
  └── has_one :share
```

**実装例:**

```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_many :lesson_records, dependent: :destroy
  has_many :keymap_sets, dependent: :destroy
  has_many :lessons, dependent: :destroy
  has_many :shares, through: :lesson_records
end

# app/models/lesson.rb
class Lesson < ApplicationRecord
  belongs_to :category
  belongs_to :user, optional: true  # 公式レッスンはuser_id = nil

  has_many :lesson_records, dependent: :destroy
end

# app/models/lesson_record.rb
class LessonRecord < ApplicationRecord
  belongs_to :user
  belongs_to :lesson

  has_one :share, dependent: :destroy
end
```

**dependent オプション:**

| オプション | 動作 | 用途 |
|-----------|------|------|
| `:destroy` | 関連レコードも削除（コールバック実行） | 通常はこれ |
| `:delete_all` | 関連レコードを削除（コールバックなし） | パフォーマンス重視 |
| `:nullify` | 外部キーをnullに設定 | 関連を切りたいが削除したくない |
| `:restrict_with_error` | 関連があれば削除を拒否 | 誤削除防止 |

### スコープ（Scope）

**Typnixでの実装例:**

```ruby
# app/models/lesson.rb
class Lesson < ApplicationRecord
  # 公開レッスン（公式 + ユーザー公開レッスン）
  scope :published, -> { joins(:category).where(categories: { published: true }) }

  # ログイン不要レッスン
  scope :public_access, -> {
    published.joins(:category).where(categories: { requires_login: false })
  }

  # 最近作成されたレッスン
  scope :recent, -> { order(created_at: :desc) }

  # 特定ユーザーが閲覧可能なレッスン
  scope :visible_to, ->(user) {
    if user&.admin?
      all  # 管理者は全て閲覧可能
    elsif user
      where("user_id = ? OR (is_public = ? AND categories.published = ?)", user.id, true, true)
        .or(where(user_id: nil, categories: { published: true }))
    else
      public_access  # 未ログインユーザーは公開レッスンのみ
    end
  }
end

# app/models/lesson_record.rb
class LessonRecord < ApplicationRecord
  scope :recent, -> { order(completed_at: :desc) }
  scope :high_accuracy, -> { where("accuracy >= ?", 95) }
  scope :this_week, -> { where("completed_at >= ?", 1.week.ago) }
  scope :this_month, -> { where("completed_at >= ?", 1.month.ago) }

  # メソッドチェーン可能
  # LessonRecord.recent.high_accuracy.this_week
end
```

**スコープのメリット:**
- 複雑なクエリを再利用可能
- メソッドチェーンで組み合わせ可能
- テスト時にモック化しやすい

### delegateパターン

**問題点（Day 21以前）:**

```ruby
# ❌ アンチパターン: 冗長なフラグ管理
class Lesson < ApplicationRecord
  belongs_to :category

  # categoryのフラグをlessonでも持つ（冗長）
  def requires_login?
    category.requires_login
  end

  def premium_only?
    category.premium
  end

  def published?
    category.published
  end
end
```

**ベストプラクティス:**

```ruby
# ✅ delegateで委譲
class Lesson < ApplicationRecord
  belongs_to :category

  delegate :requires_login?, :premium_only?, :published?, to: :category
  delegate :name, to: :category, prefix: true  # category_name として使える
end

# 使用例
lesson.requires_login?  # => category.requires_login? を呼ぶ
lesson.category_name    # => category.name を呼ぶ
```

**delegateのメリット:**
- コード量削減
- 関連モデルのメソッドを直接呼べる
- リファクタリング容易（実装変更に強い）

### コールバック

**Typnixでの実装例:**

```ruby
# app/models/share.rb
class Share < ApplicationRecord
  belongs_to :lesson_record

  # トークン自動生成
  has_secure_token :token

  # コールバック
  after_create :notify_user

  private

  def notify_user
    # シェア作成後の処理（通知など）
    Rails.logger.info "Share created: #{token}"
  end
end

# app/models/user.rb
class User < ApplicationRecord
  # username変更時にタイムスタンプ更新
  before_save :update_username_changed_at, if: :username_changed?

  private

  def update_username_changed_at
    self.username_changed_at = Time.current
  end
end
```

**主要なコールバック:**

| コールバック | タイミング | 用途 |
|------------|-----------|------|
| `before_validation` | バリデーション前 | データ正規化 |
| `after_validation` | バリデーション後 | エラーログ |
| `before_save` | 保存前 | 自動計算、暗号化 |
| `after_save` | 保存後 | 通知、ログ |
| `before_create` | 新規作成前 | 初期値設定 |
| `after_create` | 新規作成後 | ウェルカムメール |
| `before_update` | 更新前 | 変更履歴記録 |
| `after_update` | 更新後 | キャッシュクリア |
| `before_destroy` | 削除前 | 依存チェック |
| `after_destroy` | 削除後 | ログ、通知 |

**コールバックの注意点:**
- 過度なコールバックはテストを複雑化
- 副作用（メール送信など）は慎重に
- トランザクション内での実行を意識

## 3.3 クエリの最適化

### N+1問題の回避

**問題のあるコード:**

```ruby
# ❌ N+1問題
# app/controllers/admin/users_controller.rb
def index
  @users = User.all
end

# app/views/admin/users/index.html.slim
- @users.each do |user|
  tr
    td = user.name
    td = user.lesson_records.count  # ← ここで毎回SQLが発行される
```

**最適化後:**

```ruby
# ✅ includes で eager loading
# app/controllers/admin/users_controller.rb
def index
  @users = User.includes(:lesson_records).all
end

# app/views/admin/users/index.html.slim
- @users.each do |user|
  tr
    td = user.name
    td = user.lesson_records.size  # ← キャッシュされたデータを使用
```

**includesの種類:**

| メソッド | JOIN種別 | 用途 |
|---------|---------|------|
| `includes` | LEFT OUTER JOIN | 関連データも取得 |
| `joins` | INNER JOIN | 関連条件で絞り込み |
| `preload` | 別クエリで取得 | シンプルな事前読み込み |
| `eager_load` | LEFT OUTER JOIN強制 | 条件指定時 |

### カウンタキャッシュ

**問題:**

```ruby
# ❌ 毎回COUNT(*)が発行される
@category.lessons.count
```

**最適化:**

```ruby
# db/migrate/xxx_add_lessons_count_to_categories.rb
class AddLessonsCountToCategories < ActiveRecord::Migration[8.1]
  def change
    add_column :categories, :lessons_count, :integer, default: 0, null: false

    # 既存データのカウント更新
    Category.reset_column_information
    Category.find_each do |category|
      Category.update_counters category.id, lessons_count: category.lessons.length
    end
  end
end

# app/models/lesson.rb
class Lesson < ApplicationRecord
  belongs_to :category, counter_cache: true
end

# これでSQLを発行せずにカウント取得
@category.lessons_count  # ← DBカラムから直接取得
```

### インデックスの活用

**Typnixでのインデックス設計:**

```ruby
# db/migrate/xxx_add_indexes.rb
class AddIndexes < ActiveRecord::Migration[8.1]
  def change
    # 外部キー
    add_index :lesson_records, :user_id
    add_index :lesson_records, :lesson_id

    # 検索条件
    add_index :lessons, :is_public
    add_index :categories, :published

    # ユニーク制約
    add_index :users, :email, unique: true
    add_index :users, :username, unique: true

    # 複合インデックス（順序重要）
    add_index :lesson_records, [ :user_id, :completed_at ]

    # JSONB用GINインデックス
    add_index :lessons, :items, using: :gin
  end
end
```

**インデックスの原則:**
- WHERE句で使うカラムにインデックス
- JOIN条件（外部キー）にインデックス
- ORDER BY句で使うカラムにインデックス
- 複合インデックスは左から順に評価される

# Chapter 4: ルーティングとURL設計

## 4.1 RESTfulルーティングの基本

### resourcesによるREST設計

**Typnixの基本ルーティング:**

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # 公開ページ
  root "lessons#index"
  resources :lessons, only: [ :index, :show ]

  # 個人ページ
  namespace :my do
    resources :lessons          # 7つのアクション全て
    resources :keymaps, only: [ :index, :edit, :update ]
    resources :history, only: [ :index ], controller: "lesson_records"
  end

  # 管理者ページ
  namespace :admin do
    resources :users, only: [ :index, :show ]
    resources :categories       # 7つのアクション全て
  end
end
```

**生成されるルート例:**

```bash
$ rails routes | grep lessons
   GET    /lessons           lessons#index
   GET    /lessons/:id       lessons#show
   GET    /my/lessons        my/lessons#index
   POST   /my/lessons        my/lessons#create
   GET    /my/lessons/new    my/lessons#new
   GET    /my/lessons/:id/edit   my/lessons#edit
   PATCH  /my/lessons/:id    my/lessons#update
   DELETE /my/lessons/:id    my/lessons#destroy
```

### 名前空間とネスト

**Typnixでの名前空間設計:**

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # 名前空間: /my配下
  namespace :my do
    get "/", to: "settings#index", as: :root  # /my → My::SettingsController#index
    resource :account, only: [ :edit, :update ]  # 単数リソース（IDなし）
    resources :keymaps, only: [ :index, :edit, :update ]
  end

  # 名前空間: /admin配下
  namespace :admin do
    get "/", to: "dashboard#index", as: :root  # /admin → Admin::DashboardController#index
    resources :users, only: [ :index, :show ]
  end

  # カスタムルート
  get "@:username", to: "users#show", as: :user_profile  # /@username
  get "shares/:token", to: "shares#show", as: :share    # /shares/:token
end
```

**ルートパス名の使用:**

```ruby
# コントローラー内
redirect_to my_root_path                    # /my
redirect_to user_profile_path(@user.username)  # /@username
redirect_to share_path(@share.token)         # /shares/abc123

# ビュー内
= link_to "マイページ", my_root_path
= link_to "@#{user.username}", user_profile_path(user.username)
```

## 4.2 URL設計の実践

### URL構造の整理（Day 17の改善）

**改善前（Day 16以前）:**

```
/practice/:id                  # レッスン詳細
/my/practice_sessions          # 練習履歴
/admin/practice_sessions       # 管理者ページ
```

**問題点:**
- `practice`と`session`の用語が混在
- URL構造が直感的でない
- RESTfulでない

**改善後（Day 17以降）:**

```
/lessons/:id                   # レッスン詳細（数値ID）
/my/history                    # 練習履歴
/admin/users/:id/lesson_records  # 管理者: ユーザーの練習履歴
```

**リファクタリング内容:**

```ruby
# config/routes.rb（Day 17以降）
Rails.application.routes.draw do
  # 公開ページ
  resources :lessons, only: [ :index, :show ]  # practice → lessons
  resources :lesson_records, only: [ :create ]

  namespace :my do
    resources :history, only: [ :index ], controller: "lesson_records"  # 直感的なURL
  end
end

# コントローラー名も統一
# app/controllers/lesson_records_controller.rb (旧: practice_sessions_controller.rb)
# app/controllers/my/lesson_records_controller.rb
# app/controllers/admin/lesson_records_controller.rb

# モデル名も統一
# app/models/lesson_record.rb (旧: practice_session.rb)
```

**用語統一の効果:**
- コードベース全体で一貫性
- 開発者の認知負荷軽減
- ドキュメント作成が容易

### スラッグ（slug）によるURL設計

**数値IDベースのURL（基本）:**

```ruby
# config/routes.rb
resources :lessons, only: [ :index, :show ]

# 生成されるURL: /lessons/123
```

**スラッグベースのURL（可読性重視）:**

```ruby
# app/models/keymap_set.rb
class KeymapSet < ApplicationRecord
  before_validation :generate_slug, if: :new_record?

  validates :slug, presence: true, uniqueness: { scope: :user_id }

  def to_param
    slug  # URLパラメータにslugを使う
  end

  private

  def generate_slug
    return if name.blank?
    base_slug = name.parameterize
    candidate = base_slug
    counter = 1

    while KeymapSet.where(user_id: user_id, slug: candidate).exists?
      candidate = "#{base_slug}-#{counter}"
      counter += 1
    end

    self.slug = candidate
  end
end

# config/routes.rb
namespace :my do
  resources :keymaps, only: [ :index, :edit, :update ], param: :slug
end

# 生成されるURL: /my/keymaps/cornix-main/edit（可読性高い）
# コントローラー: params[:slug] でアクセス
```

**スラッグのメリット:**
- URL が可読性高い
- SEO に有利
- シェアしやすい

**スラッグのデメリット:**
- 重複チェックが必要
- 名前変更時の処理が複雑
- クエリが少し重くなる

**Typnixの判断:**
- レッスン: 数値ID（シンプルさ優先）
- キーマップ: slug（ユーザー作成コンテンツ、URL可読性重視）

### カスタムルート

**Typnixでの実装例:**

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # ユーザープロフィール: /@username
  get "@:username", to: "users#show", as: :user_profile
  get "@:username/keymaps", to: "users/keymaps#index", as: :user_keymaps

  # シェアページ: /shares/:token
  get "shares/:token", to: "shares#show", as: :share

  # 認証
  post "auth/google", to: "sessions#create", as: :google_auth
  delete "logout", to: "sessions#destroy", as: :logout

  # 静的ページ
  get "terms", to: "pages#terms", as: :terms
  get "privacy", to: "pages#privacy", as: :privacy
  get "about", to: "pages#about", as: :about
end
```

**パラメータの取得:**

```ruby
# app/controllers/users_controller.rb
class UsersController < ApplicationController
  def show
    @user = User.find_by!(username: params[:username])
  end
end

# app/controllers/shares_controller.rb
class SharesController < ApplicationController
  def show
    @share = Share.find_by!(token: params[:token])
    @lesson_record = @share.lesson_record
  end
end
```

## 4.3 ルーティング制約とセキュリティ

### パラメータ制約

**不正なパラメータを防ぐ:**

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # usernameは小文字英数字とハイフンのみ
  get "@:username", to: "users#show",
    constraints: { username: /[a-z0-9][a-z0-9-]{0,38}/ },
    as: :user_profile

  # tokenは32文字の英数字
  get "shares/:token", to: "shares#show",
    constraints: { token: /[a-z0-9]{32}/ },
    as: :share

  # IDは数値のみ
  resources :lessons, only: [ :show ],
    constraints: { id: /\d+/ }
end
```

**効果:**
- 不正なURLリクエストを早期に弾く
- セキュリティ向上
- エラーハンドリングがシンプル

### HTTPメソッドの制約

**Rails 8.1での変更（Turbo対応）:**

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # DELETEメソッドの明示
  delete "logout", to: "sessions#destroy", as: :logout

  # PATCHとPUTの両対応（Rails標準）
  resources :lessons do
    member do
      patch :publish     # PATCH /lessons/:id/publish
      put :publish       # PUT /lessons/:id/publish（互換性）
    end
  end
end
```

**Turboでのフォーム送信:**

```slim
/ app/views/layouts/partials/_header.html.slim
= button_to "ログアウト", logout_path,
  method: :delete,
  data: { turbo_method: :delete, turbo_confirm: "ログアウトしますか？" },
  class: "btn-logout"
```

### ルートの優先順位

**マッチング順序:**

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # ❌ 悪い例: 具体的なルートの後にワイルドカードを置く
  get "*path", to: "pages#not_found"
  get "about", to: "pages#about"  # ← これは決してマッチしない

  # ✅ 良い例: 具体的なルートを先に定義
  get "about", to: "pages#about"
  get "terms", to: "pages#terms"
  get "*path", to: "pages#not_found"  # ← 最後に配置
end
```

---

# Chapter 5: コントローラーとビジネスロジック

## 5.1 コントローラーの責務

### Skinny Controllerの原則

**アンチパターン（Fat Controller）:**

```ruby
# ❌ 悪い例: ビジネスロジックがコントローラーに
class My::LessonRecordsController < My::ApplicationController
  def index
    @lesson_records = current_user.lesson_records.order(completed_at: :desc)

    # 正答率の平均を計算
    total = 0
    @lesson_records.each { |r| total += r.accuracy }
    @average_accuracy = @lesson_records.any? ? (total / @lesson_records.count).round(1) : 0

    # WPMの平均を計算
    wpm_records = @lesson_records.select { |r| r.wpm.present? }
    total_wpm = 0
    wpm_records.each { |r| total_wpm += r.wpm }
    @average_wpm = wpm_records.any? ? (total_wpm / wpm_records.count).round(1) : 0

    # 期間フィルター
    if params[:period] == "week"
      @lesson_records = @lesson_records.where("completed_at >= ?", 1.week.ago)
    elsif params[:period] == "month"
      @lesson_records = @lesson_records.where("completed_at >= ?", 1.month.ago)
    end

    # ページネーション
    @lesson_records = @lesson_records.page(params[:page]).per(20)
  end
end
```

**ベストプラクティス（Skinny Controller）:**

```ruby
# ✅ 良い例: ロジックをモデルに移動
# app/controllers/my/lesson_records_controller.rb
class My::LessonRecordsController < My::ApplicationController
  def index
    @period = params[:period] || "all"
    @filtered_records = current_user.lesson_records.for_period(@period)
    @lesson_records = @filtered_records.recent.page(params[:page]).per(20)
    @total_count = @filtered_records.count
    @average_accuracy = @filtered_records.average_accuracy
    @average_wpm = @filtered_records.average_wpm
  end
end

# app/models/lesson_record.rb
class LessonRecord < ApplicationRecord
  scope :recent, -> { order(completed_at: :desc) }

  scope :for_period, ->(period) {
    case period
    when "week"
      where("completed_at >= ?", 1.week.ago)
    when "month"
      where("completed_at >= ?", 1.month.ago)
    else
      all
    end
  }

  def self.average_accuracy
    average(:accuracy)&.round(1) || 0
  end

  def self.average_wpm
    where.not(wpm: nil).average(:wpm)&.round(1) || 0
  end
end
```

**コントローラーの責務:**
1. パラメータの受け取り
2. モデルメソッドの呼び出し
3. レスポンスの返却（render/redirect）
4. 認証・認可のチェック

**モデルの責務:**
1. ビジネスロジック
2. データの永続化
3. バリデーション
4. クエリの構築

### Strong Parameters

**パラメータのホワイトリスト化:**

```ruby
# app/controllers/my/lessons_controller.rb
class My::LessonsController < My::ApplicationController
  def create
    @lesson = current_user.lessons.build(lesson_params)

    if @lesson.save
      redirect_to my_lessons_path, notice: "レッスンを作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @lesson = current_user.lessons.find(params[:id])

    if @lesson.update(lesson_params)
      redirect_to my_lessons_path, notice: "レッスンを更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def lesson_params
    params.require(:lesson).permit(
      :category_id,
      :name,
      :description,
      :is_public,
      items: []  # JSONB配列
    )
  end
end
```

**ネストしたパラメータ:**

```ruby
# app/controllers/my/keymaps_controller.rb
class My::KeymapsController < My::ApplicationController
  private

  def keymap_params
    params.require(:keymap_set).permit(
      :name,
      :description,
      :is_public,
      :keyboard_type,
      keymaps_attributes: [
        :id,
        :layer,
        :position,
        :key_char,
        :_destroy  # ネストした削除フラグ
      ]
    )
  end
end
```

## 5.2 Concernパターンの活用

### コントローラーConcernの作成

**Typnixの実装例（Day 29）:**

```ruby
# app/controllers/concerns/lesson_record_creation.rb
module LessonRecordCreation
  extend ActiveSupport::Concern

  private

  def create_lesson_record_for(user)
    @lesson_record = user.lesson_records.build(lesson_record_params)
    @lesson_record.completed_at = Time.current

    if @lesson_record.save
      render json: {
        success: true,
        message: "練習履歴を保存しました",
        lesson_record_id: @lesson_record.id
      }
    else
      render json: {
        success: false,
        errors: @lesson_record.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def lesson_record_params
    params.require(:lesson_record).permit(
      :lesson_id, :lesson_name, :word_count, :correct_count,
      :mistake_count, :accuracy, :duration_seconds, :typed_chars
    )
  end
end
```

**使用例:**

```ruby
# app/controllers/lesson_records_controller.rb
class LessonRecordsController < ApplicationController
  include LessonRecordCreation

  def create
    user = logged_in? ? current_user : User.find_by!(username: "guest")
    create_lesson_record_for(user)
  end
end

# app/controllers/my/lesson_records_controller.rb
class My::LessonRecordsController < My::ApplicationController
  include LessonRecordCreation

  def create
    create_lesson_record_for(current_user)
  end
end
```

**Concernを使うべきケース:**
- 複数のコントローラーで同じロジックが必要
- 名前空間が異なるコントローラー間での共通化
- before_actionなどのフックを共有

**Concernを使うべきでないケース:**
- 1つのコントローラーでのみ使用
- 過度な抽象化（可読性低下）

### included ブロックの活用

**before_actionの共通化:**

```ruby
# app/controllers/concerns/admin_authorizable.rb
module AdminAuthorizable
  extend ActiveSupport::Concern

  included do
    before_action :require_admin
  end

  private

  def require_admin
    unless current_user&.admin?
      redirect_to root_path, alert: "管理者権限が必要です"
    end
  end
end

# app/controllers/admin/application_controller.rb
class Admin::ApplicationController < ApplicationController
  include AdminAuthorizable  # before_actionが自動適用される
end
```

## 5.3 レスポンスの処理

### JSONレスポンス

**Typnixでの実装例:**

```ruby
# app/controllers/lesson_records_controller.rb
class LessonRecordsController < ApplicationController
  def create
    user = logged_in? ? current_user : User.find_by!(username: "guest")
    @lesson_record = user.lesson_records.build(lesson_record_params)

    if @lesson_record.save
      render json: {
        success: true,
        message: "練習履歴を保存しました",
        lesson_record_id: @lesson_record.id,
        grade: @lesson_record.grade,  # モデルメソッド
        wpm: @lesson_record.wpm
      }
    else
      render json: {
        success: false,
        errors: @lesson_record.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
end
```

**フロントエンドでの受信:**

```javascript
// app/javascript/controllers/typing_controller.js
async saveRecord(data) {
  const response = await fetch('/lesson_records', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
    },
    body: JSON.stringify({ lesson_record: data })
  });

  const result = await response.json();

  if (result.success) {
    console.log('保存成功:', result.lesson_record_id);
    this.showGrade(result.grade, result.wpm);
  } else {
    console.error('保存失敗:', result.errors);
  }
}
```

### リダイレクトとフラッシュメッセージ

**Typnixでの実装例（Day 28改善）:**

```ruby
# app/controllers/my/accounts_controller.rb
class My::AccountsController < My::ApplicationController
  def update
    if @user.update(account_params)
      redirect_to my_account_path, notice: "アカウント情報を更新しました"
    else
      flash.now[:alert] = "更新に失敗しました"
      render :edit, status: :unprocessable_entity
    end
  end
end
```

**ビューでの表示:**

```slim
/ app/views/layouts/application.html.slim
- if flash[:notice]
  .alert.alert-success.fixed.top-4.right-4.z-50
    = flash[:notice]

- if flash[:alert]
  .alert.alert-error.fixed.top-4.right-4.z-50
    = flash[:alert]
```

**flash.now vs flash:**
- `flash`: 次のリクエストまで保持（リダイレクト時）
- `flash.now`: 現在のリクエストのみ（renderときに使用）

### Turbo Streamsによる部分更新

**Typnixでの実装例（Day 28）:**

```ruby
# app/controllers/admin/allowed_emails_controller.rb
class Admin::AllowedEmailsController < Admin::ApplicationController
  def toggle_contacted
    @allowed_email = AllowedEmail.find(params[:id])
    @allowed_email.update(contacted: !@allowed_email.contacted)

    respond_to do |format|
      format.turbo_stream  # Turbo Streamsでレスポンス
      format.html { redirect_to admin_allowed_emails_path }
    end
  end
end
```

**Turbo Streamsビュー:**

```slim
/ app/views/admin/allowed_emails/toggle_contacted.turbo_stream.slim
= turbo_stream.replace "allowed_email_#{@allowed_email.id}" do
  = render "allowed_email_row", allowed_email: @allowed_email
```

**HTML側:**

```slim
/ app/views/admin/allowed_emails/index.html.slim
tbody
  - @allowed_emails.each do |email|
    = render "allowed_email_row", allowed_email: email

/ app/views/admin/allowed_emails/_allowed_email_row.html.slim
tr id="allowed_email_#{allowed_email.id}"
  td = allowed_email.email
  td
    = button_to "トグル", toggle_contacted_admin_allowed_email_path(allowed_email),
      method: :patch,
      data: { turbo_method: :patch }
```

---

# Chapter 6: ビュー層の設計

## 6.1 Slimテンプレートエンジン

### Slimの基本文法

**HTMLとの比較:**

```html
<!-- HTML -->
<div class="container mx-auto p-4">
  <h1 class="text-2xl font-bold">Welcome</h1>
  <p>Hello, <%= @user.name %>!</p>
</div>
```

```slim
/ Slim
.container.mx-auto.p-4
  h1.text-2xl.font-bold Welcome
  p Hello, #{@user.name}!
```

**Slimのメリット:**
- コード量が少ない（約30-50%削減）
- 閉じタグ不要
- インデントでネスト表現
- 可読性が高い

### Typnixでの実践例

**レイアウトファイル:**

```slim
/ app/views/layouts/application.html.slim
doctype html
html lang="ja"
  head
    meta charset="utf-8"
    meta name="viewport" content="width=device-width, initial-scale=1"
    title
      = content_for?(:title) ? yield(:title) : "Typnix"

    = csrf_meta_tags
    = csp_meta_tag

    = stylesheet_link_tag "application", "data-turbo-track": "reload"
    = javascript_importmap_tags

  body class=body_class
    = render "layouts/partials/header"

    .flex.min-h-screen
      aside.hidden.md:block.w-80.bg-gray-50.dark:bg-gray-900
        = render "shared/sidebar"

      main.flex-1.p-6
        = yield

    = render "layouts/partials/footer"
```

**フォーム:**

```slim
/ app/views/my/lessons/new.html.slim
= form_with model: [ :my, @lesson ], local: false do |f|
  .form-group
    = f.label :category_id, "カテゴリー"
    = f.collection_select :category_id, @categories, :id, :name,
      { prompt: "選択してください" },
      { class: "form-select" }

  .form-group
    = f.label :name, "レッスン名"
    = f.text_field :name, class: "form-input", required: true

  .form-group
    = f.label :description, "説明"
    = f.text_area :description, rows: 3, class: "form-textarea"

  .form-group
    = f.label :is_public do
      = f.check_box :is_public, class: "form-checkbox"
      | 公開する

  .form-actions
    = f.submit "作成", class: "btn-primary"
    = link_to "キャンセル", my_lessons_path, class: "btn-secondary"
```

## 6.2 Tailwind CSSの活用

### ユーティリティファーストの設計

**Typnixでの実装例:**

```slim
/ グリッドレイアウト
.grid.grid-cols-1.md:grid-cols-2.lg:grid-cols-3.gap-4
  .bg-white.dark:bg-gray-800.rounded-lg.shadow-md.p-4
    h3.text-lg.font-semibold = lesson.name
    p.text-gray-600.dark:text-gray-400 = lesson.description

/ レスポンシブ対応のカード
.max-w-4xl.mx-auto
  .grid.gap-6
    .bg-white.rounded-lg.shadow.p-6
      h2.text-2xl.font-bold.mb-4 統計情報
      .grid.grid-cols-2.gap-4
        div
          .text-sm.text-gray-600 平均正答率
          .text-3xl.font-bold = "#{@average_accuracy}%"
        div
          .text-sm.text-gray-600 平均WPM
          .text-3xl.font-bold = @average_wpm

/ ダークモード対応
.bg-white.dark:bg-gray-900
  .text-gray-900.dark:text-gray-100
    h1 タイトル
```

### ダークモードの実装

**Typnixでの実装（Day 9）:**

```slim
/ app/views/layouts/partials/_head.html.slim
head
  script
    | (function() {
    |   const theme = localStorage.getItem('theme') || 'system';
    |   if (theme === 'dark' || (theme === 'system' && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
    |     document.documentElement.classList.add('dark');
    |   }
    | })();
```

```javascript
// app/javascript/controllers/theme_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggle"]

  connect() {
    this.updateTheme()
  }

  toggle() {
    const themes = ['light', 'dark', 'system']
    const currentIndex = themes.indexOf(this.currentTheme)
    const nextTheme = themes[(currentIndex + 1) % themes.length]

    localStorage.setItem('theme', nextTheme)
    this.updateTheme()
  }

  updateTheme() {
    const theme = localStorage.getItem('theme') || 'system'
    const isDark = theme === 'dark' ||
      (theme === 'system' && window.matchMedia('(prefers-color-scheme: dark)').matches)

    document.documentElement.classList.toggle('dark', isDark)
  }

  get currentTheme() {
    return localStorage.getItem('theme') || 'system'
  }
}
```

## 6.3 パーシャルとDRY原則

### local_assignsによる柔軟なパーシャル

**Typnixでの実装例（Day 29）:**

```slim
/ app/views/shared/_lesson_records_table.html.slim
- if lesson_records.any?
  / PC表示
  .hidden.md:block
    table.w-full.table-auto
      thead.bg-gray-100.dark:bg-gray-800
        tr
          th.px-4.py-2.text-left 日時

          / オプション: ユーザー名
          - if local_assigns[:show_user]
            th.px-4.py-2.text-left ユーザー

          th.px-4.py-2.text-left レッスン
          th.px-4.py-2.text-right 正答率
          th.px-4.py-2.text-right WPM
          th.px-4.py-2.text-left グレード

          / オプション: アクション列
          - if local_assigns[:show_actions]
            th.px-4.py-2.text-right アクション

      tbody
        - lesson_records.each do |record|
          tr.border-t.dark:border-gray-700
            td.px-4.py-2 = record.completed_at.strftime("%Y/%m/%d %H:%M")

            - if local_assigns[:show_user]
              td.px-4.py-2
                = link_to user_profile_path(record.user.username), class: "text-blue-600"
                  = record.user.username

            td.px-4.py-2 = record.lesson_name || "不明なレッスン"
            td.px-4.py-2.text-right
              span class="#{record.accuracy >= 95 ? 'text-green-600 font-semibold' : ''}"
                = "#{record.accuracy}%"
            td.px-4.py-2.text-right = record.wpm || "-"
            td.px-4.py-2
              = render "shared/grade_badge", grade: record.grade

            - if local_assigns[:show_actions]
              td.px-4.py-2.text-right
                = link_to "詳細", [:admin, record.user, record], class: "text-blue-600"

  / モバイル表示
  .md:hidden
    .space-y-4
      - lesson_records.each do |record|
        .bg-white.dark:bg-gray-800.rounded-lg.p-4.shadow
          / ... モバイル用レイアウト ...

  / ページネーション（オプション）
  - if local_assigns[:show_pagination]
    .mt-4
      = paginate lesson_records

- else
  .text-gray-500.text-center.py-8
    | 練習履歴がありません
```

**使用例:**

```slim
/ 管理者ダッシュボード
= render "shared/lesson_records_table",
  lesson_records: @recent_records,
  show_user: true

/ 個人履歴ページ
= render "shared/lesson_records_table",
  lesson_records: @lesson_records,
  show_pagination: true

/ 管理者ユーザー詳細
= render "shared/lesson_records_table",
  lesson_records: @user.lesson_records.recent.limit(10),
  show_user: false,
  show_actions: true
```

### コンポーネント指向の設計

**小さなパーシャルに分割:**

```slim
/ app/views/shared/_grade_badge.html.slim
- grade_config = {
-   "プロ級" => "bg-purple-100 text-purple-800",
-   "上級者" => "bg-blue-100 text-blue-800",
-   "中級者" => "bg-green-100 text-green-800",
-   "初心者" => "bg-yellow-100 text-yellow-800",
-   "入門者" => "bg-gray-100 text-gray-800"
- }

span.px-2.py-1.rounded.text-xs.font-semibold class=grade_config[grade]
  = grade

/ 使用例
= render "shared/grade_badge", grade: @lesson_record.grade
```

**メリット:**
- 再利用性が高い
- テストしやすい
- メンテナンス容易

---
