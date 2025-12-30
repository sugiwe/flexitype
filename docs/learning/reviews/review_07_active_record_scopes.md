# レビューテスト: ActiveRecordスコープ

**対象教材**: [07_active_record_scopes.md](../topics/02_intermediate/07_active_record_scopes.md)
**難易度**: 🟡 中級
**推定時間**: 45〜60分

---

## 📝 テスト形式

以下のPRレビューコメントを読んで、問題点を指摘し、修正案を提示してください。
難易度は4段階（🟢→🟡→🟡🔴→🔴）で徐々に上がります。

---

## 問題1: コントローラーの権限判定ロジック（初級）🟢

### PR内容

**タイトル**: レッスン一覧ページの権限制御を実装

**説明**: レッスン一覧ページで、ユーザーの権限に応じて表示するレッスンを制御するようにしました。

**変更内容**:

```ruby
# app/controllers/lessons_controller.rb
class LessonsController < ApplicationController
  def index
    if logged_in?
      if current_user.premium?
        # プレミアムユーザー: 全て表示
        @lessons = Lesson.all
      else
        # 一般ユーザー: 公開レッスン + 自分のレッスン
        @lessons = Lesson.where(is_public: true)
                         .or(Lesson.where(user_id: current_user.id))
      end
    else
      # 未ログインユーザー: 公開のみ
      @lessons = Lesson.where(is_public: true)
    end

    @lessons = @lessons.order(created_at: :desc)
  end

  def search
    query = params[:q]

    if logged_in?
      if current_user.premium?
        @lessons = Lesson.where("name LIKE ?", "%#{query}%")
      else
        @lessons = Lesson.where(is_public: true)
                         .or(Lesson.where(user_id: current_user.id))
                         .where("name LIKE ?", "%#{query}%")
      end
    else
      @lessons = Lesson.where(is_public: true)
                       .where("name LIKE ?", "%#{query}%")
    end
  end

  def popular
    if logged_in?
      if current_user.premium?
        @lessons = Lesson.all
      else
        @lessons = Lesson.where(is_public: true)
                         .or(Lesson.where(user_id: current_user.id))
      end
    else
      @lessons = Lesson.where(is_public: true)
    end

    @lessons = @lessons.joins(:lesson_records)
                       .group(:id)
                       .order("COUNT(lesson_records.id) DESC")
                       .limit(10)
  end
end
```

### 質問

**Q1-1**: このコントローラーの権限判定ロジックの問題点を3つ挙げてください。

**Q1-2**: 同じ権限判定を他のアクション（`show`, `category` など）でも使いたい場合、どうなりますか？

**Q1-3**: DRY原則の観点から、どのように改善すべきですか？

<details>
<summary>解答例を表示</summary>

### Q1-1: 問題点

1. **DRY原則違反**: 同じ権限判定ロジックが3つのアクション（`index`, `search`, `popular`）に重複している
2. **保守性が低い**: 権限ロジックを変更する際、全てのアクションを修正する必要がある
3. **テストが困難**: 各アクションで権限判定をテストする必要があり、テストコードも重複する

### Q1-2: 他のアクションでも使う場合

さらにコードが増え、保守性が悪化します。例えば、権限ロジックを変更する場合:

- 変更前: 3アクション × 約10行 = 30行の修正
- 新規アクション追加: さらに10行の重複コード

### Q1-3: 改善案

**Lessonモデルに`visible_to`スコープを定義:**

```ruby
# app/models/lesson.rb
class Lesson < ApplicationRecord
  scope :visible_to, ->(user) {
    if user&.premium?
      all
    elsif user
      where(is_public: true).or(where(user_id: user.id))
    else
      where(is_public: true)
    end
  }
end
```

**コントローラーをシンプルに:**

```ruby
# app/controllers/lessons_controller.rb
class LessonsController < ApplicationController
  def index
    @lessons = Lesson.visible_to(current_user).order(created_at: :desc)
  end

  def search
    @lessons = Lesson.visible_to(current_user)
                     .where("name LIKE ?", "%#{params[:q]}%")
  end

  def popular
    @lessons = Lesson.visible_to(current_user)
                     .joins(:lesson_records)
                     .group(:id)
                     .order("COUNT(lesson_records.id) DESC")
                     .limit(10)
  end
end
```

**コード削減効果:**

- Before: 約60行（3アクション × 約20行）
- After: 約15行（3アクション × 1行 + スコープ定義12行）
- **削減率**: 75%

</details>

---

## 問題2: N+1クエリ問題（中級）🟡

### PR内容

