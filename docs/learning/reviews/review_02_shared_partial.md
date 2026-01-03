# Review Test #02: 共通パーシャル化によるDRY原則の実践

**難易度**: 🟡 中級
**推定時間**: 30分〜1時間
**学習トピック**: [共通パーシャル](../topics/02_intermediate/02_shared_partials.md)

---

## 前提条件

あなたはFlexitypeプロジェクトのコードレビュアーです。
以下のPRがレビュー待ちになっています。

## PR概要

- **タイトル**: 管理者向け練習履歴一覧ページ作成
- **変更ファイル数**: 3ファイル
- **目的**: 管理者が全ユーザーの練習履歴を一覧で確認できるようにする

## 変更内容

### 1. `app/views/admin/dashboard/index.html.slim` (既存)

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
          th.px-6.py-3.text-center WPM
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
            td.px-6.py-4.text-center = record.wpm || "-"
            td.px-6.py-4.text-center = "#{record.duration_seconds}秒"
            td.px-6.py-4.text-center = record.mistake_count

  / カード（モバイル版）
  .md:hidden.divide-y
    - @recent_records.each do |record|
      .p-4
        .flex.items-center.mb-3
          - if record.user.icon_url.present?
            img.w-10.h-10.rounded-full src=record.user.icon_url
          - else
            .w-10.h-10.rounded-full.bg-gray-300
              span = record.user.name[0].upcase
          div
            = link_to admin_user_path(record.user) do
              = record.user.name
            .text-xs.text-gray-500 = l(record.completed_at, format: :short)
        / ... 省略 ...
```

**約100行のコード**

### 2. `app/views/admin/lesson_records/index.html.slim` (新規作成)

```slim
/ 管理者 - 練習履歴一覧

.mb-6
  h2.text-3xl.font-bold 練習履歴一覧
  p.text-sm.text-gray-600.mt-2 全ユーザーの練習履歴を確認できます

/ 戻るリンク
.mb-6
  = link_to admin_root_path do
    | ← ダッシュボードに戻る

/ 練習履歴テーブル
.bg-white.dark:bg-gray-800.rounded-lg.shadow-md.overflow-hidden
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
          th.px-6.py-3.text-center WPM
          th.px-6.py-3.text-center 所要時間
          th.px-6.py-3.text-center ミス数
      tbody.divide-y.divide-gray-200.dark:divide-gray-700
        - @lesson_records.each do |record|
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
            td.px-6.py-4.text-center = record.wpm || "-"
            td.px-6.py-4.text-center = "#{record.duration_seconds}秒"
            td.px-6.py-4.text-center = record.mistake_count

  / カード（モバイル版）
  .md:hidden.divide-y
    - @lesson_records.each do |record|
      .p-4
        / ... 省略（dashboard と同じ内容）...

  / ページネーション
  - if @lesson_records.present?
    .p-4.border-t
      = paginate @lesson_records
```

**約80行のコード**

### 3. `app/views/my/lesson_records/index.html.slim` (既存、参考)

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
          th.px-6.py-3.text-center WPM
          th.px-6.py-3.text-center 所要時間
          th.px-6.py-3.text-center ミス数
      tbody.divide-y.divide-gray-200.dark:divide-gray-700
        - @lesson_records.each do |record|
          tr.hover:bg-gray-50.dark:hover:bg-gray-700
            td.px-6.py-4 = l(record.completed_at, format: :short)
            td.px-6.py-4 = record.lesson_name
            td.px-6.py-4.text-center = record.word_count
            td.px-6.py-4.text-center = "#{record.accuracy}%"
            td.px-6.py-4.text-center = record.wpm || "-"
            td.px-6.py-4.text-center = "#{record.duration_seconds}秒"
            td.px-6.py-4.text-center = record.mistake_count

  / カード（モバイル版）
  .md:hidden.divide-y
    - @lesson_records.each do |record|
      .p-4
        / ... 省略 ...

  / ページネーション
  - if @lesson_records.present?
    .p-4.border-t
      = paginate @lesson_records
```

**約80行のコード**（このファイルは今回のPRに含まれていないが、参考情報として提示）

---

## レビュー課題

### Q1. コードの重複（初級）🟢

