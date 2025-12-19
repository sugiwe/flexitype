# 管理者ダッシュボード設計

**実装ステータス**: ✅ **Day 20で実装完了**（Phase 1-3すべて完了）

**最終更新**: 2025-12-20

このドキュメントには、管理者ダッシュボードの完全な設計と実装詳細を記載しています。

---

## 概要

### 目的
- ベータテストユーザーの活動状況を開発者が監視できるようにする
- ユーザー数、練習回数、キーマップ数などの統計情報をダッシュボードで一覧表示
- 個別のユーザー詳細ページで、各ユーザーの練習履歴やキーマップを確認

### アクセス制御
- 開発者（管理者）のみアクセス可能
- 環境変数 `ADMIN_EMAILS` でメールアドレスをカンマ区切りで管理
- `Admin::ApplicationController` で `before_action :require_admin!` を実装

---

## URL構造

```ruby
# 管理者ページ（認証 + 管理者権限必須、/admin 名前空間）
GET /admin                      # 管理者ダッシュボード（統計概要 + ユーザー一覧）
GET /admin/users                # ユーザー一覧（ページネーション付き）
GET /admin/users/:id            # ユーザー詳細（練習履歴、キーマップ、詳細統計）
```

---

## ダッシュボード構成要素

### 1. 統計サマリーカード（4つ）

#### 総ユーザー数
- **アイコン**: ユーザーアイコン（青色）
- **数値**: `User.count`
- **サブテキスト**: 「今週の新規登録: X名」

#### 総練習回数
- **アイコン**: キーボードアイコン（緑色）
- **数値**: `TypingSession.count`
- **サブテキスト**: 「今日の練習: X回」

#### 総キーマップ数
- **アイコン**: レイヤーアイコン（黄色）
- **数値**: `KeymapSet.count`
- **サブテキスト**: 「公開キーマップ: X個」

#### 総レッスン数
- **アイコン**: ドキュメントアイコン（紫色）
- **数値**: `LessonLoader.all_lessons_flat.count`
- **サブテキスト**: 「カテゴリー数: X個」

### 2. アクティブユーザー統計

**表示項目:**
- 過去7日間のアクティブユーザー数（`last_sign_in_at >= 7.days.ago`）
- 過去30日間のアクティブユーザー数（`last_sign_in_at >= 30.days.ago`）
- 今週の練習回数（`completed_at >= 1.week.ago`）

### 3. 最新ユーザー（10名）

**表示項目:**
- ID（数値）
- アバター画像（`icon_url` または頭文字アイコン）
- 名前（`name`）
- ユーザー名（`username`、`/@username`へのリンク）
- メールアドレス（`email`）
- 練習回数（`typing_sessions.count`）
- キーマップ数（`keymap_sets.count`）
- 最終ログイン（`last_sign_in_at`、「X分前」形式）
- アクション（「詳細を見る」ボタン → `/admin/users/:id`）

**並び順:**
- 最終ログイン日時の降順（`order(last_sign_in_at: :desc)`）

**リンク:**
- 「すべて見る」ボタン → `/admin/users`

### 4. 最新練習履歴（10件）

**表示項目:**
- ユーザー名（アバター + 名前、`/@username`へのリンク）
- レッスン名
- 正答率（色分け: 90%以上=緑、70%以上=黄、それ以下=赤）
- 所要時間
- ミス数
- 日時

**並び順:**
- 完了日時の降順（`order(completed_at: :desc)`）

**パフォーマンス最適化:**
- `TypingSession.includes(:user)` でN+1クエリを防止

### 5. レッスンカテゴリー統計

**表示項目:**
- カテゴリー名（例: 「基礎練習」「プログラミング」「文章練習」）
- 各カテゴリーのレッスン数

### 6. 人気レッスンランキング（TOP 10）

**表示項目:**
- レッスン名
- 総練習回数（`TypingSession.group(:lesson_id).count`）
- 平均正答率

