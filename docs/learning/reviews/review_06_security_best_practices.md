# Review Test #06: セキュリティベストプラクティス

**難易度**: 🔴 上級
**推定時間**: 40分〜1時間
**学習トピック**: [セキュリティベストプラクティス](../topics/03_advanced/06_security_best_practices.md)

---

## 前提条件

あなたはFlexitypeプロジェクトのコードレビュアーです。
以下のPRがレビュー待ちになっています。

## PR概要

- **タイトル**: ユーザー名機能の追加
- **変更ファイル数**: 5ファイル
- **目的**: `/@username` 形式でユーザープロフィールにアクセスできるようにする

## 変更内容

### 1. `db/migrate/20260101120000_add_username_to_users.rb` (新規作成)

```ruby
class AddUsernameToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :username, :string
    add_index :users, :username, unique: true
  end
end
```

**約10行のコード**

### 2. `app/models/user.rb` (既存)

```ruby
class User < ApplicationRecord
  has_many :keymap_sets, dependent: :destroy
  has_many :lesson_records, dependent: :destroy

  validates :google_uid, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true
  validates :name, presence: true, length: { maximum: 30 }
  validates :username, presence: true, uniqueness: { case_sensitive: false },
                       format: { with: /\A[a-z0-9]+(?:[._-][a-z0-9]+)*\z/ },
                       length: { minimum: 3, maximum: 30 }

  def self.from_google(payload)
    where(google_uid: payload["sub"]).first_or_create do |user|
      user.email = payload["email"]
      user.name = payload["name"]
      user.icon_url = payload["picture"]
      user.username = payload["email"].split("@").first.downcase
    end
  end
end
```

**約30行のコード**

### 3. `app/controllers/profiles_controller.rb` (新規作成)

```ruby
class ProfilesController < ApplicationController
  def show
    @user = User.find_by(username: params[:username])
    @lesson_records = @user.lesson_records.order(completed_at: :desc).limit(10)
  end
end
```

**約10行のコード**

### 4. `config/routes.rb` (既存)

```ruby
Rails.application.routes.draw do
  root "lessons#index"

  # プロフィールページ
  get "/@:username", to: "profiles#show", as: :profile

  # 既存のルート
  resources :lessons, only: [:index, :show]
  # ...
end
```

**約30行のコード**

### 5. `app/views/profiles/show.html.slim` (新規作成)

```slim
.max-w-3xl.mx-auto.p-6
  h1.text-3xl.font-bold = @user.name
  p.text-gray-600 = "@#{@user.username}"

  h2.text-2xl.font-bold.mt-8 練習履歴
  - @lesson_records.each do |record|
    .bg-white.rounded-lg.shadow-md.p-4.mb-4
      p = record.lesson.name
      p = "正答率: #{record.accuracy}%"
```

**約20行のコード**

---

## レビュー課題

### Q1. 基本的なセキュリティ問題の特定（初級）🟢

このPRには、基本的なセキュリティ問題が3つあります。それぞれ特定し、どのような脆弱性につながるか説明してください。

1. `ProfilesController#show` に欠けている重要な処理は何ですか？
2. `User.from_google` でusernameを生成する際の問題点は何ですか？
3. `config/routes.rb` に追加されたルートの潜在的な問題は何ですか？

**回答時間の目安**: 5分

<details>
<summary>解答を表示</summary>

### A1. 基本的なセキュリティ問題の特定

**1. `ProfilesController#show` に欠けている重要な処理:**

**問題点**: ユーザーが見つからない場合のエラーハンドリングがない

```ruby
# 悪い例（現在のコード）
def show
  @user = User.find_by(username: params[:username])
  @lesson_records = @user.lesson_records.order(completed_at: :desc).limit(10)
  # @user が nil の場合、NoMethodError が発生
end

# 良い例
def show
  @user = User.find_by(username: params[:username])
  return render file: "public/404.html", status: :not_found unless @user

  @lesson_records = @user.lesson_records.order(completed_at: :desc).limit(10)
end
```

**脆弱性**: NoMethodError により、システムの内部情報（スタックトレース、ファイルパスなど）が漏洩する可能性がある。

**2. `User.from_google` でusernameを生成する際の問題点:**

**問題点**: ユーザー名の重複チェックがない

