# Review Test #10: アーキテクチャ改善とリファクタリング

**難易度**: 🔴 上級
**推定時間**: 40分〜1時間
**学習トピック**: [アーキテクチャ改善とリファクタリング](../topics/03_advanced/10_architecture_refactoring.md)

---

## 前提条件

あなたはFlexitypeプロジェクトのコードレビュアーです。
以下のPRがレビュー待ちになっています。

## PR概要

- **タイトル**: レッスンシステムのDB化とリファクタリング
- **変更ファイル数**: 25ファイル
- **目的**: YAMLファイルで管理していたレッスンデータをPostgreSQLに移行し、LessonLoaderサービスオブジェクトを削除してRails wayなアーキテクチャに改善する。また、権限フラグの冗長性を解消してデータの一貫性を保証する。

## 変更内容

### 1. `app/services/lesson_loader.rb` (削除)

このファイルは完全に削除されます。以下は削除前のコードです：

```ruby
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

**約150行のコード**

### 2. `app/models/category.rb` (新規作成)

```ruby
class Category < ApplicationRecord
  has_many :lessons, dependent: :destroy

  validates :name, presence: true, length: { maximum: 50 }, uniqueness: true
  validates :description, length: { maximum: 200 }, allow_blank: true

  scope :ordered, -> { order(display_order: :asc) }
  scope :published, -> { where(published: true) }
  scope :free, -> { where(premium: false) }
  scope :available_for_guest, -> { where(requires_login: false) }
end
```

**約15行のコード**

### 3. `app/models/lesson.rb` (新規作成)

```ruby
class Lesson < ApplicationRecord
  belongs_to :user
  belongs_to :category
  has_many :lesson_records, dependent: :destroy

  # カテゴリーの設定を継承
  delegate :requires_login, :premium, to: :category

  validates :name, presence: true, length: { maximum: 100 }
  validates :items, presence: true

  scope :ordered, -> { order(display_order: :asc, id: :asc) }
  scope :official, -> { joins(:user).where(users: { admin: true }) }
  scope :user_created, -> { joins(:user).where.not(users: { admin: true }) }
  scope :published, -> { where(is_public: true) }
  scope :free, -> { joins(:category).where(categories: { premium: false }) }

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

**約40行のコード**

### 4. `app/controllers/home_controller.rb` (既存)

```ruby
# Before
class HomeController < ApplicationController
  def index
    @categories = LessonLoader.categories
  end
end

# After
class HomeController < ApplicationController
  def index
    @categories = Category.published.ordered.includes(:lessons)
  end
end
```

### 5. `app/controllers/lessons_controller.rb` (既存)

```ruby
# Before
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

# After
class LessonsController < ApplicationController
  def show
    @lesson = Lesson.find(params[:id])
    @lesson_info = @lesson.to_lesson_info
  end
end
```

### 6. `db/migrate/YYYYMMDDHHMMSS_remove_permission_flags_from_lessons.rb` (新規作成)

```ruby
class RemovePermissionFlagsFromLessons < ActiveRecord::Migration[8.1]
  def change
    remove_column :lessons, :requires_login, :boolean
    remove_column :lessons, :premium, :boolean
  end
end
```

### 7. `db/migrate/YYYYMMDDHHMMSS_add_published_to_categories.rb` (新規作成)

```ruby
class AddPublishedToCategories < ActiveRecord::Migration[8.1]
  def change
    add_column :categories, :published, :boolean, default: true, null: false
    add_index :categories, :published

    # 既存のカテゴリーは全て公開済みに設定
    Category.update_all(published: true)
  end
end
```

### 8. `lib/tasks/migrate_lessons_from_yaml.rake` (新規作成)

