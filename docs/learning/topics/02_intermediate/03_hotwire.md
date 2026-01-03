# Hotwire（Turbo Frames + Stimulus）の実践的な使い方

**難易度**: 🟡 中級
**推定学習時間**: 2〜3時間
**対応する日報**: Day 9, Day 19, Day 22, Day 24, Day 28
**関連PR**: #94, #96, #101

---

## 🎯 学習目標

この教材を学ぶことで、以下ができるようになります:

- Turbo Framesによるページ部分更新の仕組みを理解する
- サーバーサイド管理とクライアントサイド管理の2パターンを使い分けられる
- Turbo Streamsによる動的DOM更新を実装できる
- 外部ライブラリ（Google認証など）とTurboの統合方法を理解する
- jQueryに依存しないモダンなフロントエンド開発ができる

---

## 📚 前提知識

この教材を理解するには、以下の知識が必要です:

- Railsの基本的なMVCパターン
- HTMLのdata属性の基本
- JavaScriptの基礎（ES6クラス構文）
- HTTPリクエスト/レスポンスの基本

---

## 📖 本編

### Hotwireとは？

**Hotwire (HTML Over The Wire)** は、Railsのモダンなフロントエンド戦略です。主に以下の3つのコンポーネントで構成されます:

1. **Turbo Drive**: ページ全体の高速化（ページ遷移をAjax化）
2. **Turbo Frames**: ページの一部分だけを更新
3. **Turbo Streams**: サーバーから複数の DOM 更新を送信
4. **Stimulus**: 軽量なJavaScriptフレームワーク（jQuery代替）

**従来のSPA（React/Vue）との違い:**

| 従来のSPA | Hotwire |
|-----------|---------|
| JSON APIを叩いてクライアントでHTMLを生成 | サーバーが完成したHTMLを返す |
| JavaScriptが大量に必要 | 最小限のJavaScriptで実現 |
| SEO対応が難しい | サーバーサイドレンダリングでSEOに強い |
| 初期ロードが重い | サーバーでレンダリングするため軽い |

---

## 実装パターン1: Turbo Frames（サーバーサイド管理）

このパターンは、Day 24の期間フィルター機能で採用されました。

### 概要

- タブナビゲーションをTurbo Frame内に含める
- サーバー側で現在のタブ（アクティブ状態）を管理
- Stimulusコントローラー不要でシンプル

### 実装例: 練習履歴の期間フィルター

#### 1. コントローラー（サーバーサイド）

**ファイル:** `app/controllers/my/lesson_records_controller.rb`

```ruby
class My::LessonRecordsController < My::ApplicationController
  def index
    # パラメータから期間を取得（デフォルト: "all"）
    @period = params[:period] || "all"

    # 期間でフィルタリング
    @filtered_records = filter_by_period(current_user.lesson_records, @period)

    # ページネーション付きで履歴を取得
    @lesson_records = @filtered_records.recent.page(params[:page]).per(20)

    # 統計情報を計算（フィルタリング後のレコードで計算）
    @total_count = @filtered_records.count
    @average_accuracy = @filtered_records.average(:accuracy)&.round(1) || 0
    @average_wpm = @filtered_records.where.not(wpm: nil).average(:wpm)&.round(1) || 0
  end

  private

  def filter_by_period(records, period)
    case period
    when "week"
      records.where("completed_at >= ?", 1.week.ago)
    when "month"
      records.where("completed_at >= ?", 1.month.ago)
    else
      records # 全期間
    end
  end
end
```

**ポイント:**
- `@period` でサーバー側がアクティブタブを管理
- ビューで `@period` に基づいてタブのスタイルを設定

#### 2. ビュー（Turbo Frames）

**ファイル:** `app/views/my/lesson_records/index.html.slim`