**タイトル**: 管理者ダッシュボードに最新の練習履歴を表示

**説明**: 管理者ダッシュボードに、全ユーザーの最新10件の練習履歴を表示するようにしました。

**変更内容**:

```ruby
# app/controllers/admin/dashboard_controller.rb
class Admin::DashboardController < Admin::ApplicationController
  def index
    @recent_records = LessonRecord.order(completed_at: :desc).limit(10)
  end
end
```

```slim
/ app/views/admin/dashboard/index.html.slim
h2 最新の練習履歴

table
  thead
    tr
      th ユーザー
      th レッスン
      th カテゴリー
      th 正答率
      th 所要時間
  tbody
    - @recent_records.each do |record|
      tr
        td = record.user.name
        td = record.lesson.name
        td = record.lesson.category.name
        td = "#{record.accuracy}%"
        td = "#{record.duration_seconds}秒"
```

**動作確認結果**:
- ダッシュボードが正常に表示される ✅
- ただし、ログを見ると大量のSQLが発行されている ❌

**ログ（抜粋）:**

```
LessonRecord Load (0.5ms)  SELECT "lesson_records".* FROM "lesson_records" ORDER BY "completed_at" DESC LIMIT 10
User Load (0.3ms)  SELECT "users".* FROM "users" WHERE "users"."id" = 1
Lesson Load (0.2ms)  SELECT "lessons".* FROM "lessons" WHERE "lessons"."id" = 5
Category Load (0.2ms)  SELECT "categories".* FROM "categories" WHERE "categories"."id" = 2
User Load (0.3ms)  SELECT "users".* FROM "users" WHERE "users"."id" = 2
Lesson Load (0.2ms)  SELECT "lessons".* FROM "lessons" WHERE "lessons"."id" = 3
Category Load (0.2ms)  SELECT "categories".* FROM "categories" WHERE "categories"."id" = 1
User Load (0.3ms)  SELECT "users".* FROM "users" WHERE "users"."id" = 1
Lesson Load (0.2ms)  SELECT "lessons".* FROM "lessons" WHERE "lessons"."id" = 8
Category Load (0.2ms)  SELECT "categories".* FROM "categories" WHERE "categories"."id" = 3
...（さらに続く）
```

### 質問

**Q2-1**: N+1クエリ問題とは何ですか？このコードのどこで発生していますか？

**Q2-2**: 実際に実行されているSQLは何回ですか？内訳を説明してください。

**Q2-3**: `includes`を使って解決してください。コードと実行されるSQLを示してください。

**Q2-4**: もし練習履歴が100件だった場合、SQLは何回実行されますか？（修正前/修正後）

<details>
<summary>解答例を表示</summary>

### Q2-1: N+1クエリ問題とは

**N+1クエリ問題:**

親レコード（LessonRecord）を取得するために1回のSQLを実行し、その後、各親レコードに対して関連レコード（User, Lesson, Category）を取得するために追加のSQLを実行してしまう問題。

**このコードでの発生箇所:**

```slim
- @recent_records.each do |record|
  tr
    td = record.user.name           ← ここでUser取得のSQLが実行される（N回）
    td = record.lesson.name         ← ここでLesson取得のSQLが実行される（N回）
    td = record.lesson.category.name ← ここでCategory取得のSQLが実行される（N回）
```

### Q2-2: 実行されるSQLの回数

**10件のレコードの場合:**

1. LessonRecord取得: 1回
2. User取得: 10回（各レコードごと）
3. Lesson取得: 10回（各レコードごと）
4. Category取得: 10回（各レコードごと）

**合計: 31回**（1 + 10 + 10 + 10）

**内訳:**

```
1回目: SELECT "lesson_records".* FROM "lesson_records" ORDER BY "completed_at" DESC LIMIT 10

2〜11回目: SELECT "users".* FROM "users" WHERE "users"."id" = ?  （10回）
12〜21回目: SELECT "lessons".* FROM "lessons" WHERE "lessons"."id" = ?  （10回）
22〜31回目: SELECT "categories".* FROM "categories" WHERE "categories"."id" = ?  （10回）
```

### Q2-3: `includes`による解決

**修正後のコード:**

```ruby
# app/controllers/admin/dashboard_controller.rb
class Admin::DashboardController < Admin::ApplicationController
  def index
    # includes で関連レコードを一括取得
    @recent_records = LessonRecord.order(completed_at: :desc)
                                  .includes(:user, lesson: :category)
                                  .limit(10)
    #                              ^^^^^^^^^^^^^^^^^^^^^^^^^^
    #                              user, lesson, category を一括取得
  end
end
```