```ruby
namespace :lessons do
  desc "Migrate lessons from YAML to PostgreSQL"
  task migrate_from_yaml: :environment do
    yaml_data = YAML.load_file(Rails.root.join("config", "typing_lessons.yml"))
    official_user = User.find_by(email: "typnix.app@gmail.com")

    if official_user.nil?
      puts "Error: Official user not found"
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

**約30行のコード**

---

## レビュー課題

### Q1. サービスオブジェクト削除の妥当性（初級）🟢

このPRでは、`LessonLoader`サービスオブジェクトを完全に削除しています。

1. LessonLoaderを削除した理由を3つ挙げてください。
2. YAMLファイルからDBに移行することで、どのような利点がありますか？（3つ）
3. Railsのモデルで管理することの利点は何ですか？（2つ）

**回答時間の目安**: 5分

<details>
<summary>解答を表示</summary>

### A1. サービスオブジェクト削除の妥当性

**1. LessonLoaderを削除した理由:**

1. **YAMLデータ変換という目的が消滅**: DB化により、YAMLファイルから読み込んでRubyのハッシュに変換する必要がなくなった
2. **Rails wayに回帰**: ActiveRecordの標準パターン（モデル、スコープ）で十分対応できるため、独自の抽象化レイヤーが不要
3. **責務の曖昧さ**: データ読み込み、変換、検索、カテゴリー取得など、複数の責務が混在しており、単一責任の原則に反していた

**2. YAMLファイルからDBに移行する利点:**

1. **動的なデータ作成**: ユーザーがWebフォームから直接レッスンを作成・編集できるようになる
2. **パフォーマンス向上**: データベースのインデックスにより、レッスン検索が高速化（O(n) → O(log n)）
3. **データの永続性とトランザクション**: データベースにより、データの整合性が保証され、トランザクション管理が可能

**3. Railsのモデルで管理する利点:**

1. **標準パターンの活用**: ActiveRecordのバリデーション、アソシエーション、スコープなど、強力な機能をそのまま使える
2. **ツールのサポート**: RuboCop、Bullet、N+1クエリ検出ツールなど、Rails標準パターンに対応したツールが使える

</details>

---

### Q2. delegateパターンの理解（中級）🟡

このPRでは、Lessonモデルから`requires_login`と`premium`カラムを削除し、Categoryから継承する設計に変更しています。

1. Lessonモデルとカテゴリーモデルで権限フラグが重複していた場合、どのような問題が発生しますか？（3つ）
2. `delegate :requires_login, :premium, to: :category`のコードは何をしていますか？
3. この変更によるコード削減効果、またはデータの一貫性への影響を説明してください。

**回答時間の目安**: 10分

<details>
<summary>解答を表示</summary>

### A2. delegateパターンの理解

**1. 権限フラグが重複している場合の問題:**

1. **データの矛盾**: カテゴリーが`requires_login: true`なのに、レッスンが`requires_login: false`の場合、どちらを優先すべきか不明確
2. **更新の手間**: カテゴリーの権限設定を変更する際、そのカテゴリーに属する全レッスンも手動で更新する必要がある
3. **不正アクセスの可能性**: カテゴリーは有料だが、レッスンが無料として登録されている場合、URL直打ちで`/lessons/:id`にアクセスすると無料で閲覧できてしまう

**2. `delegate :requires_login, :premium, to: :category`の動作:**

このコードは、Lessonオブジェクトに`requires_login`と`premium`メソッドを定義し、内部で`category.requires_login`と`category.premium`を呼び出すようにします。

```ruby
# delegateを使用しない場合
lesson = Lesson.first
lesson.category.requires_login  # カテゴリー経由でアクセス