```slim
/ ページヘッダー
.mb-6
  h2.text-3xl.font-bold.text-gray-800.dark:text-white 練習履歴
  p.text-sm.text-gray-600.dark:text-gray-400.mt-2 あなたのタイピング練習の記録を確認できます

/ Turbo Frame: タブナビゲーション + コンテンツ全体を囲む
= turbo_frame_tag "history_content" do
  / 期間フィルタータブ
  .mb-6
    .border-b.border-gray-200.dark:border-gray-700
      nav.-mb-px.flex.space-x-8 aria-label="Period tabs"
        / タブ1: 全期間
        = link_to my_lesson_records_path(period: 'all'), \
          data: { turbo_frame: "history_content" }, \
          class: "#{@period == 'all' ? 'border-blue-500 text-blue-600' : 'border-transparent text-gray-500'} whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm transition-colors" do
          | 全期間

        / タブ2: 直近1ヶ月
        = link_to my_lesson_records_path(period: 'month'), \
          data: { turbo_frame: "history_content" }, \
          class: "#{@period == 'month' ? 'border-blue-500 text-blue-600' : 'border-transparent text-gray-500'} whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm transition-colors" do
          | 直近1ヶ月

        / タブ3: 直近1週間
        = link_to my_lesson_records_path(period: 'week'), \
          data: { turbo_frame: "history_content" }, \
          class: "#{@period == 'week' ? 'border-blue-500 text-blue-600' : 'border-transparent text-gray-500'} whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm transition-colors" do
          | 直近1週間

  / 統計情報（期間に連動）
  .grid.grid-cols-1.md:grid-cols-3.gap-4.mb-6
    .bg-white.dark:bg-gray-800.rounded-lg.shadow.p-6
      p.text-sm.text-gray-600.dark:text-gray-400 総練習回数
      p.text-3xl.font-bold.text-blue-600.mt-2
        = @total_count
        span.text-lg.text-gray-500.ml-2 回

    .bg-white.dark:bg-gray-800.rounded-lg.shadow.p-6
      p.text-sm.text-gray-600.dark:text-gray-400 平均正答率
      p.text-3xl.font-bold.text-green-600.mt-2
        = @average_accuracy
        span.text-lg.text-gray-500.ml-2 %

  / 履歴一覧（共通パーシャル使用）
  .bg-white.dark:bg-gray-800.rounded-lg.shadow
    = render "shared/lesson_records_table", \
      lesson_records: @lesson_records, \
      show_pagination: true, \
      pagination_params: { period: @period }
```

**重要なポイント:**

1. **`turbo_frame_tag "history_content"`**
   - タブナビゲーション + コンテンツ全体を囲む
   - タブクリック時にフレーム全体が更新される

2. **`data: { turbo_frame: "history_content" }`**
   - リンククリック時に `history_content` フレーム内だけを更新
   - ページ全体はリロードされない

3. **サーバー側でアクティブ状態を管理**
   - `@period == 'all'` で条件分岐してスタイルを設定
   - Stimulusコントローラー不要

#### デバッグプロセス（Day 24の実例）

**問題1: タブのアクティブ状態が更新されない**

```slim
/ ❌ 悪い例: タブがフレーム外にある
.mb-6
  .border-b
    nav
      = link_to "全期間", my_lesson_records_path(period: 'all'), data: { turbo_frame: "history_content" }

= turbo_frame_tag "history_content" do
  / タブクリック時、この中だけが更新される
  / → タブ自体は更新されない
```

**解決策:**

```slim
/ ✅ 良い例: タブもフレーム内に含める
= turbo_frame_tag "history_content" do
  .mb-6
    .border-b
      nav
        = link_to "全期間", my_lesson_records_path(period: 'all'), data: { turbo_frame: "history_content" }
  / タブ + コンテンツ全体が更新される
  / → アクティブ状態が正しく更新される
```

**問題2: ページネーション時に期間パラメータが消える**

```ruby
# ❌ 悪い例: 期間パラメータが引き継がれない
= paginate @lesson_records
# ページ2に行くと period パラメータが消える
```

**解決策:**

```ruby
# ✅ 良い例: pagination_params で引き継ぎ
= paginate @lesson_records, params: { period: @period }
# ページ2: /my/lesson_records?period=week&page=2
```

---

## 実装パターン2: Turbo Frames（クライアントサイド管理）

このパターンは、Day 22のトップページタブ化で採用されました。

### 概要

- タブナビゲーションをTurbo Frame外に配置
- Stimulusコントローラーでクライアント側がアクティブ状態を管理
- より柔軟な制御が可能

### 実装例: トップページのタブ切り替え

#### 1. コントローラー（サーバーサイド）

**ファイル:** `app/controllers/home_controller.rb`

```ruby
class HomeController < ApplicationController
  def index
    @tabs = Category::TABS
    @current_tab = params[:tab] || "basics"

    # タブごとにカテゴリーをフィルタリング
    @categories = categories_for_tab(@current_tab)
  end

  private

  def categories_for_tab(tab)
    scope = Category.published.by_tab(tab).order(:position)
    scope = scope.public_only unless logged_in?
    scope
  end
end
```

