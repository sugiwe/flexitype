# セキュリティベストプラクティス

**難易度**: 🔴 上級
**推定学習時間**: 2.5〜3時間
**対応する日報**: Day 3, Day 19, Day 24
**関連PR**: #81 (ユーザー名変更制限), Googleログインバグ修正

---

## 🎯 学習目標

この教材を学ぶことで、以下ができるようになります：

- CSP（Content Security Policy）の設定と外部ライブラリとの競合を理解できる
- 予約語システムによるルーティング保護を実装できる
- ユーザー名変更制限などのセキュリティ機能をUXを損なわずに実装できる
- Brakemanによる継続的なセキュリティチェックを運用できる
- CSRF保護、Strong Parametersなどの基本的なセキュリティ対策を適切に実装できる
- セキュリティとユーザビリティのトレードオフを適切に判断できる

---

## 📚 前提知識

この教材を理解するには、以下の知識が必要です：

- Railsのセキュリティ基礎（CSRF、Strong Parameters、SQLインジェクション対策）
- HTTPヘッダーの基本（Content Security Policy、CORS）
- 正規表現の基礎
- バリデーションの実装経験
- Railsのコールバック（before_save、after_create など）

---

## 📖 本編

### 概要

Webアプリケーションのセキュリティは、単一の技術で達成できるものではありません。複数の防御層を組み合わせた「多層防御（Defense in Depth）」の考え方が重要です。

Typnixプロジェクトでは、以下のセキュリティ対策を段階的に実装してきました：

1. **CSP（Content Security Policy）設定** - XSS攻撃を防ぐHTTPヘッダー（Day 3, 19）
2. **予約語システム** - ルーティング衝突を防ぐバリデーション（Day 24）
3. **ユーザー名変更制限** - 悪用を防ぐ冷却期間方式（Day 24）
4. **Brakeman 0警告の維持** - 継続的なセキュリティ監視（Day 3以降、継続中）
5. **CSRF保護** - Rails標準のトークン検証（Day 3）
6. **Strong Parameters** - マスアサインメント脆弱性の防止（Day 3以降）

この教材では、これらの実装を通じて「セキュリティとユーザビリティのバランス」を学びます。完全なセキュリティは不可能であり、リスクとコストのトレードオフを適切に判断することが実務では重要です。

---

### 実装前（アンチパターン / 課題）

#### 1. CSP未設定の状態

**Day 3より前:**

```ruby
# config/initializers/content_security_policy.rb
# （ファイルが存在しない、またはコメントアウトされた状態）
```

**問題点:**
- インラインスクリプト、外部スクリプトが無制限に実行可能
- XSS（Cross-Site Scripting）攻撃に脆弱
- 悪意のあるスクリプトがユーザーのセッションを盗む可能性
- ブラウザの標準的な保護機能を活用していない

#### 2. 予約語チェックなしのユーザー名登録

**Day 24より前:**

```ruby
# app/models/user.rb
validates :username, presence: true, uniqueness: { case_sensitive: false },
                     format: { with: /\A[a-z0-9]+(?:[._-][a-z0-9]+)*\z/ },
                     length: { minimum: 3, maximum: 30 }
# 予約語チェックがない
```

**問題点:**
- "admin"、"api"、"my" などのシステムルートと衝突するユーザー名が登録可能
- `/@admin` にアクセスすると、管理者ページではなくユーザープロフィールが表示される
- ルーティングの優先順位が不明確になり、予期しない動作を引き起こす
- 悪意のあるユーザーがシステムルートを乗っ取る可能性

#### 3. ユーザー名変更制限なし

**Day 24より前:**

```ruby
# app/models/user.rb
validates :username, presence: true, uniqueness: { case_sensitive: false }
# 変更頻度の制限がない

# app/controllers/my/accounts_controller.rb
def update
  @user = current_user
  if @user.update(account_params)
    redirect_to edit_my_account_path, notice: "アカウント設定を更新しました"
  end
end
```

**問題点:**
- ユーザーが何度でもユーザー名を変更可能
- 以下のリスクがある:
  - いたずら目的での頻繁な変更（システム負荷）
  - アカウント乗っ取り後の悪用（既存URLの無効化）
  - 予約語との衝突によるルーティングエラー（バリデーション前の状態）
  - シェアURLの無効化（`/@username` が変わるため）
- セキュリティとユーザビリティのバランスが取れていない

#### 4. Brakeman警告を放置

**Day 3より前:**