**実行されるSQL（3〜4回）:**

```sql
-- 1. LessonRecordを取得
SELECT "lesson_records".* FROM "lesson_records" ORDER BY "completed_at" DESC LIMIT 10

-- 2. 関連するUser全てを一括取得
SELECT "users".* FROM "users" WHERE "users"."id" IN (1, 2, 3)

-- 3. 関連するLesson全てを一括取得
SELECT "lessons".* FROM "lessons" WHERE "lessons"."id" IN (5, 3, 8, 2)

-- 4. 関連するCategory全てを一括取得
SELECT "categories".* FROM "categories" WHERE "categories"."id" IN (1, 2, 3)
```

**合計: 3〜4回**（N+1解消）

### Q2-4: 100件の場合

**修正前（N+1発生）:**

- LessonRecord: 1回
- User: 100回
- Lesson: 100回
- Category: 100回
- **合計: 301回**

**修正後（includes使用）:**

- LessonRecord: 1回
- User: 1回（IN句で一括取得）
- Lesson: 1回（IN句で一括取得）
- Category: 1回（IN句で一括取得）
- **合計: 4回**

**削減率: 98.7%**（301回 → 4回）

</details>

---

## 問題3: `includes` と `joins` の違い（中級〜上級）🟡🔴

### PR内容

**タイトル**: 公開カテゴリーのレッスン一覧を表示

**説明**: 公開カテゴリー（`published: true`）のレッスンのみを一覧表示するようにしました。

**変更内容（パターンA）:**

```ruby
# app/controllers/lessons_controller.rb
class LessonsController < ApplicationController
  def index
    @lessons = Lesson.includes(:category)
                     .where(categories: { published: true })
                     .limit(20)
  end
end
```

**動作確認結果**:
- エラーが発生 ❌

```
ActiveRecord::StatementInvalid: PG::UndefinedTable: ERROR:  missing FROM-clause entry for table "categories"
```

**変更内容（パターンB）:**

```ruby
# app/controllers/lessons_controller.rb
class LessonsController < ApplicationController
  def index
    @lessons = Lesson.joins(:category)
                     .where(categories: { published: true })
                     .limit(20)
  end
end
```

```slim
/ app/views/lessons/index.html.slim
- @lessons.each do |lesson|
  .lesson
    h3 = lesson.name
    p カテゴリー: #{lesson.category.name}
    p 作成者: #{lesson.user.name}
```

**動作確認結果**:
- 公開カテゴリーのレッスンのみ表示される ✅
- ただし、ログを見るとN+1クエリが発生している ❌

```
Lesson Load (0.8ms)  SELECT "lessons".* FROM "lessons"
  INNER JOIN "categories" ON "categories"."id" = "lessons"."category_id"
  WHERE "categories"."published" = true LIMIT 20

Category Load (0.2ms)  SELECT "categories".* FROM "categories" WHERE "categories"."id" = 1
User Load (0.3ms)  SELECT "users".* FROM "users" WHERE "users"."id" = 5
Category Load (0.2ms)  SELECT "categories".* FROM "categories" WHERE "categories"."id" = 2
User Load (0.3ms)  SELECT "users".* FROM "users" WHERE "users"."id" = 3
...（続く）
```

### 質問

**Q3-1**: パターンAでエラーが発生した理由を説明してください。

**Q3-2**: `includes` と `joins` の違いを説明してください。

**Q3-3**: パターンBのN+1クエリを解決してください。`joins` と `includes` を組み合わせて使用してください。

**Q3-4**: 実際のFlexitype（Day 20-21）では、この問題がどのように解決されましたか？

<details>
<summary>解答例を表示</summary>

### Q3-1: パターンAのエラー理由

**原因:**

`includes`は**外部結合（LEFT OUTER JOIN）**を使って関連レコードをメモリにロードしますが、**WHERE句で関連テーブルのカラムを直接参照できない**という制約があります。

**詳細:**

```ruby
# ❌ エラーが発生
Lesson.includes(:category).where(categories: { published: true })

# includesが生成するSQL（概念的には以下のようなイメージ）
# SELECT "lessons".* FROM "lessons"  ← categoriesテーブルがFROM句にない
# WHERE "categories"."published" = true  ← エラー: categoriesテーブルが参照できない
```

`includes`は関連レコードを**後から別のSQLで取得**するため、WHERE句で関連テーブルのカラムを使えません。

### Q3-2: `includes` と `joins` の違い

#### `includes`: 外部結合 + メモリロード

```ruby
@lessons = Lesson.includes(:category)
```

**特徴:**