```ruby
# 悪い例（現在のコード）
def self.from_google(payload)
  where(google_uid: payload["sub"]).first_or_create do |user|
    user.username = payload["email"].split("@").first.downcase
    # 既存のusernameと重複する可能性がある
  end
end

# 良い例
def self.from_google(payload)
  where(google_uid: payload["sub"]).first_or_create do |user|
    user.username = generate_unique_username(payload["email"])
  end
end

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
```

**脆弱性**: 同じメールアドレスの@の前の部分を持つユーザーが登録しようとすると、一意性制約違反でエラーになる。

**3. `config/routes.rb` に追加されたルートの潜在的な問題:**

**問題点**: システムルート（`/lessons`、`/admin` など）との衝突リスク

```ruby
# 悪い例（現在のコード）
get "/@:username", to: "profiles#show", as: :profile
# username が "lessons" の場合、"/@lessons" にアクセスすると
# プロフィールページが表示される（意図しない動作）
```

**脆弱性**: ユーザーが "admin"、"api"、"my" などのシステムルートと衝突するユーザー名を登録すると、システム機能にアクセスできなくなる。

</details>

---

### Q2. ルーティング衝突の問題（中級）🟡

`/@:username` 形式のルーティングは、Railsの他のルートと衝突する可能性があります。

1. 衝突を引き起こす可能性のあるユーザー名を5つ挙げてください。
2. この問題を解決するために、どのような対策が必要ですか？
3. 予約語リストを実装する場合、どのカテゴリーに分類すべきですか？（最低3カテゴリー）

**回答時間の目安**: 10分

<details>
<summary>解答を表示</summary>

### A2. ルーティング衝突の問題

**1. 衝突を引き起こす可能性のあるユーザー名（5つ）:**

- `admin` - 管理者ページ（`/admin`）
- `api` - APIエンドポイント（`/api`）
- `my` - 個人ページ（`/my`）
- `lessons` - レッスン一覧（`/lessons`）
- `new` - RESTfulな新規作成ページ（`/lessons/new` など）

**その他の例:**

- `login`, `logout`, `signup` - 認証関連
- `settings`, `dashboard` - 設定・管理画面
- `help`, `about`, `terms`, `privacy` - 静的ページ

**2. この問題を解決するための対策:**

**対策1: 予約語リストを作成し、バリデーションで防止**

```ruby
# config/initializers/reserved_usernames.rb
module ReservedUsernames
  LIST = %w[
    admin api my lessons new edit create update destroy
    login logout signup settings help about terms privacy
    # ...100+ の予約語
  ].freeze
end

# app/models/user.rb
validate :username_not_reserved

private

def username_not_reserved
  return if username.blank?

  if ReservedUsernames::LIST.include?(username.downcase)
    errors.add(:username, "は予約されているため使用できません")
  end
end
```

**対策2: ルーティングの優先順位を調整**

```ruby
# config/routes.rb

Rails.application.routes.draw do
  # システムルートを先に定義（優先度が高い）
  resources :lessons, only: [:index, :show]
  namespace :admin do
    # 管理者ページ
  end
  namespace :my do
    # 個人ページ
  end

  # プロフィールページは最後に定義（優先度が低い）
  get "/@:username", to: "profiles#show", as: :profile
end
```

**注意**: ルーティングの優先順位だけでは不十分。ユーザーが "lessons" という名前を登録できてしまうと、`/@lessons` にアクセスした時にプロフィールページが表示される可能性がある。

**3. 予約語リストのカテゴリー（最低3カテゴリー）:**

| カテゴリー | 例 | 理由 |
|-----------|-----|------|
| **CRUD・RESTful** | new, edit, create, update, destroy, show, index | Railsの標準ルーティング |
| **認証・アカウント** | login, logout, signup, signin, users, accounts | 認証システムの標準ルート |
| **Typnix固有のリソース** | lessons, keymaps, categories, history, shares, my | アプリケーション固有のルート |
| **管理・設定** | admin, settings, dashboard, profiles | 管理画面の標準ルート |
| **システム・インフラ** | api, webhooks, static, media, public | システムルート、静的ファイル |

**Typnixでの実装例（100+ の予約語）:**

- CRUD・RESTful: 8語
- HTTPメソッド: 7語
- 認証・アカウント: 13語
- Typnix固有のリソース: 8語
- 管理・設定: 8語
- 通知・メッセージ: 5語
- 課金・決済: 7語
- コンテンツ・メディア: 8語
- API・Webhook: 3語
- ヘルプ・情報ページ: 9語
- システム・インフラ: 15語
- 検索・エクスポート: 5語
- その他: 4語

