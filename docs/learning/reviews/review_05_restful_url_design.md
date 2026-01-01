# Review Test #05: RESTfulなURL設計とルーティング

**難易度**: 🟡 中級
**推定時間**: 40分〜1時間
**学習トピック**: [RESTfulなURL設計とルーティング](../topics/02_intermediate/05_restful_url_design.md)

---

## 前提条件

あなたはFlexitypeプロジェクトのコードレビュアーです。
以下のPRがレビュー待ちになっています。

## PR概要

- **タイトル**: ユーザープロフィールURL改善とslug対応
- **変更ファイル数**: 7ファイル
- **目的**: ユーザープロフィールのURLをより魅力的にし、SEO効果を高める

## 変更内容

### 1. `config/routes.rb` (既存)

```ruby
Rails.application.routes.draw do
  # Public pages
  root "home#index"
  resources :practices, only: [ :show ]

  # User profiles (public, /@username-slug形式)
  get "/@:username/:slug", to: "profiles#show", as: :profile,
      constraints: { username: /[^\/]+/, slug: /[^\/]+/ }

  # Personal pages (no namespace)
  get "history", to: "history#index"
  get "keymaps/edit", to: "keymaps#edit"
  get "account/edit", to: "accounts#edit"
  patch "account", to: "accounts#update"

  # Admin pages (authentication + admin permission required, /admin namespace)
  namespace :admin do
    root to: "dashboard#index"
    resources :users, only: [ :index, :show ]
  end
end
```

**約40行のコード**

### 2. `app/controllers/profiles_controller.rb` (既存)

```ruby
class ProfilesController < ApplicationController
  include UserStatistics

  def show
    # /@username/slug 形式のユーザープロフィール表示
    username = params[:username]
    slug = params[:slug]

    # usernameとslugで検索（大文字小文字を区別しない）
    @user = User.find_by("LOWER(username) = ? AND LOWER(slug) = ?", username.downcase, slug.downcase)

    unless @user
      redirect_to root_path, alert: "ユーザーが見つかりませんでした"
      return
    end

    # 統計情報を読み込む（Concern使用）
    load_user_statistics(@user)
  end
end
```

**約25行のコード**

### 3. `app/controllers/history_controller.rb` (既存)

```ruby
class HistoryController < ApplicationController
  before_action :require_login

  def index
    @lesson_records = current_user.lesson_records.order(created_at: :desc)
  end

  private

  def require_login
    unless logged_in?
      redirect_to root_path, alert: "ログインが必要です"
    end
  end
end
```

**約20行のコード**

### 4. `app/controllers/keymaps_controller.rb` (既存)

```ruby
class KeymapsController < ApplicationController
  before_action :require_login

  def edit
    @keymap_set = current_user.active_keymap_set
  end

  def update
    @keymap_set = current_user.active_keymap_set
    if @keymap_set.update(keymap_params)
      redirect_to edit_keymaps_path, notice: "キーマップを更新しました"
    else
      render :edit
    end
  end

  private

  def require_login
    unless logged_in?
      redirect_to root_path, alert: "ログインが必要です"
    end
  end

  def keymap_params
    params.require(:keymap_set).permit(:name, :description)
  end
end
```

**約35行のコード**

### 5. `app/controllers/accounts_controller.rb` (既存)

```ruby
class AccountsController < ApplicationController
  before_action :require_login

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update(account_params)
      redirect_to edit_account_path, notice: "アカウント設定を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def require_login
    unless logged_in?
      redirect_to root_path, alert: "ログインが必要です"
    end
  end

  def account_params
    params.require(:user).permit(:name, :username, :slug)
  end
end
```

**約30行のコード**

### 6. `db/migrate/20251217030000_add_slug_to_users.rb` (新規作成)

```ruby
class AddSlugToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :slug, :string
    add_index :users, :slug, unique: true

    # 既存ユーザーにslugを自動生成
    reversible do |dir|
      dir.up do
        User.find_each do |user|
          user.update_column(:slug, user.username.parameterize)
        end
      end
    end

    # NOT NULL制約を追加
    change_column_null :users, :slug, false
  end
end
```

**約20行のコード**

### 7. `app/models/user.rb` (既存)