**SQLクエリ:**
```ruby
TypingSession
  .where.not(lesson_id: nil)
  .group(:lesson_id, :lesson_name)
  .select("lesson_id, lesson_name, COUNT(*) as practice_count, AVG(accuracy) as avg_accuracy")
  .order("practice_count DESC")
  .limit(10)
```

---

## ユーザー一覧ページ（`/admin/users`）

### 表示項目
- ID、アバター、名前、ユーザー名、メールアドレス
- 練習回数、キーマップ数、ログイン回数、最終ログイン
- 「詳細を見る」ボタン

### ページネーション
- Kaminari gem、1ページ20件
- 最終ログイン日時の降順

### レスポンシブUI
- **PC**: テーブル形式
- **モバイル**: カード形式

---

## ユーザー詳細ページ（`/admin/users/:id`）

### ユーザー基本情報
- アバター画像
- 名前、ユーザー名（`/@username`へのリンク）、メールアドレス
- 登録日時、最終ログイン日時（「X分前」形式）
- ログイン回数

### 統計情報（3つのカード）
- 総練習回数（緑色アイコン）
- 平均正答率（青色アイコン）
- 総キーマップ数（黄色アイコン）

### 練習履歴一覧（ページネーション付き）
- 日時、レッスン名、単語数、正答率、所要時間、ミス数
- ページネーション: Kaminari gem、1ページ20件
- レスポンシブUI（PC: テーブル、モバイル: カード）

### キーマップ一覧
- 名前、説明、キー設定数、作成日、公開設定

---

## アクセス制御の実装

### 環境変数設定

```bash
# .kamal/secrets
ADMIN_EMAILS=developer@example.com,admin@example.com
```

### Admin::ApplicationController

```ruby
class Admin::ApplicationController < ApplicationController
  before_action :require_admin!

  private

  def require_admin!
    admin_emails = ENV['ADMIN_EMAILS']&.split(',')&.map(&:strip) || []
    unless logged_in? && admin_emails.include?(current_user.email)
      redirect_to root_path, alert: "管理者権限が必要です"
    end
  end
end
```

### ApplicationHelper にヘルパーメソッド追加

```ruby
def admin?
  return false unless logged_in?
  admin_emails = ENV['ADMIN_EMAILS']&.split(',')&.map(&:strip) || []
  admin_emails.include?(current_user.email)
end
```

---

## ログイン追跡機能

### User モデルに追加カラム

```ruby
# db/migrate/20251219192820_add_login_tracking_to_users.rb
class AddLoginTrackingToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :last_sign_in_at, :datetime
    add_column :users, :current_sign_in_at, :datetime
    add_column :users, :sign_in_count, :integer, default: 0, null: false

    add_index :users, :last_sign_in_at
  end
end
```

### SessionsController#create を更新

```ruby
def create
  # ... Google認証処理 ...

  # ログイン情報を更新
  @user.update!(
    last_sign_in_at: @user.current_sign_in_at,
    current_sign_in_at: Time.current,
    sign_in_count: @user.sign_in_count + 1
  )

  # ... セッション設定 ...
end
```

---

## サイドバーメニューへの追加

管理者のみに表示される専用メニュー項目を追加（赤色テーマ）:

```slim
/ app/views/layouts/shared/_sidebar_navigation.html.slim
/ 通常メニューの後に、区切り線と管理者メニューを追加

- if admin?
  .border-t.border-gray-200.dark:border-gray-600.my-2

  li
    = link_to admin_root_path, class: "flex items-center px-4 py-3 text-gray-700 dark:text-gray-200 rounded-lg hover:bg-red-50 dark:hover:bg-red-900 hover:text-red-600 dark:hover:text-red-400 transition #{current_page?(admin_root_path) ? 'bg-red-50 dark:bg-red-900 text-red-600 dark:text-red-400 font-semibold' : ''}" do
      svg.w-5.h-5.mr-3 fill="none" stroke="currentColor" viewBox="0 0 24 24"
        path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
      span 管理画面
```

**デザイン方針:**
- 通常メニュー: 青色（`bg-blue-50`, `text-blue-600`）
- 管理者メニュー: 赤色（`bg-red-50`, `text-red-600`）
- 色は控えめ（harsh にならないよう注意）
- 区切り線で視覚的に分離

