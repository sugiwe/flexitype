# レビューテスト: Hotwire（Turbo Frames + Stimulus）

**対象教材**: [03_hotwire.md](03_hotwire.md)
**難易度**: 🟡 中級
**推定時間**: 30〜60分

---

## 📝 テスト形式

以下のPRレビューコメントを読んで、問題点を指摘し、修正案を提示してください。
難易度は4段階（🟢→🟡→🟡🔴→🔴）で徐々に上がります。

---

## 問題1: Turbo Framesの基本理解 🟢

### PR内容

**タイトル**: 練習履歴に期間フィルターを追加

**説明**: 練習履歴ページに「全期間」「直近1ヶ月」「直近1週間」のタブを追加しました。

**変更内容**:

```slim
/ app/views/my/lesson_records/index.html.slim

/ タブナビゲーション
.mb-6
  nav
    = link_to "全期間", my_lesson_records_path(period: 'all'), \
      data: { turbo_frame: "history_content" }, \
      class: "#{@period == 'all' ? 'active' : ''}"

    = link_to "直近1ヶ月", my_lesson_records_path(period: 'month'), \
      data: { turbo_frame: "history_content" }, \
      class: "#{@period == 'month' ? 'active' : ''}"

    = link_to "直近1週間", my_lesson_records_path(period: 'week'), \
      data: { turbo_frame: "history_content" }, \
      class: "#{@period == 'week' ? 'active' : ''}"

/ コンテンツエリア
= turbo_frame_tag "history_content" do
  / 履歴一覧
  - @lesson_records.each do |record|
    .record = record.lesson_name
```

**動作確認結果**:
- タブをクリックすると履歴が切り替わる ✅
- ただし、タブのアクティブ状態（青い下線）が更新されない ❌

### 質問

1. なぜタブのアクティブ状態が更新されないのですか？
2. どのように修正すべきですか？コードで示してください。
3. この修正により、何が変わりますか？

<details>
<summary>解答例を表示</summary>

### 1. 原因

タブナビゲーションが `turbo_frame_tag` の外にあるため、タブクリック時に `history_content` フレーム内だけが更新され、タブ自体は更新されない。

### 2. 修正案

**タブナビゲーションをTurbo Frameの中に含める:**

```slim
/ ✅ 修正後
= turbo_frame_tag "history_content" do
  / タブナビゲーション（フレーム内に移動）
  .mb-6
    nav
      = link_to "全期間", my_lesson_records_path(period: 'all'), \
        data: { turbo_frame: "history_content" }, \
        class: "#{@period == 'all' ? 'active' : ''}"

      = link_to "直近1ヶ月", my_lesson_records_path(period: 'month'), \
        data: { turbo_frame: "history_content" }, \
        class: "#{@period == 'month' ? 'active' : ''}"

      = link_to "直近1週間", my_lesson_records_path(period: 'week'), \
        data: { turbo_frame: "history_content" }, \
        class: "#{@period == 'week' ? 'active' : ''}"

  / コンテンツエリア
  / 履歴一覧
  - @lesson_records.each do |record|
    .record = record.lesson_name
```

### 3. 変更内容

- タブクリック時に `history_content` フレーム全体（タブナビゲーション + コンテンツ）が更新される
- サーバー側で `@period` に基づいてアクティブタブのスタイルが設定される
- アクティブ状態が正しく表示される

**重要なポイント:**
- Turbo Frame内のすべての要素が更新される
- Stimulusコントローラー不要（サーバーサイド管理）

</details>

---

## 問題2: ページネーションの実装 🟡

### PR内容

**タイトル**: 練習履歴にページネーション追加

**説明**: 練習履歴が20件以上ある場合、ページネーションを表示するようにしました。

**変更内容**:

```ruby
# app/controllers/my/lesson_records_controller.rb
class My::LessonRecordsController < My::ApplicationController
  def index
    @period = params[:period] || "all"
    @filtered_records = filter_by_period(current_user.lesson_records, @period)
    @lesson_records = @filtered_records.page(params[:page]).per(20)
  end

  private

  def filter_by_period(records, period)
    case period
    when "week"
      records.where("completed_at >= ?", 1.week.ago)
    when "month"
      records.where("completed_at >= ?", 1.month.ago)
    else
      records
    end
  end
end
```