</details>

---

### Q3. セキュリティ機能の実装（中級〜上級）🟡🔴

このPRに以下の2つのセキュリティ機能を追加してください。

1. **予約語システム**: ユーザー名が予約語でないかチェックするバリデーションを実装してください。
2. **ユーザー名変更制限**: ユーザー名を24時間に1回しか変更できないように制限してください。
3. **CSP設定**: Google Identity Services との互換性を考慮したCSP設定を追加してください。

**回答時間の目安**: 20分

<details>
<summary>解答を表示</summary>

### A3. セキュリティ機能の実装

**1. 予約語システムの実装:**

**Step 1: 予約語リストを作成**

```ruby
# config/initializers/reserved_usernames.rb
# frozen_string_literal: true

module ReservedUsernames
  LIST = %w[
    # CRUD・RESTful
    new edit create update destroy show index
    add remove list

    # HTTPメソッド
    get post put patch delete options head

    # 認証・アカウント
    login logout signup signin signout register registration
    users user accounts account
    password passwords confirmation confirmations unlock
    auth session sessions

    # Typnix固有のリソース
    lessons lesson
    keymaps keymap
    categories category
    history histories
    shares share
    my
    practices practice

    # 管理・設定
    admin admins administrator administrators
    settings setting profiles profile dashboard

    # その他（省略）
    # ...
  ].freeze
end
```

**Step 2: Userモデルにバリデーションを追加**

```ruby
# app/models/user.rb

class User < ApplicationRecord
  validates :username, presence: true, uniqueness: { case_sensitive: false },
                       format: { with: /\A[a-z0-9]+(?:[._-][a-z0-9]+)*\z/,
                                message: "は半角英数字、ハイフン、アンダースコア、ドットのみ使用できます（記号は連続不可、先頭・末尾不可）" },
                       length: { minimum: 3, maximum: 30 }
  validate :username_not_reserved

  private

  def username_not_reserved
    return if username.blank?

    if ReservedUsernames::LIST.include?(username.downcase)
      errors.add(:username, "は予約されているため使用できません")
    end
  end
end
```

**ポイント:**

- Initializerファイルで予約語リストを管理（アプリケーション起動時に一度だけロード）
- カテゴリー別に整理することで、可読性とメンテナンス性を向上
- 大文字小文字を区別しないチェック（`.downcase`）
- `validate` メソッドで独自バリデーションを実装

**2. ユーザー名変更制限の実装:**

**Step 1: マイグレーションを作成**

```ruby
# db/migrate/20260102120000_add_username_changed_at_to_users.rb

class AddUsernameChangedAtToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :username_changed_at, :datetime
  end
end
```

**Step 2: Userモデルにバリデーションとヘルパーメソッドを追加**

```ruby
# app/models/user.rb

class User < ApplicationRecord
  validate :username_change_allowed, if: :username_changed?

  # ユーザー名を変更可能かどうか
  def can_change_username?
    username_changed_at.nil? || username_changed_at < 24.hours.ago
  end

  # 次回ユーザー名変更可能日時
  def next_username_change_at
    return nil if username_changed_at.nil?

    username_changed_at + 24.hours
  end

  private

  def username_change_allowed
    return if new_record? # 新規作成時はチェックしない
    return if can_change_username?

    next_change = next_username_change_at.strftime("%Y年%m月%d日 %H時%M分")
    errors.add(:username, "は24時間に1回しか変更できません（次回変更可能: #{next_change}）")
  end
end
```

**Step 3: コントローラーでタイムスタンプを更新**

```ruby
# app/controllers/my/accounts_controller.rb

class My::AccountsController < My::ApplicationController
  def update
    @user = current_user
    username_will_change = account_params[:username].present? && @user.username != account_params[:username]

    if @user.update(account_params)
      # usernameが実際に変更された場合、username_changed_atを更新
      @user.update_column(:username_changed_at, Time.current) if username_will_change
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

**Step 4: ビューで変更可能/不可能を表示**

```slim
/ app/views/my/accounts/edit.html.slim

