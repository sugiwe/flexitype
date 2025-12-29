# 共通パーシャル - DRY原則によるビューの重複削減

## 🎯 学習目標

この教材を学ぶことで以下ができるようになります：
- [ ] ビューの重複を見つけられる
- [ ] パーシャル（部分テンプレート）を作成できる
- [ ] `local_assigns`を使った柔軟なパーシャルを書ける
- [ ] 大幅なコード削減（この例では89行削減）を実現できる

## 📚 前提知識

- Slimテンプレートエンジンの基本
- `render`メソッドの使い方
- Railsのビューヘルパーの基本

## 📖 本編

### 概要

Flexitypeプロジェクトでは、Day 29に「管理者向け練習履歴一覧ページ」を作成しました。しかし、既存の「管理者ダッシュボード」と「個人練習履歴ページ」にも同じようなテーブルが存在し、**コードが3箇所で重複**してしまいました。

**問題:**
- 管理者ダッシュボード（`admin/dashboard/index.html.slim`）
- 管理者練習履歴一覧（`admin/lesson_records/index.html.slim`）
- 個人練習履歴（`my/lesson_records/index.html.slim`）

これら3つのページで、練習履歴テーブルのコードがほぼ同じでした。

**解決策:**
共通パーシャル `shared/_lesson_records_table.html.slim` を作成し、3箇所すべてで再利用することで、**89行のコード削減**を達成しました。

### 実装前（アンチパターン）

#### 1. `app/views/admin/dashboard/index.html.slim`（一部抜粋）

```slim
/ 最近の練習履歴（最新10件）
.bg-white.dark:bg-gray-800.rounded-lg.shadow-md.p-6
  h3.text-xl.font-semibold.text-gray-800.dark:text-white 最近の練習

  / テーブル（PC版）
  .hidden.md:block
    table.w-full
      thead
        tr.border-b.border-gray-200.dark:border-gray-700
          th.px-6.py-3.text-left 日時
          th.px-6.py-3.text-left ユーザー
          th.px-6.py-3.text-left レッスン
          th.px-6.py-3.text-center 単語数
          th.px-6.py-3.text-center 正答率
          th.px-6.py-3.text-center 所要時間
          th.px-6.py-3.text-center ミス数
      tbody.divide-y.divide-gray-200.dark:divide-gray-700
        - @recent_records.each do |record|
          tr.hover:bg-gray-50.dark:hover:bg-gray-700
            td.px-6.py-4 = l(record.completed_at, format: :short)
            td.px-6.py-4
              .flex.items-center
                - if record.user.icon_url.present?
                  img.w-8.h-8.rounded-full src=record.user.icon_url
                - else
                  .w-8.h-8.rounded-full.bg-gray-300
                    span = record.user.name[0].upcase
                = link_to admin_user_path(record.user) do
                  = record.user.name
            td.px-6.py-4 = record.lesson_name
            td.px-6.py-4.text-center = record.word_count
            td.px-6.py-4.text-center = "#{record.accuracy}%"
            td.px-6.py-4.text-center = "#{record.duration_seconds}秒"
            td.px-6.py-4.text-center = record.mistake_count

  / カード（モバイル版）
  .md:hidden.divide-y
    - @recent_records.each do |record|
      .p-4
        / ... 同じような内容が続く ...
```

**約100行のコード**（PC版とモバイル版の両方）

#### 2. `app/views/my/lesson_records/index.html.slim`（一部抜粋）

```slim
/ 履歴一覧
.bg-white.dark:bg-gray-800.rounded-lg.shadow
  / テーブル（PC版）
  .hidden.md:block
    table.w-full
      thead
        tr.border-b.border-gray-200.dark:border-gray-700
          th.px-6.py-3.text-left 日時
          th.px-6.py-3.text-left レッスン
          th.px-6.py-3.text-center 単語数
          th.px-6.py-3.text-center 正答率
          th.px-6.py-3.text-center 所要時間
          th.px-6.py-3.text-center ミス数
      tbody.divide-y.divide-gray-200.dark:divide-gray-700
        - @lesson_records.each do |record|
          tr.hover:bg-gray-50.dark:hover:bg-gray-700
            td.px-6.py-4 = l(record.completed_at, format: :short)
            td.px-6.py-4 = record.lesson_name
            td.px-6.py-4.text-center = record.word_count
            td.px-6.py-4.text-center = "#{record.accuracy}%"
            td.px-6.py-4.text-center = "#{record.duration_seconds}秒"
            td.px-6.py-4.text-center = record.mistake_count

  / カード（モバイル版）
  .md:hidden.divide-y
    - @lesson_records.each do |record|
      .p-4
        / ... 同じような内容が続く ...

  / ページネーション
  - if @lesson_records.present?
    .p-4.border-t
      = paginate @lesson_records
```