このPRには明らかなコードの重複があります。

1. どこが重複していますか？具体的に2箇所以上指摘してください。
2. このまま放置すると、どのような問題が発生しますか？（3つ以上）
3. 概算で何行くらい重複していますか？

**回答時間の目安**: 5分

<details>
<summary>解答を表示</summary>

### A1. コードの重複

**1. 重複箇所:**

**① テーブルのヘッダー部分（完全に同じ）**
```slim
thead
  tr.border-b.border-gray-200.dark:border-gray-700
    th.px-6.py-3.text-left 日時
    th.px-6.py-3.text-left ユーザー
    th.px-6.py-3.text-left レッスン
    / ...
```
- `admin/dashboard/index.html.slim`
- `admin/lesson_records/index.html.slim`

**② テーブルのボディ部分（完全に同じ）**
```slim
tbody.divide-y
  - @recent_records.each do |record|
    tr.hover:bg-gray-50
      td.px-6.py-4 = l(record.completed_at, format: :short)
      td.px-6.py-4
        .flex.items-center
          / ユーザー情報の表示...
```

**③ モバイル版カード（完全に同じ）**
```slim
.md:hidden.divide-y
  - @recent_records.each do |record|
    .p-4
      / カード表示...
```

**④ ページネーション部分（`my/lesson_records` と `admin/lesson_records` で同じ）**

**2. 問題点:**

1. **保守性の低下**: デザイン変更時に3箇所（dashboard、admin一覧、個人履歴）すべて修正する必要がある
2. **一貫性の欠如リスク**: 1箇所だけ修正を忘れると、見た目が異なってしまう
3. **バグの増加**: 修正漏れによるバグが発生しやすい
4. **コードベースの肥大化**: 約180〜200行の重複コードがプロジェクトに存在
5. **新規ページ追加のコスト**: 新しいページで練習履歴を表示する場合、また同じコードをコピーする必要がある

**3. 重複行数:**

- テーブル（PC版）: 約50行 × 2箇所 = 100行
- カード（モバイル版）: 約30行 × 2箇所 = 60行
- **合計**: 約**160〜180行の重複**

さらに、`my/lesson_records/index.html.slim`も含めると、3箇所で約**200〜250行の重複**が存在。

</details>

---

### Q2. 改善方法（中級）🟡

この重複を解消するために、どのようなアプローチを取りますか？

1. 使用するRailsの機能名を答えてください
2. ファイル名とディレクトリ構成を示してください
3. どのようなオプション（パラメータ）が必要ですか？

**回答時間の目安**: 10分

<details>
<summary>解答を表示</summary>

### A2. 改善方法

**1. 使用するRailsの機能:**

**パーシャル（Partial Template）**

**2. ファイル名とディレクトリ構成:**

```
app/
└── views/
    └── shared/
        └── _lesson_records_table.html.slim  # ← 新規作成
```

**命名規則:**
- アンダースコアで始まる（`_lesson_records_table.html.slim`）
- `shared/`ディレクトリに配置（複数のコントローラーで共有）

**3. 必要なオプション:**

```ruby
lesson_records:     # 表示する練習記録のコレクション（必須）
show_user:          # ユーザー列を表示するか（オプション、デフォルト: false）
show_pagination:    # ページネーションを表示するか（オプション、デフォルト: false）
pagination_params:  # ページネーションのパラメータ（オプション）
show_start_link:    # 「練習を始める」リンクを表示するか（オプション、デフォルト: false）
```

**理由:**

- `lesson_records`: データのコレクション（必須）
- `show_user`: 管理者ページではユーザー列が必要だが、個人ページでは不要
- `show_pagination`: 一覧ページではページネーションが必要だが、ダッシュボードでは不要（10件固定）
- `pagination_params`: 期間フィルター（`period=week`など）をページネーションに引き継ぐため
- `show_start_link`: 練習履歴がない場合の「練習を始める」リンク（個人ページのみ）

</details>

---

### Q3. 具体的な実装（中級〜上級）🟡🔴

パーシャルを作成し、既存のビューを書き換えてください。