.space-y-2
  = f.label :username, "ユーザー名", class: "..."

  - if @user.can_change_username?
    = f.text_field :username, class: "... bg-white"
  - else
    = f.text_field :username, disabled: true, class: "... bg-gray-100 cursor-not-allowed"
    .text-sm.text-amber-600.dark:text-amber-400.mt-2.flex.items-start.gap-2
      svg.w-5.h-5.flex-shrink-0.mt-0.5 fill="currentColor" viewBox="0 0 20 20"
        path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd"
      div
        | ユーザー名は24時間に1回しか変更できません
        br
        strong = "次回変更可能: #{@user.next_username_change_at.strftime('%Y年%m月%d日 %H時%M分')}"
```

**ポイント:**

- `username_changed_at` カラムで最終変更日時を記録
- `can_change_username?` で変更可能かどうかを判定
- `update_column` で無限ループを回避（バリデーションをスキップ）
- UIでグレーアウト + 警告メッセージで明確に表示

**3. CSP設定の追加:**

**Step 1: CSP Initializerを作成**

```ruby
# config/initializers/content_security_policy.rb

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data
    policy.object_src  :none

    # Google Identity Services 用のスクリプト許可
    policy.script_src  :self, :https, :unsafe_inline,
                       "https://accounts.google.com"

    # Google 関連サービス用のスタイル許可
    policy.style_src   :self, :https, :unsafe_inline

    # Google Identity Services 用のフレーム許可
    policy.frame_src   :self,
                       "https://accounts.google.com"
  end

  # FIXME: nonce生成を一時的に無効化（Googleログインとの競合を回避）
  # config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  # config.content_security_policy_nonce_directives = %w[script-src style-src]
end
```

**Step 2: JavaScript で CSRF トークンを追加**

```javascript
// app/javascript/controllers/google_signin_controller.js

handleCredentialResponse(response) {
  const csrfToken = document.querySelector('meta[name="csrf-token"]').content

  fetch('/auth/google', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': csrfToken  // CSRF トークンを追加
    },
    body: JSON.stringify({ credential: response.credential })
  })
  .then(res => res.json())
  .then(data => {
    if (data.success) {
      window.location.href = data.redirect_url
    } else {
      alert('ログインに失敗しました: ' + (data.error || '不明なエラー'))
    }
  })
}
```

**ポイント:**

- XSS攻撃をブラウザレベルで防止
- Google Identity Services との互換性を考慮（`:unsafe_inline` を許可）
- nonce vs :unsafe_inline のトレードオフを適切に判断
- CSRF トークンを JavaScript で明示的に送信

**コード削減効果:**

- 追加: 約150行（予約語リスト、バリデーション、CSP設定、UI）
- セキュリティレベル: 大幅に向上（ルーティング衝突、頻繁な変更、XSS攻撃を防止）

</details>

---

### Q4. セキュリティとUXのトレードオフ（上級）🔴

以下の観点から、このPRのセキュリティ設計について評価してください。

1. CSP設定で `:unsafe_inline` を許可する判断は適切ですか？nonce機能を有効にした場合の影響を説明してください。
2. ユーザー名変更制限として「24時間の冷却期間」を選択した理由を、他の方式（生涯3回まで、無制限など）と比較して説明してください。
3. Brakeman を継続的に実行する仕組みをどのように実装しますか？（CI/CDパイプライン、Git hookなど）

**回答時間の目安**: 15分

<details>
<summary>解答を表示</summary>

### A4. セキュリティとUXのトレードオフ

#### 1. CSP設定で `:unsafe_inline` を許可する判断

**判断: 現時点では適切（一時的な妥協案）**

**理由:**

| 観点 | nonce有効 | :unsafe_inline |
|-----|----------|---------------|
| **セキュリティレベル** | 最高 | 中 |
| **Google SDK互換性** | 非対応（バグ発生） | 対応 |
| **XSS攻撃への耐性** | インラインスクリプトを個別に許可 | すべてのインラインスクリプトを許可 |
| **実装の複雑さ** | 高（各スクリプトタグにnonceを付与） | 低 |

**nonce機能を有効にした場合の影響（Day 19のバグ）:**

```ruby
# nonce有効化
config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
config.content_security_policy_nonce_directives = %w[script-src style-src]
# ↓
# Google Identity Services のインラインスクリプトがブロックされる
# ↓
# ブラウザのコンソールエラー:
# "Refused to execute inline script because it violates the following
#  Content Security Policy directive: 'script-src 'self' https: 'nonce-xxx''"
# ↓
# ログインボタンが表示されない、ログイン機能が動作しない
```

**トレードオフの判断プロセス:**

```
問題: Google Identity Services のインラインスクリプトがnonce非対応
↓
選択肢A: nonce を有効にして、Google SDK を別の方式に変更する
選択肢B: nonce を無効にして、:unsafe_inline を許可する
↓
判断: 選択肢B を採用（一時的な妥協案）
↓
理由:
- ログイン機能は必須であり、停止は許容できない
- Google SDK の nonce 対応は外部依存のため、実装時期が不明
- :unsafe_inline でも一定レベルのXSS保護は維持される（ドメイン制限）
- 将来的に Google 側の nonce 対応を待ち、または別の認証方式を検討
```

**将来的な改善策:**

- Google SDK の nonce 対応を定期的に確認
- 別の認証方式（Devise + OmniAuth、Auth0など）の検討
- CSP違反レポート（`policy.report_uri`）を有効にし、監視

#### 2. ユーザー名変更制限の方式比較

**採用した方式: 24時間の冷却期間**

**他の方式との比較:**

| 方式 | 実装複雑度 | ユーザビリティ | セキュリティ | タイポ修正 | 長期的な柔軟性 |
|-----|-----------|---------------|-------------|-----------|--------------|
| **24時間冷却期間** | 低 | 高 | 中 | 即座に可能 | 高 |
| **生涯3回まで** | 中 | 中 | 高 | 1回消費 | 低 |
| **無制限** | 低 | 最高 | 低 | 即座に可能 | 最高 |
| **変更不可** | 最低 | 最低 | 最高 | 不可 | なし |

**24時間冷却期間を選択した理由:**

**メリット:**

1. **シンプルな実装**: `username_changed_at` 1カラムのみで実装可能
2. **タイポ修正が容易**: 初回変更は即座に可能（ユーザビリティ）
3. **長期的な柔軟性**: 長期的には何度でも変更可能（ユーザビリティ）
4. **十分な抑止力**: 24時間制限でいたずら目的の頻繁な変更を防止（セキュリティ）

**デメリット:**

1. **生涯変更回数の上限がない**: 理論的には毎日変更可能（ただし、実務上は問題にならない）
2. **24時間待つ必要がある**: 2回目以降の変更は待機が必要（ただし、変更頻度は低い）

**生涯3回までの方式との比較:**

```ruby
# 生涯3回まで方式の実装例