```bash
$ bundle exec brakeman --no-pager
# 警告が5件以上表示される状態
+SECURITY WARNINGS+

+------------+-------+--------+
| Confidence | Class | Method |
+------------+-------+--------+
| High       | ...   | ...    |
| Medium     | ...   | ...    |
+------------+-------+--------+
```

**問題点:**
- SQLインジェクション、XSS、CSRFなどの脆弱性が潜在的に存在
- コード変更時に新たな脆弱性が混入しても気づかない
- セキュリティ監査時に指摘される可能性が高い
- 継続的なセキュリティチェックの習慣がない

---

### 実装後（ベストプラクティス）

#### 1. CSP（Content Security Policy）の適切な設定

**ファイル**: `config/initializers/content_security_policy.rb`

```ruby
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data
    policy.object_src  :none

    # Google Tag Manager, Google Analytics, Google AdSense用のスクリプト許可
    policy.script_src  :self, :https, :unsafe_inline,
                       "https://accounts.google.com",
                       "https://www.googletagmanager.com",
                       "https://www.google-analytics.com",
                       "https://ssl.google-analytics.com",
                       "https://pagead2.googlesyndication.com",
                       "https://adservice.google.com"

    # Google関連サービス用のスタイル許可
    policy.style_src   :self, :https, :unsafe_inline

    # Google Analytics、AdSense用のコネクト許可
    policy.connect_src :self,
                       "https://www.google-analytics.com",
                       "https://analytics.google.com",
                       "https://stats.g.doubleclick.net",
                       "https://pagead2.googlesyndication.com"

    # Google AdSense用のフレーム許可
    policy.frame_src   :self,
                       "https://accounts.google.com",
                       "https://www.googletagmanager.com",
                       "https://bid.g.doubleclick.net",
                       "https://googleads.g.doubleclick.net",
                       "https://tpc.googlesyndication.com"
  end

  # FIXME: nonce生成を一時的に無効化（Googleログインとの競合を回避）
  # config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  # config.content_security_policy_nonce_directives = %w[script-src style-src]
end
```

**改善点:**
- XSS攻撃をブラウザレベルで防止
- 許可されたドメインからのスクリプトのみ実行可能
- Google Identity Services、Google Analytics、AdSenseとの統合を考慮
- nonce vs :unsafe_inline のトレードオフを適切に判断（Day 19のバグ修正）

**nonce機能の一時的な無効化（Day 19の判断）:**

```ruby
# Day 3の当初実装（nonce有効化）
config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
config.content_security_policy_nonce_directives = %w[script-src style-src]
# → Google Identity Servicesのインラインスクリプトがブロックされる

# Day 19の修正（nonce無効化）
# config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
# config.content_security_policy_nonce_directives = %w[script-src style-src]
# → :unsafe_inline が有効になり、Googleログインが動作する
```

**トレードオフの判断:**
- **セキュリティレベル**: nonce有効 > :unsafe_inline
- **機能性**: :unsafe_inline > nonce有効（Google SDKとの互換性）
- **判断**: 一時的に :unsafe_inline を採用し、将来的にnonce対応を検討
- **理由**: ログイン機能は必須であり、nonce対応には外部SDK側の変更が必要

#### 2. 予約語システムによるルーティング保護

**ファイル**: `config/initializers/reserved_usernames.rb`

```ruby
# frozen_string_literal: true

# ユーザー名として使用できない予約語リスト
# /@username の形式でアクセスされるため、アプリケーションのルートと衝突する単語を予約
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

    # 通知・メッセージ
    notifications notification messages message inbox

    # 課金・決済
    billing payment payments subscriptions subscribe subscription
    premium

    # コンテンツ・メディア
    assets images uploads files downloads download
    blog news feed feeds rss

    # API・Webhook
    api webhooks webhook

    # ヘルプ・情報ページ
    top welcome home
    support about help faq terms privacy contact

    # システム・インフラ
    system root localhost www cdn
    mail email smtp pop imap ftp sftp ssh
    static media public
    staging development production test
    error errors log logs

    # 検索・エクスポート
    search export exports import imports

    # その他の一般的な予約語
    app assets status health ping up
  ].freeze
end
```

**Userモデル**: `app/models/user.rb`

