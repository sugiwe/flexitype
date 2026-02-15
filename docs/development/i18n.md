# 国際化対応（i18n）実装計画

**作成日:** 2025-01-05
**目的:** Typnixを日英バイリンガル対応にし、英語圏ユーザーにも提供する

---

## 📌 背景

英語圏ユーザーから以下のフィードバックを受領：
> "Please add an English translation. I would love to use this for practice on my Cornix."

Rails i18nを活用して、体系的な多言語対応を実装する。

---

## ✅ 懸念点の整理

### 1. Google AdSenseとの関係
- **結論**: 気にしなくてOK
- AdSenseは言語ごとに自動で広告を配信
- 英語対応により英語圏の広告も表示され、収益機会が増加

### 2. ログイン周りの影響
- **結論**: 気にしなくてOK
- Google認証は言語に依存しない
- フラッシュメッセージやエラーメッセージを翻訳するだけで対応可能

### 3. Stripeとの関係
- **結論**: 気にしなくてOK
- Stripeは多言語対応済み（Checkout画面は自動で言語切り替え）
- 価格表示などの説明文を翻訳すれば対応完了

### 4. やるべきこと
- **結論**: 基本的には日英翻訳がメインだが、いくつか技術的な考慮事項あり

---

## 📋 実装ステップ

### Phase 1: 基盤整備（1-2時間）

#### 1. i18n設定

**config/application.rb**
```ruby
module Flexitype
  class Application < Rails::Application
    # デフォルト言語: 日本語
    config.i18n.default_locale = :ja

    # 利用可能な言語
    config.i18n.available_locales = [:ja, :en]

    # 翻訳ファイルのロードパス
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.yml')]
  end
end
```

**ApplicationController**
```ruby
around_action :switch_locale

private

def switch_locale(&action)
  locale = params[:locale] ||
           cookies[:locale] ||
           http_accept_language.compatible_language_from(I18n.available_locales) ||
           I18n.default_locale
  cookies[:locale] = locale
  I18n.with_locale(locale, &action)
end

def default_url_options
  { locale: I18n.locale }
end
```

#### 2. 言語切り替えUI

**ヘッダーに言語切り替えボタンを追加**
- 日本語 / English の切り替え
- 現在の言語をCookieで永続化
- URLパラメータ（`?locale=en`）でも切り替え可能

#### 3. ディレクトリ構成

```
config/locales/
├── ja.yml                    # 日本語（デフォルト）
├── en.yml                    # 英語
├── models/
│   ├── ja.yml               # モデル関連（日本語）
│   └── en.yml               # モデル関連（英語）
└── views/
    ├── ja.yml               # ビュー関連（日本語）
    └── en.yml               # ビュー関連（英語）
```

---

### Phase 2: コンテンツ翻訳（3-5時間）

#### 1. 静的コンテンツ

**対象:**
- ナビゲーション（ホーム、レッスン、マイページ、管理者、ログアウト）
- ボタン（保存、キャンセル、削除、編集、作成）
- ラベル（メールアドレス、ユーザー名、パスワード）
- フラッシュメッセージ（成功、エラー、警告）
- エラーメッセージ（バリデーションエラー）

**翻訳例:**
```yaml
# config/locales/ja.yml
ja:
  navigation:
    home: "ホーム"
    lessons: "レッスン"
    my_page: "マイページ"
    admin: "管理者"
    logout: "ログアウト"

  buttons:
    save: "保存"
    cancel: "キャンセル"
    delete: "削除"
    edit: "編集"
    create: "作成"

# config/locales/en.yml
en:
  navigation:
    home: "Home"
    lessons: "Lessons"
    my_page: "My Page"
    admin: "Admin"
    logout: "Logout"

  buttons:
    save: "Save"
    cancel: "Cancel"
    delete: "Delete"
    edit: "Edit"
    create: "Create"
```

#### 2. 動的コンテンツ

**対象:**
- レッスン名、カテゴリー名
- ユーザー向けメッセージ
- グレード名（プロ級→Expert、上級者→Advanced など）

**グレード名の翻訳例:**
```yaml
# config/locales/ja.yml
grades:
  expert: "プロ級"
  advanced: "上級者"
  intermediate: "中級者"
  beginner: "初心者"
  novice: "入門者"

# config/locales/en.yml
grades:
  expert: "Expert"
  advanced: "Advanced"
  intermediate: "Intermediate"
  beginner: "Beginner"
  novice: "Novice"
```

#### 3. 固定ページ

**対象:**
- About ページ
- Terms（利用規約）
- Privacy（プライバシーポリシー）

**実装方法:**
- 言語ごとに別ファイルを用意
- 例: `app/views/pages/about.ja.html.slim`, `app/views/pages/about.en.html.slim`

---

### Phase 3: DB多言語対応（2-3時間）

#### 重要な判断ポイント

**Category、Lesson の名前・説明を多言語化する方法**

**選択肢A: JSONBカラム（推奨）**
- シンプルで管理しやすい
- Railsの標準機能のみで実装可能

```ruby
# db/migrate/XXXXXX_add_translations_to_categories.rb
class AddTranslationsToCategories < ActiveRecord::Migration[8.1]
  def change
    add_column :categories, :name_translations, :jsonb, default: {}
    add_column :categories, :description_translations, :jsonb, default: {}
  end
end

# app/models/category.rb
class Category < ApplicationRecord
  def name
    name_translations[I18n.locale.to_s] || name_translations['ja']
  end

  def description
    description_translations[I18n.locale.to_s] || description_translations['ja']
  end
end
```