# delegateを使用した場合
lesson = Lesson.first
lesson.requires_login  # Lessonオブジェクトに直接アクセス（内部でcategory.requires_loginを呼び出す）
```

**3. コード削減効果とデータの一貫性:**

**コード削減効果:**
- Lessonテーブルから2つのカラム（`requires_login`, `premium`）を削除
- Strong Parametersからこれらのフィールドを削除（My::LessonsController）
- レッスン管理フォームから権限フィールドのUIを削除

**データの一貫性への影響:**
- **単一の真実の源（Single Source of Truth）**: 権限フラグがカテゴリーに一元化され、データの矛盾が発生しない
- **自動反映**: カテゴリーの権限設定を変更すれば、そのカテゴリーの全レッスンに自動的に反映される
- **不正アクセスの防止**: レッスン単体で権限を設定できないため、URL直打ちでの不正アクセスが防止される

</details>

---

### Q3. publishedフラグの設計判断（中級〜上級）🟡🔴

このPRでは、Categoryテーブルに`published`フラグを追加しています。

1. なぜ`published`フラグが必要なのか、具体的なユースケースを2つ挙げてください。
2. マイグレーションで`default: true, null: false`と設定し、さらに`Category.update_all(published: true)`を実行している理由は何ですか？
3. `scope :published, -> { where(published: true) }`を定義することで、どのような利点がありますか？

**回答時間の目安**: 15分

<details>
<summary>解答を表示</summary>

### A3. publishedフラグの設計判断

**1. publishedフラグの必要性（ユースケース）:**

**ユースケース1: 段階的なコンテンツ準備**
- 新規カテゴリーを作成した直後は`published: false`に設定
- レッスンを複数追加して充実させる
- 準備ができたら`published: true`に変更して公開
- **メリット**: 準備中のカテゴリーがユーザーに表示されず、「レッスンがありません」という未完成の印象を与えない

**ユースケース2: 緊急時の対応**
- 問題が発生したカテゴリー（例: レッスンデータのバグ、著作権問題）を即座に非公開にできる
- カテゴリー自体を削除せずに一時的に非表示にし、修正後に再公開できる
- **メリット**: データを保持したまま柔軟に公開制御が可能

**2. `default: true, null: false`と`update_all(published: true)`の理由:**

**`default: true, null: false`:**
- **デフォルトで公開**: 既存のカテゴリー（すでにレッスンが充実しているもの）は公開状態であるべき
- **null不許可**: `published`カラムは常に`true`または`false`のいずれかであるべきで、`nil`（不明）は許容しない

**`Category.update_all(published: true)`:**
- マイグレーション実行時に既存のカテゴリーが存在する場合、自動的に`published: true`に設定
- これにより、既存カテゴリーが非公開になってしまう（ユーザーに表示されなくなる）事故を防ぐ
- **重要**: マイグレーションはスキーマ変更だけでなく、データの初期化も担当する

**3. `scope :published`の利点:**

```ruby
# スコープの定義
scope :published, -> { where(published: true) }

# コントローラで使用
@categories = Category.published.ordered.includes(:lessons)
```

**利点:**

**再利用性:**
- 複数のコントローラで`Category.published`というシンプルなコードで公開済みカテゴリーを取得できる
- コードの重複を防ぐ（DRY原則）

**可読性:**
- `Category.where(published: true)`よりも`Category.published`の方が意図が明確
- ビジネスロジック（「公開済みのカテゴリー」）をドメイン言語で表現

**メソッドチェーン:**
- スコープは他のスコープと組み合わせ可能
- 例: `Category.published.ordered.free` → 公開済み、表示順、無料カテゴリー

**テスタビリティ:**
- スコープ単体でテスト可能
- 例: `expect(Category.published.count).to eq(5)`

**コード削減効果:**
- スコープを使わない場合: 各コントローラで`where(published: true)`を記述（重複）
- スコープを使う場合: 1箇所で定義、複数箇所で再利用
- **純削減**: 約10行（重複するwhere句の削減）

</details>

---

### Q4. Rails wayとサービスオブジェクトの境界（上級）🔴

このPRでは、LessonLoaderサービスオブジェクトを削除し、Rails wayに回帰しています。しかし、サービスオブジェクトが常に悪いわけではありません。

1. サービスオブジェクトを使うべき時と使わない時の判断基準を、具体例を挙げて説明してください。
2. LessonLoaderのようなサービスオブジェクトを残すことで発生する問題点を3つ挙げてください。
3. 将来的にTypnixプロジェクトでサービスオブジェクトを導入すべきシナリオを1つ提案してください。

**回答時間の目安**: 15分

<details>
<summary>解答を表示</summary>

### A4. Rails wayとサービスオブジェクトの境界

#### 1. サービスオブジェクトを使うべき時と使わない時の判断基準

**サービスオブジェクトを使うべき時:**

**基準1: 複雑なビジネスロジックが複数のモデルにまたがる**

```ruby
# 例: ユーザー登録時の処理
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
      create_default_keymap
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

  def create_default_keymap
    @user.keymap_sets.create!(name: "デフォルトキーマップ", is_public: false)
  end
