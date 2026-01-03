# コードレビュー演習: Hotwire（Turbo Frames + Stimulus）

## 📋 演習の目的

このコードレビュー演習では、以下のスキルを身につけます：
- [ ] jQueryベースのタブ切り替えの問題点を指摘できる
- [ ] Turbo Framesによる改善方法を提案できる
- [ ] サーバーサイド管理とクライアントサイド管理の使い分けを判断できる
- [ ] Turbo Streamsの適切な実装方法を理解できる

---

## 🔍 PR内容

**PR タイトル:** ユーザー設定ページにタブ機能を追加

**説明:**
ユーザー設定ページに「プロフィール」「セキュリティ」「通知」の3つのタブを追加し、タブ切り替えでコンテンツを動的に切り替えられるようにしました。

**変更内容:**
- jQueryでタブ切り替えを実装
- AJAXでサーバーからコンテンツを取得
- クラス切り替えでアクティブタブを管理

---

## 📝 提出されたコード

### 1. JavaScript

```javascript
// app/javascript/application.js
import Rails from "@rails/ujs"
import Turbolinks from "turbolinks"
import * as ActiveStorage from "@rails/activestorage"
import "channels"
import $ from "jquery"

Rails.start()
Turbolinks.start()
ActiveStorage.start()

$(document).ready(function() {
  $('.tab-link').click(function(e) {
    e.preventDefault()

    // 全タブのアクティブクラスを削除
    $('.tab-link').removeClass('active')

    // クリックされたタブにアクティブクラスを追加
    $(this).addClass('active')

    // タブに対応するコンテンツを表示
    const target = $(this).data('tab')
    $('.tab-content').hide()
    $(`#${target}`).show()

    // サーバーから新しいコンテンツを取得
    $.ajax({
      url: $(this).attr('href'),
      method: 'GET',
      dataType: 'html',
      success: function(data) {
        $(`#${target}`).html(data)
      },
      error: function() {
        alert('コンテンツの取得に失敗しました')
      }
    })
  })

  // 初期表示時に最初のタブをアクティブに
  $('.tab-link').first().addClass('active')
  $('.tab-content').first().show()
})
```

### 2. HTML/ビュー

```html
<!-- app/views/my/settings/index.html.erb -->
<div class="container">
  <h1>ユーザー設定</h1>

  <!-- タブナビゲーション -->
  <nav class="tabs">
    <a href="/my/settings?tab=profile" class="tab-link" data-tab="profile">プロフィール</a>
    <a href="/my/settings?tab=security" class="tab-link" data-tab="security">セキュリティ</a>
    <a href="/my/settings?tab=notifications" class="tab-link" data-tab="notifications">通知</a>
  </nav>

  <!-- タブコンテンツ -->
  <div id="profile" class="tab-content">
    <%= render "settings/profile" %>
  </div>

  <div id="security" class="tab-content" style="display:none">
    <%= render "settings/security" %>
  </div>

  <div id="notifications" class="tab-content" style="display:none">
    <%= render "settings/notifications" %>
  </div>
</div>
```

### 3. CSS

```css
/* app/assets/stylesheets/tabs.css */
.tabs {
  display: flex;
  border-bottom: 1px solid #ccc;
  margin-bottom: 20px;
}

.tab-link {
  padding: 10px 20px;
  cursor: pointer;
  border-bottom: 2px solid transparent;
  text-decoration: none;
  color: #666;
}

.tab-link.active {
  border-bottom-color: #007bff;
  color: #007bff;
  font-weight: bold;
}