**約80行のコード**（PC版、モバイル版、ページネーション）

**問題点:**
1. **コードの重複**: 3箇所でほぼ同じテーブルを書いている
2. **保守性の低下**: デザイン変更時に3箇所修正する必要がある
3. **一貫性の欠如**: 片方だけ修正して統一性が失われるリスク
4. **コードベースの肥大化**: 約200行の重複コード

### 実装後（ベストプラクティス）

#### 1. 共通パーシャル: `app/views/shared/_lesson_records_table.html.slim`

```slim
/ 練習履歴テーブル（PC版・モバイル版対応、共通パーシャル）
/ 使い方: = render "shared/lesson_records_table", lesson_records: @lesson_records, show_pagination: true, show_user: false

- if lesson_records.any?
  / テーブル（PC）
  .hidden.md:block
    table.w-full
      thead
        tr.border-b.border-gray-200.dark:border-gray-700
          th.px-6.py-3.text-left.text-xs.font-medium.text-gray-500.dark:text-gray-400.uppercase.tracking-wider 日時
          - if local_assigns[:show_user]
            th.px-6.py-3.text-left.text-xs.font-medium.text-gray-500.dark:text-gray-400.uppercase.tracking-wider ユーザー
          th.px-6.py-3.text-left.text-xs.font-medium.text-gray-500.dark:text-gray-400.uppercase.tracking-wider レッスン
          th.px-6.py-3.text-center.text-xs.font-medium.text-gray-500.dark:text-gray-400.uppercase.tracking-wider 単語数
          th.px-6.py-3.text-center.text-xs.font-medium.text-gray-500.dark:text-gray-400.uppercase.tracking-wider 正答率
          th.px-6.py-3.text-center.text-xs.font-medium.text-gray-500.dark:text-gray-400.uppercase.tracking-wider WPM
          th.px-6.py-3.text-center.text-xs.font-medium.text-gray-500.dark:text-gray-400.uppercase.tracking-wider グレード
          th.px-6.py-3.text-center.text-xs.font-medium.text-gray-500.dark:text-gray-400.uppercase.tracking-wider 所要時間
          th.px-6.py-3.text-center.text-xs.font-medium.text-gray-500.dark:text-gray-400.uppercase.tracking-wider ミス数
      tbody.divide-y.divide-y-gray-200.dark:divide-gray-700
        - lesson_records.each do |record|
          tr.hover:bg-gray-50.dark:hover:bg-gray-700.transition-colors
            td.px-6.py-4.whitespace-nowrap.text-sm.text-gray-900.dark:text-gray-100
              = l(record.completed_at, format: :short)
            - if local_assigns[:show_user]
              td.px-6.py-4
                .flex.items-center
                  - if record.user.icon_url.present?
                    img.w-8.h-8.rounded-full.mr-3 src=record.user.icon_url alt=record.user.name
                  - else
                    .w-8.h-8.rounded-full.bg-gray-300.dark:bg-gray-600.flex.items-center.justify-center.mr-3
                      span.text-sm.font-medium.text-gray-600.dark:text-gray-300 = record.user.name[0].upcase
                  - if defined?(admin_user_path)
                    = link_to admin_user_path(record.user), class: "text-sm.font-medium.text-blue-600.dark:text-blue-400.hover:underline" do
                      = record.user.name
                  - else
                    span.text-sm.font-medium.text-gray-900.dark:text-gray-100 = record.user.name
            td.px-6.py-4.text-sm
              .font-medium.text-gray-900.dark:text-gray-100
                - if record.lesson_name.present?
                  = record.lesson_name
                - else
                  span.text-gray-400 不明
            td.px-6.py-4.whitespace-nowrap.text-center.text-sm.text-gray-900.dark:text-gray-100
              = record.word_count
            td.px-6.py-4.whitespace-nowrap.text-center.text-sm
              - if record.accuracy && record.accuracy >= 90
                span.text-green-600.dark:text-green-400.font-semibold = "#{record.accuracy}%"
              - elsif record.accuracy && record.accuracy >= 70
                span.text-yellow-600.dark:text-yellow-400.font-semibold = "#{record.accuracy}%"
              - else
                span.text-red-600.dark:text-red-400.font-semibold = "#{record.accuracy}%"
            td.px-6.py-4.whitespace-nowrap.text-center.text-sm.text-gray-900.dark:text-gray-100
              - if record.wpm
                = record.wpm
              - else
                | -
            td.px-6.py-4.whitespace-nowrap.text-center.text-sm
              = render "shared/grade_badge", grade: record.grade
            td.px-6.py-4.whitespace-nowrap.text-center.text-sm.text-gray-900.dark:text-gray-100
              - minutes = record.duration_seconds / 60
              - seconds = record.duration_seconds % 60
              = "#{minutes}分#{seconds}秒"
            td.px-6.py-4.whitespace-nowrap.text-center.text-sm.text-gray-900.dark:text-gray-100
              = record.mistake_count

  / カード（モバイル）
  .md:hidden.divide-y.divide-gray-200.dark:divide-gray-700
    - lesson_records.each do |record|
      .p-4
        - if local_assigns[:show_user]
          .flex.items-center.mb-3
            / ... ユーザー情報表示 ...
        / ... レッスン情報、統計情報の表示 ...

  / ページネーション
  - if local_assigns[:show_pagination] && lesson_records.respond_to?(:total_pages)
    .p-4.border-t.border-gray-200.dark:border-gray-700
      = paginate lesson_records, param_name: (local_assigns[:pagination_params] || {})

- else
  / 履歴なし
  .p-12.text-center
    svg.mx-auto.h-12.w-12.text-gray-400.dark:text-gray-600 fill="none" stroke="currentColor" viewBox="0 0 24 24"
      path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
    p.mt-4.text-gray-500.dark:text-gray-400 練習履歴がありません
    - if local_assigns[:show_start_link]
      p.text-sm.text-gray-400.dark:text-gray-500.mt-2 タイピング練習を完了すると、ここに履歴が表示されます
      .mt-6
        = link_to "練習を始める", root_path, class: "inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700"
```