```slim
/ app/views/my/lesson_records/index.html.slim
= turbo_frame_tag "history_content" do
  / タブナビゲーション（省略）

  / 履歴一覧
  - @lesson_records.each do |record|
    .record = record.lesson_name

  / ページネーション
  = paginate @lesson_records
```

**動作確認結果**:
- 「全期間」タブでページ2に移動 → OK ✅
- 「直近1週間」タブでページ2に移動 → 「全期間」のページ2が表示される ❌

### 質問

1. なぜ「直近1週間」タブでページネーションを押すと「全期間」が表示されるのですか？
2. どのように修正すべきですか？コードで示してください。
3. この問題は実際のプロジェクト（Flexitype）でも発生しましたか？

<details>
<summary>解答例を表示</summary>

### 1. 原因

ページネーションのリンクに `period` パラメータが含まれていないため、ページ2に移動すると `period` パラメータが消え、デフォルト値（`"all"`）が使用される。

```
期待: /my/lesson_records?period=week&page=2
実際: /my/lesson_records?page=2  ← period が消える
```

### 2. 修正案

**`pagination_params` でパラメータを引き継ぐ:**

```slim
/ ✅ 修正後
= turbo_frame_tag "history_content" do
  / タブナビゲーション（省略）

  / 履歴一覧
  - @lesson_records.each do |record|
    .record = record.lesson_name

  / ページネーション（period パラメータを引き継ぎ）
  = paginate @lesson_records, params: { period: @period }
```

### 3. Flexitypeでの実例

はい、Day 24でこの問題が発生しました。

**解決策:**
- `params: { period: @period }` を追加
- これにより、ページ遷移時に期間パラメータが保持される

**結果:**
```
/my/lesson_records?period=week&page=1  （ページ1）
↓
/my/lesson_records?period=week&page=2  （ページ2、periodパラメータが引き継がれる）
```

</details>

---

## 問題3: Turbo Streamsのターゲット指定 🟡🔴

### PR内容

**タイトル**: 通知フラグのトグル機能を追加

**説明**: 許可メールアドレス一覧で、連絡済みフラグをワンクリックでトグルできるようにしました。

**変更内容**:

```ruby
# app/controllers/admin/allowed_emails_controller.rb
def toggle_notified
  @allowed_email = AllowedEmail.find(params[:id])

  if @allowed_email.notified_at.present?
    @allowed_email.update!(notified_at: nil)
  else
    @allowed_email.update!(notified_at: Time.current)
  end

  respond_to do |format|
    format.turbo_stream
    format.html { redirect_to admin_allowed_emails_path }
  end
end
```

```slim
/ app/views/admin/allowed_emails/index.html.slim
table
  thead
    tr
      th メールアドレス
      th 連絡済み
      th アクション
  tbody
    - @allowed_emails.each do |allowed_email|
      tr
        td = allowed_email.email
        td id="notified_status_#{allowed_email.id}"
          = render partial: "notified_button", locals: { allowed_email: allowed_email }
        td
          = link_to "削除", admin_allowed_email_path(allowed_email), method: :delete
```

```slim
/ app/views/admin/allowed_emails/toggle_notified.turbo_stream.slim
= turbo_stream.replace "notified_status_#{@allowed_email.id}" do
  = render partial: "notified_button", locals: { allowed_email: @allowed_email }
```

**動作確認結果**:
- ボタンをクリックすると状態が切り替わる ✅
- ただし、クリック後にボタンが消えてしまう ❌

### 質問

1. なぜボタンが消えてしまうのですか？
2. どのように修正すべきですか？コードで示してください。
3. Turbo Streamsのターゲット指定で気をつけるべきポイントは何ですか？

<details>
<summary>解答例を表示</summary>

### 1. 原因

`td` 要素自体を `id` でターゲット指定しているため、Turbo Streamの`replace`で`td`要素全体が置き換えられる。しかし、パーシャル（`_notified_button.html.slim`）は`button_to`のみを返すため、`td`要素が消えてテーブル構造が壊れる。