```ruby
class User < ApplicationRecord
  # ...その他のコード

  validates :username, presence: true, uniqueness: { case_sensitive: false },
                       format: { with: /\A[a-z0-9]+(?:[._-][a-z0-9]+)*\z/ },
                       length: { minimum: 3, maximum: 30 }

  validates :slug, presence: true, uniqueness: { case_sensitive: false },
                   format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/ },
                   length: { minimum: 3, maximum: 50 }

  before_validation :generate_slug, if: :slug_blank?

  # Gmailアドレスからユニークなusernameを生成
  def self.generate_unique_username(email)
    username_base = email.split("@").first.downcase
    username = username_base
    counter = 1
    while exists?(username: username)
      username = "#{username_base}#{counter}"
      counter += 1
    end
    username
  end

  # ...その他のコード

  private

  def slug_blank?
    slug.blank?
  end

  def generate_slug
    self.slug = username.parameterize
    counter = 1
    while User.exists?(slug: slug)
      self.slug = "#{username.parameterize}-#{counter}"
      counter += 1
    end
  end
end
```

**約50行のコード（変更箇所のみ抜粋）**

---

## レビュー課題

### Q1. 基本的なルーティング問題（初級）🟢

このPRのroutes.rbを見て、以下の問題点を指摘してください：

1. 個人ページ（`history`, `keymaps/edit`, `account/edit`）のURL設計で、RESTful設計の観点から問題となる点を3つ挙げてください。
2. `resources :practices`という命名は、Day 17後のTypnixプロジェクトでは何に変更されていますか？その理由を説明してください。
3. ルーティングに名前空間が欠けている箇所を指摘し、どのように改善すべきか提案してください。

**回答時間の目安**: 10分

<details>
<summary>解答を表示</summary>

### A1. 基本的なルーティング問題

**1. 個人ページのURL設計の問題点:**

**問題点1: RESTfulな設計ではない**

- `get "history", to: "history#index"`: `resources`を使うべき
- `get "keymaps/edit", to: "keymaps#edit"`: IDが欠けており、RESTful設計ではない
- `get "account/edit", to: "accounts#edit"`: `resource`（単数形）を使うべき

**問題点2: HTTPメソッドの不統一**

- `patch "account", to: "accounts#update"`: `resource :account`を使えば自動的に生成される

**問題点3: 名前空間の欠如**

- 個人ページが認証必須であることがURL構造から不明瞭
- `/my`名前空間を使うべき（Day 17の改善例を参照）

**2. `resources :practices`の変更:**

Day 17後のTypnixプロジェクトでは、`resources :lessons, only: [ :show ]`に変更されています。

**理由:**

- **ドメイン用語の統一**: 内部的には「Lesson」モデルを使用しているため、URLも統一した
- **意味の明確化**: 「practices（練習）」よりも「lessons（レッスン）」の方が、「学習コンテンツ」を表現するのに適している
- **将来のDB化**: LessonモデルをDB化する際、URLとモデル名が一致する方が分かりやすい

**3. 名前空間が欠けている箇所:**

個人ページ（`history`, `keymaps/edit`, `account/edit`）に名前空間がありません。

**改善案:**

```ruby
# 改善後
namespace :my do
  root to: "dashboard#index"  # /my
  resources :history, only: [ :index ], controller: "lesson_records"
  resources :keymaps, only: [ :edit, :update ]
  resource :account, only: [ :edit, :update ]
end
```

**メリット:**

- `/my`配下は認証必須と一目で分かる
- My::ApplicationControllerで認証ロジックを一元管理できる
- DRY原則の徹底（各コントローラで`before_action :require_login`を書く必要がない）

</details>

---

### Q2. スラッグの必要性とYAGNI原則（中級）🟡

このPRでは、ユーザープロフィールURLを`/@username`から`/@username/:slug`に変更し、Userモデルにslugカラムを追加しています。

1. slugを追加することで得られるメリットを2つ挙げてください。
2. 一方で、Day 17のTypnixプロジェクトではslugを追加しませんでした。YAGNI（You Aren't Gonna Need It）原則の観点から、slugを追加しなかった理由を3つ挙げてください。
3. このPRでslugを追加することは、YAGNI原則違反と言えるでしょうか？あなたの意見を述べてください。

**回答時間の目安**: 15分

<details>
<summary>解答を表示</summary>

### A2. スラッグの必要性とYAGNI原則

**1. slugを追加することで得られるメリット:**

**メリット1: SEO効果の向上**

- `/@alice/my-awesome-profile`のように、URLにキーワードが含まれるため、検索エンジンに有利
- ユーザープロフィールが検索結果に表示されやすくなる