- 関連レコードをメモリにロード（Eager Loading）
- N+1クエリ対策に使う
- WHERE句で関連テーブルのカラムを参照できない
- 関連レコードがなくても親レコードは取得される（LEFT JOIN）

**実行されるSQL:**

```sql
-- 1. Lessonを取得
SELECT "lessons".* FROM "lessons"

-- 2. 関連するCategoryを一括取得
SELECT "categories".* FROM "categories" WHERE "categories"."id" IN (1, 2, 3)
```

#### `joins`: 内部結合（INNER JOIN）

```ruby
@lessons = Lesson.joins(:category)
```

**特徴:**

- SQLの結合のみ（メモリにはロードしない）
- WHERE条件で関連テーブルのカラムを参照できる
- 関連レコードがない親レコードは除外される（INNER JOIN）
- N+1クエリ対策にはならない

**実行されるSQL:**

```sql
-- 1回のSQL（結合のみ）
SELECT "lessons".* FROM "lessons"
INNER JOIN "categories" ON "categories"."id" = "lessons"."category_id"
```

### Q3-3: `joins` + `includes` による解決

**修正後のコード:**

```ruby
# app/controllers/lessons_controller.rb
class LessonsController < ApplicationController
  def index
    @lessons = Lesson.joins(:category)                           # 絞り込み用
                     .where(categories: { published: true })     # 公開カテゴリーのみ
                     .includes(:category, :user)                 # N+1対策
                     .limit(20)
  end
end
```

**実行されるSQL（3回）:**

```sql
-- 1. joinsで絞り込み
SELECT "lessons".* FROM "lessons"
INNER JOIN "categories" ON "categories"."id" = "lessons"."category_id"
WHERE "categories"."published" = true
LIMIT 20

-- 2. includesでCategoryを一括取得
SELECT "categories".* FROM "categories" WHERE "categories"."id" IN (1, 2, 3)

-- 3. includesでUserを一括取得
SELECT "users".* FROM "users" WHERE "users"."id" IN (5, 3, 8)
```

**ポイント:**

1. `joins(:category)`: WHERE条件で絞り込むために使用
2. `where(categories: { published: true })`: 公開カテゴリーのみ取得
3. `includes(:category, :user)`: N+1対策で関連レコードを一括取得

### Q3-4: Flexitypeでの実例

**Day 20の管理者ダッシュボード:**

```ruby
# app/controllers/admin/dashboard_controller.rb
class Admin::DashboardController < Admin::ApplicationController
  def index
    # 最新10件の練習履歴（N+1対策済み）
    @recent_records = LessonRecord.order(completed_at: :desc)
                                  .includes(:user, lesson: :category)
                                  .limit(10)
    #                              ^^^^^^^^^^^^^^^^^^^^^^^^^^
    #                              user, lesson, lesson.category を一括取得

    # 人気レッスンランキング
    @popular_lessons = LessonRecord
      .where.not(lesson_id: nil)                    # lesson_idがnilでないもの
      .group(:lesson_id, :lesson_name)              # グループ化
      .select("lesson_id, lesson_name, COUNT(*) as lesson_count, AVG(accuracy) as avg_accuracy")
      .order("lesson_count DESC")
      .limit(10)
  end
end
```

**Day 21のLessonモデル:**

```ruby
# app/models/lesson.rb
class Lesson < ApplicationRecord
  # joinsを使った絞り込みスコープ
  scope :official, -> { joins(:user).where(users: { admin: true }) }
  scope :free, -> { joins(:category).where(categories: { premium: false }) }
  scope :premium, -> { joins(:category).where(categories: { premium: true }) }

  # 権限管理スコープ（joins + includes併用の例）
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
end
```

</details>

---

## 問題4: スコープのチェーンと複雑なクエリ（上級）🔴

### PR内容

**タイトル**: 練習履歴の高度なフィルター機能を実装

**説明**: 練習履歴ページに、期間・正答率・グレードによる複数のフィルター機能を追加しました。

**変更内容（パターンA）:**

```ruby
# app/models/lesson_record.rb
class LessonRecord < ApplicationRecord
  # スコープ定義
  scope :recent, -> { order(completed_at: :desc) }
  scope :high_accuracy, -> { where("accuracy >= ?", 90) }
  scope :this_week, -> { where("completed_at >= ?", 1.week.ago) }
  scope :this_month, -> { where("completed_at >= ?", 1.month.ago) }

  # 複合スコープ
  scope :excellent_this_week, -> { recent.high_accuracy.this_week }
end
```

