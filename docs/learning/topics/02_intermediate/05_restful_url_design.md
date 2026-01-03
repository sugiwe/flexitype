# RESTfulなURL設計とルーティング

**難易度**: 🟡 中級
**推定学習時間**: 1.5〜2時間
**対応する日報**: Day 17
**関連PR**: #96 (Day 17のURL構造整理)

---

## 🎯 学習目標

この教材を学ぶことで、以下ができるようになります：

- RESTful設計の原則を理解し、適切なURL構造を設計できる
- `/my`名前空間による個人ページの整理手法を習得できる
- `/@username`形式のユーザープロフィールURLを実装できる
- YAGNI（You Aren't Gonna Need It）原則に基づいた設計判断ができる
- Rails標準の`resources`ルーティングを最大限活用できる

---

## 📚 前提知識

この教材を理解するには、以下の知識が必要です：

- Railsルーティングの基本（`get`, `post`, `resources`など）
- HTTPメソッド（GET, POST, PUT/PATCH, DELETE）の基本
- Railsの名前空間（namespace）の概念
- MVC（Model-View-Controller）アーキテクチャの理解
- RESTful設計の基本概念（リソース指向、CRUD操作）

---

## 📖 本編

### 概要

**URL設計の重要性**

URL設計は、Webアプリケーションの「玄関口」であり、ユーザー体験とSEOの両面で非常に重要です。良いURL設計は以下のような利点をもたらします：

- **ユーザーフレンドリー**: URLを見ただけで何のページか分かる
- **SEO効果**: 検索エンジンがページ内容を理解しやすい
- **保守性**: コードの構造が整理され、開発効率が向上する
- **拡張性**: 将来の機能追加に対応しやすい

Typnixプロジェクトでは、Day 17に大規模なURL構造の整理を実施しました。この日報では、実際に直面した設計課題と、YAGNI原則に基づいた解決策を詳しく解説します。

**RESTful設計とは**

RESTful設計は、以下の5つの原則に基づいています：

1. **リソース指向**: URLはリソース（ユーザー、記事、コメントなど）を表現する
2. **HTTPメソッドの活用**: GET（読み取り）、POST（作成）、PUT/PATCH（更新）、DELETE（削除）を適切に使い分ける
3. **ステートレス**: サーバー側で状態を保持せず、リクエストごとに完結する
4. **階層構造**: リソース間の関係を階層的に表現する（例: `/users/1/posts/5`）
5. **統一インターフェース**: 一貫性のあるURL設計で予測可能性を高める

---

### 実装前（アンチパターン / 課題）

**Day 17以前のURL構造**

Typnixプロジェクトでは、Day 16まで以下のようなURL構造を使っていました：

```ruby
# config/routes.rb（Day 16まで）

# 練習ページ（クエリパラメータ方式）
get "practice", to: "practice#index"
# URL例: /practice?category=word_practice&lesson=beginner_words

# 練習履歴（認証後のページだが、名前空間なし）
get "history", to: "history#index"
# URL例: /history

# キーマップ設定（認証後のページだが、名前空間なし）
get "keymaps/current/edit", to: "keymaps#edit"
# URL例: /keymaps/current/edit

# プロフィールページなし
```

**問題点:**

1. **クエリパラメータへの依存**: `/practice?category=xxx&lesson=xxx`は長く、SEOに不利
2. **個別URLの欠如**: 各レッスンに固有のURLがなく、シェアやブックマークに不便
3. **名前空間の欠如**: 認証が必要なページと不要なページが混在し、構造が不明瞭
4. **スケーラビリティの低さ**: レッスンをDB化する際に大規模な変更が必要
5. **ユーザープロフィールの欠如**: ユーザー同士の交流や成果シェアができない
6. **URLの予測不可能性**: `keymaps/current/edit`は直感的でなく、RESTfulな設計から逸脱

**当初検討した過剰な設計（YAGNI違反の例）**

