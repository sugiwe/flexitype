# アーキテクチャ改善とリファクタリング

**難易度**: 🔴 上級
**推定学習時間**: 2〜3時間
**対応する日報**: Day 20, Day 21
**関連PR**: #64 (practice/session → lesson/lesson_record), #65 (lesson DB migration), #66 (category management)

---

## 🎯 学習目標

この教材を学ぶことで、以下ができるようになります：

- サービスオブジェクトの適切な使い方を理解し、使うべき時と使わない時を判断できる
- YAMLからDBへの移行戦略を学び、データ移行のベストプラクティスを実践できる
- delegateパターンによる冗長性解消の効果を理解し、実装できる
- Rails wayなアーキテクチャを設計し、保守性・拡張性の高いコードを書ける

---

## 📚 前提知識

この教材を理解するには、以下の知識が必要です：

- Railsの基本的なMVCパターン（モデル、ビュー、コントローラの役割）
- ActiveRecordの基本操作（CRUD、アソシエーション、スコープ）
- サービスオブジェクトパターンの基礎（POROでビジネスロジックを切り出す考え方）
- マイグレーションの基本（テーブル作成、カラム追加、データ移行）
- delegateパターンの基礎（オブジェクトに別のオブジェクトのメソッド呼び出しを委譲する）

---

## 📖 本編

### 概要

Typnixプロジェクトでは、Day 20-21にかけて大規模なアーキテクチャ改善を実施しました。この改善は、以下の3つの大きな柱で構成されています：

1. **用語統一リファクタリング**（Day 20）: practice/session → lesson/lesson_record への全面的な名称変更
2. **レッスンDB化**（Day 21午前）: YAMLファイルからPostgreSQLへのデータ移行とLessonLoaderサービスオブジェクトの削除
3. **権限フラグの整理**（Day 21午後）: delegateパターンによる冗長性解消とpublishedフラグの追加

これらの改善により、コードベース全体の一貫性が向上し、将来的な機能拡張がしやすくなりました。特に、**「Rails wayに回帰する」**という設計思想が重要なポイントです。

サービスオブジェクトは、複雑なビジネスロジックを切り出す強力な手法ですが、すべてのケースで有効というわけではありません。場合によっては、Railsの標準パターン（モデル、コントローラ、スコープ）で十分対応できることがあります。今回の改善では、「サービスオブジェクトを使うべき時・使わない時」の判断基準を学ぶことができます。

また、データの冗長性（同じ情報を複数の場所に持つ）は、保守性を低下させる大きな要因です。Lessonモデルとカテゴリーモデルで重複していた権限フラグ（`requires_login`, `premium`）を整理し、delegateパターンで解消した事例は、DRY原則の実践例として非常に参考になります。

---

### 実装前（アンチパターン / 課題）

#### 1. 用語の不統一（practice/session問題）

**問題の背景:**

Day 20以前のコードベースでは、以下のような用語の不統一がありました：

- URL: `/practices/:id` → レッスンを表示するページ
- コントローラ: `PracticesController` → レッスンの表示を担当
- モデル: `TypingSession` → レッスンの練習記録を保存

この用語の不統一により、以下の問題が発生していました：

**問題点:**
- **ドメインモデルが不明確**: "practice"（練習する）は動詞的で、リソース名として不適切
- **セッション用語の混同**: "typing_session"（タイピングセッション）はログインセッションと混同されやすい
- **一貫性の欠如**: URLでは"practice"、モデルでは"session"と、同じ概念に異なる名前を使用
- **新規開発者の混乱**: コードベースを理解する際、用語の対応関係を覚える負担が大きい

#### 2. LessonLoaderサービスオブジェクト

Day 20以前、レッスンデータはYAMLファイル（`config/typing_lessons.yml`）で管理されていました。このYAMLデータをRubyのハッシュ形式に変換し、ビューで使いやすい形式にするために、`LessonLoader`というサービスオブジェクトが存在していました。

**LessonLoaderの役割:**

```ruby
# app/services/lesson_loader.rb（Day 20以前）
class LessonLoader
  def self.all_lessons
    @all_lessons ||= YAML.load_file(Rails.root.join("config", "typing_lessons.yml"))
  end

  def self.all_lessons_flat
    all_lessons.flat_map do |category_key, category_data|
      category_data["lessons"].map do |lesson|
        lesson.merge(
          "category" => category_data["name"],
          "category_key" => category_key,
          "category_description" => category_data["description"]
        )
      end
    end
  end

  def self.find_lesson(lesson_id)
    all_lessons_flat.find { |lesson| lesson["lesson_id"] == lesson_id }
  end

  def self.categories
    all_lessons.map do |category_key, category_data|
      {
        "key" => category_key,
        "name" => category_data["name"],
        "description" => category_data["description"],
        "lessons" => category_data["lessons"]
      }
    end
  end
end
```

