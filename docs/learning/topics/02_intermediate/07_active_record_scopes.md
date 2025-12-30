# ActiveRecordスコープの効果的な使い方

**難易度**: 🟡 中級
**推定学習時間**: 60〜90分
**関連する実装**: Day 20-21（管理者ダッシュボード、レッスンDB化）

---

## 📚 学習目標

このトピックを学ぶことで、以下のスキルが身につきます：

1. **ActiveRecordスコープの基本的な使い方を理解する**
   - スコープの定義方法と利用方法
   - スコープのチェーン（組み合わせ）

2. **複雑な権限ロジックをスコープに集約できる**
   - `visible_to(user)` のような動的スコープ
   - ログイン状態・ユーザー種別による分岐

3. **N+1クエリ問題を理解し、解決できる**
   - `includes` による関連レコードの一括取得
   - `joins` と `includes` の違い

4. **スコープのチェーン、合成を使いこなせる**
   - 複数のスコープを組み合わせた柔軟なクエリ構築
   - メソッドチェーンによる可読性の向上

---

## 🎯 なぜスコープが重要なのか

### 実装前（アンチパターン）

スコープを使わない場合、権限判定ロジックがコントローラーに散在します：

```ruby
# ❌ アンチパターン: コントローラーに権限判定が散在
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
    # 検索機能でも同じ権限判定を繰り返す...
    if logged_in?
      if current_user.premium?
        @lessons = Lesson.where("name LIKE ?", "%#{params[:q]}%")
      else
        @lessons = Lesson.where(is_public: true)
                         .or(Lesson.where(user_id: current_user.id))
                         .where("name LIKE ?", "%#{params[:q]}%")
      end
    else
      @lessons = Lesson.where(is_public: true)
                       .where("name LIKE ?", "%#{params[:q]}%")
    end
  end

  def popular
    # 人気レッスン一覧でも同じ権限判定...
    # （さらに20行のコードが続く）
  end
end
```

**問題点:**

1. **DRY原則違反**: 同じ権限判定ロジックが複数のアクションに重複
2. **保守性が低い**: 権限ロジックを変更する際、全てのアクションを修正する必要がある
3. **テストが困難**: 各アクションで権限判定をテストする必要がある
4. **可読性が低い**: コントローラーが肥大化し、ビジネスロジックが見えにくい

---

## ✅ 実装後（ベストプラクティス）

### パターン1: 権限管理スコープ（`visible_to(user)`）

Day 21でFlexitypeに実装した`Lesson.visible_to(user)`を例に、権限管理をスコープに集約します。

#### モデルでのスコープ定義

```ruby
# app/models/lesson.rb
class Lesson < ApplicationRecord
  belongs_to :user
  belongs_to :category

  # 特定ユーザーに表示可能なレッスンを取得
  # 管理者: 全レッスン
  # 一般ユーザー: 公式レッスン + 自分のレッスン + 公開レッスン
  scope :visible_to, ->(user) {
    if user&.admin?
      # 管理者は全てのレッスンを閲覧可能
      all
    else
      # 一般ユーザーは以下のいずれかを閲覧可能:
      # 1. 公式レッスン (users.admin = true)
      # 2. 自分のレッスン (lessons.user_id = user.id)
      # 3. 公開レッスン (lessons.is_public = true)
      left_joins(:user).where(
        "lessons.user_id = :user_id OR lessons.is_public = true OR users.admin = true",
        user_id: user&.id
      ).distinct
    end
  }
end
```

**重要なポイント:**

1. **動的パラメータ**: `->(user)` でユーザーを引数として受け取る
2. **nilセーフ**: `user&.admin?` で未ログイン（`user = nil`）にも対応
3. **SQLレベルの最適化**: `left_joins(:user)` で結合、`distinct` で重複排除
4. **明確な条件**: OR条件で「公式 OR 自分の OR 公開」を表現

#### コントローラーでの使用

