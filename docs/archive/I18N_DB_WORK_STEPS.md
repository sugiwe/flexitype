# DB多言語対応 作業手順書

**作成日:** 2026-01-07
**作業ブランチ:** feature/i18n-db-multilingual
**完了後に削除:** このファイルは作業完了後に削除してください。仕様はCLAUDE.mdに統合されます。

---

## 📋 作業概要

Category と Lesson の名前・説明を日英両方で管理できるようにする。

### 実装方針
- JSONBカラムで多言語管理（`name_translations`, `description_translations`）
- 既存の `name`/`description` カラムは残す（フォールバック用）
- 管理画面で日本語名（必須）と英語名（任意）を編集可能に
- フォールバック: 英語 → 日本語 → 既存カラム

---

## ✅ 作業ステップ

### Step 1: ブランチ作成

```bash
git checkout -b feature/i18n-db-multilingual
```

### Step 2: マイグレーション作成（スキーマ変更）

```bash
rails generate migration AddTranslationsToCategoriesAndLessons
```

```ruby
# db/migrate/XXXXXX_add_translations_to_categories_and_lessons.rb
class AddTranslationsToCategoriesAndLessons < ActiveRecord::Migration[8.1]
  def change
    # Categories
    add_column :categories, :name_translations, :jsonb, default: {}
    add_column :categories, :description_translations, :jsonb, default: {}

    # Lessons
    add_column :lessons, :name_translations, :jsonb, default: {}
    add_column :lessons, :description_translations, :jsonb, default: {}
  end
end
```

### Step 3: データマイグレーション作成

```bash
rails generate migration MigrateExistingCategoryAndLessonData
```

```ruby
# db/migrate/XXXXXX_migrate_existing_category_and_lesson_data.rb
class MigrateExistingCategoryAndLessonData < ActiveRecord::Migration[8.1]
  def up
    Category.find_each do |category|
      category.update_columns(
        name_translations: { "ja" => category.name },
        description_translations: { "ja" => category.description.to_s }
      )
    end

    Lesson.find_each do |lesson|
      lesson.update_columns(
        name_translations: { "ja" => lesson.name },
        description_translations: { "ja" => lesson.description.to_s }
      )
    end
  end

  def down
    # ロールバック時は何もしない（既存データを保護）
  end
end
```

### Step 4: タブの翻訳をYMLに追加

#### config/locales/ja.yml

```yaml
# タブ翻訳（Category::TABSで使用）
tabs:
  basics:
    name: "基礎トレーニング"
    description: "キー配置と指の練習"
  english:
    name: "英語練習"
    description: "英単語・フレーズの練習"
  japanese:
    name: "日本語練習"
    description: "かな・ローマ字入力"
  programming:
    name: "プログラミング"
    description: "コード・用語の練習"
  my_lessons:
    name: "マイレッスン"
    description: "自作レッスン（準備中）"
  community:
    name: "コミュニティ"
    description: "共有レッスン（準備中）"
```

#### config/locales/en.yml

```yaml
# Tab translations (used in Category::TABS)
tabs:
  basics:
    name: "Basic Training"
    description: "Key layout and finger practice"
  english:
    name: "English Practice"
    description: "Words and phrases"
  japanese:
    name: "Japanese Practice"
    description: "Kana and Romaji input"
  programming:
    name: "Programming"
    description: "Code and terminology"
  my_lessons:
    name: "My Lessons"
    description: "Custom lessons (coming soon)"
  community:
    name: "Community"
    description: "Shared lessons (coming soon)"
```

### Step 5: Categoryモデル修正