#### 2. ビュー（Turbo Frames + Stimulus）

**ファイル:** `app/views/home/index.html.slim`

```slim
/ タブナビゲーション（Stimulusコントローラーで管理）
.mb-6 data-controller="tabs"
  .border-b.border-gray-200.dark:border-gray-700
    nav.flex.space-x-2 aria-label="Tabs"
      - @tabs.each do |tab_key, tab_config|
        = link_to root_path(tab: tab_key), \
          data: { \
            turbo_frame: "lesson_content", \
            tabs_target: "tab", \
            tab: tab_key \
          }, \
          class: "group inline-flex items-center gap-2 px-4 py-3 border-b-2 font-medium text-sm transition-colors #{'border-blue-500 text-blue-600' if @current_tab == tab_key.to_s} #{'border-transparent text-gray-500' unless @current_tab == tab_key.to_s}" do
          span.text-xl = tab_config[:icon]
          = tab_config[:name]

  / Turbo Frame: レッスンコンテンツのみ
  = turbo_frame_tag "lesson_content", data: { tabs_target: "content" } do
    = render partial: "tab_content", locals: { tab_key: @current_tab }
```

**ポイント:**
- `data-controller="tabs"` で Stimulus コントローラーを適用
- タブナビゲーションは Turbo Frame の外
- `data: { tabs_target: "tab" }` で Stimulus がターゲットを取得

#### 3. Stimulusコントローラー（クライアントサイド）

**ファイル:** `app/javascript/controllers/tabs_controller.js`

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "tab", "content" ]

  connect() {
    // Turbo Frameのロード開始/終了イベントをリッスン
    this.contentTarget.addEventListener("turbo:frame-load", this.hideLoading.bind(this))
    this.contentTarget.addEventListener("turbo:before-frame-render", this.showLoading.bind(this))

    // タブクリック時のイベントリスナーを追加
    this.tabTargets.forEach(tab => {
      tab.addEventListener('click', this.switchTab.bind(this))
    })
  }

  disconnect() {
    // イベントリスナーのクリーンアップ
    this.contentTarget.removeEventListener("turbo:frame-load", this.hideLoading.bind(this))
    this.contentTarget.removeEventListener("turbo:before-frame-render", this.showLoading.bind(this))
  }

  switchTab(event) {
    // クリックされたタブを取得
    const clickedTab = event.currentTarget

    // 全タブのアクティブ状態をリセット
    this.tabTargets.forEach(tab => {
      tab.classList.remove('border-blue-500', 'text-blue-600')
      tab.classList.add('border-transparent', 'text-gray-500')
    })

    // クリックされたタブをアクティブに
    clickedTab.classList.remove('border-transparent', 'text-gray-500')
    clickedTab.classList.add('border-blue-500', 'text-blue-600')
  }

  showLoading() {
    // ローディング表示を追加
    const loadingHTML = `
      <div class="flex items-center justify-center py-12">
        <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500"></div>
        <span class="ml-3 text-gray-600">読み込み中...</span>
      </div>
    `
    if (!this.contentTarget.querySelector('.loading-indicator')) {
      const loadingDiv = document.createElement('div')
      loadingDiv.className = 'loading-indicator'
      loadingDiv.innerHTML = loadingHTML
      this.contentTarget.insertBefore(loadingDiv, this.contentTarget.firstChild)
    }
  }

  hideLoading() {
    // ローディング表示を削除
    const loadingIndicator = this.contentTarget.querySelector('.loading-indicator')
    if (loadingIndicator) {
      loadingIndicator.remove()
    }
  }
}
```

**Stimulusの基本構造:**

1. **`static targets`**: DOM要素を取得
   - `tab`: タブボタン（複数）
   - `content`: コンテンツエリア（1つ）

2. **`connect()`**: コントローラー起動時に実行
   - イベントリスナーの追加
   - 初期化処理

3. **`disconnect()`**: コントローラー停止時に実行
   - イベントリスナーのクリーンアップ

4. **カスタムメソッド**: `switchTab()`, `showLoading()`, `hideLoading()`

---

## 実装パターン3: Turbo Streams（動的DOM更新）

このパターンは、Day 28の通知フラグトグル機能で採用されました。

### 概要

- サーバーから複数のDOM更新命令を送信
- ページリロード不要で部分的にUIを更新
- フォーム送信後の即座のフィードバックに最適

### 実装例: 通知フラグのトグル機能

#### 1. コントローラー

**ファイル:** `app/controllers/admin/allowed_emails_controller.rb`

```ruby
class Admin::AllowedEmailsController < Admin::ApplicationController
  before_action :set_allowed_email, only: [:toggle_notified]

  # PATCH /admin/allowed_emails/:id/toggle_notified
  def toggle_notified
    if @allowed_email.notified_at.present?
      @allowed_email.update!(notified_at: nil)
    else
      @allowed_email.update!(notified_at: Time.current)
    end

    respond_to do |format|
      format.turbo_stream  # Turbo Stream形式で返す
      format.html { redirect_to admin_allowed_emails_path }
    end
  end

  private

  def set_allowed_email
    @allowed_email = AllowedEmail.find(params[:id])
  end