**メリット2: ユーザーフレンドリー**

- URLを見ただけでプロフィール内容が推測できる
- SNSでシェアする際に見栄えが良い

**2. Day 17でslugを追加しなかった理由（YAGNI原則）:**

**理由1: 現時点で必要ない**

- ユーザープロフィールのSEO効果は、現時点では優先度が低い
- `/@username`で十分であり、slugがなくても機能する

**理由2: 実装コストが高い**

- slug生成ロジック、バリデーション、重複チェック、マイグレーションなど、実装に時間がかかる
- Day 17の時点では、他に優先すべきタスク（`/my`名前空間への移行など）があった

**理由3: 拡張性への影響が小さい**

- 将来的にslugが必要になったら、その時点で追加すれば良い
- 数値IDベースの設計（`/@username`）は、slugを後から追加しても問題ない

**3. このPRでslugを追加することは、YAGNI原則違反か:**

**意見: 状況による（コンテキスト依存）**

**YAGNI原則違反と言える場合:**

- ユーザープロフィールのSEOが現時点で重要でない場合
- slugを使った具体的なユースケース（例: プロフィールのカスタマイズ、複数プロフィール作成など）が存在しない場合
- 実装コストが他のタスクに比べて高い場合

**YAGNI原則違反でない場合:**

- ユーザープロフィールが「コンテンツ」として重要であり、SEOが初期段階から要件に含まれる場合
- ブログやポートフォリオサイトのように、URLの美しさが重要な場合
- slugを使った具体的なユースケースが既に存在する場合（例: 複数のプロフィールページを持つ機能）

**Typnixプロジェクトの場合:**

Typnixはタイピングアプリであり、ユーザープロフィールは「成果シェア」のための補助的な機能です。現時点では`/@username`で十分であり、slugは「今必要ないもの」と判断できます。したがって、Day 17でslugを追加しなかったのは、YAGNI原則に従った正しい判断と言えます。

**教訓:**

YAGNI原則は「絶対にシンプルにする」という意味ではなく、「今の要件に対して必要なものだけを実装する」という意味です。要件次第では、slugは「今必要なもの」になります。

</details>

---

### Q3. `/my`名前空間の提案とcontroller:オプションの活用（中級〜上級）🟡🔴

このPRには、個人ページに名前空間が欠けています。Day 17のTypnixプロジェクトのように、`/my`名前空間を導入する形で改善案を提示してください。

1. routes.rbの改善案を示してください（`namespace :my`を使用）。
2. 各コントローラを`My::`名前空間に移動し、DRY原則に従って認証ロジックを集約してください。具体的には、`My::ApplicationController`を作成し、継承構造を示してください。
3. `/my/history`というURLで、コントローラは`My::LessonRecordsController`を使いたい場合、`controller:`オプションをどのように活用しますか？routes.rbの該当箇所を示してください。

**回答時間の目安**: 20分

<details>
<summary>解答を表示</summary>

### A3. `/my`名前空間の提案とcontroller:オプションの活用

**1. routes.rbの改善案:**

```ruby
# config/routes.rb（改善後）

Rails.application.routes.draw do
  # Public pages
  root "home#index"
  resources :lessons, only: [ :show ]  # practices → lessonsに変更

  # User profiles (public, /@username形式、slugは削除)
  get "/@:username", to: "profiles#show", as: :profile, constraints: { username: /[^\/]+/ }

  # Personal pages (authentication required, /my namespace)
  namespace :my do
    root to: "dashboard#index"  # /my
    resources :keymaps, only: [ :index, :new, :create, :edit, :update, :destroy ]
    resources :history, only: [ :index ], controller: "lesson_records"  # /my/history
    resource :account, only: [ :edit, :update ]  # /my/account/edit
  end

  # Admin pages (authentication + admin permission required, /admin namespace)
  namespace :admin do
    root to: "dashboard#index"  # /admin
    resources :users, only: [ :index, :show ]
  end
end
```

**ポイント:**

- **個人ページを`/my`配下に集約**: 認証が必要なページを明確に分離
- **slugを削除**: YAGNI原則に従い、現時点で不要なslugは削除
- **practices → lessonsに変更**: ドメイン用語の統一
- **`resource :account`（単数形）**: アカウント設定はIDなしのリソース
- **`resources :keymaps`（複数形）**: キーマップは複数管理可能なリソース