end
```

**理由:**
- 複数の外部サービス（メール送信、GA、Slack）との連携
- トランザクション管理が必要
- ビジネスロジックが複雑で、コントローラやモデルに書くと肥大化
- 1つの「登録」という概念を表現するのに適切

**基準2: 外部API連携や複雑なデータ変換**

```ruby
# 例: Google Analytics APIからデータを取得し、加工する
class AnalyticsReportService
  def initialize(start_date, end_date)
    @start_date = start_date
    @end_date = end_date
  end

  def call
    raw_data = fetch_from_google_analytics
    transform_data(raw_data)
  end

  private

  def fetch_from_google_analytics
    # Google Analytics APIを呼び出し
  end

  def transform_data(raw_data)
    # データを加工してグラフ用のフォーマットに変換
  end
end
```

**理由:**
- 外部APIとの連携ロジックをモデルに書くと責務が曖昧
- データ変換ロジックが複雑で、コントローラに書くと可読性が低下

**サービスオブジェクトを使わない時:**

**基準1: 単純なCRUD操作**

```ruby
# 悪い例（過剰な抽象化）
class LessonCreationService
  def initialize(user, lesson_params)
    @user = user
    @lesson_params = lesson_params
  end

  def call
    @user.lessons.create(@lesson_params)
  end
end

# 良い例（Rails標準パターン）
# コントローラで直接
@lesson = current_user.lessons.create(lesson_params)
```

**理由:**
- ActiveRecordのcreateメソッドで十分対応可能
- サービスオブジェクトを作ると過剰な抽象化になる

**基準2: データベースクエリのみ**

```ruby
# 悪い例（LessonLoaderのようなパターン）
class LessonFinder
  def self.find_visible_to(user)
    if user&.admin?
      Lesson.all
    else
      Lesson.where(user: user).or(Lesson.where(is_public: true))
    end
  end
end

# 良い例（スコープで対応）
# app/models/lesson.rb
scope :visible_to, ->(user) {
  if user&.admin?
    all
  else
    where(user: user).or(where(is_public: true))
  end
}

# コントローラで使用
@lessons = Lesson.visible_to(current_user)
```

**理由:**
- ActiveRecordスコープで十分対応可能
- スコープはメソッドチェーン可能で、再利用性が高い
- サービスオブジェクトを作ると、Railsの標準パターンから逸脱する

#### 2. LessonLoaderのようなサービスオブジェクトを残すことで発生する問題点

**問題点1: Rails wayからの逸脱**

- LessonLoaderは独自の抽象化レイヤーを作成しており、ActiveRecordの標準パターンを使っていない
- 新規開発者がコードベースを理解する際、「なぜLessonモデルではなくLessonLoaderを使うのか？」という疑問が生じる
- Railsのツール（Bullet、N+1クエリ検出ツールなど）が効果的に機能しない可能性

**問題点2: 責務の曖昧さ**

- LessonLoaderは以下の複数の責務を持っていた：
  - YAMLファイルの読み込み
  - データ変換（YAMLからRubyのハッシュへ）
  - レッスン検索（find_lesson）
  - カテゴリー一覧取得（categories）
- 単一責任の原則に反しており、どこに何を書くべきか判断しづらい

**問題点3: パフォーマンス問題**

- `find_lesson`メソッドは全レッスンを読み込んでから`find`で検索（O(n)の計算量）
- データベースのインデックスを活用できず、レッスン数が増えるとパフォーマンスが低下
- ActiveRecordの`find`メソッドならO(log n)で検索可能

#### 3. 将来的にTypnixプロジェクトでサービスオブジェクトを導入すべきシナリオ

**シナリオ: レッスン成績分析サービス**

```ruby
# app/services/lesson_performance_analyzer.rb
class LessonPerformanceAnalyzer
  def initialize(user, period: :all_time)
    @user = user
    @period = period
  end

  def call
    {
      total_lessons: total_lessons,
      average_accuracy: average_accuracy,
      average_wpm: average_wpm,
      grade_distribution: grade_distribution,
      improvement_rate: improvement_rate,
      weak_lessons: weak_lessons,
      strong_lessons: strong_lessons
    }
  end

  private

  def lesson_records
    @lesson_records ||= case @period
    when :last_week
      @user.lesson_records.where("completed_at >= ?", 1.week.ago)
    when :last_month
      @user.lesson_records.where("completed_at >= ?", 1.month.ago)
    else
      @user.lesson_records
    end
  end

  def total_lessons
    lesson_records.count
  end

  def average_accuracy
    lesson_records.average(:accuracy)&.round(1) || 0
  end

  def average_wpm
    lesson_records.map(&:wpm).sum / lesson_records.count.to_f
  end

  def grade_distribution
    lesson_records.group_by(&:grade).transform_values(&:count)
  end

  def improvement_rate
    # 直近10件と過去10件の平均WPMを比較し、改善率を計算
    recent = lesson_records.order(completed_at: :desc).limit(10).map(&:wpm).sum / 10.0
    old = lesson_records.order(completed_at: :asc).limit(10).map(&:wpm).sum / 10.0
    ((recent - old) / old * 100).round(1)
  end

  def weak_lessons
    # 正答率が低いレッスンTOP 5
    lesson_records.group(:lesson_id).average(:accuracy).sort_by { |_id, avg| avg }.first(5)
  end

  def strong_lessons
    # 正答率が高いレッスンTOP 5
    lesson_records.group(:lesson_id).average(:accuracy).sort_by { |_id, avg| -avg }.first(5)
  end