```ruby
# app/models/category.rb

class Category < ApplicationRecord
  has_many :lessons, dependent: :destroy

  # タブ定義（シンプル化）
  TABS = {
    basics: { key: "basics", icon: "🔰" },
    english: { key: "english", icon: "🔠" },
    japanese: { key: "japanese", icon: "🌸" },
    programming: { key: "programming", icon: "💻" },
    my_lessons: { key: "my_lessons", icon: "📝", disabled: true },
    community: { key: "community", icon: "👥", disabled: true }
  }.freeze

  # バリデーション
  validates :name, presence: true, length: { maximum: 50 }, uniqueness: true
  validates :description, length: { maximum: 200 }, allow_blank: true
  validates :tab, presence: true, inclusion: { in: TABS.keys.map(&:to_s) }

  # スコープ
  scope :ordered, -> { order(display_order: :asc) }
  scope :published, -> { where(published: true) }
  scope :free, -> { where(premium: false) }
  scope :available_for_guest, -> { where(requires_login: false) }
  scope :by_tab, ->(tab_key) { where(tab: tab_key.to_s) }

  # 多言語対応メソッド
  def translated_name
    name_translations[I18n.locale.to_s].presence ||
      name_translations["ja"].presence ||
      name
  end

  def translated_description
    description_translations[I18n.locale.to_s].presence ||
      description_translations["ja"].presence ||
      description
  end

  # クラスメソッド
  def self.available_tabs
    TABS.reject { |_key, config| config[:disabled] }
  end

  def self.all_tabs
    TABS
  end

  def self.tab_name(tab_key)
    I18n.t("tabs.#{tab_key}.name", default: tab_key.to_s.titleize)
  end

  def self.tab_description(tab_key)
    I18n.t("tabs.#{tab_key}.description", default: "")
  end
end
```

### Step 6: Lessonモデル修正

```ruby
# app/models/lesson.rb

class Lesson < ApplicationRecord
  belongs_to :user
  belongs_to :category
  has_many :lesson_records, dependent: :destroy

  # カテゴリーの設定を継承
  delegate :requires_login, :premium, to: :category

  # バリデーション
  validates :name, presence: true, length: { maximum: 100 }
  validates :description, length: { maximum: 500 }, allow_blank: true
  validates :items, presence: true
  validates :count, numericality: { greater_than: 0, less_than_or_equal_to: 100 }

  # スコープ
  scope :ordered, -> { order(display_order: :asc, id: :asc) }
  scope :official, -> { joins(:user).where(users: { admin: true }) }
  scope :user_created, -> { joins(:user).where.not(users: { admin: true }) }
  scope :published, -> { where(is_public: true) }
  scope :free, -> { joins(:category).where(categories: { premium: false }) }
  scope :premium, -> { joins(:category).where(categories: { premium: true }) }
  scope :available_for_guest, -> { joins(:category).where(categories: { requires_login: false }) }

  scope :visible_to, ->(user) {
    if user&.admin?
      all
    else
      left_joins(:user).where(
        "lessons.user_id = :user_id OR lessons.is_public = true OR users.admin = true",
        user_id: user&.id
      ).distinct
    end
  }

  # 多言語対応メソッド
  def translated_name
    name_translations[I18n.locale.to_s].presence ||
      name_translations["ja"].presence ||
      name
  end

  def translated_description
    description_translations[I18n.locale.to_s].presence ||
      description_translations["ja"].presence ||
      description
  end

  # 公式レッスンかどうかを判定
  def official?
    user&.admin?
  end

  # JavaScript用のレッスン情報をJSON形式で返す
  def to_lesson_info
    {
      lesson_id: id,
      category_name: category.translated_name,
      category_description: category.translated_description,
      lesson_name: translated_name,
      lesson_description: translated_description,
      count: count,
      requires_login: category.requires_login,
      premium: category.premium
    }
  end
end
```

### Step 7: 管理画面の修正（英語名編集機能追加）

#### Admin::CategoriesController

```ruby
# app/controllers/admin/categories_controller.rb

def category_params
  params.require(:category).permit(
    :name, :description, :tab, :display_order, :published,
    :requires_login, :premium,
    :name_en, :description_en  # 追加
  )
end

def create
  @category = Category.new(category_params.except(:name_en, :description_en))
  @category.name_translations = {
    "ja" => category_params[:name],
    "en" => category_params[:name_en].presence
  }.compact
  @category.description_translations = {
    "ja" => category_params[:description],
    "en" => category_params[:description_en].presence
  }.compact

  if @category.save
    redirect_to admin_categories_path, notice: "カテゴリーを作成しました"
  else
    render :new, status: :unprocessable_entity
  end
end

def update
  if @category.update(category_params.except(:name_en, :description_en))
    @category.name_translations = {
      "ja" => category_params[:name],
      "en" => category_params[:name_en].presence
    }.compact
    @category.description_translations = {
      "ja" => category_params[:description],
      "en" => category_params[:description_en].presence
    }.compact
    @category.save

    redirect_to admin_categories_path, notice: "カテゴリーを更新しました"
  else
    render :edit, status: :unprocessable_entity
  end
end
```