```ruby
# app/controllers/my/history_controller.rb
class My::HistoryController < My::ApplicationController
  def index
    @period = params[:period] || "all"
    @min_accuracy = params[:min_accuracy]&.to_i || 0
    @grade = params[:grade]

    # 複雑な条件分岐
    @lesson_records = current_user.lesson_records

    if @period == "week"
      @lesson_records = @lesson_records.where("completed_at >= ?", 1.week.ago)
    elsif @period == "month"
      @lesson_records = @lesson_records.where("completed_at >= ?", 1.month.ago)
    end

    if @min_accuracy > 0
      @lesson_records = @lesson_records.where("accuracy >= ?", @min_accuracy)
    end

    if @grade.present?
      @lesson_records = @lesson_records.where(grade: @grade)
    end

    @lesson_records = @lesson_records.order(completed_at: :desc).page(params[:page])
  end
end
```

**動作確認結果**:
- フィルター機能は正常に動作する ✅
- ただし、コードが冗長で読みにくい ❌

### 質問

**Q4-1**: このコントローラーの問題点を2つ挙げてください。

**Q4-2**: スコープを活用してコントローラーをリファクタリングしてください。以下のスコープを追加定義してください：
   - `by_period(period)`: 期間フィルター（"week", "month", "all"）
   - `min_accuracy(accuracy)`: 最小正答率フィルター
   - `by_grade(grade)`: グレードフィルター

**Q4-3**: リファクタリング後のコントローラーを書いてください。

**Q4-4**: スコープではなく通常のクラスメソッドを使うべきケースを説明してください。

<details>
<summary>解答例を表示</summary>

### Q4-1: 問題点

1. **コントローラーにビジネスロジックが多すぎる**: 期間・正答率・グレードのフィルタリングロジックがコントローラーに散在
2. **テストが困難**: コントローラーの統合テストでしかフィルター機能をテストできない（モデル単体でのテストが難しい）

### Q4-2: スコープの追加定義

```ruby
# app/models/lesson_record.rb
class LessonRecord < ApplicationRecord
  # 既存のスコープ
  scope :recent, -> { order(completed_at: :desc) }
  scope :high_accuracy, -> { where("accuracy >= ?", 90) }
  scope :this_week, -> { where("completed_at >= ?", 1.week.ago) }
  scope :this_month, -> { where("completed_at >= ?", 1.month.ago) }

  # 新規スコープ（引数付き）
  scope :by_period, ->(period) {
    case period&.to_s
    when "week"
      this_week
    when "month"
      this_month
    else
      all  # "all"またはnil → 全期間
    end
  }

  scope :min_accuracy, ->(accuracy) {
    return all if accuracy.blank? || accuracy.to_i <= 0
    where("accuracy >= ?", accuracy.to_i)
  }

  scope :by_grade, ->(grade) {
    return all if grade.blank?
    where(grade: grade)
  }
end
```

**ポイント:**

- `by_period`: 期間文字列を受け取り、既存のスコープ（`this_week`, `this_month`）を再利用
- `min_accuracy`: nilや0以下の場合は`all`を返す（フィルタリングなし）
- `by_grade`: nilや空文字の場合は`all`を返す

### Q4-3: リファクタリング後のコントローラー

```ruby
# app/controllers/my/history_controller.rb
class My::HistoryController < My::ApplicationController
  def index
    # パラメータ取得
    @period = params[:period] || "all"
    @min_accuracy = params[:min_accuracy]
    @grade = params[:grade]

    # スコープチェーンで柔軟にフィルタリング
    @lesson_records = current_user.lesson_records
                                  .by_period(@period)
                                  .min_accuracy(@min_accuracy)
                                  .by_grade(@grade)
                                  .recent
                                  .includes(:lesson, :user)  # N+1対策
                                  .page(params[:page])
  end
end
```

**コード削減効果:**

- Before: 約25行（if文による条件分岐）
- After: 約8行（スコープチェーン）
- **削減率**: 68%

**メリット:**

1. **可読性**: `by_period(@period).min_accuracy(@min_accuracy).by_grade(@grade)` で意図が明確
2. **保守性**: フィルターロジックの変更はモデルのスコープを修正するだけ
3. **テスト容易性**: スコープ単体でテスト可能
4. **柔軟性**: 任意のフィルターを組み合わせられる

### Q4-4: クラスメソッドを使うべきケース

#### ケース1: ActiveRecord::Relationを返さない処理

```ruby
# ❌ スコープには適さない（Hashを返す）
scope :count_by_grade, -> { group(:grade).count }

# ✅ クラスメソッドにする
def self.count_by_grade
  group(:grade).count
end
```