**コントローラでの使用例:**

```ruby
# app/controllers/home_controller.rb（Day 20以前）
class HomeController < ApplicationController
  def index
    @categories = LessonLoader.categories
  end
end

# app/controllers/lessons_controller.rb（Day 20以前）
class LessonsController < ApplicationController
  def show
    lesson_data = LessonLoader.find_lesson(params[:id].to_i)
    if lesson_data.nil?
      redirect_to root_path, alert: "レッスンが見つかりません"
      return
    end

    @lesson_info = lesson_data
  end
end
```

**問題点:**
- **YAMLファイルで管理**: レッスンを追加・編集するたびにYAMLファイルを手動で編集し、デプロイが必要
- **動的な作成が不可能**: ユーザーが自分でレッスンを作成する機能を実装できない
- **データ検索が非効率**: 毎回全レッスンを読み込んでから`find`で検索（O(n)の計算量）
- **サービスオブジェクトの肥大化**: データ変換ロジックがサービスオブジェクトに集中し、責務が曖昧
- **Rails wayからの逸脱**: ActiveRecordの標準パターンを使わず、独自の抽象化レイヤーを作成

#### 3. 権限フラグの冗長性

Day 21午前の時点で、LessonモデルとCategoryモデルの両方に以下のカラムが存在していました：

```ruby
# app/models/lesson.rb（Day 21午前時点）
class Lesson < ApplicationRecord
  belongs_to :category

  # Lessonテーブルのカラム
  # - requires_login (boolean)
  # - premium (boolean)
end

# app/models/category.rb（Day 21午前時点）
class Category < ApplicationRecord
  has_many :lessons

  # Categoryテーブルのカラム
  # - requires_login (boolean)
  # - premium (boolean)
end
```

**問題点:**
- **データの矛盾が発生する可能性**: カテゴリーが`requires_login: true`なのに、レッスンが`requires_login: false`の場合、どちらを優先すべきか不明確
- **更新の手間**: カテゴリーの権限設定を変更する際、そのカテゴリーに属する全レッスンも更新する必要がある
- **URL直打ちでの不正アクセス**: カテゴリーは有料だが、レッスンが無料として登録されている場合、`/lessons/:id`に直接アクセスすると無料で閲覧できてしまう
- **コードの重複**: 権限チェックのロジックがカテゴリーとレッスンの両方で必要になる

#### 4. カテゴリーの公開制御がない

Day 21午前の時点では、カテゴリーに`published`フラグがなく、レッスンが0件でも空のカテゴリーがホームページに表示されていました。

**問題点:**
- **準備中のカテゴリーが表示される**: 新規カテゴリーを作成した瞬間に公開されてしまう
- **ユーザー体験の低下**: 「このカテゴリーにはレッスンがありません」と表示され、未完成の印象を与える
- **段階的な準備ができない**: カテゴリーを作成してからレッスンを充実させるまで、非公開で準備する手段がない

---

### 実装後（ベストプラクティス）

#### 1. 用語の統一（lesson/lesson_record）

**変更内容:**

- `practice` → `lesson`（URL、コントローラ、ビュー）
- `TypingSession` → `LessonRecord`（モデル、テーブル、変数）

**ルーティング:**

```ruby
# config/routes.rb（Day 20以降）
Rails.application.routes.draw do
  resources :lessons, only: [:show]

  # 旧URLからのリダイレクト（後方互換性）
  get "/practices/:id", to: redirect("/lessons/%{id}")
end
```

**モデル:**

```ruby
# app/models/lesson_record.rb（Day 20以降）
class LessonRecord < ApplicationRecord
  belongs_to :user
  belongs_to :lesson

  validates :accuracy, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :duration, numericality: { greater_than: 0 }
  validates :mistakes, numericality: { greater_than_or_equal_to: 0 }

  scope :recent, -> { order(completed_at: :desc) }

  # WPM計算（1分あたりの単語数）
  def wpm
    return 0 if duration.nil? || duration.zero?
    ((word_count / duration.to_f) * 60).round(1)
  end

  # グレード判定（5段階）
  def grade
    score = (accuracy / 100.0) * wpm
    case score
    when 80.. then :pro
    when 60...80 then :advanced
    when 40...60 then :intermediate
    when 20...40 then :beginner
    else :novice
    end
  end
end
```