```ruby
validates :username, presence: true, uniqueness: { case_sensitive: false },
                     format: { with: /\A[a-z0-9]+(?:[._-][a-z0-9]+)*\z/,
                              message: "は半角英数字、ハイフン、アンダースコア、ドットのみ使用できます（記号は連続不可、先頭・末尾不可）" },
                     length: { minimum: 3, maximum: 30 }
validate :username_not_reserved

private

# ユーザー名が予約語でないかチェック
def username_not_reserved
  return if username.blank?

  if ReservedUsernames::LIST.include?(username.downcase)
    errors.add(:username, "は予約されているため使用できません")
  end
end
```

**改善点:**
- 100+ の予約語をカテゴリー別に管理
- ルーティング衝突を未然に防止
- Initializerファイルで管理することで、コード変更なしに追加可能
- 大文字小文字を区別しないチェック（`.downcase`）
- 既存の別アプリでの実績がある方式を採用

#### 3. ユーザー名変更制限（24時間冷却期間方式）

**データベース設計**: `db/migrate/20251223194636_add_username_changed_at_to_users.rb`

```ruby
class AddUsernameChangedAtToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :username_changed_at, :datetime
  end
end
```

**Userモデル**: `app/models/user.rb`

```ruby
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

# ユーザー名の変更が許可されているかチェック
def username_change_allowed
  return if new_record? # 新規作成時はチェックしない
  return if can_change_username?

  next_change = next_username_change_at.strftime("%Y年%m月%d日 %H時%M分")
  errors.add(:username, "は24時間に1回しか変更できません（次回変更可能: #{next_change}）")
end
```

**コントローラー**: `app/controllers/my/accounts_controller.rb`

```ruby
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
```

**ビュー**: `app/views/my/accounts/edit.html.slim`

```slim
/ ユーザー名設定
.space-y-2
  = f.label :username, "ユーザー名", class: "..."
  p.text-xs.text-gray-500...
    | プロフィールページのURL（
    span.font-mono.text-blue-600 = "typnix.com/@#{@user.username}"
    | ）に使用されます

  - if @user.can_change_username?
    = f.text_field :username, class: "..."
  - else
    = f.text_field :username, disabled: true, class: "... bg-gray-100 cursor-not-allowed"
    .text-sm.text-amber-600...
      svg.w-5.h-5.flex-shrink-0 ...
      div
        | ユーザー名は24時間に1回しか変更できません
        br
        strong = "次回変更可能: #{@user.next_username_change_at.strftime('%Y年%m月%d日 %H時%M分')}"
```

**改善点:**
- 24時間の冷却期間でいたずらを防止
- タイポ修正のための初回変更は即座に可能（ユーザビリティ）
- UIで変更可能/不可能を明確に表示（グレーアウト、警告メッセージ）
- `update_column` で無限ループを回避（バリデーションをスキップ）
- セキュリティとユーザビリティのバランスを実現

#### 4. Brakeman 0警告の維持

**コマンド実行**:

```bash
$ bundle exec brakeman --no-pager

+SECURITY WARNINGS+

No warnings found
```

**継続的な運用**:

```markdown
# CLAUDE.md の開発ルール

### コミット運用

- **リモートプッシュ前に以下のチェックを実行する:**
  - `bundle exec rubocop`: コード品質チェック
  - `bundle exec brakeman --no-pager`: セキュリティ脆弱性チェック
  - `bundle exec rspec`: テスト実行（Day 25で導入）
```

**改善点:**
- SQLインジェクション、XSS、CSRF などの脆弱性を自動検出
- 継続的なセキュリティチェックの習慣化
- コード変更時に新たな脆弱性が混入しないよう監視
- リモートプッシュ前の必須チェック項目として明文化

#### 5. CSRF保護とStrong Parameters

**SessionsController**: `app/controllers/sessions_controller.rb`

```ruby
class SessionsController < ApplicationController
  # Google Identity ServicesのIDトークン検証による認証のため、createアクションのみCSRF検証を除外
  protect_from_forgery except: :create

  def create
    # Google IDトークンの検証
    payload = GoogleIDToken::Validator.new.check(params[:credential], ENV["GOOGLE_CLIENT_ID"])

    if payload
      @user = User.from_google(payload)
      session[:user_id] = @user.id
      render json: { success: true, redirect_url: root_path }
    else
      render json: { success: false, error: "認証に失敗しました" }, status: :unauthorized
    end
  rescue StandardError => e
    Rails.logger.error("Google authentication error: #{e.message}")
    render json: { success: false, error: "認証に失敗しました" }, status: :unauthorized
  end
end
```

**JavaScript**: `app/javascript/controllers/google_signin_controller.js`