class User < ApplicationRecord
  validates :username_change_count, numericality: { less_than_or_equal_to: 3 }

  def can_change_username?
    username_change_count < 3
  end

  # 変更時にカウントをインクリメント
  after_update :increment_username_change_count, if: :saved_change_to_username?

  private

  def increment_username_change_count
    increment!(:username_change_count)
  end
end
```

**問題点:**

- 3回使い切った後は永久に変更不可（ユーザーから「不便だ」という苦情が来る）
- タイポ修正で1回消費してしまう（ユーザビリティが低い）
- 実装が複雑（カウンターのインクリメント、リセットロジックなど）

**判断:**

- Typnix のユースケースでは、「タイポ修正のための初回変更」と「頻繁な変更の防止」のバランスが重要
- 24時間冷却期間は、セキュリティとユーザビリティの最適なバランスを実現

#### 3. Brakeman を継続的に実行する仕組み

**方式1: Git hook（ローカルチェック）**

```bash
# .git/hooks/pre-push （または .husky/pre-push）

#!/bin/sh
echo "Running security checks before push..."

# RuboCop
bundle exec rubocop
if [ $? -ne 0 ]; then
  echo "RuboCop failed. Please fix the issues before pushing."
  exit 1
fi

# Brakeman
bundle exec brakeman --no-pager
if [ $? -ne 0 ]; then
  echo "Brakeman found security warnings. Please fix them before pushing."
  exit 1
fi

# RSpec
bundle exec rspec
if [ $? -ne 0 ]; then
  echo "RSpec tests failed. Please fix them before pushing."
  exit 1
fi

echo "All checks passed!"
```

**メリット:**

- リモートプッシュ前に自動チェック
- 開発者がローカルで即座に問題を修正できる
- CI/CDの実行時間を節約

**デメリット:**

- Git hookは `.git/hooks/` にあるため、リポジトリに含まれない
- 開発者が手動でセットアップする必要がある（または Husky を使用）

**方式2: GitHub Actions（CI/CDパイプライン）**

```yaml
# .github/workflows/ci.yml