Day 17の初期段階では、以下のような複雑な設計を検討していました：

```ruby
# 検討したが採用しなかった設計例

# カテゴリ + スラッグ方式（過剰に複雑）
get "practices/:category/:lesson_slug", to: "practices#show"
# URL例: /practices/word_practice/beginner_words

# スラッグベースのユーザープロフィール（過剰な機能）
get "/@:username/:slug", to: "profiles#show"
# URL例: /@alice/my-awesome-profile
```

**過剰設計の問題点:**

1. **スラッグの一意性管理が複雑**: 同じスラッグを持つレッスンが存在しないか常にチェックが必要
2. **カテゴリ変更時にURLが変わる**: SEOとブックマークに悪影響
3. **実装コストが高い**: スラッグ生成、バリデーション、重複チェックなど
4. **ユーザー作成レッスンへの対応が困難**: 将来的な拡張時に設計変更が必要
5. **YAGNI原則違反**: 現時点で必要ない機能を実装しようとしている

---

### 実装後（ベストプラクティス）

**Day 17後のURL構造（シンプルかつ拡張性の高い設計）**

最終的に採用したURL構造は、以下の通りです：

```ruby
# config/routes.rb（Day 17後）

Rails.application.routes.draw do
  # Public pages
  root "home#index"
  resources :lessons, only: [ :show ]  # 数値IDベース

  # 旧URLからのリダイレクト（301 Moved Permanently）
  get "/practices/:id", to: redirect("/lessons/%{id}", status: 301)

  # User profiles (public, /@username形式)
  get "/@:username", to: "profiles#show", as: :profile, constraints: { username: /[^\/]+/ }

  # Personal pages (authentication required, /my namespace)
  namespace :my do
    root to: "dashboard#index"  # /my
    resources :keymaps, only: [ :index, :new, :create, :edit, :update, :destroy ], param: :slug
    resources :history, only: [ :index ], controller: "lesson_records"  # /my/history
    resource :account, only: [ :edit, :update ]  # /my/account/edit
  end

  # Admin pages (authentication + admin permission required, /admin namespace)
  namespace :admin do
    root to: "dashboard#index"  # /admin
    resources :users, only: [ :index, :show ]
    # ...他の管理者ページ
  end
end
```

**改善点:**

1. **数値IDベースのシンプル設計**: `/lessons/1`, `/lessons/7`など、管理が容易
2. **名前空間による整理**: `/my`（個人ページ）、`/admin`（管理者ページ）で明確に分離
3. **RESTful設計の徹底**: `resources`ルーティングを活用し、Rails標準に準拠
4. **`/@username`形式**: GitHubやTwitterと同様のユーザープロフィールURL
5. **将来の拡張性**: DB化時に数値IDをそのまま使える
6. **301リダイレクト**: 旧URLからの移行をスムーズに実施

**コード削減効果:**

Day 17の変更により、以下のような効果が得られました：

- **LessonLoader**: 約120行 → 約80行（デフォルトフォールバック処理を削除）
- **PracticeController**: 約50行 → 約20行（シンプルな`show`アクションに変更）
- **削減率**: 約40%のコード削減

---

### 解説

#### なぜこの設計が優れているのか

**1. 数値IDベースの利点**

数値IDベースのURL（`/lessons/1`）は、以下の利点があります：

- **シンプル**: スラッグ生成や一意性チェックが不要
- **高速**: データベースの主キー検索により、クエリが高速
- **一意性保証**: 自動採番IDによる一意性が保証される
- **実装コスト低**: Rails標準の`resources`ルーティングで実装可能
- **拡張性**: レッスンをDB化する際、IDをそのまま使える

```ruby
# コントローラの実装例（シンプル）
def show
  lesson_id = params[:id]
  @lesson_info = LessonLoader.get_lesson_info(lesson_id)
  @words = LessonLoader.get_practice_items(lesson_id)
end
```