**2. コントローラの改善案（継承構造）:**

```ruby
# app/controllers/my/application_controller.rb（新規作成）
class My::ApplicationController < ApplicationController
  before_action :require_login

  private

  def require_login
    unless logged_in?
      redirect_to root_path, alert: "ログインが必要です"
    end
  end
end

# app/controllers/my/dashboard_controller.rb（新規作成）
class My::DashboardController < My::ApplicationController
  def index
    # マイページ（設定ダッシュボード）
    # ビューで各種設定へのリンクを表示
  end
end

# app/controllers/my/lesson_records_controller.rb（既存のHistoryControllerを移動）
class My::LessonRecordsController < My::ApplicationController
  def index
    @lesson_records = current_user.lesson_records.order(created_at: :desc)
  end
end

# app/controllers/my/keymaps_controller.rb（既存のKeymapsControllerを移動）
class My::KeymapsController < My::ApplicationController
  def edit
    @keymap_set = current_user.active_keymap_set
  end

  def update
    @keymap_set = current_user.active_keymap_set
    if @keymap_set.update(keymap_params)
      redirect_to edit_my_keymap_path(@keymap_set), notice: "キーマップを更新しました"
    else
      render :edit
    end
  end

  private

  def keymap_params
    params.require(:keymap_set).permit(:name, :description)
  end
end

# app/controllers/my/accounts_controller.rb（既存のAccountsControllerを移動）
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
    params.require(:user).permit(:name, :username)  # slugを削除
  end
end
```

**ポイント:**

- **My::ApplicationController**: 認証ロジック（`before_action :require_login`）を一元管理
- **DRY原則の徹底**: 各コントローラで`before_action`を重複して書く必要がない
- **継承構造**: すべての個人ページコントローラが`My::ApplicationController`を継承
- **slugを削除**: Userモデルからslugカラムを削除し、`account_params`からも削除

**3. controller:オプションの活用:**

```ruby
# config/routes.rb（該当箇所）

namespace :my do
  # URL: /my/history
  # Controller: My::LessonRecordsController
  resources :history, only: [ :index ], controller: "lesson_records"
end
```

**なぜcontroller:オプションを使うのか:**

- **URLの簡潔化**: `/my/lesson_records`よりも`/my/history`の方が直感的
- **ドメイン用語の統一**: ユーザー向けには「履歴（history）」、内部的には「レッスン記録（lesson_records）」
- **柔軟性**: URLとコントローラーを独立して変更可能

**コード削減効果:**

- **削除**: 約30行（各コントローラの`before_action :require_login`と`require_login`メソッド）
- **追加**: 約10行（`My::ApplicationController`）
- **純削減**: 約20行

**URL例:**

| 変更前 | 変更後 | HTTPメソッド |
|--------|--------|-------------|
| `/history` | `/my/history` | GET |
| `/keymaps/edit` | `/my/keymaps/1/edit` | GET |
| `/account/edit` | `/my/account/edit` | GET |
| `/account` | `/my/account` | PATCH |

</details>

---

### Q4. URL設計の総合判断（上級）🔴

このPRの設計判断を総合的に評価してください。以下の観点から分析し、Day 17のTypnixプロジェクトと比較してください。

**評価観点:**

1. **SEO vs 実装コスト**: slugを追加することで得られるSEO効果と、実装コストのトレードオフをどう判断すべきか
2. **ユーザー名変更の影響**: `/@username/:slug`の場合、usernameを変更するとURLが変わってしまいます。この問題をどう解決すべきか（Day 24のTypnixプロジェクトでは24時間制限を導入しています）
3. **将来の拡張性**: 数値IDベース（`/@username`）とslugベース（`/@username/:slug`）では、どちらが拡張性が高いか

**回答時間の目安**: 15分

<details>
<summary>解答を表示</summary>

### A4. URL設計の総合判断

#### 1. SEO vs 実装コスト

**SEO効果の評価:**

ユーザープロフィールのSEO効果は、アプリケーションの性質によって大きく異なります。

**ブログやポートフォリオサイト:**
- ユーザープロフィールが「コンテンツ」の中心である場合、SEO効果は高い
- slugを使った美しいURL（`/@alice/my-awesome-profile`）は、SNSでシェアされやすい
- 実装コストに見合う価値がある