```javascript
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

**AccountsController**: `app/controllers/my/accounts_controller.rb`

```ruby
private

def account_params
  params.require(:user).permit(:name, :username)
end
```

**改善点:**
- CSRF保護を適切に実装（Google認証のみ例外）
- Strong Parametersでマスアサインメント脆弱性を防止
- JavaScriptでCSRFトークンを明示的に送信
- `params.require(:user).permit(...)` でホワイトリスト方式

---

### 解説

#### なぜこの設計が優れているのか

**1. CSPによる多層防御**

CSP（Content Security Policy）は、ブラウザに「どのスクリプトやスタイルを読み込んでいいか」を指示するセキュリティ機能です。XSS攻撃の最後の防御線として機能します。

**CSPの3レベル:**

| レベル | 設定 | セキュリティ | 互換性 | TypnixでのDay |
|--------|------|-------------|--------|--------------|
| **Strict（厳格）** | nonce有効、:unsafe_inline無効 | 最高 | 低（外部SDK非対応） | Day 3（初回） |
| **Moderate（中程度）** | :unsafe_inline有効、ドメイン制限 | 中 | 中（Google SDK対応） | Day 19（現在） |
| **Permissive（緩い）** | CSP未設定 | 低 | 高 | Day 3より前 |

Typnixでは、**Moderate（中程度）** を採用しています。これは、Google Identity Servicesとの互換性を保ちつつ、XSS攻撃を一定レベル防ぐためです。

**nonce vs :unsafe_inline の判断:**

- **nonce**: 各スクリプトタグに一意の値（nonce）を付与し、CSPヘッダーと照合する方式
  - メリット: インラインスクリプトを個別に許可できる（最高のセキュリティ）
  - デメリット: Google Identity Servicesなどの外部SDKが非対応

- **:unsafe_inline**: すべてのインラインスクリプトを許可する方式
  - メリット: 外部SDKとの互換性が高い
  - デメリット: インラインスクリプトを使ったXSS攻撃に脆弱

**Day 19のバグ修正での判断:**

```
問題: Google Identity Servicesのインラインスクリプトがnonce非対応
↓
判断: 一時的にnonceを無効化し、:unsafe_inlineを有効にする
↓
理由: ログイン機能は必須であり、nonce対応には外部SDK側の変更が必要
↓
将来: Google側のnonce対応を待ち、または別の認証方式を検討
```

**2. 予約語システムによるルーティング保護**

予約語システムは、`/@username` 形式のプロフィールURLがシステムルートと衝突しないよう保護する仕組みです。

**100個の予約語を定義した根拠:**

| カテゴリー | 例 | 予約語数 | 理由 |
|-----------|-----|----------|------|
| CRUD・RESTful | new, edit, create, update, destroy | 8 | Railsの標準ルーティング |
| HTTPメソッド | get, post, put, patch, delete | 7 | HTTPの基本メソッド |
| 認証・アカウント | login, logout, signup, signin | 13 | 認証システムの標準ルート |
| Typnix固有のリソース | lessons, keymaps, categories | 8 | アプリケーション固有のルート |
| 管理・設定 | admin, settings, dashboard | 8 | 管理画面の標準ルート |
| その他 | api, webhooks, static, media, etc. | 56+ | 将来的な拡張を考慮 |

**カテゴリー別に整理した理由:**

- **保守性**: 新しい予約語を適切なカテゴリーに追加できる
- **可読性**: 100個の予約語を一覧で見た時に、カテゴリーが明確
- **チーム開発**: どのカテゴリーに何が含まれるか、チームメンバーが理解しやすい

**Initializerファイルで管理する理由:**

- **アプリケーション起動時に一度だけロード**: パフォーマンス上の問題がない
- **コード変更なしに予約語を追加可能**: データベースに保存するより簡潔
- **既存の別アプリでの実績**: feeeed.jpなどの実績がある方式を採用

**3. セキュリティとユーザビリティのバランス**

ユーザー名変更制限では、以下の要件を満たす必要がありました：

| 要件 | セキュリティ寄り | ユーザビリティ寄り | Typnixの判断 |
|-----|----------------|-------------------|-------------|
| タイポ修正 | 変更不可 | 即座に変更可能 | **初回変更は即座に可能** |
| 頻繁な変更 | 生涯3回まで | 無制限 | **24時間の冷却期間** |
| 変更可能性の明示 | なし | UIで明確に表示 | **グレーアウト + 警告** |
| 次回変更可能日時 | なし | 表示する | **日時を強調表示** |

**24時間の冷却期間方式を採用した理由:**

- **メリット**:
  - シンプルな実装（`username_changed_at` 1カラムのみ）
  - ユーザーに柔軟性を提供（長期的には何度でも変更可能）
  - タイポ修正のための初回変更は即座に可能
- **デメリット**:
  - 生涯変更回数の上限がない（ただし、24時間制限で十分抑止力がある）

**生涯変更回数制限と比較:**

| 方式 | 実装複雑度 | ユーザビリティ | セキュリティ | Typnixでの判断 |
|-----|-----------|---------------|-------------|--------------|
| 24時間冷却期間 | 低 | 高 | 中 | **採用** |
| 生涯3回まで | 中 | 中 | 高 | 不採用（柔軟性不足） |
| 無制限 | 低 | 最高 | 低 | 不採用（悪用リスク） |

**4. 継続的なセキュリティチェック**

Brakemanによるセキュリティチェックを「リモートプッシュ前の必須チェック」として明文化することで、以下の効果があります：

- **属人化の防止**: 開発者が変わってもセキュリティチェックが継続される
- **新たな脆弱性の早期発見**: コード変更時に即座に検出
- **セキュリティ意識の向上**: 毎回チェックすることで、脆弱性を意識したコーディングが習慣化
- **監査対応**: セキュリティ監査時に「継続的なチェック」を証明できる

**RuboCop、Brakeman、RSpecの3点セット:**

| ツール | チェック内容 | Day 3以降の状態 |
|--------|-------------|---------------|
| RuboCop | コード品質（スタイル、ベストプラクティス） | 違反なし |
| Brakeman | セキュリティ脆弱性（SQLi、XSS、CSRF） | 警告0件 |
| RSpec | 機能テスト（Day 25で導入） | 全テストパス |

**5. OWASP Top 10への対応**

OWASP Top 10は、Webアプリケーションの代表的な脆弱性トップ10です。Typnixでの対応状況を以下に示します：

| OWASP Top 10（2021） | Typnixでの対応 | 実装Day |
|--------------------|---------------|---------|
| A01: アクセス制御の不備 | `before_action :require_login` で認証を実装 | Day 2-3 |
| A02: 暗号化の失敗 | SSL/TLS、Rails credentials | Day 14 |
| A03: インジェクション | Strong Parameters、ActiveRecord | Day 3 |
| A04: 安全でない設計 | 予約語システム、24時間制限 | Day 24 |
| A05: セキュリティ設定のミス | CSP、Brakeman 0警告 | Day 3, 19 |
| A06: 脆弱で古いコンポーネント | bundler-audit で定期チェック | Day 15 |
| A07: 識別と認証の失敗 | Google ID Token検証、CSRF | Day 3 |
| A08: ソフトウェアとデータの整合性 | 外部キー制約、NOT NULL | Day 24 |
| A09: セキュリティログと監視の失敗 | Rails.logger、エラートラッキング予定 | 将来実装 |
| A10: サーバーサイドリクエストフォージェリ | 該当機能なし | - |

---

#### 実装のポイント

**1. CSPのデバッグ手法**

CSP違反は、ブラウザのコンソールにエラーが表示されます。

**ブラウザのコンソールエラー（Day 19のバグ）:**

```
Refused to execute inline script because it violates the following
Content Security Policy directive: "script-src 'self' https: 'nonce-xxx'".
```

**デバッグ手順:**

1. **コンソールエラーを読む**: どのディレクティブ（script-src、style-src）が違反しているか確認
2. **nonce vs :unsafe_inline の判断**: 外部SDKがnonce対応かどうか確認
3. **一時的な緩和策**: `config.content_security_policy_report_only = true` で監視モードに変更
4. **段階的な強化**: 緩和策で動作確認後、段階的にCSPを強化

**2. 予約語チェックの実装パターン**

**バリデーションメソッド:**

```ruby
validate :username_not_reserved