**2. `/my`名前空間による個人ページの整理**

`/my`名前空間は、以下のメリットをもたらします：

- **認証ロジックの集約**: `My::ApplicationController`で`before_action :require_login`を一元管理
- **URLの明確化**: `/my`配下は認証が必要と一目で分かる
- **DRY原則の徹底**: 各コントローラで`before_action`を重複して書く必要がない

```ruby
# app/controllers/my/application_controller.rb
class My::ApplicationController < ApplicationController
  before_action :require_login

  private

  def require_login
    unless logged_in?
      redirect_to root_path, alert: "ログインが必要です"
    end
  end
end

# app/controllers/my/dashboard_controller.rb
class My::DashboardController < My::ApplicationController
  def index
    # ログインチェックはMy::ApplicationControllerで実施済み
    # ビューで各種設定へのリンクを表示
  end
end
```

**3. `/@username`形式のユーザープロフィール**

GitHubやTwitterと同様の`/@username`形式は、以下の利点があります：

- **ユーザーフレンドリー**: 直感的で覚えやすい（例: `typnix.com/@alice`）
- **SEO効果**: ユーザー名がURLに含まれるため、検索エンジンに有利
- **シェアしやすい**: SNSでシェアする際に見栄えが良い
- **拡張性**: 将来的に`/@username/lessons`などのサブページを追加可能

```ruby
# config/routes.rb
get "/@:username", to: "profiles#show", as: :profile, constraints: { username: /[^\/]+/ }

# app/controllers/profiles_controller.rb
class ProfilesController < ApplicationController
  def show
    username = params[:username]

    # usernameで検索（大文字小文字を区別しない）
    @user = User.find_by("LOWER(username) = ?", username.downcase)

    unless @user
      redirect_to root_path, alert: "ユーザーが見つかりませんでした"
      return
    end
  end
end
```

**ルーティング制約の重要性**

`constraints: { username: /[^\/]+/ }`は、ドット（`.`）を含むusernameに対応するために必要です。Railsのデフォルトルーティングでは、ドットは拡張子として解釈されるため、`alice.bob`のようなusernameがある場合、`.bob`が拡張子として扱われてしまいます。この制約により、「スラッシュ以外の任意の文字列」をusernameとして認識させることができます。

**4. RESTful設計の徹底**

Rails標準の`resources`ルーティングを活用することで、以下のメリットがあります：

- **統一インターフェース**: 一貫性のあるURL設計（例: `/my/keymaps/1/edit`）
- **予測可能性**: Railsの慣習に従うことで、開発者が直感的に理解できる
- **ヘルパーメソッドの自動生成**: `edit_my_keymap_path(keymap)`などのヘルパーが自動生成される
- **保守性向上**: Railsコミュニティのベストプラクティスに準拠

```ruby
# 単数形resource vs 複数形resources

# 複数形resources: IDベースのCRUD（通常のリソース）
resources :keymaps, only: [ :index, :new, :create, :edit, :update, :destroy ]
# GET    /my/keymaps          -> index
# GET    /my/keymaps/new      -> new
# POST   /my/keymaps          -> create
# GET    /my/keymaps/1/edit   -> edit
# PATCH  /my/keymaps/1        -> update
# DELETE /my/keymaps/1        -> destroy

# 単数形resource: IDなしのリソース（ユーザー固有のリソース）
resource :account, only: [ :edit, :update ]
# GET    /my/account/edit     -> edit
# PATCH  /my/account          -> update
```

**5. YAGNI原則の実践**

YAGNI（You Aren't Gonna Need It）原則は、「今必要ないものは作らない」という考え方です。Day 17では、以下の判断を行いました：

- **スラッグは不要**: 現時点では数値IDで十分であり、スラッグは将来必要になったら追加する
- **カテゴリ階層は不要**: `/lessons/:id`で十分であり、カテゴリはレッスン情報に含める
- **複雑なバリデーションは不要**: usernameの基本的なバリデーションのみ実装（Gmail互換）