**約127行**（PC版、モバイル版、ページネーション、空状態すべて含む）

#### 2. 改善後: `app/views/admin/dashboard/index.html.slim`

```slim
/ 最近の練習履歴（最新10件）
.bg-white.dark:bg-gray-800.rounded-lg.shadow-md.p-6
  .flex.items-center.justify-between.mb-4
    h3.text-xl.font-semibold.text-gray-800.dark:text-white 最近の練習
    = link_to admin_lesson_records_path, class: "text-sm text-blue-600 dark:text-blue-400 hover:underline" do
      | すべて見る →

  / 共通パーシャル使用（ユーザー列表示、ページネーションなし）
  = render "shared/lesson_records_table", lesson_records: @recent_records, show_user: true
```

**11行**（元の約100行から**89行削減**）

#### 3. 改善後: `app/views/my/lesson_records/index.html.slim`

```slim
/ 履歴一覧
.bg-white.dark:bg-gray-800.rounded-lg.shadow.transition-colors
  = render "shared/lesson_records_table", lesson_records: @lesson_records, show_pagination: true, pagination_params: { period: @period }, show_start_link: true
```

**2行**（元の約80行から**78行削減**）

#### 4. 改善後: `app/views/admin/lesson_records/index.html.slim`（新規）

```slim
/ 練習履歴テーブル（共通パーシャル使用、ユーザー列表示）
.bg-white.dark:bg-gray-800.rounded-lg.shadow-md.overflow-hidden
  = render "shared/lesson_records_table", lesson_records: @lesson_records, show_pagination: true, show_user: true
```