**コントローラ:**

```ruby
# app/controllers/lessons_controller.rb（Day 20以降）
class LessonsController < ApplicationController
  def show
    @lesson = Lesson.find(params[:id])
    @lesson_info = @lesson.to_lesson_info
  end
end
```

**改善点:**
- **一貫性の向上**: URL、モデル、変数名が全て"lesson"で統一され、コードベース全体で同じ用語を使用
- **明確なドメインモデル**: "lesson"（レッスン）はリソース名として自然で、"lesson_record"（レッスンの記録）も直感的
- **後方互換性の確保**: 旧URLからのリダイレクトにより、既存のブックマークやリンクが機能し続ける
- **新規開発者のオンボーディング改善**: 用語が明確で、コードベースを理解しやすい

**コード削減効果:**
- 変更ファイル数: 20ファイル以上
- 用語統一により、コメントや変数名が直感的になり、ドキュメントの必要性が減少

#### 2. LessonLoaderの削除とRails wayへの回帰

**変更内容:**

LessonLoaderサービスオブジェクトを削除し、ActiveRecordの標準パターンでレッスンデータを取得するように変更しました。

**Category・Lessonモデルの作成:**

```ruby
# app/models/category.rb（Day 21以降）
class Category < ApplicationRecord
  has_many :lessons, dependent: :destroy

  # バリデーション
  validates :name, presence: true, length: { maximum: 50 }, uniqueness: true
  validates :description, length: { maximum: 200 }, allow_blank: true

  # スコープ
  scope :ordered, -> { order(display_order: :asc) }
  scope :published, -> { where(published: true) }
  scope :free, -> { where(premium: false) }
  scope :available_for_guest, -> { where(requires_login: false) }
end

# app/models/lesson.rb（Day 21以降）
class Lesson < ApplicationRecord
  belongs_to :user
  belongs_to :category
  has_many :lesson_records, dependent: :destroy

  # カテゴリーの設定を継承（後述のdelegate パターン）
  delegate :requires_login, :premium, to: :category

  # バリデーション
  validates :name, presence: true, length: { maximum: 100 }
  validates :items, presence: true

  # スコープ
  scope :ordered, -> { order(display_order: :asc, id: :asc) }
  scope :official, -> { joins(:user).where(users: { admin: true }) }
  scope :user_created, -> { joins(:user).where.not(users: { admin: true }) }
  scope :published, -> { where(is_public: true) }

  # 特定ユーザーに表示可能なレッスンを取得
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

  # JavaScript用のレッスン情報をJSON形式で返す
  def to_lesson_info
    {
      lesson_id: id,
      category_name: category.name,
      lesson_description: description,
      count: count,
      requires_login: category.requires_login,
      premium: category.premium
    }
  end
end
```

**コントローラの変更:**

```ruby
# app/controllers/home_controller.rb（Day 21以降）
class HomeController < ApplicationController
  def index
    # LessonLoader.categories → ActiveRecordのクエリに変更
    @categories = Category.published.ordered.includes(:lessons)
  end
end

# app/controllers/lessons_controller.rb（Day 21以降）
class LessonsController < ApplicationController
  def show
    # LessonLoader.find_lesson → ActiveRecordのfindに変更
    @lesson = Lesson.find(params[:id])
    @lesson_info = @lesson.to_lesson_info
  end
end
```

**データ移行スクリプト:**

```ruby
# lib/tasks/migrate_lessons_from_yaml.rake
namespace :lessons do
  desc "Migrate lessons from YAML to PostgreSQL"
  task migrate_from_yaml: :environment do
    yaml_data = YAML.load_file(Rails.root.join("config", "typing_lessons.yml"))
    official_user = User.find_by(email: "typnix.app@gmail.com")

    if official_user.nil?
      puts "Error: Official user not found (typnix.app@gmail.com)"
      exit 1
    end

    yaml_data.each do |category_key, category_data|
      category = Category.create!(
        name: category_data["name"],
        description: category_data["description"],
        display_order: category_data["display_order"] || 0
      )

      category_data["lessons"].each do |lesson_data|
        category.lessons.create!(
          user: official_user,
          name: lesson_data["name"],
          description: lesson_data["description"],
          items: lesson_data["items"],
          count: lesson_data["count"]
        )
      end
    end

    puts "Migration completed: #{Category.count} categories, #{Lesson.count} lessons"
  end
end
```