```ruby
# ✅ ベストプラクティス: スコープを使用
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

- Before: 約20行のif文が各アクションに重複
- After: 1行の`visible_to(current_user)`
- **削減率**: 95%

**メリット:**

1. **DRY**: 権限ロジックが1箇所に集約
2. **保守性**: 権限変更時、スコープ1箇所を修正するだけ
3. **テスト容易性**: スコープ単体でテスト可能
4. **可読性**: コントローラーがシンプルで意図が明確

---

### パターン2: N+1クエリ対策（`includes`, `eager_load`）

Day 20の管理者ダッシュボード実装で、N+1クエリ問題を解決しました。

#### N+1クエリ問題とは

**悪い例（N+1クエリ発生）:**

```ruby
# ❌ N+1クエリが発生するコード
class Admin::DashboardController < Admin::ApplicationController
  def index
    @lesson_records = LessonRecord.recent.limit(10)
  end
end
```

```slim
/ app/views/admin/dashboard/index.html.slim
- @lesson_records.each do |record|
  .record
    p ユーザー: #{record.user.name}        ← N+1発生
    p レッスン: #{record.lesson.name}      ← N+1発生
    p カテゴリー: #{record.lesson.category.name}  ← N+1発生
```

**実行されるSQL（101回）:**

```sql
-- 1. LessonRecordを取得（1回）
SELECT "lesson_records".* FROM "lesson_records" ORDER BY "completed_at" DESC LIMIT 10

-- 2. 各レコードに対してUserを取得（10回、N+1）
SELECT "users".* FROM "users" WHERE "users"."id" = 1  -- record 1
SELECT "users".* FROM "users" WHERE "users"."id" = 2  -- record 2
SELECT "users".* FROM "users" WHERE "users"."id" = 1  -- record 3
...（10回繰り返し）

-- 3. 各レコードに対してLessonを取得（10回、N+1）
SELECT "lessons".* FROM "lessons" WHERE "lessons"."id" = 5  -- record 1
SELECT "lessons".* FROM "lessons" WHERE "lessons"."id" = 3  -- record 2
...（10回繰り返し）

-- 4. 各Lessonに対してCategoryを取得（10回、N+1）
SELECT "categories".* FROM "categories" WHERE "categories"."id" = 1
SELECT "categories".* FROM "categories" WHERE "categories"."id" = 2
...（10回繰り返し）

-- 合計: 1 + 10 + 10 + 10 = 31回のSQL実行
```

**問題:**

- データベースへのアクセスが31回（1 + 10×3）
- ページ表示が遅くなる
- データベースサーバーに負荷がかかる

#### 解決策: `includes` による一括取得

```ruby
# ✅ N+1クエリを解決したコード
class Admin::DashboardController < Admin::ApplicationController
  def index
    # includes で関連レコードを一括取得
    @lesson_records = LessonRecord.recent.includes(:user, lesson: :category).limit(10)
    #                                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    #                                      user, lesson, category を一括取得
  end
end
```

**実行されるSQL（3回）:**

```sql
-- 1. LessonRecordを取得（1回）
SELECT "lesson_records".* FROM "lesson_records" ORDER BY "completed_at" DESC LIMIT 10

-- 2. 関連するUser全てを一括取得（1回）
SELECT "users".* FROM "users" WHERE "users"."id" IN (1, 2, 3, 4, 5)

-- 3. 関連するLessonとCategoryを一括取得（1回）
SELECT "lessons".* FROM "lessons" WHERE "lessons"."id" IN (5, 3, 8, 2)
SELECT "categories".* FROM "categories" WHERE "categories"."id" IN (1, 2, 3)

-- 合計: 3〜4回のSQL実行（N+1解消）
```

**N+1問題の解決:**

- Before: 31回のSQL
- After: 3〜4回のSQL
- **削減率**: 87%〜90%

**パフォーマンス改善:**

- ページ読み込み速度: 約10倍高速化（環境による）
- データベース負荷: 約90%削減

---

### `includes` と `joins` の違い

#### `includes`: 外部結合（LEFT OUTER JOIN）+ 一括取得

```ruby
# includes: 関連レコードを一括取得（外部結合）
@lessons = Lesson.includes(:user, :category).limit(10)