```ruby
# YAGNI原則に基づいた設計判断の例

# ❌ 過剰な設計（スラッグ追加）
class Lesson
  validates :slug, presence: true, uniqueness: true
  before_validation :generate_slug

  def generate_slug
    self.slug = name.parameterize if slug.blank?
  end
end

# ✅ シンプルな設計（数値IDのみ）
class Lesson
  # スラッグは不要、IDで十分
end
```

**YAGNI vs BDUF（Big Design Up Front）のバランス**

YAGNI原則を徹底しすぎると、将来の拡張が困難になることもあります。Day 17では、以下のバランスを取りました：

- **数値IDベース**: 将来のDB化を見据えた設計（適度な先読み）
- **スラッグは不要**: 現時点で必要ないため実装しない（YAGNI）
- **`/@username`形式**: 将来的なサブページ追加に対応しやすい（適度な先読み）

---

#### 実装のポイント

**1. username機能の実装**

Day 17では、`/@username`形式のプロフィールURLを実装するために、Userモデルにusernameカラムを追加しました。

**マイグレーション:**

```ruby
# db/migrate/20251217022209_add_username_to_users.rb
class AddUsernameToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :username, :string, null: false
    add_index :users, :username, unique: true
  end
end
```

**Userモデルのバリデーション:**

```ruby
# app/models/user.rb
class User < ApplicationRecord
  validates :username, presence: true, uniqueness: { case_sensitive: false },
                       format: { with: /\A[a-z0-9]+(?:[._-][a-z0-9]+)*\z/,
                                message: "は半角英数字、ハイフン、アンダースコア、ドットのみ使用できます（記号は連続不可、先頭・末尾不可）" },
                       length: { minimum: 3, maximum: 30 }

  # Gmailアドレスからユニークなusernameを生成
  def self.generate_unique_username(email)
    # Gmailアドレスの@の前の部分を取得し、小文字化
    username_base = email.split("@").first.downcase

    # 既存のusernameと重複しないようにする
    username = username_base
    counter = 1
    while exists?(username: username)
      username = "#{username_base}#{counter}"
      counter += 1
    end

    username
  end

  # Google IDトークンのペイロードからユーザーを検索または作成
  def self.from_google(payload)
    where(google_uid: payload["sub"]).first_or_create do |user|
      user.email = payload["email"]
      user.name = payload["name"]
      user.icon_url = payload["picture"]
      user.username = generate_unique_username(payload["email"])
    end
  end
end
```

**Gmail互換のバリデーションルール:**

- 半角英数字、ハイフン、アンダースコア、ドットのみ使用可能
- 記号は連続不可（`alice..bob`は不可）
- 先頭・末尾に記号は不可（`.alice`や`alice.`は不可）
- 3文字以上30文字以下
- 大文字小文字を区別しないユニーク制約

**2. アカウント設定画面の実装**

Day 17では、usernameを編集できるアカウント設定画面を実装しました。

```ruby
# app/controllers/my/accounts_controller.rb
class My::AccountsController < My::ApplicationController
  def edit
    @user = current_user
  end

  def update
    @user = current_user

    if @user.update(account_params)
      redirect_to edit_my_account_path, notice: "アカウント設定を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def account_params
    params.require(:user).permit(:name, :username)
  end
end
```

**Strong Parametersの重要性:**

`account_params`メソッドでは、`permit`を使って許可するパラメータを明示的に指定しています。これにより、悪意のあるユーザーが`admin`フラグなどの意図しないパラメータを送信しても、無視されます（Mass Assignment脆弱性対策）。

**3. 301リダイレクトによる旧URL対応**

Day 17では、旧URL（`/practices/:id`）から新URL（`/lessons/:id`）への301リダイレクトを実装しました。