#### カテゴリー編集フォーム

```slim
/ app/views/admin/categories/_form.html.slim

= form_with model: [:admin, category], local: true do |f|
  / 日本語名
  .mb-4
    = f.label :name, "カテゴリー名（日本語）*", class: "block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2"
    = f.text_field :name, required: true, class: "w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md dark:bg-gray-700 dark:text-white"

  / 英語名
  .mb-4
    = f.label :name_en, "カテゴリー名（英語）", class: "block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2"
    = f.text_field :name_en, value: category.name_translations["en"], class: "w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md dark:bg-gray-700 dark:text-white"
    p.text-xs.text-gray-500.mt-1 未登録の場合、英語表示時に日本語名が表示されます

  / 日本語説明
  .mb-4
    = f.label :description, "説明（日本語）", class: "block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2"
    = f.text_area :description, rows: 3, class: "w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md dark:bg-gray-700 dark:text-white"

  / 英語説明
  .mb-4
    = f.label :description_en, "説明（英語）", class: "block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2"
    = f.text_area :description_en, value: category.description_translations["en"], rows: 3, class: "w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md dark:bg-gray-700 dark:text-white"
    p.text-xs.text-gray-500.mt-1 未登録の場合、英語表示時に日本語説明が表示されます

  / その他のフィールド（既存のまま）
  / ...
```

#### My::LessonsController（同様の修正）

同様に `lesson_params` に `:name_en`, `:description_en` を追加し、
create/update アクションで `name_translations`, `description_translations` を設定。

### Step 8: ビュー修正（全箇所）

以下のファイルで `category.name` → `category.translated_name` に変更：

**対象ファイル（例）:**
- `app/views/lessons/index.html.slim`
- `app/views/lessons/show.html.slim`
- `app/views/shared/_published_lessons.html.slim`
- `app/views/admin/categories/index.html.slim`
- `app/views/admin/lessons/index.html.slim`
- その他、Category/Lessonのname/descriptionを使用している全ビュー

**検索コマンド:**
```bash
# Categoryのname/descriptionを使っている箇所を検索
grep -r "category\.name" app/views/
grep -r "category\.description" app/views/

# Lessonのname/descriptionを使っている箇所を検索
grep -r "lesson\.name" app/views/
grep -r "lesson\.description" app/views/
```

### Step 9: RSpecテスト追加

```ruby
# spec/models/category_spec.rb

require "rails_helper"

RSpec.describe Category, type: :model do
  describe "#translated_name" do
    let(:category) { create(:category, name: "基礎", name_translations: translations) }

    context "when English translation exists" do
      let(:translations) { { "ja" => "基礎", "en" => "Basics" } }

      it "returns English name when locale is en" do
        I18n.with_locale(:en) do
          expect(category.translated_name).to eq("Basics")
        end
      end

      it "returns Japanese name when locale is ja" do
        I18n.with_locale(:ja) do
          expect(category.translated_name).to eq("基礎")
        end
      end
    end

    context "when English translation is missing" do
      let(:translations) { { "ja" => "基礎" } }

      it "falls back to Japanese name" do
        I18n.with_locale(:en) do
          expect(category.translated_name).to eq("基礎")
        end
      end
    end

    context "when translations are empty" do
      let(:translations) { {} }

      it "falls back to name column" do
        I18n.with_locale(:en) do
          expect(category.translated_name).to eq("基礎")
        end
      end
    end
  end

  describe "#translated_description" do
    let(:category) { create(:category, description: "説明", description_translations: translations) }

    context "when English translation exists" do
      let(:translations) { { "ja" => "説明", "en" => "Description" } }

      it "returns English description when locale is en" do
        I18n.with_locale(:en) do
          expect(category.translated_description).to eq("Description")
        end
      end
    end

    context "when English translation is missing" do
      let(:translations) { { "ja" => "説明" } }

      it "falls back to Japanese description" do
        I18n.with_locale(:en) do
          expect(category.translated_description).to eq("説明")
        end
      end
    end
  end

  describe ".tab_name" do
    it "returns translated tab name for ja locale" do
      I18n.with_locale(:ja) do
        expect(Category.tab_name("basics")).to eq("基礎トレーニング")
      end
    end

    it "returns translated tab name for en locale" do
      I18n.with_locale(:en) do
        expect(Category.tab_name("basics")).to eq("Basic Training")
      end
    end
  end

  describe ".tab_description" do
    it "returns translated tab description for ja locale" do
      I18n.with_locale(:ja) do
        expect(Category.tab_description("basics")).to eq("キー配置と指の練習")
      end
    end

    it "returns translated tab description for en locale" do
      I18n.with_locale(:en) do
        expect(Category.tab_description("basics")).to eq("Key layout and finger practice")
      end
    end
  end
end
```