# 実行されるSQL（2〜3回）
# SELECT "lessons".* FROM "lessons" LIMIT 10
# SELECT "users".* FROM "users" WHERE "users"."id" IN (1, 2, 3)
# SELECT "categories".* FROM "categories" WHERE "categories"."id" IN (5, 8)
```

**特徴:**

- 関連レコードをメモリにロード（Eager Loading）
- 関連レコードがなくても親レコードは取得される（LEFT JOIN）
- N+1クエリ対策に使う

**使用例:**

```ruby
# ビューで関連レコードを表示する場合
@lessons.each do |lesson|
  puts lesson.user.name        # ← メモリから取得（追加SQLなし）
  puts lesson.category.name    # ← メモリから取得（追加SQLなし）
end
```

#### `joins`: 内部結合（INNER JOIN）

```ruby
# joins: SQLの結合のみ（メモリにはロードしない）
@lessons = Lesson.joins(:user).where(users: { admin: true })

# 実行されるSQL（1回）
# SELECT "lessons".* FROM "lessons"
# INNER JOIN "users" ON "users"."id" = "lessons"."user_id"
# WHERE "users"."admin" = true
```

**特徴:**

- SQLレベルの結合のみ（関連レコードはメモリにロードしない）
- WHERE条件で関連テーブルのカラムを参照する場合に使う
- 関連レコードがない親レコードは除外される（INNER JOIN）

**使用例:**

```ruby
# 管理者が作成したレッスンのみを取得（WHERE条件で絞り込み）
@official_lessons = Lesson.joins(:user).where(users: { admin: true })

# 公開カテゴリーのレッスンのみを取得
@public_lessons = Lesson.joins(:category).where(categories: { published: true })
```

#### 組み合わせて使う

```ruby
# joins（絞り込み） + includes（N+1対策）
@lessons = Lesson.joins(:category)
                 .where(categories: { published: true })  # 公開カテゴリーのみ
                 .includes(:user, :category)              # N+1対策
                 .limit(10)
```

**実行されるSQL:**

```sql
-- 1. joinsで絞り込み
SELECT "lessons".* FROM "lessons"
INNER JOIN "categories" ON "categories"."id" = "lessons"."category_id"
WHERE "categories"."published" = true LIMIT 10

-- 2. includesで関連レコードを一括取得
SELECT "users".* FROM "users" WHERE "users"."id" IN (1, 2, 3)
SELECT "categories".* FROM "categories" WHERE "categories"."id" IN (5, 8)
```

---

### パターン3: スコープのチェーン

複数のスコープを組み合わせて柔軟なクエリを構築します。

#### 基本的なスコープ定義

```ruby
# app/models/lesson_record.rb
class LessonRecord < ApplicationRecord
  belongs_to :user
  belongs_to :lesson

  # スコープ定義
  scope :recent, -> { order(completed_at: :desc) }
  scope :high_accuracy, -> { where("accuracy >= ?", 90) }
  scope :this_week, -> { where("completed_at >= ?", 1.week.ago) }
  scope :this_month, -> { where("completed_at >= ?", 1.month.ago) }

  # 複合スコープ（既存スコープを組み合わせ）
  scope :excellent_this_week, -> { recent.high_accuracy.this_week }
end
```

#### スコープのチェーン

```ruby
# 使用例1: 単体スコープ
@records = LessonRecord.recent.limit(10)

# 使用例2: 複数スコープのチェーン
@records = LessonRecord.recent.high_accuracy.this_week.limit(10)

# 使用例3: 複合スコープ + whereを追加
@records = LessonRecord.excellent_this_week.where(user_id: current_user.id)

# 使用例4: スコープ + joins + includes
@records = LessonRecord.recent
                       .joins(:lesson)
                       .where(lessons: { is_public: true })
                       .includes(:user, :lesson)
                       .limit(10)