**理由:** スコープは常にActiveRecord::Relationを返すべきだが、`count`はHashを返すため、クラスメソッドが適切。

#### ケース2: 複雑な条件分岐やロジック

```ruby
# ❌ スコープが複雑すぎる
scope :search_by_filters, ->(filters) {
  query = all
  query = query.where(category_id: filters[:category_id]) if filters[:category_id].present?
  query = query.where("name LIKE ?", "%#{filters[:keyword]}%") if filters[:keyword].present?
  query = query.where("price >= ?", filters[:min_price]) if filters[:min_price].present?
  query = query.where("price <= ?", filters[:max_price]) if filters[:max_price].present?
  query = query.where(tags: { name: filters[:tag] }) if filters[:tag].present?
  query
}

# ✅ クラスメソッドで読みやすく書く
def self.search_by_filters(filters)
  query = all
  query = apply_category_filter(query, filters[:category_id])
  query = apply_keyword_filter(query, filters[:keyword])
  query = apply_price_filter(query, filters[:min_price], filters[:max_price])
  query = apply_tag_filter(query, filters[:tag])
  query
end

private

def self.apply_category_filter(query, category_id)
  return query if category_id.blank?
  query.where(category_id: category_id)
end

def self.apply_keyword_filter(query, keyword)
  return query if keyword.blank?
  query.where("name LIKE ?", "%#{keyword}%")
end

# ...他のフィルターメソッド
```

**理由:** 複雑なロジックはクラスメソッドに分割することで可読性・保守性が向上する。

#### ケース3: 引数が多い場合（3つ以上）

```ruby
# ❌ 引数が多すぎる
scope :advanced_search, ->(keyword, category, min_price, max_price, tags) {
  # ...
}

# ✅ クラスメソッドで名前付き引数を使う
def self.advanced_search(keyword:, category: nil, min_price: 0, max_price: Float::INFINITY, tags: [])
  query = all
  query = query.where("name LIKE ?", "%#{keyword}%")
  query = query.where(category_id: category) if category.present?
  query = query.where("price >= ? AND price <= ?", min_price, max_price)
  query = query.where(tags: { name: tags }) if tags.any?
  query
end
```

**理由:** 名前付き引数で意図が明確になり、デフォルト値も設定できる。

</details>

---

## 総合問題: 実装パターンの選択（上級）🔴

### シナリオ

以下の要件に基づいて、適切なスコープ設計を行ってください。

**要件:**

あなたは書籍管理システムを開発しています。以下の要件を満たすスコープを設計してください。

#### Bookモデル

```ruby
class Book < ApplicationRecord
  belongs_to :author
  belongs_to :publisher
  has_many :reviews

  # published_at: 出版日
  # price: 価格
  # stock: 在庫数
  # is_public: 公開フラグ
end
```

#### 要件1: 権限管理

- 管理者: 全ての書籍を閲覧可能
- 一般ユーザー: 公開書籍（`is_public: true`）のみ閲覧可能
- 未ログインユーザー: 公開 + 在庫あり（`stock > 0`）の書籍のみ閲覧可能

#### 要件2: フィルター機能

- 価格範囲で絞り込み（最小価格〜最大価格）
- 出版年で絞り込み（2020年、2021年など）
- 人気順（レビュー数が多い順）
- 新着順（出版日が新しい順）

#### 要件3: N+1クエリ対策

- 書籍一覧で著者名、出版社名、レビュー数を表示する
- N+1クエリが発生しないようにする

### 問題

**Q総合-1**: `visible_to(user)` スコープを実装してください。管理者・一般ユーザー・未ログインユーザーの3パターンに対応してください。

**Q総合-2**: 以下のスコープを実装してください：
   - `price_range(min_price, max_price)`: 価格範囲フィルター
   - `published_in_year(year)`: 出版年フィルター
   - `popular`: 人気順（レビュー数降順）
   - `newest`: 新着順（出版日降順）

**Q総合-3**: BooksControllerの`index`アクションを実装してください。以下の要件を満たしてください：
   - 権限管理（`visible_to`）
   - フィルター機能（価格範囲、出版年）
   - ソート（人気順 or 新着順）
   - N+1クエリ対策
   - ページネーション

**Q総合-4**: この実装のテストコード（RSpec）を書いてください。最低3つのテストケースを含めてください。

<details>
<summary>解答例を表示</summary>

### Q総合-1: `visible_to(user)` スコープ