```ruby
# spec/models/lesson_spec.rb（同様のテストを追加）

RSpec.describe Lesson, type: :model do
  describe "#translated_name" do
    # Category と同様のテストパターン
  end

  describe "#translated_description" do
    # Category と同様のテストパターン
  end
end
```

### Step 10: 品質チェック

```bash
# マイグレーション実行
rails db:migrate

# RuboCop（コード品質チェック）
bundle exec rubocop

# Brakeman（セキュリティチェック）
bundle exec brakeman --no-pager

# RSpec（テスト実行）
bundle exec rspec
```

### Step 11: 動作確認

1. サーバー起動: `rails server`
2. ブラウザで確認:
   - トップページ（日本語・英語）
   - レッスン詳細ページ（日本語・英語）
   - 管理画面でカテゴリー編集（英語名入力）
   - 管理画面でレッスン編集（英語名入力）
3. フォールバックの確認:
   - 英語名未登録のカテゴリーを英語表示

### Step 12: コミット・プッシュ

```bash
# 変更を確認
git status
git diff

# ステージング
git add .

# コミット
git commit -m "DB多言語対応の実装

- CategoryとLessonにJSONBカラムを追加（name_translations, description_translations）
- 既存データを日本語翻訳として移行
- モデルにtranslated_name/translated_descriptionメソッドを実装
- タブ翻訳をYMLファイルで管理
- 管理画面で英語名・英語説明を編集可能に
- ビューで多言語対応メソッドを使用
- RSpecテスト追加（translated_name/description、tab_name/description）
- フォールバック機能実装（英語 → 日本語 → 既存カラム）

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# プッシュ
git push origin feature/i18n-db-multilingual
```

### Step 13: PR作成

GitHubでPRを作成し、レビュー依頼。

---

## 📝 チェックリスト

- [ ] Step 1: ブランチ作成
- [ ] Step 2: マイグレーション作成（スキーマ変更）
- [ ] Step 3: データマイグレーション作成
- [ ] Step 4: タブの翻訳をYMLに追加
- [ ] Step 5: Categoryモデル修正
- [ ] Step 6: Lessonモデル修正
- [ ] Step 7: 管理画面の修正（英語名編集機能）
- [ ] Step 8: ビュー修正（全箇所）
- [ ] Step 9: RSpecテスト追加
- [ ] Step 10: 品質チェック
- [ ] Step 11: 動作確認
- [ ] Step 12: コミット・プッシュ
- [ ] Step 13: PR作成

---

## ⚠️ 注意事項

1. **既存のnameカラムは削除しない**
   - フォームでの編集、バリデーション、フォールバックに使用
   - 将来的に削除する可能性はあるが、今回は残す

2. **英語名は任意**
   - 管理画面で英語名を入力しなくてもOK
   - フォールバックで日本語名が表示される

3. **ビュー修正の範囲が広い**
   - `grep`コマンドで全箇所を確認
   - 見落としがないように注意

4. **テストの追加**
   - フォールバック動作を必ずテスト
   - 日本語・英語の両方でテスト

---

**作業完了後:**
- このファイルを削除
- 仕様を `CLAUDE.md` に統合
- `I18N_PLAN.md` のPhase 3を完了としてマーク