**2行**（パーシャルがなければ約80行必要だった）

### 解説

#### `local_assigns`の活用

**`local_assigns`とは？**

`local_assigns`は、パーシャルに渡されたローカル変数を格納するハッシュです。

```ruby
local_assigns[:show_user]
# パーシャル呼び出し時に show_user が渡されていれば true/false、渡されていなければ nil
```

**メリット:**
1. **オプショナルなパラメータ**: 渡されなくてもエラーにならない
2. **柔軟な条件分岐**: `if local_assigns[:show_user]` で存在チェック
3. **デフォルト値の設定**: `local_assigns[:show_user] || false` のように書ける

**使用例:**

```slim
/ ユーザー列は管理者ページでのみ表示
- if local_assigns[:show_user]
  th.px-6.py-3.text-left ユーザー
```

#### パーシャルの呼び出しパターン

**パターン1: 管理者ダッシュボード（ユーザー列あり、ページネーションなし）**

```slim
= render "shared/lesson_records_table", lesson_records: @recent_records, show_user: true
```

**パターン2: 個人練習履歴（ユーザー列なし、ページネーションあり）**

```slim
= render "shared/lesson_records_table", lesson_records: @lesson_records, show_pagination: true, show_start_link: true
```

**パターン3: 管理者一覧（ユーザー列あり、ページネーションあり）**

```slim
= render "shared/lesson_records_table", lesson_records: @lesson_records, show_pagination: true, show_user: true
```

#### コード削減の効果

**削減行数:**
- 管理者ダッシュボード: 89行削減
- 個人練習履歴: 78行削減（改善前のコードは書かなかったが、同等のコードが必要だった）
- 管理者一覧: 78行削減（新規ページだが、パーシャルがなければ同等のコードが必要）

**合計**: 約**245行の削減**（共通パーシャル127行を考慮すると、純削減は約118行）

**メリット:**
1. **保守性の向上**: デザイン変更は1箇所のみ修正
2. **一貫性の保証**: すべてのページで同じUIを使用
3. **新規ページの追加が容易**: 2行で練習履歴テーブルを追加できる
4. **バグの減少**: 修正漏れがなくなる

#### 条件分岐のパターン

**1. `if local_assigns[:key]` - 渡されたかチェック**

```slim
- if local_assigns[:show_user]
  / show_user が true または false で渡された場合のみ実行
```

**2. `unless local_assigns[:key]` - 渡されていない場合**

```slim
- unless local_assigns[:show_user]
  / show_user が渡されていない、または false の場合実行
```

**3. `if defined?(helper_method)` - ヘルパーメソッドの存在チェック**

```slim
- if defined?(admin_user_path)
  = link_to admin_user_path(record.user) do
    = record.user.name
- else
  span = record.user.name
```

管理者ページでは `admin_user_path` が使えるが、個人ページでは使えないため、この条件分岐が必要。

### 実際の変更内容（Day 29のコミット）

この改善は以下のPRで実装されました：
- **PR**: #101
- **日報**: Day 29（2025-12-29）
- **変更ファイル数**: 4ファイル
  - 新規: `app/views/shared/_lesson_records_table.html.slim`
  - 変更: `app/views/admin/dashboard/index.html.slim`
  - 変更: `app/views/my/lesson_records/index.html.slim`
  - 新規: `app/views/admin/lesson_records/index.html.slim`

**コード削減率**: 約**53%削減**（重複コード245行 → 共通パーシャル127行）

## 💡 まとめ

**共通パーシャルの重要ポイント:**

1. **DRY原則**: ビューの重複を避ける
2. **`local_assigns`**: オプショナルなパラメータを柔軟に扱う
3. **配置場所**: `app/views/shared/` ディレクトリ（複数のコントローラーで共有）
4. **命名規則**: アンダースコアで始まる（`_lesson_records_table.html.slim`）
5. **使用方法**: `render "shared/lesson_records_table", ...`

**実践のポイント:**

- パーシャルの先頭にコメントで使い方を書く
- `local_assigns`で条件分岐を柔軟に
- PC版とモバイル版を1つのパーシャルにまとめる
- 空状態（データがない場合）のUIも含める
- オプションが多くなりすぎたら分割を検討