```

**スコープチェーンの利点:**

1. **可読性**: `recent.high_accuracy.this_week` は意図が明確
2. **柔軟性**: 必要なスコープだけを組み合わせられる
3. **再利用性**: スコープ自体が再利用可能
4. **保守性**: スコープ内のロジックを変更すれば、全ての使用箇所に反映される

---

### Flexitypeでの実装例

#### 1. Lessonモデルのスコープ（Day 21実装）

```ruby
# app/models/lesson.rb
class Lesson < ApplicationRecord
  # 基本的なスコープ
  scope :ordered, -> { order(display_order: :asc, id: :asc) }
  scope :official, -> { joins(:user).where(users: { admin: true }) }
  scope :user_created, -> { joins(:user).where.not(users: { admin: true }) }
  scope :published, -> { where(is_public: true) }

  # カテゴリーに基づくスコープ
  scope :free, -> { joins(:category).where(categories: { premium: false }) }
  scope :premium, -> { joins(:category).where(categories: { premium: true }) }
  scope :available_for_guest, -> { joins(:category).where(categories: { requires_login: false }) }

  # 権限管理スコープ（最も重要）
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

**使用例（コントローラー）:**

```ruby
# app/controllers/lessons_controller.rb
class LessonsController < ApplicationController
  def index
    # 公開レッスン + 表示順でソート
    @lessons = Lesson.visible_to(current_user).ordered
  end

  def premium
    # プレミアムレッスンのみ + 表示順でソート
    @lessons = Lesson.visible_to(current_user).premium.ordered
  end

  def official
    # 公式レッスンのみ + 表示順でソート
    @lessons = Lesson.visible_to(current_user).official.ordered
  end
end
```

#### 2. LessonRecordモデルのスコープ

```ruby
# app/models/lesson_record.rb
class LessonRecord < ApplicationRecord
  # 完了日時降順
  scope :recent, -> { order(completed_at: :desc) }

  # 期間フィルター（Day 24実装）
  scope :this_week, -> { where("completed_at >= ?", 1.week.ago) }
  scope :this_month, -> { where("completed_at >= ?", 1.month.ago) }
end
```

**使用例（コントローラー）:**

```ruby
# app/controllers/my/history_controller.rb
class My::HistoryController < My::ApplicationController
  def index
    @period = params[:period] || "all"

    # スコープ + 期間フィルター + ページネーション
    @lesson_records = filter_by_period(current_user.lesson_records, @period)
                        .recent
                        .includes(:user, lesson: :category)  # N+1対策
                        .page(params[:page]).per(20)
  end

  private

  def filter_by_period(records, period)
    case period
    when "week"
      records.this_week
    when "month"
      records.this_month
    else
      records
    end
  end
end
```

---

## 🔍 スコープを使うべき場面・使わない方が良い場面

### 使うべき場面

1. **複数箇所で使われるクエリ条件**
   ```ruby
   # ✅ 複数のコントローラーで「公開レッスン」を取得する
   scope :published, -> { where(is_public: true) }
   ```

2. **ビジネスロジックを含む複雑な条件**
   ```ruby
   # ✅ 権限に基づく表示制御
   scope :visible_to, ->(user) { ... }
   ```

3. **メソッドチェーンで組み合わせたい条件**
   ```ruby
   # ✅ チェーン可能なスコープ
   Lesson.published.official.ordered
   ```

4. **時間に基づくフィルター**
   ```ruby
   # ✅ よく使う期間フィルター
   scope :this_week, -> { where("created_at >= ?", 1.week.ago) }
   ```

### 使わない方が良い場面

1. **1箇所でしか使わない単純な条件**
   ```ruby
   # ❌ スコープにする必要がない
   scope :name_is_test, -> { where(name: "test") }

   # ✅ 直接書く
   Lesson.where(name: "test")
   ```

2. **引数が多く、複雑なロジック**
   ```ruby
   # ❌ スコープが複雑すぎる
   scope :complex_search, ->(name, category, min_price, max_price, tags) {
     # 30行の複雑なロジック...
   }

   # ✅ クラスメソッドにする
   def self.complex_search(name:, category:, min_price:, max_price:, tags:)
     # 複雑なロジックを読みやすく書く
   end
   ```

3. **ActiveRecordのRelationを返さない処理**
   ```ruby
   # ❌ スコープはRelationを返すべき
   scope :count_by_category, -> { group(:category_id).count }  # Hashを返す

   # ✅ クラスメソッドにする
   def self.count_by_category
     group(:category_id).count
   end
   ```