1. `app/views/shared/_lesson_records_table.html.slim` の実装（簡略版で良い）
2. `app/views/admin/dashboard/index.html.slim` の改善後のコード
3. `app/views/admin/lesson_records/index.html.slim` の改善後のコード

**回答時間の目安**: 15分

<details>
<summary>解答を表示</summary>

### A3. 具体的な実装

**1. パーシャル: `app/views/shared/_lesson_records_table.html.slim`**

```slim
/ 練習履歴テーブル（PC版・モバイル版対応、共通パーシャル）
/ 使い方: = render "shared/lesson_records_table", lesson_records: @lesson_records, show_pagination: true, show_user: false

- if lesson_records.any?
  / テーブル（PC）
  .hidden.md:block
    table.w-full
      thead
        tr.border-b.border-gray-200.dark:border-gray-700
          th.px-6.py-3.text-left 日時
          - if local_assigns[:show_user]
            th.px-6.py-3.text-left ユーザー
          th.px-6.py-3.text-left レッスン
          th.px-6.py-3.text-center 単語数
          th.px-6.py-3.text-center 正答率
          th.px-6.py-3.text-center WPM
          th.px-6.py-3.text-center 所要時間
          th.px-6.py-3.text-center ミス数
      tbody.divide-y.divide-gray-200.dark:divide-gray-700
        - lesson_records.each do |record|
          tr.hover:bg-gray-50.dark:hover:bg-gray-700
            td.px-6.py-4 = l(record.completed_at, format: :short)
            - if local_assigns[:show_user]
              td.px-6.py-4
                .flex.items-center
                  - if record.user.icon_url.present?
                    img.w-8.h-8.rounded-full src=record.user.icon_url
                  - else
                    .w-8.h-8.rounded-full.bg-gray-300
                      span = record.user.name[0].upcase
                  - if defined?(admin_user_path)
                    = link_to admin_user_path(record.user) do
                      = record.user.name
                  - else
                    span = record.user.name
            td.px-6.py-4 = record.lesson_name
            td.px-6.py-4.text-center = record.word_count
            td.px-6.py-4.text-center = "#{record.accuracy}%"
            td.px-6.py-4.text-center = record.wpm || "-"
            td.px-6.py-4.text-center = "#{record.duration_seconds}秒"
            td.px-6.py-4.text-center = record.mistake_count

  / カード（モバイル）
  .md:hidden.divide-y
    - lesson_records.each do |record|
      .p-4
        - if local_assigns[:show_user]
          .flex.items-center.mb-3
            / ユーザー情報...
        / レッスン情報...

  / ページネーション
  - if local_assigns[:show_pagination] && lesson_records.respond_to?(:total_pages)
    .p-4.border-t
      = paginate lesson_records

- else
  / 履歴なし
  .p-12.text-center
    p 練習履歴がありません
    - if local_assigns[:show_start_link]
      = link_to "練習を始める", root_path, class: "btn"
```

**ポイント:**
- `if local_assigns[:show_user]` でユーザー列の表示制御
- `if defined?(admin_user_path)` で管理者ページとそれ以外を判別
- `if local_assigns[:show_pagination]` でページネーション制御
- `lesson_records.any?` で空状態の処理

**2. 改善後: `app/views/admin/dashboard/index.html.slim`**

```slim
/ 最近の練習履歴（最新10件）
.bg-white.dark:bg-gray-800.rounded-lg.shadow-md.p-6
  .flex.items-center.justify-between.mb-4
    h3.text-xl.font-semibold.text-gray-800.dark:text-white 最近の練習
    = link_to admin_lesson_records_path, class: "text-sm text-blue-600 hover:underline" do
      | すべて見る →

  / 共通パーシャル使用（ユーザー列表示、ページネーションなし）
  = render "shared/lesson_records_table", lesson_records: @recent_records, show_user: true
```

**削減効果:** 約100行 → **11行**（**89行削減**）

**3. 改善後: `app/views/admin/lesson_records/index.html.slim`**