```slim
/ ❌ 問題のある構造
td id="notified_status_#{allowed_email.id}"  ← この td 要素全体が置き換えられる
  = button_to "連絡済み", ...  ← これだけが返される（td がなくなる）
```

### 2. 修正案

**`td`の中に`div`を追加し、その`div`だけを置き換える:**

```slim
/ ✅ 修正後
table
  thead
    tr
      th メールアドレス
      th 連絡済み
      th アクション
  tbody
    - @allowed_emails.each do |allowed_email|
      tr
        td = allowed_email.email
        td
          / td の中に div を追加（この div だけがターゲット）
          div id="notified_status_#{allowed_email.id}"
            = render partial: "notified_button", locals: { allowed_email: allowed_email }
        td
          = link_to "削除", admin_allowed_email_path(allowed_email), method: :delete
```

**Turbo Streamテンプレートは変更なし:**

```slim
/ app/views/admin/allowed_emails/toggle_notified.turbo_stream.slim
= turbo_stream.replace "notified_status_#{@allowed_email.id}" do
  = render partial: "notified_button", locals: { allowed_email: @allowed_email }
```

### 3. ターゲット指定のポイント

**重要な原則:**
- **ターゲット要素は、構造的に置き換えても問題ない単位で設定する**

**ダメな例:**
- `<td id="...">` をターゲットにする → テーブル構造が壊れる
- `<tr id="...">` をターゲットにする → 行全体が消える
- `<ul id="...">` をターゲットにする → リスト全体が消える

**良い例:**
- `<td><div id="..."></div></td>` → `div` だけを置き換え
- `<tr><td><div id="..."></div></td></tr>` → `div` だけを置き換え
- `<ul><li id="..."></li></ul>` → `li` を追加/削除

**Day 28のFlexitypeでの実例:**

Day 28でこの問題が発生し、`td`の中に`div`を追加することで解決しました。

</details>

---

## 問題4: Google認証とTurboの統合 🔴

### PR内容

**タイトル**: Google Sign-InをTurboに対応

**説明**: Google Identity Services SDKを使ったログイン機能を実装しました。

**変更内容**:

```javascript
// app/javascript/controllers/google_signin_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Google Identity Services の初期化
    if (typeof google !== "undefined" && google.accounts) {
      google.accounts.id.initialize({
        client_id: this.element.dataset.clientId,
        callback: this.handleCredentialResponse.bind(this)
      })

      google.accounts.id.renderButton(
        document.getElementById("g_id_signin"),
        { theme: "outline", size: "large" }
      )
    }
  }

  handleCredentialResponse(response) {
    // IDトークンをサーバーに送信
    const form = document.createElement('form')
    form.method = 'POST'
    form.action = '/auth/google'

    const input = document.createElement('input')
    input.type = 'hidden'
    input.name = 'credential'
    input.value = response.credential

    form.appendChild(input)
    document.body.appendChild(form)
    form.submit()
  }
}
```

**動作確認結果**:
- 初回ログイン → OK ✅
- ログアウト後、再度ログインページに戻る → エラー ❌

```
[GSI_LOGGER]: Failed to render button before calling initialize().
```

### 質問

1. なぜ2回目のログインでエラーが発生するのですか？
2. どのように修正すべきですか？コードで示してください。
3. CSP（Content Security Policy）の設定も必要ですか？必要な場合、どのように設定すべきですか？
4. この問題は実際のプロジェクト（Flexitype）でどのように解決されましたか？

<details>
<summary>解答例を表示</summary>

### 1. 原因

**Turboによる高速ページ遷移の影響:**
- Turboはページ全体をリロードせず、`<body>`だけを置き換える
- ログアウト → ログインページに戻ると、Stimulusコントローラーが再度`connect()`を実行
- Google SDKが再初期化され、既存のSDKインスタンスと競合

**問題の流れ:**
```
1. 初回ログイン: google.accounts.id.initialize() 実行 → OK
2. ログアウト: Turboでページ遷移（bodyだけ置き換え）
3. ログインページに戻る: connect() が再度実行される
4. google.accounts.id.initialize() が2回目の実行 → エラー
```