private

def username_not_reserved
  return if username.blank?

  if ReservedUsernames::LIST.include?(username.downcase)
    errors.add(:username, "は予約されているため使用できません")
  end
end
```

**ポイント:**

- `validate` メソッドで独自バリデーションを実装
- `return if username.blank?` で nil/空文字をスキップ（presence: true と重複しない）
- `.downcase` で大文字小文字を区別しない（"Admin" も "admin" も予約語）
- エラーメッセージはユーザーに分かりやすい日本語で

**3. タイムスタンプ更新時の無限ループ回避**

**問題: `update` を使うと無限ループになる**

```ruby
# 悪い例
def update
  @user = current_user
  if @user.update(account_params)
    @user.update(username_changed_at: Time.current) # 無限ループ
  end
end
```

**理由:**

1. `@user.update(account_params)` でバリデーションが実行される
2. `username_change_allowed` バリデーションが `username_changed_at` をチェック
3. `@user.update(username_changed_at: Time.current)` で再度バリデーションが実行される
4. 無限ループ

**解決策: `update_column` を使う**

```ruby
# 良い例
def update
  @user = current_user
  username_will_change = account_params[:username].present? && @user.username != account_params[:username]

  if @user.update(account_params)
    @user.update_column(:username_changed_at, Time.current) if username_will_change
  end