**改善点:**
- **Rails wayに回帰**: サービスオブジェクトを削除し、ActiveRecordの標準パターンに統一
- **データベース管理**: PostgreSQLでレッスンデータを管理することで、動的な作成・編集が可能に
- **パフォーマンス向上**: データベースのインデックスにより、レッスン検索が高速化（O(n) → O(log n)）
- **拡張性の向上**: ユーザーが自分でレッスンを作成する機能（`/my/lessons`）が実装可能に
- **責務の明確化**: データ取得はモデル、表示はビュー、制御はコントローラと役割が明確

**コード削減効果:**
- Before: `app/services/lesson_loader.rb` 約150行
- After: 削除（モデルとスコープで代替）
- **削減率**: 100%（サービスオブジェクト不要に）

#### 3. delegateパターンによる冗長性解消

**変更内容:**

Lessonテーブルから`requires_login`と`premium`カラムを削除し、Categoryの設定を継承するようにしました。

**マイグレーション:**

```ruby
# db/migrate/YYYYMMDDHHMMSS_remove_permission_flags_from_lessons.rb
class RemovePermissionFlagsFromLessons < ActiveRecord::Migration[8.1]
  def change
    remove_column :lessons, :requires_login, :boolean
    remove_column :lessons, :premium, :boolean
  end
end
```

**Lessonモデルの変更:**

```ruby
# app/models/lesson.rb（Day 21午後以降）
class Lesson < ApplicationRecord
  belongs_to :category

  # カテゴリーの設定を継承
  delegate :requires_login, :premium, to: :category

  # スコープもカテゴリーテーブルを参照するように変更
  scope :free, -> { joins(:category).where(categories: { premium: false }) }
  scope :premium, -> { joins(:category).where(categories: { premium: true }) }
  scope :available_for_guest, -> { joins(:category).where(categories: { requires_login: false }) }
end
```

**delegateパターンの仕組み:**

```ruby
# delegateを使用しない場合
lesson = Lesson.first
lesson.category.requires_login  # カテゴリー経由でアクセス

# delegateを使用した場合
lesson = Lesson.first
lesson.requires_login  # Lessonオブジェクトに直接アクセス（内部でcategory.requires_loginを呼び出す）
```

**改善点:**
- **データの一貫性**: カテゴリー単位で権限管理されるため、矛盾が発生しない
- **更新の簡素化**: カテゴリーの権限設定を変更すれば、そのカテゴリーの全レッスンに自動反映
- **不正アクセスの防止**: レッスン単体で権限を設定できないため、URL直打ちでの不正アクセスが防止される
- **コードのシンプル化**: レッスン管理フォームから権限フィールドを削除でき、UIが簡潔に

**コード削減効果:**
- Before: Lessonテーブルに`requires_login`, `premium`カラムが存在
- After: delegateパターンでカテゴリーから継承
- **削減率**: カラム2つ削除、Strong Parameters簡素化

#### 4. publishedフラグによる公開制御

**変更内容:**

Categoryテーブルに`published`カラムを追加し、カテゴリーの公開/非公開を管理できるようにしました。

**マイグレーション:**

```ruby
# db/migrate/YYYYMMDDHHMMSS_add_published_to_categories.rb
class AddPublishedToCategories < ActiveRecord::Migration[8.1]
  def change
    add_column :categories, :published, :boolean, default: true, null: false
    add_index :categories, :published

    # 既存のカテゴリーは全て公開済みに設定
    Category.update_all(published: true)
  end
end
```

**Categoryモデルの変更:**

```ruby
# app/models/category.rb（Day 21午後以降）
class Category < ApplicationRecord
  scope :published, -> { where(published: true) }
end
```

**コントローラの変更:**

```ruby
# app/controllers/home_controller.rb（Day 21午後以降）
class HomeController < ApplicationController
  def index
    @categories = Category.published.ordered.includes(:lessons)
  end
end
```

**カテゴリー管理フォーム:**

```slim
# app/views/admin/categories/_form.html.slim
= form_with model: [:admin, category], local: true do |f|
  .mb-4
    = f.label :name, "カテゴリー名", class: "block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2"
    = f.text_field :name, class: "w-full px-3 py-2 border border-gray-300 rounded-lg"

  .mb-4
    = f.label :description, "説明", class: "block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2"
    = f.text_area :description, rows: 3, class: "w-full px-3 py-2 border border-gray-300 rounded-lg"

  .mb-4
    = f.check_box :published, class: "mr-2"
    = f.label :published, "公開する", class: "text-sm text-gray-700 dark:text-gray-300"

  = f.submit "保存", class: "px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
```