end
```

**ポイント:**
- `respond_to do |format|` で Turbo Stream に対応
- `format.turbo_stream` を指定

#### 2. ビュー（一覧ページ）

**ファイル:** `app/views/admin/allowed_emails/index.html.slim`

```slim
table.w-full
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
          / Turbo Streamsで置き換えられる部分
          div id="notified_status_#{allowed_email.id}"
            = render partial: "notified_button", locals: { allowed_email: allowed_email }
        td
          = link_to "削除", admin_allowed_email_path(allowed_email), method: :delete
```

**重要なポイント:**

1. **`div id="notified_status_#{allowed_email.id}"`**
   - Turbo Streams のターゲット指定に使用
   - 一意のIDが必須

2. **パーシャル化**
   - 更新される部分をパーシャルに分離
   - Turbo Stream で同じパーシャルを再利用

#### 3. パーシャル（トグルボタン）

**ファイル:** `app/views/admin/allowed_emails/_notified_button.html.slim`

```slim
- if allowed_email.notified_at.present?
  / 連絡済み
  = button_to toggle_notified_admin_allowed_email_path(allowed_email), \
    method: :patch, \
    class: "inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-green-100 text-green-800 hover:bg-green-200 transition" do
    svg.w-4.h-4.mr-1 fill="none" stroke="currentColor" viewBox="0 0 24 24"
      path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"
    | 連絡済み (#{allowed_email.notified_at.strftime('%m/%d')})
- else
  / 未連絡
  = button_to toggle_notified_admin_allowed_email_path(allowed_email), \
    method: :patch, \
    class: "inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-gray-100 text-gray-600 hover:bg-gray-200 transition" do
    svg.w-4.h-4.mr-1 fill="none" stroke="currentColor" viewBox="0 0 24 24"
      path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"
    | 未連絡
```

#### 4. Turbo Streamテンプレート

**ファイル:** `app/views/admin/allowed_emails/toggle_notified.turbo_stream.slim`

```slim
= turbo_stream.replace "notified_status_#{@allowed_email.id}" do
  = render partial: "notified_button", locals: { allowed_email: @allowed_email }
```

**Turbo Streamの命令:**

| 命令 | 説明 | 使用例 |
|------|------|--------|
| `replace` | 要素全体を置き換え | ボタンの状態変更 |
| `update` | 要素の内容だけ置き換え | テキストの更新 |
| `append` | 要素の末尾に追加 | リストへの新規アイテム追加 |
| `prepend` | 要素の先頭に追加 | 最新コメントの追加 |
| `remove` | 要素を削除 | アイテムの削除 |

#### デバッグプロセス（Day 28の実例）

**問題: Turbo Streamsで要素が消える**

```slim
/ ❌ 悪い例: td要素自体をターゲットにする
td id="notified_status_#{allowed_email.id}"
  = render partial: "notified_button"
```

Turbo Streamで`replace`すると、`td`要素全体が置き換えられ、テーブル構造が壊れる。

**解決策:**

```slim
/ ✅ 良い例: td の中に div を追加
td
  div id="notified_status_#{allowed_email.id}"
    = render partial: "notified_button"
```

`td`の中の`div`だけを置き換えることで、テーブル構造を保ったまま更新できる。

---

## トラブルシューティング: Google認証とTurboの競合

Day 19で発生したGoogle Sign-In SDKとTurboの競合問題を解説します。

### 問題点

Google Sign-In SDKがTurboによるページ遷移を検知できず、初期化が重複してエラーになる。

```
[GSI_LOGGER]: The given origin is not allowed for the given client ID.
```

### 原因

1. **Turboによる高速ページ遷移**
   - Turboはページ全体をリロードせず、`<body>`だけを置き換える
   - Google SDKが再初期化される
   - 既存のSDKインスタンスと競合

2. **CSP（Content Security Policy）の競合**
   - Railsのnonce機能とGoogle SDKが競合
   - `script-src 'self' 'nonce-xxx'` ではGoogle SDKが動作しない

### 解決策1: 重複初期化の防止

**ファイル:** `app/javascript/controllers/google_signin_controller.js`

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // 既に初期化済みかチェック
    if (this.element.dataset.googleSigninInitialized === "true") {
      console.log("[GoogleSignIn] Already initialized, skipping...")
      return
    }

    // Google Identity Services の初期化
    if (typeof google !== "undefined" && google.accounts) {
      google.accounts.id.initialize({
        client_id: this.element.dataset.clientId,
        callback: this.handleCredentialResponse.bind(this)
      })

      google.accounts.id.renderButton(
        document.getElementById("g_id_signin"),
        {
          theme: "outline",
          size: "large",
          width: 280
        }
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
    // ID トークンをサーバーに送信
    const form = document.createElement('form')
    form.method = 'POST'
    form.action = '/auth/google'

    const input = document.createElement('input')
    input.type = 'hidden'
    input.name = 'credential'
    input.value = response.credential

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

**ポイント:**
- `data-google-signin-initialized` フラグで重複初期化を防止
- `disconnect()` でクリーンアップ
- Turboによるページ遷移後も正常に動作

### 解決策2: CSP設定の調整

**ファイル:** `config/initializers/content_security_policy.rb`

```ruby
Rails.application.config.content_security_policy do |policy|
  policy.default_src :self, :https
  policy.font_src    :self, :https, :data
  policy.img_src     :self, :https, :data
  policy.object_src  :none

  # Google Identity Services用の設定
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

2. **nonce機能の無効化**
   - RailsのnonceとGoogle SDKが競合
   - セキュリティと機能のトレードオフ

3. **Google ドメインの許可**
   - `script-src`, `frame-src`, `connect-src` にGoogle のドメインを追加

---

## パターンの使い分け

| パターン | 適している場合 | 適していない場合 |
|----------|----------------|------------------|
| **Turbo Frames（サーバー管理）** | タブの状態がURLパラメータと連動する、シンプルな実装を優先 | 複雑なクライアント側の状態管理が必要 |
| **Turbo Frames（クライアント管理）** | ローディング表示やアニメーションが必要、複数のフレームを連携 | サーバー側で状態管理できる単純なケース |
| **Turbo Streams** | フォーム送信後の即座のフィードバック、複数箇所の同時更新 | ページ全体のリロードで済む場合 |

### 実装の選択基準

**サーバーサイド管理を選ぶべきケース:**
- URLパラメータで状態を管理したい（ブックマーク可能性）
- SEOを重視する
- JavaScriptを最小限に抑えたい

**クライアントサイド管理を選ぶべきケース:**
- ローディングアニメーションが必要
- 複数のフレームを連携させたい
- より柔軟な制御が必要

**Turbo Streamsを選ぶべきケース:**
- フォーム送信後の即座のフィードバック
- 複数箇所の同時更新（例: カウンター + リスト追加）
- 削除アクションの即座の反映

---

## 💡 まとめ

### Hotwireの重要ポイント

1. **Turbo Frames**: ページの一部分だけを更新
   - `turbo_frame_tag` で囲んだ範囲だけが更新される
   - `data: { turbo_frame: "フレームID" }` でターゲットを指定

2. **Turbo Streams**: サーバーから複数のDOM更新を送信
   - `replace`, `update`, `append`, `prepend`, `remove` の5つの命令
   - フォーム送信後の即座のフィードバックに最適

3. **Stimulus**: 軽量なJavaScriptフレームワーク
   - `data-controller` でコントローラーを適用
   - `data-{controller}-target` でDOM要素を取得
   - `connect()`, `disconnect()` でライフサイクル管理

### ベストプラクティス

**Turbo Frames:**
- タブナビゲーションをフレーム内に含めるか外に出すかを慎重に検討
- ページネーションパラメータの引き継ぎを忘れない
- フレームIDは一意にする

**Turbo Streams:**
- ターゲット要素は構造的に置き換えても問題ない単位で設定
- パーシャル化して再利用しやすくする
- `respond_to do |format|` で両方のフォーマットに対応

**Stimulus:**
- イベントリスナーのクリーンアップを忘れない（`disconnect()`）
- 重複初期化を防ぐフラグを設定
- 外部ライブラリとの統合時は競合に注意

### 将来の学習

- Turbo Nativeによるモバイルアプリ化
- Hotwireとインポートマップの統合
- パフォーマンス最適化（遅延ロード、キャッシュ戦略）

---

## 🔗 関連教材

- [Concernパターン](01_concerns_pattern.md) - コントローラーの共通化
- [共通パーシャル](02_shared_partials.md) - ビューの共通化
- [リファクタリングパターン](../03_advanced/01_refactoring_patterns.md) - その他の改善パターン

---

## 📝 演習問題

### 問題1: 基礎理解（Turbo Frames）

以下の要件を満たすタブ切り替え機能を実装してください。

**要件:**
- タブ: 「全て」「進行中」「完了」の3つ
- サーバーサイド管理（Stimulus不要）
- タブのアクティブ状態がURLパラメータと連動

<details>
<summary>解答例を表示</summary>

**コントローラー:**

```ruby
class TasksController < ApplicationController
  def index
    @status = params[:status] || "all"
    @tasks = filter_by_status(Task.all, @status)
  end

  private

  def filter_by_status(tasks, status)
    case status
    when "in_progress"
      tasks.where(status: "in_progress")
    when "completed"
      tasks.where(status: "completed")
    else
      tasks
    end
  end
end
```

**ビュー:**

```slim
= turbo_frame_tag "tasks_content" do
  .mb-6
    nav
      = link_to tasks_path(status: 'all'), \
        data: { turbo_frame: "tasks_content" }, \
        class: "#{@status == 'all' ? 'active' : ''}" do
        | 全て

      = link_to tasks_path(status: 'in_progress'), \
        data: { turbo_frame: "tasks_content" }, \
        class: "#{@status == 'in_progress' ? 'active' : ''}" do
        | 進行中

      = link_to tasks_path(status: 'completed'), \
        data: { turbo_frame: "tasks_content" }, \
        class: "#{@status == 'completed' ? 'active' : ''}" do
        | 完了

  / タスク一覧
  - @tasks.each do |task|
    .task = task.title
```

</details>

### 問題2: 応用（Turbo Streams）

以下の要件を満たす「いいね」機能を実装してください。

**要件:**
- いいねボタンをクリックすると、ページリロードなしでいいね数が更新される
- いいね済みの場合は「いいね解除」に表示が変わる
- Turbo Streamsを使用

<details>
<summary>解答例を表示</summary>

**コントローラー:**

```ruby
class LikesController < ApplicationController
  def create
    @post = Post.find(params[:post_id])
    @like = @post.likes.create!(user: current_user)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @post }
    end
  end

  def destroy
    @like = Like.find(params[:id])
    @post = @like.post
    @like.destroy!

    respond_to do |format|
      format.turbo_stream { render :create }  # create.turbo_stream.slimを再利用
      format.html { redirect_to @post }
    end
  end
end
```

**ビュー（一覧ページ）:**

```slim
.post
  h3 = post.title
  div id="like_button_#{post.id}"
    = render partial: "likes/button", locals: { post: post }
```

**パーシャル（いいねボタン）:**

```slim
/ app/views/likes/_button.html.slim
- if current_user && post.liked_by?(current_user)
  = button_to post_like_path(post, post.likes.find_by(user: current_user)), \
    method: :delete, \
    class: "liked" do
    | ❤️ #{post.likes.count}
- else
  = button_to post_likes_path(post), \
    method: :post, \
    class: "like" do
    | 🤍 #{post.likes.count}
```

**Turbo Streamテンプレート:**

```slim
/ app/views/likes/create.turbo_stream.slim
= turbo_stream.replace "like_button_#{@post.id}" do
  = render partial: "likes/button", locals: { post: @post }
```

</details>

---

**作成日**: 2025-12-30
**難易度**: 🟡 中級
**学習時間の目安**: 2〜3時間
**関連Day**: Day 9, 19, 22, 24, 28