### 2. 修正案（重複初期化の防止）

**フラグを使って重複初期化を防ぐ:**

```javascript
// ✅ 修正後
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // 既に初期化済みかチェック
    if (this.element.dataset.googleSigninInitialized === "true") {
      console.log("[GoogleSignIn] Already initialized, skipping...")
      return  // 早期リターン
    }

    // Google Identity Services の初期化
    if (typeof google !== "undefined" && google.accounts) {
      google.accounts.id.initialize({
        client_id: this.element.dataset.clientId,
        callback: this.handleCredentialResponse.bind(this)
      })

      google.accounts.id.renderButton(
        document.getElementById("g_id_signin"),
        { theme: "outline", size: "large", width: 280 }
      )

      // 初期化済みフラグを設定
      this.element.dataset.googleSigninInitialized = "true"
      console.log("[GoogleSignIn] Initialized successfully")
    }
  }

  disconnect() {
    // コントローラーが破棄される時にクリーンアップ
    if (this.element.dataset.googleSigninInitialized === "true") {
      this.element.dataset.googleSigninInitialized = "false"
      console.log("[GoogleSignIn] Disconnected")
    }
  }

  handleCredentialResponse(response) {
    // IDトークンをサーバーに送信
    const form = document.createElement('form')
    form.method = 'POST'
    form.action = '/auth/google'

    const input = document.createElement('input')
    input.type = 'hidden'
    input.name = 'credential'
    input.value = response.credential

    // CSRF トークンを追加
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content
    const csrfInput = document.createElement('input')
    csrfInput.type = 'hidden'
    csrfInput.name = 'authenticity_token'
    csrfInput.value = csrfToken

    form.appendChild(input)
    form.appendChild(csrfInput)
    document.body.appendChild(form)
    form.submit()
  }
}
```

**重要なポイント:**
- `data-google-signin-initialized` フラグで初期化済みかチェック
- `disconnect()` でクリーンアップ
- CSRF トークンの追加（セキュリティ対策）

### 3. CSP設定（必須）

**ファイル:** `config/initializers/content_security_policy.rb`

```ruby
# ✅ CSP設定
Rails.application.config.content_security_policy do |policy|
  policy.default_src :self, :https
  policy.font_src    :self, :https, :data
  policy.img_src     :self, :https, :data
  policy.object_src  :none

  # Google Identity Services用の設定（重要）
  policy.script_src :self, :https, :unsafe_inline, "https://accounts.google.com"
  policy.frame_src :self, "https://accounts.google.com"
  policy.connect_src :self, "https://accounts.google.com"

  # Turbo対応（nonce無効化）
  policy.style_src :self, :https, :unsafe_inline
end

# nonce機能を無効化（Google SDKとの競合を回避）
Rails.application.config.content_security_policy_nonce_generator = nil
Rails.application.config.content_security_policy_nonce_directives = []
```

**重要な変更点:**

1. **`:unsafe_inline` の追加**
   - Google SDKがインラインスクリプトを使用するため必須
   - セキュリティリスクはあるが、Google SDKを使う場合は避けられない

2. **nonce機能の無効化**
   - Railsのnonce機能とGoogle SDKが競合
   - `content_security_policy_nonce_generator = nil` で無効化

3. **Google ドメインの許可**
   - `script-src`: Google SDKスクリプトの読み込み
   - `frame-src`: Google認証画面のiframe
   - `connect_src`: Google APIへの接続

### 4. Flexitypeでの実例（Day 19）

Day 19でこの問題が発生し、以下の2段階で解決しました:

**Phase 1: 重複初期化の防止**
- `data-google-signin-initialized` フラグの導入
- `disconnect()` でのクリーンアップ

**Phase 2: CSP設定の調整**
- `:unsafe_inline` の追加
- nonce機能の無効化
- Googleドメインの許可

**結果:**
- Turboによるページ遷移後も正常に動作 ✅
- ログアウト → 再ログインが可能 ✅
- コンソール警告は残るが、機能的には全く問題なし ✅