.tab-content {
  padding: 20px;
}
```

### 4. Gemfile

```ruby
gem 'jquery-rails'
gem 'turbolinks', '~> 5'
```

---

## 🎯 レビュー課題

以下の質問に答えてください。レベルごとに分かれています。

---

## 質問1: このコードの問題点（初級）🟢

以下の観点から、このコードの問題点を指摘してください。

### Q1-1: jQueryを使うことの問題点を3つ挙げてください

<details>
<summary>ヒント</summary>

- 依存関係
- Rails 7以降のデフォルト構成
- パフォーマンス

</details>

<details>
<summary>回答例</summary>

**1. 追加のライブラリ依存**
- jQueryは追加の依存関係であり、バンドルサイズが増加する
- Rails 7以降ではjQueryは標準で含まれていない
- モダンなJavaScript（ES6+）だけで十分実装可能

**2. Turboとの競合**
- Rails 7のデフォルトはTurbo（Hotwire）
- jQueryの`$(document).ready()`はTurboのページ遷移で再実行されない
- `Turbolinks.start()`とも競合する可能性がある

**3. メンテナンス性の低下**
- jQueryは古い技術で、最新のベストプラクティスではない
- 新しい開発者がjQueryを知らない可能性が高い
- Stimulusなどのモダンなフレームワークの方が保守性が高い

</details>

---

### Q1-2: Rails 7+で推奨される方法は何ですか？

<details>
<summary>ヒント</summary>

- Hotwire
- Turbo Frames
- Stimulus

</details>

<details>
<summary>回答例</summary>

**Rails 7+の標準: Hotwire（Turbo + Stimulus）**

- **Turbo Frames**: ページの一部だけを更新
- **Turbo Streams**: サーバーからDOM要素を動的に更新
- **Stimulus**: JavaScriptコントローラーでインタラクションを管理

**メリット:**
- jQueryなどの追加ライブラリ不要
- サーバーサイドレンダリングでSEOに有利
- ブラウザバックが正常に動作
- JavaScriptを最小限に抑えつつSPA風のUXを実現

**具体的な実装方法:**
1. **Turbo Framesのみ（サーバーサイド管理）**: 最もシンプル
2. **Turbo Frames + Stimulus（クライアントサイド管理）**: より動的なUI
3. **Turbo Streams（部分更新）**: フォーム送信後など

</details>

---

### Q1-3: このコードのブラウザバック問題について説明してください

<details>
<summary>ヒント</summary>

- URLの変化
- ブラウザ履歴
- ページ遷移

</details>

<details>
<summary>回答例</summary>

**問題:**
- タブクリック時に`e.preventDefault()`でデフォルトのページ遷移を抑制している
- jQueryの`$.ajax()`でコンテンツを取得しているため、URLが変わらない
- ブラウザ履歴に記録されないため、ブラウザバックが動作しない

**具体例:**
1. ユーザーが「プロフィール」タブをクリック
2. URLは `/my/settings` のまま変わらない
3. 「セキュリティ」タブをクリック
4. URLは依然として `/my/settings` のまま
5. ブラウザバックを押しても、タブの状態は変わらない（期待: プロフィールタブに戻る）

**解決策（Turbo Frames使用時）:**
- URLパラメータを使用（`/my/settings?tab=profile`）
- Turbo Framesは自動的にブラウザ履歴に記録される
- ブラウザバックで正しくタブが切り替わる

</details>

---

## 質問2: Turbo Framesによる改善（中級）🟡

このコードをTurbo Framesで改善する方法を考えてください。

### Q2-1: Turbo Framesを使った実装方法を説明してください

<details>
<summary>ヒント</summary>

- `turbo_frame_tag`
- `data: { turbo_frame: "..." }`
- サーバーサイドレンダリング

</details>

<details>
<summary>回答例</summary>

**ビュー（Slim形式）:**

```slim
/ app/views/my/settings/index.html.slim