```ruby
# config/routes.rb
get "/practices/:id", to: redirect("/lessons/%{id}", status: 301)
```

**301リダイレクトの重要性:**

- **SEO保護**: 検索エンジンに「URLが永久に変更された」ことを伝える
- **ブックマーク対応**: ユーザーの古いブックマークが引き続き機能する
- **外部リンク対応**: 他サイトからのリンクが404にならない

**4. controller: オプションの活用**

Day 17では、URLとコントローラー名を分離するため、`controller:`オプションを活用しました。

```ruby
# config/routes.rb
namespace :my do
  # URL: /my/history
  # Controller: My::LessonRecordsController
  resources :history, only: [ :index ], controller: "lesson_records"
end
```

**なぜ`controller:`オプションを使うのか:**

- **URLの簡潔化**: `/my/lesson_records`よりも`/my/history`の方が直感的
- **ドメイン用語の統一**: ユーザー向けには「履歴（history）」、内部的には「レッスン記録（lesson_records）」
- **柔軟性**: URLとコントローラーを独立して変更可能

---

### Typnixプロジェクトでの実例

**ファイル**: `config/routes.rb`（Day 17後の全体構造）

```ruby
Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # Authentication routes
  post "/auth/google", to: "sessions#create"
  delete "/logout", to: "sessions#destroy"

  # Public pages
  root "home#index"
  resources :lessons, only: [ :show ]

  # 旧URLからのリダイレクト（301 Moved Permanently）
  get "/practices/:id", to: redirect("/lessons/%{id}", status: 301)

  # Share pages (public)
  resources :shares, only: [ :show, :create ], param: :token

  get "about", to: "pages#about"
  get "terms", to: "pages#terms"
  get "privacy", to: "pages#privacy"

  # User profiles (public, /@username形式)
  get "/@:username", to: "profiles#show", as: :profile, constraints: { username: /[^\/]+/ }

  # Personal pages (authentication required, /my namespace)
  namespace :my do
    root to: "dashboard#index"  # /my
    resources :keymaps, only: [ :index, :new, :create, :edit, :update, :destroy ], param: :slug
    resources :lessons, only: [ :index, :new, :create, :edit, :update, :destroy ]
    resources :history, only: [ :index ], controller: "lesson_records"  # /my/history
    resource :account, only: [ :edit, :update ]  # /my/account/edit
  end

  # Admin pages (authentication + admin permission required, /admin namespace)
  namespace :admin do
    root to: "dashboard#index"  # /admin
    resources :users, only: [ :index, :show ]
    resources :categories, except: [ :show ]
    # ...その他の管理者ページ
  end
end
```

**使用箇所:**

- `/`: トップページ（レッスン一覧）
- `/lessons/1`: レッスンページ（例: 上段キー練習）
- `/@alice`: ユーザー「alice」のプロフィール
- `/my`: マイページ（設定ダッシュボード）
- `/my/history`: 練習履歴
- `/my/keymaps/my-keymap/edit`: キーマップ「my-keymap」の編集
- `/my/account/edit`: アカウント設定
- `/admin`: 管理者ダッシュボード
- `/admin/users`: ユーザー一覧

**RESTful設計の実践例:**

| HTTPメソッド | URL | アクション | 説明 |
|------------|-----|----------|------|
| GET | `/lessons` | index | レッスン一覧（未実装） |
| GET | `/lessons/1` | show | レッスン詳細 |
| GET | `/my/keymaps` | index | キーマップ一覧 |
| GET | `/my/keymaps/new` | new | 新規キーマップ作成画面 |
| POST | `/my/keymaps` | create | キーマップ作成 |
| GET | `/my/keymaps/my-keymap/edit` | edit | キーマップ編集画面 |
| PATCH | `/my/keymaps/my-keymap` | update | キーマップ更新 |
| DELETE | `/my/keymaps/my-keymap` | destroy | キーマップ削除 |

**URL生成ヘルパーの活用:**