end
```

**`update_column` のメリット:**

- バリデーションをスキップするため、無限ループを回避
- コールバックも実行されないため、高速
- タイムスタンプのような「システム内部の管理データ」の更新に最適

**注意点:**

- `updated_at` も更新されない
- バリデーションがスキップされるため、不正なデータが保存される可能性がある
- ユーザー入力データには使わない（`update` または `update!` を使う）

**4. UIでのセキュリティ制限の表現**

**条件分岐でフィールドを無効化:**

```slim
- if @user.can_change_username?
  = f.text_field :username, class: "... bg-white"
- else
  = f.text_field :username, disabled: true, class: "... bg-gray-100 cursor-not-allowed"
```

**警告メッセージの表示:**

```slim
- unless @user.can_change_username?
  .text-sm.text-amber-600...
    svg.w-5.h-5.flex-shrink-0 ...
    div
      | ユーザー名は24時間に1回しか変更できません
      br
      strong = "次回変更可能: #{@user.next_username_change_at.strftime('%Y年%m月%d日 %H時%M分')}"
```

**ポイント:**

- **グレーアウト**: `bg-gray-100` でフィールドを視覚的に無効化
- **アイコン**: SVGアイコンで警告を強調
- **次回変更可能日時**: `<strong>` タグで強調表示
- **色の選択**: 赤（エラー）ではなく、アンバー（警告）を使用

---

### Typnixプロジェクトでの実例

#### 1. CSP設定の段階的な進化

**Day 3（初回実装）:**

```ruby
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.script_src  :self, :https
    policy.style_src   :self, :https
  end

  # nonce生成を有効化
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w[script-src style-src]
end
```

**Day 19（Googleログインバグ修正）:**

```ruby
Rails.application.configure do
  config.content_security_policy do |policy|
    # Google SDKのドメインを追加
    policy.script_src  :self, :https, :unsafe_inline,
                       "https://accounts.google.com"
  end

  # nonce生成を一時的に無効化（Googleログインとの競合を回避）
  # config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  # config.content_security_policy_nonce_directives = %w[script-src style-src]
end
```

**Day 20（Google Analytics、AdSense追加）:**

```ruby
Rails.application.configure do
  config.content_security_policy do |policy|
    # Google Tag Manager, Google Analytics, Google AdSense用のスクリプト許可
    policy.script_src  :self, :https, :unsafe_inline,
                       "https://accounts.google.com",
                       "https://www.googletagmanager.com",
                       "https://www.google-analytics.com",
                       "https://pagead2.googlesyndication.com",
                       "https://adservice.google.com"

    # connect_src, frame_src なども追加
  end
end
```

**教訓:**

- CSPは段階的に強化していく
- 新しい外部サービスを追加する際は、CSPの更新を忘れない
- nonce vs :unsafe_inline の判断は、機能性とセキュリティのトレードオフを考慮

#### 2. 予約語システムの実装（Day 24）

**使用箇所:**

- **Userモデル**: `app/models/user.rb`（バリデーション）
- **新規ユーザー登録**: `User.from_google(payload)` で自動生成されるユーザー名
- **アカウント設定画面**: `app/views/my/accounts/edit.html.slim`（エラーメッセージ）

**実際のバリデーションエラー:**

```ruby
# Railsコンソール
user = User.new(username: "admin", email: "test@example.com", ...)
user.valid?
# => false
user.errors[:username]
# => ["は予約されているため使用できません"]
```

**自動生成時の衝突回避:**

```ruby
def self.generate_unique_username(email)
  username_base = email.split("@").first.downcase
  username = username_base
  counter = 1

  # 既存のusernameと重複しないようにする
  while exists?(username: username)
    username = "#{username_base}#{counter}"
    counter += 1
  end

  # 予約語チェックは、Userモデルのバリデーションで自動的に実行される
  username