---

## ルーティング

```ruby
# config/routes.rb
namespace :admin do
  root to: "dashboard#index"
  resources :users, only: [:index, :show]
end
```

---

## パフォーマンス最適化

### N+1クエリ対策

```ruby
# 最新練習履歴でのN+1クエリ防止
@recent_sessions = TypingSession.includes(:user).order(completed_at: :desc).limit(10)
```

---

## 実装段階（✅ すべて完了）

### ✅ Phase 1: 基盤整備（Day 20 午前）
- Admin 名前空間の作成
- Admin::ApplicationController の実装
- ログイン追跡カラムの追加（マイグレーション）
- SessionsController の更新
- 環境変数 `ADMIN_EMAILS` の設定
- `admin?` ヘルパーメソッドの実装

### ✅ Phase 2: ダッシュボード実装（Day 20 午後）
- `/admin` ルートとダッシュボードコントローラの作成
- 4つの統計サマリーカードの実装
- アクティブユーザー統計の追加
- 最新ユーザー（10名）の実装
- 最新練習履歴（10件）の実装
- レッスンカテゴリー統計の実装
- 人気レッスンランキング（TOP 10）の実装
- サイドバーへの管理者メニュー追加

### ✅ Phase 3: 詳細ページ実装（Day 20 夜）
- `/admin/users` 一覧ページ（ページネーション付き）
- `/admin/users/:id` 詳細ページ
  - ユーザー基本情報
  - 統計情報（3つのカード）
  - 練習履歴一覧（ページネーション付き）
  - キーマップ一覧
- レスポンシブUI（PC: テーブル、モバイル: カード）
- 日本語ロケールファイルの追加（`time_ago_in_words` 翻訳）

---

## 将来的な拡張（任意）

### グラフ機能（Chart.js）
- ユーザー登録数の推移（日別・週別）
- 練習回数の推移
- 平均正答率の推移

### CSV エクスポート
- ユーザーデータのエクスポート
- 練習履歴のエクスポート

### 高度なフィルタリング
- ユーザー検索（名前、メールアドレス）
- 期間フィルター（登録日時、最終ログイン日時）
- アクティビティフィルター（練習回数でソート）

---

## レッスンのDB化について

### 現状
- レッスンデータは YAML ファイル管理（`config/lessons/`）
- 開発者が手動で追加・編集
- Git 管理されており、変更履歴が追跡可能

### DB化を検討する理由
- 管理画面からレッスンの追加・編集ができるようになる
- 練習回数などの統計をレッスンと直接紐づけられる
- レッスンごとの詳細な分析が可能になる

### 方針
- 今回の管理者ダッシュボード実装では、YAML のまま維持
- DB 化は別の独立したタスクとして、将来的に実装
- 理由:
  - レッスンは開発者が管理するもので、ユーザーが作成するものではない
  - YAML 管理の方がデプロイ時にシンプル（Git で管理可能）
  - 現状でも `lesson_id` を `typing_sessions` に保存しているため、統計は取得可能
  - DB 化は大きな変更となるため、管理者ダッシュボード実装とは切り分ける

### 将来的にDB化する場合の設計メモ
- Lesson モデル、Category モデルの作成
- YAML データを DB に移行するマイグレーション
- 管理画面からのレッスン CRUD 機能
- レッスンバージョン管理（変更履歴）

---

## まとめ

**実装完了（Day 20）:**
- ✅ 管理者ダッシュボード（Phase 1-3すべて完了）
- ✅ ログイン追跡機能
- ✅ ユーザー一覧・詳細ページ
- ✅ 統計情報・人気レッスンランキング
- ✅ レスポンシブUI（モバイル・PC両対応）
- ✅ 日本語ロケール対応

**セキュリティ:**
- ✅ 環境変数によるアクセス制御
- ✅ 管理者のみアクセス可能
- ✅ Brakeman 0警告

**パフォーマンス:**
- ✅ N+1クエリ対策（`includes(:user)`）
- ✅ 適切なインデックス設計