**既知の問題:**
```
[GSI_LOGGER]: Failed to render button before calling initialize().
```
この警告はGoogle側の内部処理によるもので、完全な解消は困難。ただし、機能に影響はない。

</details>

---

## 総合問題: 実装パターンの選択 🔴

### シナリオ

以下の3つの機能を実装する必要があります。それぞれに最適な実装パターン（Turbo Frames サーバー管理 / Turbo Frames クライアント管理 / Turbo Streams）を選び、理由を説明してください。

### 機能1: 商品一覧のカテゴリーフィルター

**要件:**
- タブ: 「全て」「食品」「衣料」「家電」の4つ
- タブクリック時に商品一覧が切り替わる
- URLで状態を共有したい（ブックマーク可能）
- ページネーション対応

### 機能2: ダッシュボードの統計カード

**要件:**
- 複数のカード（売上、注文数、ユーザー数など）
- 期間選択（今日、今週、今月）でリアルタイム更新
- カードごとにローディングアニメーション表示
- カード間でアニメーションのタイミングをずらす

### 機能3: コメントの即座の追加/削除

**要件:**
- コメント投稿フォーム送信時、ページリロードなしでコメントリストに追加
- コメント削除時、ページリロードなしでリストから削除
- 投稿後、フォームをクリア
- コメント数をリアルタイム更新

<details>
<summary>解答例を表示</summary>

### 機能1: 商品一覧のカテゴリーフィルター

**選択: Turbo Frames（サーバーサイド管理）**

**理由:**

1. **URLで状態を共有したい**
   - サーバーサイド管理では `?category=food` のようなパラメータで状態管理
   - ブックマーク可能、SEOにも有利

2. **シンプルな実装**
   - Stimulusコントローラー不要
   - サーバー側で `@category` を管理するだけ

3. **ページネーション対応**
   - `params: { category: @category }` で簡単に引き継ぎ可能

**実装例:**

```ruby
# コントローラー
class ProductsController < ApplicationController
  def index
    @category = params[:category] || "all"
    @products = filter_by_category(Product.all, @category).page(params[:page])
  end
end
```

```slim
/ ビュー
= turbo_frame_tag "products_content" do
  / タブナビゲーション（フレーム内）
  nav
    = link_to "全て", products_path(category: 'all'), data: { turbo_frame: "products_content" }
    = link_to "食品", products_path(category: 'food'), data: { turbo_frame: "products_content" }

  / 商品一覧
  - @products.each do |product|
    .product = product.name

  / ページネーション（カテゴリー引き継ぎ）
  = paginate @products, params: { category: @category }
```

**参考: Flexitypeの実装**
- Day 24の期間フィルター（同じパターン）

---

### 機能2: ダッシュボードの統計カード

**選択: Turbo Frames（クライアントサイド管理） + Stimulus**

**理由:**

1. **ローディングアニメーションが必要**
   - Stimulusで柔軟に制御
   - カードごとにアニメーションタイミングをずらす

2. **URLで状態を共有する必要がない**
   - ダッシュボードの期間選択は一時的な状態
   - ブックマーク不要

3. **複数フレームの連携**
   - 複数のカード（複数のTurbo Frames）を同時に更新
   - Stimulusで統一的に管理

**実装例:**

```javascript
// Stimulusコントローラー
export default class extends Controller {
  static targets = ["card", "period"]

  connect() {
    this.cardTargets.forEach((card, index) => {
      card.addEventListener("turbo:before-frame-render", () => {
        // カードごとにアニメーション遅延
        setTimeout(() => this.showLoading(card), index * 100)
      })
      card.addEventListener("turbo:frame-load", () => {
        this.hideLoading(card)
      })
    })
  }

  changePeriod(event) {
    const period = event.target.value
    // 全カードを更新
    this.cardTargets.forEach(card => {
      const url = card.dataset.url + `?period=${period}`
      card.src = url
    })
  }
}
```