end
```

**教訓:**

- 予約語チェックはバリデーションレベルで実装することで、すべての入力経路で保護される
- 自動生成時も予約語を避けるロジックを組み込む
- カウンター（1, 2, 3...）による衝突回避が有効

#### 3. ユーザー名変更制限の実装（Day 24）

**実装ファイル:**

- `db/migrate/20251223194636_add_username_changed_at_to_users.rb`: マイグレーション
- `app/models/user.rb`: バリデーション + ヘルパーメソッド
- `app/controllers/my/accounts_controller.rb`: タイムスタンプ更新
- `app/views/my/accounts/edit.html.slim`: UI実装

**使用箇所:**

- **初回変更（即座に可能）**: タイポ修正、好みのユーザー名への変更
- **2回目以降（24時間制限）**: 頻繁な変更を防止
- **UIでの表示**: グレーアウト、警告メッセージ、次回変更可能日時

**実際のユーザーフロー:**

1. ユーザー登録: `username_changed_at` が `nil`
2. 初回変更: `can_change_username?` が `true` → 変更可能
3. 変更後: `username_changed_at` が現在時刻に更新
4. 24時間以内の変更: `can_change_username?` が `false` → 変更不可
5. 24時間経過後: `can_change_username?` が `true` → 変更可能

**教訓:**

- 初回変更を即座に可能にすることで、ユーザビリティを損なわない
- UIで制限理由を明確に説明することで、ユーザーの理解を促進
- `update_column` で無限ループを回避

#### 4. Brakeman 0警告の継続的な維持

**コマンド実行の習慣化:**

```bash
# リモートプッシュ前
$ bundle exec rubocop
$ bundle exec brakeman --no-pager
$ bundle exec rspec
```

**Brakemanの警告例（Day 3より前）:**

```
+SECURITY WARNINGS+

+------------+-------+--------+----------------------------------------+
| Confidence | Class | Method | Message                                |
+------------+-------+--------+----------------------------------------+
| High       | User  | update | Mass assignment (params[:user])        |
| Medium     | ...   | ...    | SQL injection possible                 |
+------------+-------+--------+----------------------------------------+
```

**修正例（Strong Parameters）:**

```ruby
# 悪い例（Day 3より前）
def update
  @user = User.find(params[:id])
  @user.update(params[:user]) # Mass assignment
end

# 良い例（Day 3以降）
def update
  @user = User.find(params[:id])
  @user.update(user_params)
end

private

def user_params
  params.require(:user).permit(:name, :username)
end
```

**教訓:**

- Brakemanの警告は具体的な脆弱性箇所を示してくれる
- Strong Parametersはマスアサインメント脆弱性の基本的な対策
- 継続的なチェックで新たな脆弱性を早期発見

---

## 💡 まとめ

### 重要ポイント

- ✅ **CSPは段階的に強化**: nonce vs :unsafe_inline の判断は、機能性とセキュリティのトレードオフを考慮
- ✅ **予約語システムは100+の予約語をカテゴリー別に管理**: ルーティング衝突を未然に防止
- ✅ **ユーザー名変更制限は24時間の冷却期間方式**: セキュリティとユーザビリティのバランス
- ✅ **Brakeman 0警告の継続的な維持**: リモートプッシュ前の必須チェック
- ✅ **CSRF保護とStrong Parametersは基本**: Rails標準のセキュリティ機能を適切に実装
- ✅ **セキュリティとUXのトレードオフを適切に判断**: 完全なセキュリティは不可能、リスクとコストのバランス

### セキュリティチェックリスト

**デプロイ前のチェック:**

- [ ] `bundle exec brakeman --no-pager` で警告0件
- [ ] `bundle exec rubocop` で違反なし
- [ ] `bundle exec rspec` で全テストパス（Day 25以降）
- [ ] CSP設定が適切（外部SDKのドメインを許可）
- [ ] Strong Parametersが適切（`permit`で必要なパラメータのみ許可）
- [ ] CSRF保護が適切（例外が必要な場合はコメントで理由を記載）
- [ ] 予約語システムが適切（新しいルートを追加した場合は予約語リストも更新）

**定期的なメンテナンス:**

- [ ] `bundle exec bundler-audit` で脆弱性のあるgemをチェック（月1回）
- [ ] CSP違反がないか、ブラウザのコンソールを定期的に確認
- [ ] 予約語リストに新しいルートを追加（機能追加時）
- [ ] ユーザー名変更制限の期間を見直し（悪用の傾向があれば延長を検討）

### 次のステップ

このトピックを理解したら、以下に進むことをお勧めします：

- **RSpecによるテスト戦略（07_rspec_testing_strategy.md）**: セキュリティ機能のテストを実装
- **データマイグレーションの段階的アプローチ（08_data_migration_patterns.md）**: データ整合性を保証する外部キー制約
- **運用効率化とフィーチャーフラグ（09_feature_flags_and_operations.md）**: セキュリティ機能の削除容易性を確保

---

## 🔗 関連教材

- [RESTfulなURL設計（04_restful_url_design.md）](../02_intermediate/04_restful_url_design.md)
- [RSpecによるテスト戦略（07_rspec_testing_strategy.md）](07_rspec_testing_strategy.md)
- [レビューテスト: セキュリティベストプラクティス](../../reviews/review_06_security_best_practices.md)

---

## 📝 演習問題（オプション）

### 問題1: CSP違反のデバッグ

新しい外部スクリプト（`https://example.com/script.js`）を読み込もうとしたところ、ブラウザのコンソールに以下のエラーが表示されました。