```ruby
# app/models/book.rb
class Book < ApplicationRecord
  belongs_to :author
  belongs_to :publisher
  has_many :reviews

  # 権限管理スコープ
  scope :visible_to, ->(user) {
    if user&.admin?
      # 管理者: 全て表示
      all
    elsif user
      # 一般ユーザー: 公開書籍のみ
      where(is_public: true)
    else
      # 未ログインユーザー: 公開 + 在庫あり
      where(is_public: true, stock: 1..)  # stock > 0
    end
  }
end
```

**ポイント:**

- `user&.admin?`: nilセーフな管理者チェック
- `user`: nilでない（ログイン済み）かチェック
- `stock: 1..`: Railsの範囲クエリ（`stock > 0`と同義）

### Q総合-2: フィルター・ソートスコープ

```ruby
# app/models/book.rb
class Book < ApplicationRecord
  # ... 既存のコード

  # 価格範囲フィルター
  scope :price_range, ->(min_price, max_price) {
    return all if min_price.blank? && max_price.blank?

    query = all
    query = query.where("price >= ?", min_price.to_i) if min_price.present?
    query = query.where("price <= ?", max_price.to_i) if max_price.present?
    query
  }

  # 出版年フィルター
  scope :published_in_year, ->(year) {
    return all if year.blank?

    start_date = Date.new(year.to_i, 1, 1)
    end_date = Date.new(year.to_i, 12, 31)
    where(published_at: start_date..end_date)
  }

  # 人気順（レビュー数降順）
  scope :popular, -> {
    left_joins(:reviews)
      .group("books.id")
      .order("COUNT(reviews.id) DESC")
  }

  # 新着順（出版日降順）
  scope :newest, -> { order(published_at: :desc) }
end
```

**ポイント:**

- `price_range`: min/maxのどちらか一方だけでも対応
- `published_in_year`: 年範囲を日付範囲に変換
- `popular`: `left_joins`でレビューがない書籍も含める、`group`でレビュー数をカウント
- `newest`: シンプルなソート

### Q総合-3: BooksController

```ruby
# app/controllers/books_controller.rb
class BooksController < ApplicationController
  def index
    # パラメータ取得
    @min_price = params[:min_price]
    @max_price = params[:max_price]
    @year = params[:year]
    @sort = params[:sort] || "newest"  # デフォルトは新着順

    # スコープチェーンで柔軟にクエリ構築
    @books = Book.visible_to(current_user)                      # 権限管理
                 .price_range(@min_price, @max_price)           # 価格フィルター
                 .published_in_year(@year)                      # 出版年フィルター
                 .includes(:author, :publisher, :reviews)       # N+1対策
                 .send(sort_scope)                              # ソート
                 .page(params[:page]).per(20)                   # ページネーション
  end

  private

  def sort_scope
    case @sort
    when "popular"
      :popular
    else
      :newest
    end
  end
end
```

**実装のポイント:**

1. **権限管理**: `visible_to(current_user)` で最初にフィルタリング
2. **フィルター**: `price_range`, `published_in_year` で条件を追加
3. **N+1対策**: `includes(:author, :publisher, :reviews)` で関連レコード一括取得
4. **ソート**: `send(sort_scope)` で動的にスコープを適用
5. **ページネーション**: Kaminari gemの`page`メソッド

**実行されるSQL（概念）:**

```sql
-- 1. 権限管理 + フィルター + ソート
SELECT "books".* FROM "books"
LEFT OUTER JOIN "reviews" ON "reviews"."book_id" = "books"."id"
WHERE "books"."is_public" = true
  AND "books"."price" >= 1000
  AND "books"."price" <= 3000
  AND "books"."published_at" BETWEEN '2020-01-01' AND '2020-12-31'
GROUP BY "books"."id"
ORDER BY COUNT(reviews.id) DESC
LIMIT 20 OFFSET 0

-- 2. 関連するAuthorを一括取得
SELECT "authors".* FROM "authors" WHERE "authors"."id" IN (1, 2, 3)

-- 3. 関連するPublisherを一括取得
SELECT "publishers".* FROM "publishers" WHERE "publishers"."id" IN (5, 8)

-- 4. 関連するReviewを一括取得
SELECT "reviews".* FROM "reviews" WHERE "reviews"."book_id" IN (10, 11, 12, ...)
```

### Q総合-4: RSpecテストコード