**Typnixプロジェクト（タイピングアプリ）:**
- ユーザープロフィールは「成果シェア」のための補助的な機能
- SEO効果よりも、タイピング練習の機能充実が優先度が高い
- 実装コストに見合う価値が低い

**実装コストの内訳:**

- slug生成ロジック（約30行）
- バリデーション（約20行）
- 重複チェック（約20行）
- マイグレーション（約20行）
- テスト（約50行）
- **合計: 約140行**

**Day 17の判断:**

Typnixプロジェクトでは、slugを追加しないことでコードを削減し、他の機能（`/my`名前空間への移行、`/@username`形式の実装など）に時間を使いました。これは、YAGNI原則に従った正しい判断と言えます。

---

#### 2. ユーザー名変更の影響

**問題点:**

`/@username/:slug`の場合、usernameを変更するとURLが変わってしまいます。例：

- 変更前: `/@alice/my-awesome-profile`
- 変更後: `/@alice2/my-awesome-profile`

これにより、以下の問題が発生します：

- **ブックマークが無効化**: ユーザーの古いブックマークが404になる
- **外部リンクが切れる**: 他サイトからのリンクが無効化される
- **SEO効果の喪失**: 検索エンジンのインデックスが無効化される

**解決策1: username変更を制限する（Day 24のTypnixプロジェクト）**

```ruby
# app/models/user.rb
class User < ApplicationRecord
  validate :username_change_allowed, if: :username_changed?

  def can_change_username?
    username_changed_at.nil? || username_changed_at < 24.hours.ago
  end

  def next_username_change_at
    return nil if username_changed_at.nil?

    username_changed_at + 24.hours
  end

  private

  def username_change_allowed
    return if new_record?
    return if can_change_username?

    next_change = next_username_change_at.strftime("%Y年%m月%d日 %H時%M分")
    errors.add(:username, "は24時間に1回しか変更できません（次回変更可能: #{next_change}）")
  end
end
```

**メリット:**
- username変更の頻度を制限することで、URL変更の影響を最小化
- 実装コストが低い

**デメリット:**
- 完全にはURL変更を防げない

**解決策2: 数値IDベースに変更する（Day 17のTypnixプロジェクト）**

```ruby
# config/routes.rb
get "/@:username", to: "profiles#show", as: :profile
```

数値IDベース（実際にはusernameだが、slugはなし）にすることで、以下のメリットがあります：

- **username変更に強い**: usernameを変更してもURLは`/@new_username`に自動的に変わる
- **シンプル**: slugの管理が不要

**デメリット:**
- SEO効果がslugベースよりも低い

**解決策3: 301リダイレクトを実装する（高度な対応）**

```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_many :username_histories, dependent: :destroy

  after_update :record_username_change, if: :saved_change_to_username?

  private

  def record_username_change
    username_histories.create!(
      old_username: username_before_last_save,
      new_username: username,
      changed_at: Time.current
    )
  end
end

# app/controllers/profiles_controller.rb
class ProfilesController < ApplicationController
  def show
    username = params[:username]

    # 現在のusernameで検索
    @user = User.find_by("LOWER(username) = ?", username.downcase)

    # 見つからない場合、過去のusernameで検索
    unless @user
      history = UsernameHistory.find_by("LOWER(old_username) = ?", username.downcase)
      if history
        redirect_to profile_path(history.user.username), status: 301
        return
      end
    end

    unless @user
      redirect_to root_path, alert: "ユーザーが見つかりませんでした"
      return
    end

    load_user_statistics(@user)
  end
end
```

**メリット:**
- 過去のusernameでアクセスしても、新しいusernameにリダイレクトされる
- ブックマークや外部リンクが引き続き機能する

**デメリット:**
- 実装コストが高い（UsernameHistoryモデル、マイグレーション、リダイレクトロジック）
- データベースに履歴を保存するため、ストレージコストが増える

**Day 17の判断:**

Typnixプロジェクトでは、解決策2（数値IDベース、slugなし）を採用し、Day 24で解決策1（24時間制限）を追加しました。これにより、シンプルな設計を維持しつつ、username変更の影響を最小化しています。

---

#### 3. 将来の拡張性

**数値IDベース（`/@username`）:**

**メリット:**
- **シンプル**: slugの管理が不要
- **username変更に強い**: usernameを変更してもURLは自動的に変わる
- **拡張性**: 将来的にslugを追加することも可能
- **実装コスト低**: Rails標準の機能で実装可能