```
Refused to load the script 'https://example.com/script.js' because it violates
the following Content Security Policy directive: "script-src 'self' https:".
```

CSP設定をどのように修正すれば良いですか？

<details>
<summary>解答例を表示</summary>

```ruby
# config/initializers/content_security_policy.rb

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https

    # 外部スクリプトのドメインを追加
    policy.script_src  :self, :https, :unsafe_inline,
                       "https://example.com"  # ← NEW!
  end
end
```

**解説:**

- `script-src` ディレクティブに `"https://example.com"` を追加
- `:https` だけでは不十分（`:https` は「すべてのHTTPSドメイン」ではなく「data: blob: などのスキーム」を許可）
- ドメインを明示的に指定する必要がある
- サーバーを再起動して設定を反映（Initializerファイルの変更）

</details>

---

### 問題2: 予約語リストへの追加

新しい機能として「チーム機能」を追加することになりました。以下のルートを追加する予定です：

- `/teams` - チーム一覧
- `/teams/new` - チーム作成
- `/teams/:id` - チーム詳細

予約語リストに追加すべき単語を挙げてください。

<details>
<summary>解答例を表示</summary>

```ruby
# config/initializers/reserved_usernames.rb

module ReservedUsernames
  LIST = %w[
    # ...既存の予約語...

    # チーム機能（NEW!）
    teams team

    # ...その他の予約語...
  ].freeze
end
```

**解説:**

- `teams` と `team` の両方を追加（単数形・複数形の両方）
- `new` は既に CRUD・RESTful カテゴリーに存在するため、追加不要
- `:id` パラメータは動的ルートなので、予約語には含めない
- カテゴリー（`# チーム機能`）を明記することで、将来的なメンテナンスが容易

</details>

---

### 問題3: セキュリティとUXのトレードオフ

ユーザーから「ユーザー名を24時間に1回しか変更できないのは不便だ。もっと頻繁に変更したい」という要望がありました。

以下の選択肢の中から、最も適切な対応を選んでください。

1. 24時間制限を1時間に短縮する
2. プレミアムユーザーのみ制限を緩和する
3. 変更回数をカウントし、3回まで即座に変更可能にする
4. 制限を撤廃し、無制限に変更可能にする

<details>
<summary>解答例を表示</summary>

**正解**: **2. プレミアムユーザーのみ制限を緩和する**

**理由:**

- **選択肢1（1時間に短縮）**: いたずら目的での悪用が増える可能性がある
- **選択肢2（プレミアムユーザーのみ緩和）**: セキュリティとユーザビリティのバランスが取れる
- **選択肢3（3回まで即座に変更可能）**: 3回使い切った後の不満が出る可能性がある
- **選択肢4（無制限）**: セキュリティリスクが高い

**実装例:**

```ruby
# app/models/user.rb

def can_change_username?
  return true if premium? # プレミアムユーザーは制限なし
  username_changed_at.nil? || username_changed_at < 24.hours.ago
end
```

**代替案:**

- プレミアムユーザーは1時間制限
- 一般ユーザーは24時間制限
- 初回変更は即座に可能（両方）

</details>

---

**作成日**: 2026-01-02
**難易度**: 🔴 上級
**推定学習時間**: 2.5〜3時間