```ruby
# spec/models/book_spec.rb
require 'rails_helper'

RSpec.describe Book, type: :model do
  describe 'scopes' do
    describe '.visible_to' do
      let(:admin_user) { create(:user, admin: true) }
      let(:general_user) { create(:user, admin: false) }

      let!(:public_in_stock) { create(:book, is_public: true, stock: 10) }
      let!(:public_out_of_stock) { create(:book, is_public: true, stock: 0) }
      let!(:private_in_stock) { create(:book, is_public: false, stock: 10) }

      context '管理者の場合' do
        it '全ての書籍を取得できる' do
          books = Book.visible_to(admin_user)
          expect(books).to contain_exactly(public_in_stock, public_out_of_stock, private_in_stock)
        end
      end

      context '一般ユーザーの場合' do
        it '公開書籍のみ取得できる' do
          books = Book.visible_to(general_user)
          expect(books).to contain_exactly(public_in_stock, public_out_of_stock)
        end
      end

      context '未ログインユーザーの場合' do
        it '公開 + 在庫ありの書籍のみ取得できる' do
          books = Book.visible_to(nil)
          expect(books).to contain_exactly(public_in_stock)
        end
      end
    end

    describe '.price_range' do
      let!(:cheap_book) { create(:book, price: 500) }
      let!(:mid_book) { create(:book, price: 1500) }
      let!(:expensive_book) { create(:book, price: 3000) }

      it '最小価格と最大価格の範囲内の書籍を取得できる' do
        books = Book.price_range(1000, 2000)
        expect(books).to contain_exactly(mid_book)
      end

      it '最小価格のみ指定した場合、それ以上の書籍を取得できる' do
        books = Book.price_range(1000, nil)
        expect(books).to contain_exactly(mid_book, expensive_book)
      end

      it '最大価格のみ指定した場合、それ以下の書籍を取得できる' do
        books = Book.price_range(nil, 2000)
        expect(books).to contain_exactly(cheap_book, mid_book)
      end
    end

    describe '.published_in_year' do
      let!(:book_2020) { create(:book, published_at: Date.new(2020, 6, 15)) }
      let!(:book_2021) { create(:book, published_at: Date.new(2021, 3, 10)) }

      it '指定した年に出版された書籍を取得できる' do
        books = Book.published_in_year(2020)
        expect(books).to contain_exactly(book_2020)
      end
    end

    describe '.popular' do
      let!(:popular_book) { create(:book) }
      let!(:unpopular_book) { create(:book) }

      before do
        create_list(:review, 5, book: popular_book)
        create_list(:review, 2, book: unpopular_book)
      end

      it 'レビュー数の多い順に書籍を取得できる' do
        books = Book.popular
        expect(books.first).to eq(popular_book)
      end
    end
  end
end
```

**テストのポイント:**

1. **境界値テスト**: 権限の3パターン、価格範囲の3パターン
2. **データセットアップ**: `let!`でテストデータ作成
3. **検証**: `contain_exactly`で期待する要素を厳密にチェック
4. **可読性**: contextブロックで条件を明確に

</details>

---

## 採点基準

### 問題1（🟢）: 20点

- Q1-1: 問題点を正しく指摘できている: 6点
- Q1-2: 影響を理解している: 4点
- Q1-3: スコープを使った改善案が正しい: 10点

### 問題2（🟡）: 25点

- Q2-1: N+1クエリ問題を正しく説明できている: 7点
- Q2-2: SQL実行回数の内訳を正しく説明できている: 6点
- Q2-3: `includes`による解決策が正しい: 10点
- Q2-4: 100件の場合の計算が正しい: 2点

### 問題3（🟡🔴）: 25点

- Q3-1: パターンAのエラー理由を説明できている: 6点
- Q3-2: `includes`と`joins`の違いを説明できている: 8点
- Q3-3: `joins` + `includes`の組み合わせが正しい: 9点
- Q3-4: Flexitypeの実例を知っている: 2点

### 問題4（🔴）: 30点

- Q4-1: 問題点を正しく指摘できている: 5点
- Q4-2: スコープ定義が正しい: 10点
- Q4-3: リファクタリングが適切: 10点
- Q4-4: クラスメソッドを使うべきケースを説明できている: 5点

### 総合問題（🔴）: ボーナス30点

- Q総合-1: `visible_to`スコープが正しい: 8点
- Q総合-2: フィルター・ソートスコープが正しい: 8点
- Q総合-3: コントローラー実装が適切: 8点
- Q総合-4: テストコードが適切: 6点

**合計: 130点（ボーナス含む）**

---

## 合格ライン

- 60点以上: 合格（基本的な理解がある）
- 80点以上: 優秀（実践的な知識がある）
- 100点以上: 非常に優秀（ActiveRecordスコープを深く理解している）

---

**作成日**: 2025-12-31
**対象教材**: [07_active_record_scopes.md](../topics/02_intermediate/07_active_record_scopes.md)
**難易度**: 🟡 中級