**デメリット:**
- **SEO効果が低い**: URLにキーワードが含まれない
- **ユーザーフレンドリー度が低い**: URLから内容が推測しにくい

**slugベース（`/@username/:slug`）:**

**メリット:**
- **SEO効果が高い**: URLにキーワードが含まれる
- **ユーザーフレンドリー**: URLを見ただけで内容が推測できる

**デメリット:**
- **複雑**: slug生成、バリデーション、重複チェックなど、実装が複雑
- **username変更に弱い**: usernameを変更するとURLが変わる
- **実装コスト高**: 約140行のコードが必要

**どちらが拡張性が高いか:**

**短期的な拡張性（1-2ヶ月以内）:**

数値IDベース（`/@username`）の方が拡張性が高いです。理由は以下の通りです：

- 実装がシンプルであるため、他の機能追加に時間を使える
- slugは後から追加することも可能

**長期的な拡張性（1年以上）:**

slugベース（`/@username/:slug`）の方が拡張性が高い場合もあります。理由は以下の通りです：

- ユーザーが複数のプロフィールページを持つ機能を追加する場合、slugが必要
- ブログやポートフォリオサイトのように、URLの美しさが重要な場合、slugは必須

**Day 17の判断:**

Typnixプロジェクトでは、短期的な拡張性を優先し、数値IDベース（`/@username`）を採用しました。将来的にslugが必要になったら、その時点で追加する方針です。

---

#### まとめ

**このPRの問題点:**

1. **YAGNI原則違反**: 現時点で不要なslugを追加している
2. **名前空間の欠如**: 個人ページに`/my`名前空間がない
3. **DRY原則違反**: 各コントローラで`before_action :require_login`を重複して書いている
4. **username変更の影響**: usernameを変更するとURLが変わってしまう

**Day 17のTypnixプロジェクトとの比較:**

| 項目 | このPR | Day 17のTypnixプロジェクト |
|------|--------|--------------------------|
| slug | あり（`/@username/:slug`） | なし（`/@username`） |
| 名前空間 | なし | `/my`名前空間あり |
| DRY原則 | 各コントローラで重複 | My::ApplicationControllerで集約 |
| username変更対応 | なし | 24時間制限（Day 24） |
| 実装コスト | 高（約140行） | 低（約30行） |
| 拡張性 | slugベース | 数値IDベース |

**改善提案:**

1. slugを削除し、YAGNI原則に従う
2. `/my`名前空間を導入し、個人ページを整理する
3. `My::ApplicationController`を作成し、DRY原則を徹底する
4. username変更に24時間制限を導入する（Day 24の実装を参照）

**最終評価:**

このPRは、slugを追加することでSEO効果を狙っていますが、実装コストが高く、YAGNI原則に違反しています。Day 17のTypnixプロジェクトのように、シンプルな数値IDベース（`/@username`）を採用し、将来的に必要になったらslugを追加する方が良いでしょう。

</details>

---

## 総合評価

### 基準

- **Q1を正解**: RESTful設計の基本を理解している
- **Q2を正解**: YAGNI原則を理解し、設計判断ができる
- **Q3を正解**: 名前空間とDRY原則を実践できる
- **Q4を正解**: URL設計の総合的な判断ができる（上級レベル）

### 次のステップ

- **Q1のみ正解**: RESTful設計の基本は理解できています。[トピック教材](../topics/02_intermediate/05_restful_url_design.md)のYAGNI原則の章を復習してください。
- **Q1-Q2正解**: YAGNI原則の理解は十分です。名前空間とDRY原則の章を学習し、Q3に再挑戦してください。
- **Q1-Q3正解**: 名前空間とDRY原則を実践できています。Q4に挑戦し、URL設計の総合的な判断力を磨いてください。
- **全問正解**: おめでとうございます！RESTfulなURL設計を完全に理解しています。次は[Concernパターンによるコードの共通化](../topics/02_intermediate/07_concern_pattern.md)に進んでください。

## 参考資料

- [RESTfulなURL設計とルーティング](../topics/02_intermediate/05_restful_url_design.md)
- [パーシャル化によるDRY原則の実践](../topics/02_intermediate/04_dry_partials.md)
- Day 17の日報: `docs/daily_reports/2025-12-17.md`
- Day 24の日報: `docs/daily_reports/2025-12-24.md`（username変更制限）

---

**作成日**: 2026-01-01
**難易度**: 🟡 中級
**推定時間**: 40分〜1時間