**改善点:**
- **段階的な準備が可能**: カテゴリーを作成した後、レッスンを充実させてから公開できる
- **明示的な公開制御**: `published`フラグにより、管理者が意図的に公開/非公開を切り替えられる
- **ユーザー体験の向上**: 準備中のカテゴリーが表示されず、完成したコンテンツのみ提供できる

**コード削減効果:**
- Before: カテゴリーは常に公開（レッスン数0でも表示）
- After: `published: false`で非公開、管理者が明示的に公開
- **削減率**: コード削減ではなく、機能追加（柔軟性向上）

---

### 解説

#### なぜこの設計が優れているのか

**1. Rails wayへの回帰 - フレームワークの力を活用する**

Railsは「設定より規約」（Convention over Configuration）の哲学に基づいており、標準パターンに従うことで多くの利点が得られます。

- **ActiveRecordの強力な機能**: スコープ、アソシエーション、バリデーションなど、データ操作に必要な機能が標準で提供される
- **可読性の向上**: Railsに慣れた開発者であれば、標準パターンのコードは直感的に理解できる
- **ツールのサポート**: RuboCop、Bullet、N+1クエリ検出ツールなど、Railsの標準パターンに対応したツールが豊富
- **保守性の向上**: フレームワークのアップデートに追従しやすく、長期的な保守が容易

LessonLoaderサービスオブジェクトは、YAMLデータを変換するという明確な目的がありましたが、DB化によりその目的が消滅しました。このような場合、サービスオブジェクトを無理に残すのではなく、Rails wayに回帰する方が賢明です。

**2. データの一貫性を保証する - 単一の真実の源（Single Source of Truth）**

データの冗長性は、以下の問題を引き起こします：

- **矛盾の発生**: 同じ情報を複数の場所に持つと、どれが正しいか判断できなくなる
- **更新漏れ**: 1箇所を更新しても、他の場所を更新し忘れる可能性がある
- **バグの温床**: データの矛盾により、予期しない動作が発生する

delegateパターンにより、権限フラグをカテゴリーに一元化することで、これらの問題を根本的に解決できました。

```ruby
# 悪い例（冗長性あり）
category.requires_login = true
lesson.requires_login = false  # カテゴリーと矛盾！

# 良い例（delegateパターン）
category.requires_login = true
lesson.requires_login  # => true（カテゴリーから継承）
```

**3. 段階的な拡張を可能にする - 将来への備え**

publishedフラグの追加は、単なる公開制御以上の意味を持ちます：

- **段階的なコンテンツ準備**: カテゴリーを作成してからレッスンを充実させるまで、非公開で準備できる
- **A/Bテストの基盤**: 一部のユーザーにのみ新カテゴリーを公開するなど、柔軟な運用が可能
- **緊急時の対応**: 問題が発生したカテゴリーを即座に非公開にできる

このような機能は、初期段階では必要性が低く見えますが、サービスの成長とともに重要になります。アーキテクチャ設計時に「将来どう拡張するか」を考慮することが重要です。

**4. 用語の統一 - 認知負荷の軽減**

プログラマーは、コードを読む時間の方が書く時間よりも圧倒的に長いため、可読性が重要です。用語が統一されていると、以下の利点があります：

- **メンタルモデルの一貫性**: 同じ概念に同じ名前を使うことで、脳内のモデルが一貫する
- **検索の容易さ**: `lesson`で検索すれば、関連するコードが全て見つかる
- **新規参加者のオンボーディング**: 用語が明確で、プロジェクトを理解しやすい

practice/session → lesson/lesson_record への変更は、単なる名前の変更ではなく、ドメインモデルの明確化という設計上の改善です。

**5. 責務の明確化 - Single Responsibility Principle（単一責任の原則）**

サービスオブジェクトは、複雑なビジネスロジックを切り出すのに有効ですが、責務が曖昧になりやすいという欠点があります：

- **LessonLoaderの責務**: YAMLデータの読み込み、データ変換、カテゴリー取得、レッスン検索など、複数の責務が混在
- **モデルの責務**: データの永続化、バリデーション、ビジネスロジック
- **コントローラの責務**: リクエストの処理、ビューへのデータ渡し

サービスオブジェクトを削除し、モデルとスコープに集約することで、責務が明確になりました：