**選択肢B: 専用の翻訳テーブル（Mobility gem）**
- より高度な多言語対応
- 複雑さが増す

**選択肢C: 日英両方のレッスンを別々に作成**
- 最もシンプル
- 管理が煩雑になる可能性

**推奨**: 選択肢A（JSONBカラム）

#### レッスンコンテンツの翻訳

**課題**: 現在のレッスン（items JSONB）をどう翻訳するか

**選択肢:**
- **A. 日本語レッスンはそのまま、英語専用レッスンを別途作成**（推奨）
  - シンプル、管理しやすい
  - 言語ごとに最適化されたコンテンツを提供可能
- **B. items JSONBに言語キーを追加**
  - 複雑になる
  - メンテナンスが困難

**推奨**: 選択肢A

---

### Phase 4: SEO・OGP対応（1-2時間）

#### 1. hreflang設定

言語ごとのURLを検索エンジンに伝える

```slim
/ app/views/layouts/application.html.slim
link rel="alternate" hreflang="ja" href="#{root_url(locale: :ja)}"
link rel="alternate" hreflang="en" href="#{root_url(locale: :en)}"
link rel="alternate" hreflang="x-default" href="#{root_url(locale: :ja)}"
```

#### 2. OGP多言語対応

言語ごとにOGPタグを動的生成

```ruby
# app/helpers/application_helper.rb
def og_title
  if I18n.locale == :ja
    "Typnix - 分割型キーボード練習アプリ"
  else
    "Typnix - Split Keyboard Practice App"
  end
end

def og_description
  if I18n.locale == :ja
    "Cornixなどのカラムスタッガードキーボードでのタイピングスキルアップをサポート"
  else
    "Practice typing on column-staggered keyboards like Cornix"
  end
end
```

---

## 🛠 技術的な実装詳細

### URL設計

**推奨アプローチ:**
- デフォルト（日本語）: `https://typnix.com/lessons/1`
- 英語: `https://typnix.com/lessons/1?locale=en`（Cookieで永続化）

**メリット:**
- URLがシンプル（言語プレフィックス不要）
- 既存のURLが変わらない（SEO影響なし）
- Cookieで言語選択を永続化

### 日付・時刻の表示

Railsのi18nで自動対応
- 日本語: "2026年1月5日"
- 英語: "January 5, 2026"

---

## ⚠️ 注意点・懸念事項

### 1. 翻訳の品質

- 機械翻訳に頼りすぎない
- ネイティブチェックが理想（可能であれば）
- 用語の一貫性を保つ

### 2. メンテナンス性

- 新機能追加時に日英両方の翻訳を忘れない
- 翻訳漏れをチェックする仕組み（i18n-tasks gem）

### 3. パフォーマンス

- JSONBクエリのパフォーマンス影響は軽微
- 必要に応じてインデックス追加

---

## 📊 作業見積もり

| フェーズ | 作業時間 | 内容 |
|---------|---------|------|
| Phase 1 | 1-2時間 | 基盤整備、言語切り替え機能 |
| Phase 2 | 3-5時間 | 静的コンテンツ翻訳 |
| Phase 3 | 2-3時間 | DB多言語対応 |
| Phase 4 | 1-2時間 | SEO・OGP対応 |
| **合計** | **7-12時間** | 慎重に進めて1-2日 |

---

## 📝 実装順序（推奨）

### Step 1: 基盤整備（最優先）
1. i18n設定追加（`config/application.rb`）
2. 言語切り替え機能実装（`ApplicationController`）
3. ヘッダーに言語切り替えボタン追加

### Step 2: 静的コンテンツ翻訳
1. ナビゲーション、ボタン
2. フラッシュメッセージ
3. About、Terms、Privacyページ

### Step 3: 動的コンテンツ翻訳
1. Category、Lesson名の多言語化（JSONB）
2. グレード名、統計情報
3. エラーメッセージ

### Step 4: SEO・OGP対応
1. hreflang設定
2. OGP多言語対応

---

## 🔧 便利なGem

### http_accept_language
ブラウザの言語設定を自動検出

```ruby
# Gemfile
gem 'http_accept_language'

# ApplicationController
def switch_locale(&action)
  locale = params[:locale] ||
           cookies[:locale] ||
           http_accept_language.compatible_language_from(I18n.available_locales) ||
           I18n.default_locale
  cookies[:locale] = locale
  I18n.with_locale(locale, &action)
end
```

### i18n-tasks（オプション）
翻訳漏れをチェック

```ruby
# Gemfile
gem 'i18n-tasks', group: :development

# 実行
bundle exec i18n-tasks missing
bundle exec i18n-tasks unused
```

---

## 📚 参考資料

- [Rails国際化（i18n）APIガイド](https://railsguides.jp/i18n.html)
- [http_accept_language](https://github.com/iain/http_accept_language)
- [i18n-tasks](https://github.com/glebm/i18n-tasks)

---

## 次回の検討事項

後日、このドキュメントをベースに以下を検討：
1. Phase 1から実装を開始するか
2. 翻訳の優先順位（どの部分から翻訳するか）
3. 英語専用レッスンの内容（どのようなレッスンを用意するか）
4. テスト戦略（多言語対応のテスト方法）

**最終更新:** 2025-01-05