.container
  h1 ユーザー設定

  / Turbo Frame（タブナビゲーション + コンテンツ全体を囲む）
  = turbo_frame_tag "settings_content" do
    / タブナビゲーション
    nav.tabs
      = link_to "プロフィール",
        my_settings_path(tab: 'profile'),
        data: { turbo_frame: "settings_content" },
        class: "tab-link #{@tab == 'profile' ? 'active' : ''}"

      = link_to "セキュリティ",
        my_settings_path(tab: 'security'),
        data: { turbo_frame: "settings_content" },
        class: "tab-link #{@tab == 'security' ? 'active' : ''}"

      = link_to "通知",
        my_settings_path(tab: 'notifications'),
        data: { turbo_frame: "settings_content" },
        class: "tab-link #{@tab == 'notifications' ? 'active' : ''}"

    / タブコンテンツ
    .tab-content
      - case @tab
      - when 'profile'
        = render "settings/profile"
      - when 'security'
        = render "settings/security"
      - when 'notifications'
        = render "settings/notifications"
```

**コントローラー:**

```ruby
# app/controllers/my/settings_controller.rb
class My::SettingsController < ApplicationController
  def index
    @tab = params[:tab] || "profile"  # デフォルトは「プロフィール」
  end
end
```

**JavaScript: 不要（0行）**

</details>

---

### Q2-2: `turbo_frame_tag`の役割は何ですか？

<details>
<summary>ヒント</summary>

- フレーム境界
- 部分更新
- ID指定

</details>

<details>
<summary>回答例</summary>

**`turbo_frame_tag`の役割:**

1. **フレーム境界の定義**
   - `turbo_frame_tag "settings_content"`で囲まれた範囲がフレームになる
   - この範囲内のリンクやフォームは、デフォルトでフレーム内だけを更新する

2. **部分更新のターゲット指定**
   - `data: { turbo_frame: "settings_content" }`でターゲットを指定
   - リンククリック時に、`settings_content`フレームだけが更新される
   - ページ全体はリロードされない

3. **サーバーレスポンスのマッチング**
   - サーバーからのレスポンスも同じID（`settings_content`）のフレームを含む必要がある
   - 同じIDのフレーム内容だけが置き換わる

**HTMLレンダリング結果:**

```html
<turbo-frame id="settings_content">
  <!-- フレーム内のコンテンツ -->
</turbo-frame>
```

</details>

---

### Q2-3: `data: { turbo_frame: "..." }`の意味は何ですか？

<details>
<summary>ヒント</summary>

- リンクの動作指定
- ターゲットフレーム
- デフォルト動作

</details>

<details>
<summary>回答例</summary>

**`data: { turbo_frame: "..." }`の意味:**

1. **ターゲットフレームの指定**
   - このリンクをクリックした際に更新するフレームを指定
   - `data: { turbo_frame: "settings_content" }` → `settings_content`フレームを更新

2. **デフォルト動作との違い**
   - デフォルト: フレーム内のリンクは、そのフレーム自身を更新
   - `data: { turbo_frame: "settings_content" }`: 明示的に特定のフレームを指定

3. **特殊な値**
   - `data: { turbo_frame: "_top" }`: フレームを抜けて、ページ全体を更新
   - `data: { turbo_frame: "_self" }`: そのフレーム自身を更新（デフォルト）

**例:**

```slim
/ フレーム内のリンクが他のフレームを更新
= turbo_frame_tag "sidebar" do
  = link_to "プロフィール",
    my_settings_path(tab: 'profile'),
    data: { turbo_frame: "main_content" }  # main_contentフレームを更新

= turbo_frame_tag "main_content" do
  / プロフィールコンテンツ
```

</details>

---

## 質問3: 2つのパターンの実装（中級〜上級）🟡🔴

サーバーサイド管理パターンとStimulus管理パターンの両方を実装してください。

### Q3-1: サーバーサイド管理パターンのコードを書いてください

<details>
<summary>ヒント</summary>

- コントローラーで`@tab`を管理
- ビューで`@tab`に基づいてアクティブ状態を判定
- Stimulusコントローラー不要

</details>

<details>
<summary>回答例</summary>

**コントローラー:**

```ruby
# app/controllers/my/settings_controller.rb
class My::SettingsController < ApplicationController
  def index
    @tab = params[:tab] || "profile"  # デフォルトは「プロフィール」
  end