- **Category/Lessonモデル**: レッスンデータの管理、バリデーション、スコープ
- **HomeController/LessonsController**: カテゴリー・レッスンの表示制御
- **ビュー**: データの表示

---

#### 実装のポイント

**1. データ移行の3段階アプローチ**

大規模なデータ移行では、以下の3段階アプローチが効果的です：

**Phase 1: データクリーンアップ**
```ruby
# 古いデータ削除、nilデータの自動マッチング
LessonRecord.where(lesson_id: nil).destroy_all
```

**Phase 2: スキーマクリーンアップ**
```ruby
# 型変更（string → bigint）
change_column :lesson_records, :lesson_id, :bigint, using: 'lesson_id::bigint'
```

**Phase 3: データ整合性確保**
```ruby
# NOT NULL制約、外部キー制約、インデックス追加
change_column_null :lesson_records, :lesson_id, false
add_foreign_key :lesson_records, :lessons
add_index :lesson_records, :lesson_id
```

このアプローチにより、データの安全性を保ちながら段階的にスキーマを変更できます。

**2. Rakeタスクによるデータ移行**

データ移行スクリプトは、必ずRakeタスク化しましょう：

```ruby
# lib/tasks/migrate_lessons_from_yaml.rake
namespace :lessons do
  desc "Migrate lessons from YAML to PostgreSQL"
  task migrate_from_yaml: :environment do
    # 移行処理
  end
end
```

**メリット:**
- **再実行可能**: 本番環境で何度でも実行できる
- **ドキュメント化**: デプロイ手順書に明記できる
- **バージョン管理**: Gitで管理され、履歴が残る

**実行方法:**
```bash
# ローカル環境
rails lessons:migrate_from_yaml

# 本番環境（Kamal経由）
kamal app exec --roles=web 'bin/rails lessons:migrate_from_yaml'
```

**3. 後方互換性の確保**

URLやモデル名を変更する際は、必ず後方互換性を確保しましょう：

```ruby
# config/routes.rb
get "/practices/:id", to: redirect("/lessons/%{id}")
```

**メリット:**
- **既存のブックマークが機能**: ユーザーの保存済みURLが壊れない
- **SEOの維持**: 検索エンジンのインデックスが自動的に更新される
- **段階的な移行**: 旧URLを一定期間サポートし、徐々に新URLに移行できる

**4. delegateパターンの注意点**

delegateパターンは強力ですが、以下の点に注意が必要です：

```ruby
# 正しい使い方
delegate :requires_login, :premium, to: :category

# 注意: カテゴリーがnilの場合、NoMethodErrorが発生する
lesson = Lesson.new
lesson.requires_login  # => NoMethodError: undefined method `requires_login' for nil:NilClass

# 解決策1: allow_nilオプション
delegate :requires_login, :premium, to: :category, allow_nil: true

# 解決策2: バリデーションでcategoryの存在を保証
validates :category, presence: true
```

Typnixプロジェクトでは、Lessonは必ずCategoryに属するため、`validates :category, presence: true`（または`belongs_to`のデフォルト動作）により、nilが発生しない設計になっています。

**5. スコープの活用**

スコープは、再利用可能なクエリを定義する強力な手法です：

```ruby
# app/models/lesson.rb
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

# コントローラで使用
@lessons = Lesson.visible_to(current_user)
```

**メリット:**
- **再利用性**: 複数のコントローラで同じ権限チェックを使える
- **テスタビリティ**: スコープ単体でテスト可能
- **可読性**: `visible_to(current_user)`という名前で意図が明確

---

### Typnixプロジェクトでの実例

#### 1. HomeControllerでのカテゴリー取得

**ファイル**: `app/controllers/home_controller.rb`

```ruby
class HomeController < ApplicationController
  def index
    @categories = Category.published.ordered.includes(:lessons)
  end
end
```

**解説:**
- `published`: 公開済みのカテゴリーのみ取得
- `ordered`: 表示順（display_order）でソート
- `includes(:lessons)`: N+1クエリを防止（カテゴリーとレッスンを1回のクエリで取得）

このシンプルな1行で、以下の処理が実現されています：
- 公開制御（publishedスコープ）
- ソート（orderedスコープ）
- パフォーマンス最適化（includes）

#### 2. LessonsControllerでのレッスン表示

**ファイル**: `app/controllers/lessons_controller.rb`

```ruby
class LessonsController < ApplicationController
  def show
    @lesson = Lesson.find(params[:id])
    @lesson_info = @lesson.to_lesson_info
  end