```slim
/ app/views/my/dashboard/index.html.slim

/ マイページダッシュボード
.grid.grid-cols-1.md:grid-cols-2.gap-6
  / アカウント設定カード
  .card
    h2 アカウント設定
    = link_to "編集", edit_my_account_path, class: "btn-primary"

  / キーマップ設定カード
  .card
    h2 キーマップ設定
    = link_to "キーマップ一覧", my_keymaps_path, class: "btn-primary"

  / 練習履歴カード
  .card
    h2 練習履歴
    = link_to "履歴を見る", my_history_index_path, class: "btn-primary"
```

---

## 💡 まとめ

### 重要ポイント

- ✅ **数値IDベースのシンプル設計**: スラッグは現時点で不要、YAGNIに従う
- ✅ **RESTful設計の徹底**: `resources`ルーティングを活用し、Rails標準に準拠
- ✅ **名前空間による整理**: `/my`（個人ページ）、`/admin`（管理者ページ）で明確に分離
- ✅ **`/@username`形式**: ユーザーフレンドリーで拡張性の高いURL
- ✅ **DRY原則の実践**: `My::ApplicationController`で認証ロジックを集約
- ✅ **301リダイレクト**: 旧URLからの移行をスムーズに実施
- ✅ **controller: オプション**: URLとコントローラー名を分離し、柔軟性を向上

### RESTful設計の5原則（再掲）

1. **リソース指向**: URLはリソースを表現する（例: `/lessons/1`）
2. **HTTPメソッドの活用**: GET（読み取り）、POST（作成）、PUT/PATCH（更新）、DELETE（削除）
3. **ステートレス**: リクエストごとに完結する
4. **階層構造**: リソース間の関係を階層的に表現する（例: `/my/keymaps/1`）
5. **統一インターフェース**: 一貫性のあるURL設計

### YAGNI vs BDUF のバランス

- **YAGNI（You Aren't Gonna Need It）**: 今必要ないものは作らない
- **BDUF（Big Design Up Front）**: 将来を見据えた設計
- **バランス**: Day 17では、数値IDベース（適度な先読み）とスラッグなし（YAGNI）のバランスを取った

### 次のステップ

このトピックを理解したら、以下に進むことをお勧めします：