**共通パーシャル化すべきケース:**

- ✅ 3箇所以上で同じUIが使われている
- ✅ デザイン変更の可能性が高い
- ✅ 一貫性を保ちたい重要なUI

**共通パーシャル化すべきでないケース:**

- ❌ 2箇所以下でしか使われていない（オーバーエンジニアリング）
- ❌ UIが微妙に異なり、条件分岐が複雑になる
- ❌ 特定のページでのみ使用する特殊なUI

## 🔗 関連教材

- [Concernパターン](01_concerns_pattern.md) - コントローラーの共通化
- [リファクタリングパターン](../03_advanced/01_refactoring_patterns.md) - その他の改善パターン

## 📝 演習問題

### 問題1: 基礎理解

以下のコードで、`show_details`オプションを追加して、詳細情報を表示/非表示できるようにしてください。

```slim
/ app/views/shared/_user_card.html.slim
.user-card
  .name = user.name
  .email = user.email
  / ここに show_details が true の場合のみ詳細情報を表示
```

<details>
<summary>解答例を表示</summary>

```slim
/ app/views/shared/_user_card.html.slim
.user-card
  .name = user.name
  .email = user.email
  - if local_assigns[:show_details]
    .details
      .created-at = "登録日: #{l(user.created_at, format: :short)}"
      .last-sign-in = "最終ログイン: #{l(user.current_sign_in_at, format: :short)}"
```

**使用例:**

```slim
/ 詳細情報を表示
= render "shared/user_card", user: @user, show_details: true

/ 詳細情報を非表示
= render "shared/user_card", user: @user
```

</details>

### 問題2: 応用

あなたのプロジェクトで、以下の3つのページに同じようなユーザーリストが表示されています。
これを共通パーシャル化する場合、どのような設計にしますか？

- 管理者ユーザー一覧: アイコン、名前、メールアドレス、**管理者バッジ**、アクションボタン
- チームメンバー一覧: アイコン、名前、**役割**、最終ログイン日時
- 検索結果: アイコン、名前、メールアドレス

**考えるべきポイント:**
1. パーシャルのファイル名
2. 必要なオプション
3. 条件分岐のロジック

<details>
<summary>解答例を表示</summary>

**1. パーシャル名:**

`app/views/shared/_users_list.html.slim`

**2. 必要なオプション:**

```ruby
users:              # ユーザーのコレクション（必須）
show_admin_badge:   # 管理者バッジを表示（オプション、デフォルト: false）
show_role:          # 役割を表示（オプション、デフォルト: false）
show_last_sign_in:  # 最終ログイン日時を表示（オプション、デフォルト: false）
show_actions:       # アクションボタンを表示（オプション、デフォルト: false）
```

**3. 実装例:**

```slim
/ app/views/shared/_users_list.html.slim
.users-list
  - users.each do |user|
    .user-item
      / 共通部分: アイコンと名前
      .flex.items-center
        - if user.icon_url.present?
          img.w-10.h-10.rounded-full src=user.icon_url
        .ml-3
          .name = user.name
          .email = user.email

      / オプション: 管理者バッジ
      - if local_assigns[:show_admin_badge] && user.admin?
        span.badge.admin 管理者

      / オプション: 役割
      - if local_assigns[:show_role]
        .role = user.role

      / オプション: 最終ログイン日時
      - if local_assigns[:show_last_sign_in]
        .last-sign-in = l(user.current_sign_in_at, format: :short)

      / オプション: アクションボタン
      - if local_assigns[:show_actions]
        .actions
          = link_to "編集", edit_admin_user_path(user)
          = link_to "削除", admin_user_path(user), method: :delete
```

**使用例:**

```slim
/ 管理者ユーザー一覧
= render "shared/users_list", users: @users, show_admin_badge: true, show_actions: true

/ チームメンバー一覧
= render "shared/users_list", users: @team_members, show_role: true, show_last_sign_in: true

/ 検索結果
= render "shared/users_list", users: @search_results
```

</details>

---

**作成日**: 2025-12-29
**難易度**: 🟡 中級
**学習時間の目安**: 1〜2時間
**関連Day**: Day 29