```slim
/ ビュー
.dashboard data-controller="dashboard"
  / 期間選択（フレーム外）
  select data-action="change->dashboard#changePeriod"
    option value="today" 今日
    option value="week" 今週
    option value="month" 今月

  / 統計カード（複数のTurbo Frames）
  = turbo_frame_tag "sales_card", src: sales_path, data: { dashboard_target: "card", url: sales_path }
  = turbo_frame_tag "orders_card", src: orders_path, data: { dashboard_target: "card", url: orders_path }
  = turbo_frame_tag "users_card", src: users_path, data: { dashboard_target: "card", url: users_path }
```

**参考: Flexitypeの実装**
- Day 22のトップページタブ（同じパターン）

---

### 機能3: コメントの即座の追加/削除

**選択: Turbo Streams**

**理由:**

1. **フォーム送信後の即座のフィードバック**
   - コメント追加後、すぐにリストに反映
   - フォームをクリア（複数箇所の更新）

2. **複数箇所の同時更新**
   - コメントリストに追加（`append`）
   - コメント数を更新（`update`）
   - フォームをクリア（`update`）

3. **削除アクションの即座の反映**
   - コメントをリストから削除（`remove`）
   - コメント数を更新（`update`）

**実装例:**

```ruby
# コントローラー
class CommentsController < ApplicationController
  def create
    @comment = Comment.create!(comment_params)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @comment.post }
    end
  end

  def destroy
    @comment = Comment.find(params[:id])
    @comment.destroy!

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @comment.post }
    end
  end
end
```

```slim
/ create.turbo_stream.slim
/ 1. コメントリストに追加
= turbo_stream.append "comments_list" do
  = render partial: "comments/comment", locals: { comment: @comment }

/ 2. コメント数を更新
= turbo_stream.update "comments_count" do
  = @comment.post.comments.count

/ 3. フォームをクリア
= turbo_stream.update "comment_form" do
  = render partial: "comments/form", locals: { post: @comment.post }
```

```slim
/ destroy.turbo_stream.slim
/ 1. コメントを削除
= turbo_stream.remove "comment_#{@comment.id}"

/ 2. コメント数を更新
= turbo_stream.update "comments_count" do
  = @comment.post.comments.count
```

**参考: Flexitypeの実装**
- Day 28の通知フラグトグル（同じパターン）

---

### まとめ: パターン選択の基準

| パターン | 適している場合 | 実装の複雑さ |
|----------|----------------|--------------|
| **Turbo Frames（サーバー管理）** | URLで状態共有、シンプルな実装 | 低 |
| **Turbo Frames（クライアント管理）** | ローディング表示、複数フレーム連携 | 中 |
| **Turbo Streams** | フォーム送信後のフィードバック、複数箇所同時更新 | 中〜高 |

**基本方針:**
1. まずサーバーサイド管理で実装できないか検討
2. クライアント側の柔軟な制御が必要ならStimulus追加
3. 複数箇所の同時更新が必要ならTurbo Streams

</details>

---

## 採点基準

### 問題1（🟢）: 20点
- 原因を正しく理解している: 10点
- 修正案が正しい: 10点

### 問題2（🟡）: 20点
- 原因を正しく理解している: 7点
- 修正案が正しい: 10点
- Flexitypeの実例を知っている: 3点

### 問題3（🟡🔴）: 30点
- 原因を正しく理解している: 10点
- 修正案が正しい: 15点
- ターゲット指定のポイントを理解している: 5点

### 問題4（🔴）: 30点
- 原因を正しく理解している: 10点
- 修正案が正しい: 10点
- CSP設定の必要性を理解している: 5点
- Flexitypeの実例を知っている: 5点

### 総合問題（🔴）: ボーナス20点
- 機能1の選択と理由が適切: 7点
- 機能2の選択と理由が適切: 7点
- 機能3の選択と理由が適切: 6点

**合計: 120点（ボーナス含む）**

---

## 合格ライン

- 60点以上: 合格（基本的な理解がある）
- 80点以上: 優秀（実践的な知識がある）
- 100点以上: 非常に優秀（Hotwireを深く理解している）

---

**作成日**: 2025-12-30
**対象教材**: [03_hotwire.md](03_hotwire.md)
**難易度**: 🟡 中級