end
```

**解説:**
- `Lesson.find`: ActiveRecordの標準メソッドでレッスンを取得（IDでインデックス検索、高速）
- `to_lesson_info`: JavaScript用のJSON形式に変換するインスタンスメソッド

Day 20以前は`LessonLoader.find_lesson`でYAMLデータを全件検索していましたが、DB化によりO(log n)の高速検索が可能になりました。

#### 3. My::LessonsControllerでの権限管理

**ファイル**: `app/controllers/my/lessons_controller.rb`

```ruby
class My::LessonsController < ApplicationController
  before_action :require_login!

  def index
    @lessons = Lesson.visible_to(current_user).ordered
  end

  def new
    @lesson = current_user.lessons.build
  end

  def create
    @lesson = current_user.lessons.build(lesson_params)
    if @lesson.save
      redirect_to my_lessons_path, notice: "レッスンを作成しました"
    else
      render :new
    end
  end

  private

  def lesson_params
    params.require(:lesson).permit(:category_id, :name, :description, :items, :is_public)
  end
end
```

**解説:**
- `visible_to(current_user)`: ユーザーごとに閲覧可能なレッスンを取得（スコープで権限チェック）
- `current_user.lessons.build`: 現在のユーザーに紐付いたレッスンを作成
- Strong Parameters: 一般ユーザーは`requires_login`や`premium`を編集できない（カテゴリーから継承されるため、パラメータに含まない）

#### 4. 管理者用カテゴリー管理

**ファイル**: `app/controllers/admin/categories_controller.rb`

```ruby
class Admin::CategoriesController < Admin::ApplicationController
  def index
    @categories = Category.ordered.includes(:lessons)
  end

  def create
    @category = Category.new(category_params)
    if @category.save
      redirect_to admin_categories_path, notice: "カテゴリーを作成しました"
    else
      render :new
    end
  end

  def destroy
    @category = Category.find(params[:id])
    if @category.lessons.exists?
      redirect_to admin_categories_path, alert: "レッスンが紐付いているため削除できません"
    else
      @category.destroy
      redirect_to admin_categories_path, notice: "カテゴリーを削除しました"
    end
  end

  private

  def category_params
    params.require(:category).permit(:name, :description, :display_order, :published, :requires_login, :premium)
  end
end
```

**解説:**
- 削除保護機能: レッスンが紐付いている場合は削除不可（データの整合性を保証）
- 管理者のみpublished, requires_login, premiumフラグを編集可能
- Strong Parametersで権限別のパラメータ許可を実装

**使用箇所:**
- `/admin/categories`: カテゴリー一覧（管理者専用）
- `/admin/categories/new`: 新規カテゴリー作成
- `/admin/categories/:id/edit`: カテゴリー編集

---

## 💡 まとめ

### 重要ポイント

- ✅ **Rails wayの重要性**: サービスオブジェクトが不要な場合は、ActiveRecordの標準パターンに回帰する方が保守性が高い
- ✅ **適切な抽象化レベルの選択**: サービスオブジェクトを使うべき時（複雑なビジネスロジック、外部API連携など）と使わない時（単純なデータ変換、CRUD操作）を見極める
- ✅ **delegateパターンのベストプラクティス**: データの冗長性を解消し、単一の真実の源（Single Source of Truth）を確立する
- ✅ **データ移行の段階的アプローチ**: Phase 1（データクリーンアップ）→ Phase 2（スキーマクリーンアップ）→ Phase 3（整合性確保）の3段階で安全に移行
- ✅ **後方互換性の確保**: URLやモデル名を変更する際は、リダイレクトやエイリアスで既存のリンクを保護
- ✅ **用語の統一**: ドメインモデルを明確にし、コードベース全体で一貫した用語を使用することで可読性が向上
- ✅ **段階的な拡張を可能にする設計**: publishedフラグのような柔軟な機能を初期段階で実装することで、将来の拡張が容易に

### 次のステップ

このトピックを理解したら、以下に進むことをお勧めします：

- **データベース設計とマイグレーション戦略**: 外部キー制約、NOT NULL制約、インデックスの効果的な使い方
- **ActiveRecordスコープの効果的な使い方**: 複雑なクエリをスコープに抽象化する技法
- **Concernパターン**: モデル間で共通のロジックを共有する手法
- **テスト駆動開発（TDD）**: リファクタリング時にテストで安全性を確保する方法

---

## 🔗 関連教材

- [データベース設計とマイグレーション戦略](../02_intermediate/04_database_design.md)
- [ActiveRecordスコープの効果的な使い方](../02_intermediate/05_activerecord_scopes.md)
- [レビューテスト: アーキテクチャ改善とリファクタリング](../../reviews/review_10_architecture_refactoring.md)

---

## 📝 演習問題（オプション）

### 問題1: サービスオブジェクトの適切な使い分け

以下のシナリオで、サービスオブジェクトを使うべきか、Railsの標準パターンで十分かを判断してください。

**シナリオA**: ユーザー登録時に、以下の処理を実行する必要があります：
1. Userレコードを作成
2. ウェルカムメールを送信
3. Google Analytics にイベントを送信
4. Slackに通知を送信

**シナリオB**: レッスン一覧を取得する際、以下の条件でフィルタリングする必要があります：
1. 公開済みのカテゴリーのみ
2. ユーザーがログインしている場合は、自分のレッスンも含める
3. 表示順でソート

<details>
<summary>解答例を表示</summary>

**シナリオA: サービスオブジェクトを使うべき**

```ruby
# app/services/user_registration_service.rb
class UserRegistrationService
  def initialize(user_params)
    @user_params = user_params
  end

  def call
    ActiveRecord::Base.transaction do
      @user = User.create!(@user_params)
      send_welcome_email
      track_registration_event
      notify_slack
      @user
    end
  end

  private

  def send_welcome_email
    UserMailer.welcome(@user).deliver_later
  end

  def track_registration_event
    GoogleAnalytics.track_event("user_registration", user_id: @user.id)
  end

  def notify_slack
    SlackNotifier.notify("New user registered: #{@user.email}")
  end