end
```

**ビュー:**

```slim
/ app/views/my/settings/index.html.slim

.container
  h1 ユーザー設定

  / Turbo Frame（タブナビゲーション + コンテンツを囲む）
  = turbo_frame_tag "settings_content" do
    / タブナビゲーション
    .border-b.border-gray-200
      nav.-mb-px.flex.space-x-8
        = link_to my_settings_path(tab: 'profile'),
          data: { turbo_frame: "settings_content" },
          class: "#{@tab == 'profile' ? 'border-blue-500 text-blue-600' : 'border-transparent text-gray-500'} whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm" do
          | プロフィール

        = link_to my_settings_path(tab: 'security'),
          data: { turbo_frame: "settings_content" },
          class: "#{@tab == 'security' ? 'border-blue-500 text-blue-600' : 'border-transparent text-gray-500'} whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm" do
          | セキュリティ

        = link_to my_settings_path(tab: 'notifications'),
          data: { turbo_frame: "settings_content" },
          class: "#{@tab == 'notifications' ? 'border-blue-500 text-blue-600' : 'border-transparent text-gray-500'} whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm" do
          | 通知

    / タブコンテンツ
    .tab-content.py-6
      - case @tab
      - when 'profile'
        = render "settings/profile"
      - when 'security'
        = render "settings/security"
      - when 'notifications'
        = render "settings/notifications"