- [Concernパターンによるコードの共通化](../02_intermediate/07_concern_pattern.md)
- [セキュリティベストプラクティス](../03_advanced/01_security_best_practices.md)
- [Review Test #05: RESTfulなURL設計のレビュー](../../reviews/review_05_restful_url_design.md)

---

## 🔗 関連教材

- [パーシャル化によるDRY原則の実践](../02_intermediate/04_dry_partials.md)
- [データマイグレーション3段階アプローチ](../03_advanced/02_data_migration.md)
- [Turbo Framesによる部分更新](../02_intermediate/08_turbo_frames.md)
- [Day 17の日報](../../../daily_reports/2025-12-17.md)

---

## 📝 演習問題（オプション）

### 問題1: RESTfulなURL設計

以下のリソースに対して、RESTfulなURL設計を行ってください：

- ユーザー（User）
- ユーザーが投稿した記事（Post）
- 記事に付いたコメント（Comment）

**要件:**
- 7つのRESTfulアクション（index, show, new, create, edit, update, destroy）をすべて含める
- ネストされたリソース（例: `/users/1/posts`）も含める
- routes.rbの記述例を示す

<details>
<summary>解答例を表示</summary>

```ruby
# config/routes.rb

Rails.application.routes.draw do
  # ユーザー
  resources :users, only: [ :index, :show ] do
    # ユーザーの記事（ネストされたリソース）
    resources :posts, only: [ :index, :new, :create ]
  end

  # 記事（トップレベル）
  resources :posts, only: [ :show, :edit, :update, :destroy ] do
    # 記事のコメント（ネストされたリソース）
    resources :comments, only: [ :index, :new, :create ]
  end

  # コメント（トップレベル）
  resources :comments, only: [ :show, :edit, :update, :destroy ]
end
```

**URL例:**

| HTTPメソッド | URL | アクション | 説明 |
|------------|-----|----------|------|
| GET | `/users` | index | ユーザー一覧 |
| GET | `/users/1` | show | ユーザー詳細 |
| GET | `/users/1/posts` | index | ユーザー1の記事一覧 |
| GET | `/users/1/posts/new` | new | ユーザー1の新規記事作成画面 |
| POST | `/users/1/posts` | create | ユーザー1の記事作成 |
| GET | `/posts/5` | show | 記事5詳細 |
| GET | `/posts/5/edit` | edit | 記事5編集画面 |
| PATCH | `/posts/5` | update | 記事5更新 |
| DELETE | `/posts/5` | destroy | 記事5削除 |
| GET | `/posts/5/comments` | index | 記事5のコメント一覧 |
| GET | `/posts/5/comments/new` | new | 記事5の新規コメント作成画面 |
| POST | `/posts/5/comments` | create | 記事5のコメント作成 |
| GET | `/comments/10` | show | コメント10詳細 |
| GET | `/comments/10/edit` | edit | コメント10編集画面 |
| PATCH | `/comments/10` | update | コメント10更新 |
| DELETE | `/comments/10` | destroy | コメント10削除 |

**解説:**

- **ネストの深さは2階層まで**: `/users/1/posts/5/comments`のように3階層にすると複雑になるため、コメントの詳細はトップレベルに配置（`/comments/10`）
- **一覧と作成はネスト**: ユーザーの記事一覧（`/users/1/posts`）や記事のコメント一覧（`/posts/5/comments`）はネストして、親リソースとの関係を明示
- **詳細・編集・削除はトップレベル**: 記事の詳細（`/posts/5`）やコメントの詳細（`/comments/10`）はトップレベルに配置し、URLを簡潔に保つ

</details>

---

### 問題2: YAGNI原則の判断

以下のシナリオで、YAGNI原則に基づいてどちらの設計を採用すべきか判断してください：

**シナリオ:**
ブログシステムを構築しています。記事（Post）のURLを以下の2つから選ぶ必要があります：

- **案A**: `/posts/:id`（数値IDベース）
- **案B**: `/posts/:slug`（スラッグベース、例: `/posts/my-first-article`）

**要件:**
- 現時点では記事数は少なく、スラッグの重複は発生していない
- 将来的には記事数が増える可能性がある
- SEOを重視したい
- 実装コストを抑えたい

**判断基準:**
1. どちらの設計を採用すべきか
2. その理由を3つ挙げる
3. 採用しなかった設計の欠点を2つ挙げる

<details>
<summary>解答例を表示</summary>

### 解答: 案Bを採用（スラッグベース）

**理由:**

1. **SEO効果が高い**: `/posts/my-first-article`のようにURLに記事タイトルが含まれるため、検索エンジンに有利
2. **ユーザーフレンドリー**: URLを見ただけで記事内容が推測でき、シェアしやすい
3. **ブックマークに強い**: 記事タイトルがURLに含まれるため、ブックマーク一覧で識別しやすい

**案A（数値IDベース）の欠点:**

1. **SEO効果が低い**: `/posts/123`のようなURLは、検索エンジンが内容を推測できない
2. **ユーザー体験の低下**: URLから記事内容が分からず、シェアやブックマークに不便

**補足:**

Day 17のTypnixプロジェクトでは数値IDベースを採用しましたが、これはレッスンがSEOよりも「機能」として重視されるためです。一方、ブログのような「コンテンツ」を扱うシステムでは、SEOが重要であるため、スラッグベースが適しています。

**YAGNI原則との関係:**

- **ブログシステム**: SEOは初期段階から重要であるため、スラッグは「今必要なもの」→ 案Bを採用
- **Typnixプロジェクト（Day 17）**: レッスンのシェアやSEOは後回しで良いため、スラッグは「今必要ないもの」→ 案Aを採用

**教訓:**

YAGNI原則は「絶対にシンプルにする」という意味ではなく、「今の要件に対して必要なものだけを実装する」という意味です。ブログシステムではSEOが要件であるため、スラッグは必要です。

</details>

---

### 問題3: 名前空間の設計

以下のページを持つECサイトを構築しています。適切な名前空間を設計してください：

**ページ一覧:**
- 商品一覧（公開）
- 商品詳細（公開）
- ショッピングカート（ログイン必須）
- 注文履歴（ログイン必須）
- アカウント設定（ログイン必須）
- 商品管理（管理者のみ）
- 注文管理（管理者のみ）
- ユーザー管理（管理者のみ）

**要件:**
- 公開ページ、ログイン必須ページ、管理者ページを明確に分離する
- routes.rbの記述例を示す
- 各名前空間のベースコントローラーを示す

<details>
<summary>解答例を表示</summary>

```ruby
# config/routes.rb

Rails.application.routes.draw do
  # Public pages
  root "products#index"
  resources :products, only: [ :index, :show ]

  # Personal pages (authentication required, /my namespace)
  namespace :my do
    root to: "dashboard#index"  # /my
    resource :cart, only: [ :show, :update ]  # /my/cart
    resources :orders, only: [ :index, :show ]  # /my/orders
    resource :account, only: [ :edit, :update ]  # /my/account
  end

  # Admin pages (authentication + admin permission required, /admin namespace)
  namespace :admin do
    root to: "dashboard#index"  # /admin
    resources :products, only: [ :index, :new, :create, :edit, :update, :destroy ]
    resources :orders, only: [ :index, :show, :update ]
    resources :users, only: [ :index, :show ]
  end
end
```

**ベースコントローラー:**

```ruby
# app/controllers/my/application_controller.rb
class My::ApplicationController < ApplicationController
  before_action :require_login

  private

  def require_login
    unless logged_in?
      redirect_to root_path, alert: "ログインが必要です"
    end
  end
end

# app/controllers/admin/application_controller.rb
class Admin::ApplicationController < ApplicationController
  before_action :require_login
  before_action :require_admin

  private

  def require_login
    unless logged_in?
      redirect_to root_path, alert: "ログインが必要です"
    end
  end

  def require_admin
    unless current_user.admin?
      redirect_to root_path, alert: "管理者権限が必要です"
    end
  end
end
```

**URL例:**

| ページ | URL | 認証 | 権限 |
|--------|-----|------|------|
| 商品一覧 | `/products` | 不要 | - |
| 商品詳細 | `/products/1` | 不要 | - |
| マイページ | `/my` | 必要 | - |
| ショッピングカート | `/my/cart` | 必要 | - |
| 注文履歴 | `/my/orders` | 必要 | - |
| アカウント設定 | `/my/account/edit` | 必要 | - |
| 管理者ダッシュボード | `/admin` | 必要 | 管理者 |
| 商品管理 | `/admin/products` | 必要 | 管理者 |
| 注文管理 | `/admin/orders` | 必要 | 管理者 |
| ユーザー管理 | `/admin/users` | 必要 | 管理者 |

**解説:**

- **公開ページ**: 名前空間なし（トップレベル）
- **個人ページ**: `/my`名前空間（ログイン必須、My::ApplicationControllerで認証チェック）
- **管理者ページ**: `/admin`名前空間（ログイン + 管理者権限必須、Admin::ApplicationControllerで権限チェック）
- **単数形resource**: ショッピングカート（`resource :cart`）とアカウント設定（`resource :account`）はIDなしのリソース

</details>

---

**作成日**: 2026-01-01
**難易度**: 🟡 中級
**推定学習時間**: 1.5〜2時間