end

# コントローラで使用
UserRegistrationService.new(user_params).call
```

**理由:**
- 複数の外部サービスとの連携が含まれる
- トランザクション管理が必要
- ビジネスロジックが複雑（4つのステップ）
- コントローラに書くと肥大化し、テストが困難

**シナリオB: Railsの標準パターンで十分**

```ruby
# app/models/lesson.rb
scope :visible_to, ->(user) {
  if user&.admin?
    all
  elsif user
    left_joins(:user, :category).where(
      "categories.published = true AND (lessons.user_id = :user_id OR lessons.is_public = true OR users.admin = true)",
      user_id: user.id
    ).distinct
  else
    joins(:category).where(categories: { published: true }, is_public: true)
  end
}

# コントローラで使用
@lessons = Lesson.visible_to(current_user).ordered
```

**理由:**
- データベースクエリのみ（外部サービス連携なし）
- ActiveRecordスコープで十分対応可能
- 再利用可能（複数のコントローラで使える）
- サービスオブジェクトを作ると過剰な抽象化になる

</details>

### 問題2: delegateパターンの実装練習

以下の要件を満たすように、delegateパターンを使ってモデルを設計してください。

**要件:**
- Blogモデル（ブログ）とPostモデル（記事）がある
- Blogには`published`フラグがある（公開/非公開）
- Postは必ずBlogに属する
- PostはBlogの公開状態を継承する（Blogが非公開なら、Postも非公開）
- Postから`blog.published`にアクセスする際、`post.published?`という形で簡潔にアクセスしたい

<details>
<summary>解答例を表示</summary>

```ruby
# app/models/blog.rb
class Blog < ApplicationRecord
  has_many :posts, dependent: :destroy

  validates :title, presence: true

  scope :published, -> { where(published: true) }

  def published?
    published
  end
end

# app/models/post.rb
class Post < ApplicationRecord
  belongs_to :blog

  # Blogの公開状態を継承
  delegate :published?, to: :blog

  validates :title, presence: true
  validates :content, presence: true

  # スコープもBlogの公開状態を参照
  scope :published, -> { joins(:blog).where(blogs: { published: true }) }
end

# 使用例
blog = Blog.create!(title: "My Blog", published: true)
post = blog.posts.create!(title: "First Post", content: "Hello, world!")

post.published?  # => true（blogから継承）

blog.update!(published: false)
post.reload
post.published?  # => false（blogから継承、自動的に非公開に）
```

**解説:**
- `delegate :published?, to: :blog` により、`post.published?`で`post.blog.published?`と同じ結果を得られる
- Postテーブルに`published`カラムを持たないため、データの一貫性が保証される
- Blogの公開状態を変更すれば、そのBlogの全Postに自動的に反映される

</details>

---

**作成日**: 2026-01-02
**難易度**: 🔴
**推定学習時間**: 2〜3時間