```

**JavaScript: 不要（0行）**

**メリット:**
- JavaScriptが全く不要
- サーバーサイドでアクティブ状態を管理（シンプル）
- SEOに有利（サーバーサイドレンダリング）
- ブラウザバックが正常に動作

**デメリット:**
- サーバーへのリクエストが発生（わずかな遅延）

</details>

---

### Q3-2: Stimulus管理パターンのコードを書いてください

<details>
<summary>ヒント</summary>

- Stimulusコントローラーを作成
- `switchTab`メソッドでクラス切り替え
- `showLoading`/`hideLoading`でローディング表示

</details>

<details>
<summary>回答例</summary>

**Stimulusコントローラー:**

```javascript
// app/javascript/controllers/tabs_controller.js
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
    this.contentTarget.removeEventListener("turbo:frame-load", this.hideLoading.bind(this))
    this.contentTarget.removeEventListener("turbo:before-frame-render", this.showLoading.bind(this))
  }

  switchTab(event) {
    // クリックされたタブを取得
    const clickedTab = event.currentTarget

    // 全タブのアクティブ状態をリセット
    this.tabTargets.forEach(tab => {
      tab.classList.remove('border-blue-500', 'text-blue-600')
      tab.classList.add('border-transparent', 'text-gray-500', 'hover:text-gray-700')
    })

    // クリックされたタブをアクティブに
    clickedTab.classList.remove('border-transparent', 'text-gray-500', 'hover:text-gray-700')
    clickedTab.classList.add('border-blue-500', 'text-blue-600')
  }

  showLoading() {
    // ローディング表示
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

**ビュー:**

```slim
/ app/views/my/settings/index.html.slim

/ Stimulusコントローラーを適用
.container data-controller="tabs"
  h1 ユーザー設定

  / タブナビゲーション
  .border-b.border-gray-200
    nav.-mb-px.flex.space-x-8
      = link_to my_settings_path(tab: 'profile'),
        data: {
          turbo_frame: "settings_content",
          tabs_target: "tab"
        },
        class: "#{@tab == 'profile' ? 'border-blue-500 text-blue-600' : 'border-transparent text-gray-500'} whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm" do
        | プロフィール

      = link_to my_settings_path(tab: 'security'),
        data: {
          turbo_frame: "settings_content",
          tabs_target: "tab"
        },
        class: "#{@tab == 'security' ? 'border-blue-500 text-blue-600' : 'border-transparent text-gray-500'} whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm" do
        | セキュリティ

      = link_to my_settings_path(tab: 'notifications'),
        data: {
          turbo_frame: "settings_content",
          tabs_target: "tab"
        },
        class: "#{@tab == 'notifications' ? 'border-blue-500 text-blue-600' : 'border-transparent text-gray-500'} whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm" do
        | 通知

  / Turbo Frame（コンテンツ）
  = turbo_frame_tag "settings_content", data: { tabs_target: "content" } do
    .tab-content.py-6
      - case @tab
      - when 'profile'
        = render "settings/profile"
      - when 'security'
        = render "settings/security"
      - when 'notifications'
        = render "settings/notifications"
```

**メリット:**
- クライアント側で即座にアクティブ状態が変わる
- ローディングインジケーターなどの追加機能を実装可能
- Turbo Frameの読み込みイベントをリッスンできる

**デメリット:**
- JavaScriptコードが必要（約60行）
- クラス名をJavaScriptとHTMLの両方で管理（保守性が若干低下）

</details>

---

### Q3-3: それぞれのメリット・デメリットを説明してください

<details>
<summary>ヒント</summary>

- JavaScript量
- サーバーリクエスト
- UX（ユーザー体験）
- 保守性

</details>

<details>
<summary>回答例</summary>

### サーバーサイド管理パターン（パターンA）

**メリット:**
1. **JavaScriptが全く不要**
   - HTML属性のみ（約5行）
   - 学習コストが低い
   - メンテナンスが容易

2. **サーバーサイドレンダリング**
   - SEOに有利
   - 初期表示が早い（サーバーで完成したHTMLを返す）

3. **ブラウザバックが正常に動作**
   - URLパラメータ（`?tab=profile`）で状態を管理
   - ブラウザ履歴に記録される

4. **シンプルな設計**
   - アクティブ状態をサーバー側（`@tab`変数）で管理
   - ビューで`@tab`に基づいてスタイルを設定

**デメリット:**
1. **サーバーへのリクエストが発生**
   - タブクリック時にわずかな遅延（ネットワーク遅延）
   - ただし、Turbo Framesのキャッシュで高速化

2. **クライアント側の複雑な状態管理には不向き**
   - ローディングインジケーターなどの追加機能が難しい

---

### Stimulus管理パターン（パターンB）

**メリット:**
1. **即座にアクティブ状態が変わる**
   - クライアント側でクラス切り替え（サーバーレスポンス待ちなし）
   - よりスムーズなUX

2. **追加機能を実装可能**
   - ローディングインジケーター
   - アニメーション効果
   - Turbo Frameの読み込みイベントをリッスン

3. **柔軟な制御**
   - JavaScriptでDOM操作が可能
   - 複雑な状態管理にも対応

**デメリット:**
1. **JavaScriptコードが必要**
   - 約60行のStimulusコントローラー
   - 学習コストが若干高い

2. **クラス名の二重管理**
   - JavaScriptとHTMLの両方でクラス名を管理
   - タブのスタイルを変更する際、両方を修正する必要がある
   - 保守性が若干低下

3. **デバッグがやや困難**
   - クライアント側のJavaScriptとサーバー側のRailsの両方をデバッグ
   - ブラウザの開発者ツールでのデバッグが必要

---

### 使い分け基準

**サーバーサイド管理を選ぶべき場合:**
- タブのアクティブ状態をサーバーで管理できる
- JavaScriptを最小限に抑えたい
- SEOが重要（サーバーサイドレンダリング）
- シンプルなタブ切り替え

**Stimulus管理を選ぶべき場合:**
- ローディングインジケーターなどの追加機能が必要
- より動的なUI（即座にアクティブ状態を変えたい）
- Turbo Frameの読み込みイベントをリッスンしたい
- クライアント側で複雑な状態管理が必要

</details>

---

## 質問4: 設計判断（上級）🔴

以下のシナリオに対して、どのパターンを選ぶべきか判断してください。

### Q4-1: どのような場合にサーバーサイド管理を選ぶべきですか？

<details>
<summary>ヒント</summary>

- タブの数
- SEOの重要性
- JavaScriptの複雑さ
- 保守性

</details>

<details>
<summary>回答例</summary>

**サーバーサイド管理（パターンA）を選ぶべき場合:**

1. **シンプルなタブ切り替え**
   - タブが3〜5個程度
   - タブコンテンツがサーバーから取得したデータ
   - 特別なアニメーションやローディング表示が不要

2. **SEOが重要**
   - 検索エンジンにタブコンテンツをインデックスさせたい
   - URLパラメータで各タブに直接アクセス可能にしたい
   - サーバーサイドレンダリングで初期表示を高速化

3. **JavaScriptを最小限に抑えたい**
   - フロントエンド開発者がいない小規模チーム
   - Rails中心の開発（JavaScript知識が少ない）
   - コードの保守性を優先

4. **ブラウザバックが重要**
   - ユーザーがタブを切り替えた後、ブラウザバックで前のタブに戻りたい
   - URLで状態を管理したい（`?tab=profile`）

**具体例:**
- 期間フィルタータブ（全期間・1ヶ月・1週間）
- カテゴリー別一覧ページ（基礎・英語・日本語・プログラミング）
- ページネーション付きの検索結果
- ユーザー設定ページ（プロフィール・セキュリティ・通知）

</details>

---

### Q4-2: どのような場合にStimulus管理を選ぶべきですか？

<details>
<summary>ヒント</summary>

- ローディング表示
- アニメーション
- リアルタイム性
- イベントリスニング

</details>

<details>
<summary>回答例</summary>

**Stimulus管理（パターンB）を選ぶべき場合:**

1. **ローディングインジケーターが必要**
   - タブコンテンツの読み込みに時間がかかる
   - ユーザーに「読み込み中」を明示したい
   - Turbo Frameの読み込みイベントをリッスンする必要がある

2. **より動的なUI**
   - タブクリック時に即座にアクティブ状態を変えたい（サーバーレスポンス待ちなし）
   - アニメーション効果を追加したい（フェードイン/フェードアウトなど）
   - クライアント側で複雑な状態管理が必要

3. **イベントリスニング**
   - `turbo:frame-load`、`turbo:before-frame-render`などのイベントを処理したい
   - タブ切り替え時に追加のアクション（アナリティクス送信など）を実行したい

4. **複雑なインタラクション**
   - ドラッグ&ドロップ対応の一覧
   - リアルタイムバリデーション
   - 複数のDOM要素を同時に更新

**具体例:**
- カテゴリータブ（ローディング表示付き）
- ダッシュボード（複数のウィジェットを動的に切り替え）
- リアルタイムチャット（タブごとにメッセージ一覧）
- 複雑なフォーム（タブごとに入力項目、バリデーション）

</details>

---

### Q4-3: Turbo StreamsとTurbo Framesの使い分け基準は何ですか？

<details>
<summary>ヒント</summary>

- ページ遷移 vs 部分更新
- フォーム送信
- リアルタイム性
- 複数要素の更新

</details>

<details>
<summary>回答例</summary>

### Turbo Frames（ページの一部を置き換え）

**使うべき場合:**
- **ページ遷移的な部分更新**
  - タブ切り替え
  - ページネーション
  - モーダル表示
  - サイドバーの切り替え

- **コンテンツ全体を置き換え**
  - フレーム内の全コンテンツを新しいHTMLに置き換える
  - 1つのフレームに対して1つのアクション

**特徴:**
- リンククリックやフォーム送信で自動的にフレームを更新
- URLパラメータで状態を管理（ブラウザバック対応）
- サーバーサイドレンダリング

**例:**
```slim
= turbo_frame_tag "settings_content" do
  / タブナビゲーション + コンテンツ
```

---

### Turbo Streams（複数のDOM要素を動的に更新）

**使うべき場合:**
- **フォーム送信後の部分更新**
  - 成功メッセージの表示
  - フォームのリセット
  - 一覧への項目追加

- **リアルタイム感のある操作**
  - いいねボタン、フォローボタンのトグル
  - 通知の既読/未読切り替え
  - チェックボックスのワンクリック更新

- **複数のDOM要素を同時に更新**
  - カウンターの更新 + メッセージ表示
  - 削除ボタン → 要素削除 + カウント減少
  - フォーム送信 → 一覧に追加 + フォームリセット

**特徴:**
- サーバーから複数の`turbo_stream`アクションを送信可能
- ページリロード不要
- WebSocketと組み合わせてリアルタイム更新も可能

**アクションの種類:**
- `turbo_stream.replace`: 要素ごと置き換え
- `turbo_stream.update`: 要素の内側だけ更新
- `turbo_stream.append`: 要素を追加
- `turbo_stream.prepend`: 要素を先頭に追加
- `turbo_stream.remove`: 要素を削除

**例:**
```ruby
# コントローラー
def toggle_notified
  @allowed_email.update!(notified_at: Time.current)
  respond_to do |format|
    format.turbo_stream
  end
end
```

```slim
/ app/views/admin/allowed_emails/toggle_notified.turbo_stream.slim
= turbo_stream.replace "notified_status_#{@allowed_email.id}" do
  = render "notified_button", allowed_email: @allowed_email
```

---

### 使い分けまとめ

| 基準 | Turbo Frames | Turbo Streams |
|------|-------------|--------------|
| **用途** | ページ遷移的な部分更新 | フォーム送信後の部分更新 |
| **更新範囲** | 1つのフレーム全体 | 複数のDOM要素を個別に |
| **トリガー** | リンククリック、フォーム送信 | サーバーからの明示的な指示 |
| **ブラウザバック** | 対応（URLパラメータ） | 非対応（状態はURLに反映されない） |
| **リアルタイム性** | 低（ページ遷移的） | 高（即座に反映） |
| **実装の複雑さ** | 簡単 | やや複雑（Turbo Streamテンプレート） |

</details>

---

## 🎓 追加課題（オプション）

以下の課題に挑戦してみましょう：

1. **外部ライブラリとの統合**
   - Google認証ボタンをTurboに対応させるStimulusコントローラーを作成してください
   - 重複初期化の防止を実装してください

2. **Turbo Streamsによるいいねボタン**
   - 記事に対するいいねボタンをTurbo Streamsで実装してください
   - いいねカウントも同時に更新してください

3. **ページネーション付きタブ**
   - タブ切り替え + ページネーションを実装してください
   - URLパラメータで`tab`と`page`の両方を管理してください

---

## 📚 参考資料

- [Turbo公式ドキュメント](https://turbo.hotwired.dev/)
- [Stimulus公式ドキュメント](https://stimulus.hotwired.dev/)
- [Hotwire: HTML Over The Wire](https://hotwired.dev/)
- Flexitype Day 9日報: Turbo/Google認証の互換性修正
- Flexitype Day 19日報: Googleログイン機能の緊急バグ修正
- Flexitype Day 22日報: トップページのタブ化実装
- Flexitype Day 24日報: 練習履歴の期間フィルター実装
- Flexitype Day 28日報: 連絡済みフラグ機能追加

---

## ✅ 評価基準

各質問の回答を以下の基準で自己評価してください：

- **🟢 初級（Q1）**: jQueryの問題点を理解し、Hotwireの基本概念を説明できる
- **🟡 中級（Q2-Q3）**: Turbo Framesの実装ができ、2つのパターンを使い分けられる
- **🔴 上級（Q4）**: 適切な設計判断ができ、Turbo StreamsとTurbo Framesを使い分けられる

すべての質問に正確に答えられたら、Hotwire（Turbo Frames + Stimulus）をマスターしたと言えるでしょう！