end

# コントローラで使用
class My::AnalyticsController < ApplicationController
  def index
    @performance = LessonPerformanceAnalyzer.new(current_user, period: params[:period]).call
  end
end
```

**理由:**

**複雑な集計ロジック:**
- 複数の統計計算（平均、グループ化、ソート）を組み合わせる
- モデルに書くと肥大化し、責務が曖昧になる

**ビジネスロジックの明確化:**
- 「成績分析」という1つのビジネス概念を表現
- コントローラやモデルに書くよりも、サービスオブジェクトとして独立させる方が意図が明確

**テスタビリティ:**
- サービスオブジェクト単体でテスト可能
- モックやスタブを使いやすい

**再利用性:**
- 複数のコントローラ（ダッシュボード、統計ページなど）で同じ分析ロジックを使える

#### まとめ

LessonLoaderは、YAMLデータ変換という目的が消滅した時点で不要になりました。一方、複雑なビジネスロジックや外部API連携、集計処理など、明確な責務を持つサービスオブジェクトは、Railsプロジェクトにおいて有効です。重要なのは、「Rails wayで対応できるか？」を常に問い、安易にサービスオブジェクトを作らないことです。

</details>

---

## 総合評価

### 基準

- **Q1を正解**: サービスオブジェクト削除の基本的な理由を理解している（初級レベル）
- **Q2を正解**: delegateパターンとデータの一貫性の重要性を理解している（中級レベル）
- **Q3を正解**: publishedフラグのような機能追加の設計判断を理解している（中級〜上級レベル）
- **Q4を正解**: Rails wayとサービスオブジェクトの適切な使い分けを理解している（上級レベル）

### 次のステップ

- **Q1のみ正解**: サービスオブジェクトの基本概念は理解していますが、delegateパターンやRails wayの深い理解が必要です。トピック10を再読し、実際のコードで練習してみましょう。
- **Q1-Q2正解**: delegateパターンとデータの一貫性を理解していますが、設計判断（publishedフラグなど）の経験が必要です。実際のプロジェクトで権限管理やフラグ設計を実践してみましょう。
- **Q1-Q3正解**: アーキテクチャの基本は理解していますが、Rails wayとサービスオブジェクトの境界についてさらに深く学ぶと良いでしょう。RailsガイドやDHHのブログを読むことをお勧めします。
- **全問正解**: アーキテクチャ改善とリファクタリングの本質を理解しています！次は、実際のプロジェクトで大規模リファクタリングを計画・実行してみましょう。パフォーマンス最適化やCI/CD統合にも挑戦してみてください。

## 参考資料

- [アーキテクチャ改善とリファクタリング](../topics/03_advanced/10_architecture_refactoring.md)
- [データベース設計とマイグレーション戦略](../topics/02_intermediate/04_database_design.md)
- Day 20 の日報: `docs/daily_reports/2025-12-20.md`
- Day 21 の日報: `docs/daily_reports/2025-12-21.md`
- 実際のPR: #64 (practice/session → lesson/lesson_record), #65 (lesson DB migration), #66 (category management)

---

**作成日**: 2026-01-02
**難易度**: 🔴
**推定時間**: 40分〜1時間