```slim
/ 管理者 - 練習履歴一覧

.mb-6
  h2.text-3xl.font-bold 練習履歴一覧
  p.text-sm.text-gray-600.mt-2 全ユーザーの練習履歴を確認できます

/ 戻るリンク
.mb-6
  = link_to admin_root_path do
    | ← ダッシュボードに戻る

/ 練習履歴テーブル（共通パーシャル使用、ユーザー列表示）
.bg-white.dark:bg-gray-800.rounded-lg.shadow-md.overflow-hidden
  = render "shared/lesson_records_table", lesson_records: @lesson_records, show_pagination: true, show_user: true
```

**削減効果:** 約80行 → **16行**（**64行削減**）

</details>

---

### Q4. `local_assigns`の理解（上級）🔴

以下のコードの違いを説明してください。

**パターンA:**
```slim
- if show_user
  th ユーザー
```

**パターンB:**
```slim
- if local_assigns[:show_user]
  th ユーザー
```

1. どのような違いがありますか？
2. パターンAの問題点は何ですか？
3. なぜパターンBを使うべきなのでしょうか？

**回答時間の目安**: 10分

<details>
<summary>解答を表示</summary>

### A4. `local_assigns`の理解

**1. 違い:**

**パターンA: `if show_user`**
- `show_user`という変数が定義されていることを前提とする
- 渡されていない場合、`NameError`（未定義変数エラー）が発生

**パターンB: `if local_assigns[:show_user]`**
- `local_assigns`ハッシュに`show_user`キーが存在するかチェック
- 渡されていない場合でもエラーにならない（`nil`として扱われる）

**2. パターンAの問題点:**

```slim
/ パーシャル呼び出し
= render "shared/lesson_records_table", lesson_records: @records
/ show_user を渡していない
```

```slim
/ パーシャル内
- if show_user  # ← NameError: undefined local variable or method `show_user'
  th ユーザー
```

**エラーが発生:**
```
ActionView::Template::Error: undefined local variable or method `show_user'
```

**3. パターンBを使うべき理由:**

**① オプショナルなパラメータを実現できる**

```slim
/ show_user を渡す場合
= render "shared/lesson_records_table", lesson_records: @records, show_user: true

/ show_user を渡さない場合（エラーにならない）
= render "shared/lesson_records_table", lesson_records: @records
```

**② デフォルト値の設定が可能**

```slim
- show_user = local_assigns[:show_user] || false
/ show_user が渡されていない場合、デフォルトで false
```

**③ 柔軟なパーシャル設計**

必須パラメータと任意パラメータを明確に分けられる：
- 必須: `lesson_records`（エラーになっても良い）
- 任意: `show_user`、`show_pagination`（エラーにならない）

**④ パーシャルの再利用性が向上**

同じパーシャルを異なる文脈で使える：
```slim
/ 管理者ページ: ユーザー列あり
= render "shared/lesson_records_table", lesson_records: @records, show_user: true

/ 個人ページ: ユーザー列なし
= render "shared/lesson_records_table", lesson_records: @records

/ 両方とも動作する（エラーにならない）
```

</details>

---

## 総合評価

### 基準

- **Q1を正解**: ビューの重複を見つけられる
- **Q2を正解**: パーシャル化の基本を理解している
- **Q3を正解**: 実装レベルでパーシャルを使いこなせる
- **Q4を正解**: `local_assigns`の仕組みを深く理解している

### コード削減効果（Day 29の実績）

- **管理者ダッシュボード**: 100行 → 11行（89行削減）
- **管理者一覧**: 80行 → 16行（64行削減）
- **個人履歴**: 80行 → 2行（78行削減）

**合計削減**: 約**231行**
**コード削減率**: 約**53%**

### 次のステップ

- **Q1のみ正解**: [共通パーシャルの教材](../02_intermediate/02_shared_partials.md)を再度読む
- **Q1-Q2正解**: 実際にパーシャルを作成してみる
- **Q1-Q3正解**: `local_assigns`の応用パターンを学ぶ
- **全問正解**: 他のレビューテストに進む

## 参考資料

- [共通パーシャルの教材](../topics/02_intermediate/02_shared_partials.md)
- [Concernパターン](../topics/02_intermediate/01_concerns_pattern.md) - コントローラーの共通化
- Day 29の日報: `docs/daily_reports/2025-12-29.md`
- 実際のPR: #101

---

**作成日**: 2025-12-29
**難易度**: 🟡 中級
**推定時間**: 30分〜1時間