---

## 💡 スコープとクラスメソッドの使い分け

### スコープを使う場合

```ruby
# ✅ ActiveRecord::Relationを返す単純な条件
scope :published, -> { where(is_public: true) }
scope :recent, -> { order(created_at: :desc) }
```

**特徴:**

- 常にActiveRecord::Relationを返す
- メソッドチェーンが保証される
- `nil`を返すことができない（必ず`all`相当が返る）

### クラスメソッドを使う場合

```ruby
# ✅ 複雑なロジック、または非Relationを返す場合
class Lesson < ApplicationRecord
  # 統計情報を返す（Hashを返す）
  def self.count_by_category
    group(:category_id).count
  end

  # 条件分岐が複雑な検索
  def self.search_by_filters(filters)
    query = all
    query = query.where(category_id: filters[:category_id]) if filters[:category_id].present?
    query = query.where("name LIKE ?", "%#{filters[:keyword]}%") if filters[:keyword].present?
    query = query.where("price >= ?", filters[:min_price]) if filters[:min_price].present?
    query
  end
end
```

**特徴:**

- 柔軟性が高い（Relation以外も返せる）
- `nil`を返すことができる
- 複雑な条件分岐を書きやすい

---

## 📊 スコープの内部動作

### 遅延評価（Lazy Evaluation）

スコープは**実際に必要になるまでSQLを実行しない**という特性があります。

```ruby
# 1. スコープを定義（SQLは実行されない）
@lessons = Lesson.published.ordered

# 2. さらにスコープを追加（まだSQLは実行されない）
@lessons = @lessons.where("name LIKE ?", "%Ruby%")

# 3. ここでSQLが実行される
@lessons.each do |lesson|  # ← 初めてSQLが実行される
  puts lesson.name
end

# 4. 再度アクセス（キャッシュから取得、SQLは実行されない）
@lessons.each do |lesson|
  puts lesson.name
end
```

**実行されるSQL（1回のみ）:**

```sql
SELECT "lessons".* FROM "lessons"
WHERE "lessons"."is_public" = true
  AND "name" LIKE '%Ruby%'
ORDER BY "lessons"."display_order" ASC, "lessons"."id" ASC
```

**遅延評価のメリット:**

1. **パフォーマンス最適化**: 必要な時まで実行を遅らせる
2. **柔軟なクエリ構築**: 条件を段階的に追加できる
3. **不要なクエリを防ぐ**: 使わなければSQLが実行されない

---

## 🎓 まとめ

### スコープのベストプラクティス

1. **DRY原則を守る**: 同じ条件は1箇所に集約
2. **意図を明確にする**: スコープ名で何をするか分かるようにする
3. **メソッドチェーンを活用**: 小さなスコープを組み合わせる
4. **N+1クエリを防ぐ**: `includes`で関連レコードを一括取得
5. **複雑すぎる場合はクラスメソッドに**: 30行を超えるロジックはスコープに適さない

### パフォーマンス最適化のチェックリスト

- [ ] コントローラーで同じWHERE条件が複数回出現していないか？
- [ ] ビューで関連レコード（`user.name`など）を参照していないか？
- [ ] `includes`で関連レコードを一括取得しているか？
- [ ] `joins`と`where`で絞り込んでから`includes`で取得しているか？

### Flexitypeでの実装例から学ぶ

- **Day 20**: N+1クエリ対策（`includes(:user, :lesson)`）
- **Day 21**: 権限管理スコープ（`visible_to(user)`）
- **Day 24**: 期間フィルター（`this_week`, `this_month`）

---

**次のステップ:**

このトピックをマスターしたら、[レビューテスト: ActiveRecordスコープ](../../reviews/review_07_active_record_scopes.md) に挑戦しましょう！

---

**作成日**: 2025-12-31
**対応するFlexitypeの実装**: Day 20-21, Day 24
**関連ドキュメント**: `CLAUDE_FEATURES.md`, `CLAUDE_LESSON_DB_PLAN.md`