name: CI

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  security:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.4.4
          bundler-cache: true

      - name: Run RuboCop
        run: bundle exec rubocop

      - name: Run Brakeman
        run: bundle exec brakeman --no-pager

      - name: Run RSpec
        run: bundle exec rspec
```

**メリット:**

- PR マージ前に自動チェック
- チーム全体で統一されたチェック環境
- バッジをREADMEに表示できる（信頼性の可視化）

**デメリット:**

- GitHub Actions の実行時間がかかる（数分）
- ローカルでチェックせずにプッシュすると、CI/CD でエラーになる

**方式3: 両方を組み合わせ（推奨）**

```
ローカル開発
↓
Git hook でチェック（pre-push）← 早期発見
↓
リモートプッシュ
↓
GitHub Actions でチェック（CI/CD）← 最終確認
↓
PR マージ
```

**メリット:**

- ローカルで早期発見、CI/CDで最終確認
- 二重チェックでセキュリティを担保

**Typnix での実装（CLAUDE.md に明記）:**

```markdown
# CLAUDE.md の開発ルール

### コミット運用

- **リモートプッシュ前に以下のチェックを実行する:**
  - `bundle exec rubocop`: コード品質チェック
  - `bundle exec brakeman --no-pager`: セキュリティ脆弱性チェック
  - `bundle exec rspec`: テスト実行（Day 25で導入）
```

**将来的な改善:**

- Git hook の自動セットアップスクリプト（`bin/setup` に追加）
- GitHub Actions でのバッジ表示
- Brakeman の CI/CD 統合（PR コメントに警告を表示）

#### まとめ

**セキュリティとUXのバランスは、以下の要素を考慮して判断:**

1. **リスク評価**: どの程度のセキュリティリスクが許容できるか
2. **ユーザー影響**: セキュリティ機能がユーザー体験をどの程度損なうか
3. **実装コスト**: セキュリティ機能の実装にかかる時間とリソース
4. **将来的な改善**: 一時的な妥協案を採用した場合、将来的な改善計画を立てる

**Typnix での判断:**

- **CSP**: 一時的に `:unsafe_inline` を許可し、Google SDK の nonce 対応を待つ
- **ユーザー名変更制限**: 24時間冷却期間でセキュリティとUXのバランスを実現
- **Brakeman**: ローカル（Git hook）+ CI/CD で二重チェック

</details>

---

## 総合評価

### 基準

- **Q1を正解**: 基本的なセキュリティ問題を理解している（エラーハンドリング、重複チェック、ルーティング衝突）
- **Q2を正解**: ルーティング衝突の問題と予約語システムの必要性を理解している
- **Q3を正解**: セキュリティ機能（予約語、変更制限、CSP）を実装できる
- **Q4を正解**: セキュリティとUXのトレードオフを適切に判断できる（上級レベル）

### 次のステップ

- **Q1のみ正解**: [セキュリティベストプラクティス](../topics/03_advanced/06_security_best_practices.md) を再度読み、予約語システムとCSP設定の実装を学ぶ
- **Q1-Q2正解**: Q3の実装パターンを練習し、実際のコードで再現してみる
- **Q1-Q3正解**: Q4のトレードオフの判断基準を復習し、他のケース（プレミアム課金、API制限など）でも応用する
- **全問正解**: [RSpecによるテスト戦略](../topics/03_advanced/07_rspec_testing_strategy.md) に進み、セキュリティ機能のテストを実装する

## 参考資料

- [セキュリティベストプラクティス](../topics/03_advanced/06_security_best_practices.md)
- [RESTfulなURL設計](../topics/02_intermediate/04_restful_url_design.md)
- Day 3 の日報: `docs/daily_reports/2025-12-03.md` (CSRF保護、CSP初回実装)
- Day 19 の日報: `docs/daily_reports/2025-12-19.md` (Googleログインバグ修正、nonce vs :unsafe_inline)
- Day 24 の日報: `docs/daily_reports/2025-12-24.md` (予約語システム、ユーザー名変更制限)
- 実際のPR: #81 (ユーザー名変更制限と予約語チェック)

---

**作成日**: 2026-01-02
**難易度**: 🔴 上級
**推定時間**: 40分〜1時間
