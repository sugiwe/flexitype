# データベース設計とマイグレーション戦略

**難易度**: 🟡 中級
**推定学習時間**: 2〜3時間
**対応する日報**: Day 21, Day 24
**関連PR**: #96

---

## 🎯 学習目標

この教材を学ぶことで、以下ができるようになります：

- 3段階マイグレーション戦略（データクリーンアップ→型変更→制約追加）を理解し、実践できる
- JSONB型の利点と活用方法を理解し、適切に設計できる
- 外部キー制約とNOT NULL制約の重要性を理解し、データ整合性を保証できる
- PostgreSQLの型キャスト機能（`using: 'column::type'`）を活用し、安全な型変更を実施できる
- 本番環境でのデータ移行におけるリスクとベストプラクティスを理解できる

---

## 📚 前提知識

この教材を理解するには、以下の知識が必要です：

- Railsマイグレーションの基本（`rails generate migration`、`rails db:migrate`、`rails db:rollback`）
- PostgreSQLの基礎知識（データ型、インデックス、制約）
- ActiveRecordの基本（モデル、関連付け、バリデーション）
- SQL の基本的な理解（SELECT、UPDATE、DELETE、JOIN など）

---

## 📖 本編

### 概要

データベース設計は、アプリケーションの安定性とパフォーマンスに直結する重要な要素です。特に、データ移行（マイグレーション）は、既存データを壊さずにスキーマを変更する必要があるため、慎重な戦略が求められます。

Flexitypeプロジェクトでは、Day 24にレッスン記録（`lesson_records`テーブル）の大規模なクリーンアップを実施しました。このクリーンアップでは、以下の課題に直面しました：

1. **古いデータ構造の名残**: YAML形式からDB形式への移行後、古いカラム（`category` string型）が残っていた
2. **型不一致**: `lesson_id` カラムが string型で保存されていたが、本来は bigint型であるべき
3. **データの不整合**: 29件のレコードで `lesson_id` が nil だった
4. **制約の欠如**: 外部キー制約やNOT NULL制約がなく、無効なデータの保存が可能だった

これらの課題を解決するために、**3段階マイグレーション戦略**を採用しました。この戦略により、データ損失のリスクを最小化しつつ、データベースのクリーンアップと整合性の確保を実現しました。

本教材では、この実例を通じて、本番環境でのデータ移行におけるベストプラクティスを学びます。

---

### 実装前（アンチパターン / 課題）

#### データ構造の問題

クリーンアップ前の `lesson_records` テーブルは、以下のような問題を抱えていました：

```ruby
# 古い lesson_records テーブルのスキーマ（問題あり）
create_table "lesson_records", force: :cascade do |t|
  t.string "lesson_id"              # ⚠️ 本来はbigint型であるべき
  t.bigint "user_id", null: false
  t.string "lesson_name"
  t.integer "word_count"
  t.integer "mistake_count"
  t.integer "duration_seconds"
  t.string "category"               # ⚠️ 古いデータ構造の名残
  t.datetime "completed_at"
  t.datetime "created_at", null: false
  t.datetime "updated_at", null: false

  # ⚠️ 外部キー制約なし
  # ⚠️ NOT NULL制約なし（lesson_idがnilでも保存可能）
end
```

#### データの実態

データベースの実態調査により、以下の問題が判明しました：

```ruby
# データ分析スクリプトの実行結果
総レコード数: 33件
  - category フィールドあり: 2件（2025-12-16のYAMLベース）
  - lesson_id が nil: 29件
  - lesson_id あり（文字列ID）: 4件
```

**問題点:**

1. **古いデータ構造の残存**:
   - 2件のレコードが古い `category` カラム（string型）を使用
   - これらは2025-12-16のYAMLベースのレッスンで、現在のLessonモデルと互換性がない

2. **型不一致によるJOINエラー**:
   - `lesson_id` が string型だが、`lessons.id` は bigint型
   - `LessonRecord.joins(:lesson)` で `operator does not exist: bigint = character varying` エラー

3. **データの不整合**:
   - 29件のレコードで `lesson_id` が nil
   - これらのレコードは `lesson_name` カラムの値でレッスンを特定していた（非正規化）

4. **制約の欠如**:
   - 外部キー制約がないため、存在しないレッスンへの参照が可能
   - NOT NULL制約がないため、`lesson_id: nil` で保存可能
   - データ整合性が保証されない

5. **パフォーマンスの問題**:
   - `lesson_id` カラムにインデックスがない
   - JOINクエリが遅い

---

### 実装後（3段階マイグレーション戦略）

3段階マイグレーション戦略では、以下の順序でデータベースをクリーンアップします：

1. **Phase 1: データクリーンアップ** - 古いデータの削除、nilデータの自動マッチング
2. **Phase 2: スキーマクリーンアップ** - 型変更、不要なカラムの削除
3. **Phase 3: データ整合性の確保** - NOT NULL制約、外部キー制約、インデックスの追加

この段階的アプローチにより、各フェーズで問題が発生した場合でも、個別にロールバックが可能です。

---

#### Phase 1: データクリーンアップ

**ファイル**: `db/migrate/20251224053646_cleanup_lesson_records_data.rb`

```ruby
class CleanupLessonRecordsData < ActiveRecord::Migration[8.1]
  def up
    # Step 1: 古いデータ（category フィールド使用、ID: 1, 2）を削除
    # これらは2025-12-16の古いYAMLベースのレッスンデータで、現在のLessonに対応していない
    LessonRecord.where.not(category: nil).delete_all
    puts "✓ 古いcategoryフィールド使用のレコード（2件）を削除"

    # Step 2: lesson_id が nil のレコードを lesson_name からマッチングして更新
    # すべての lesson_name は現在の Lesson テーブルに存在することを確認済み
    LessonRecord.where(lesson_id: nil).find_each do |record|
      matching_lesson = Lesson.find_by(name: record.lesson_name)

      if matching_lesson
        # lesson_id を文字列として更新（次のマイグレーションでbigintに変換する）
        record.update_column(:lesson_id, matching_lesson.id.to_s)
      else
        # マッチしない場合は警告（ただし分析結果では全てマッチする）
        puts "⚠️  Warning: No matching lesson for record ID #{record.id}, lesson_name: #{record.lesson_name}"
      end
    end
    puts "✓ lesson_id が nil のレコード（29件）を lesson_name から自動マッチングして更新"

    # Step 3: 結果確認
    total = LessonRecord.count
    with_lesson_id = LessonRecord.where.not(lesson_id: nil).count
    puts ""
    puts "データクリーンアップ完了:"
    puts "  Total records: #{total}"
    puts "  With lesson_id: #{with_lesson_id}"
    puts "  Remaining nil: #{total - with_lesson_id}"
  end

  def down
    # ロールバックは困難（元のデータを復元できない）
    raise ActiveRecord::IrreversibleMigration, "このマイグレーションはロールバックできません"
  end
end
```

**改善点:**
- ✅ 古い `category` カラム使用のレコード（2件）を削除
- ✅ `lesson_id` が nil のレコード（29件）を `lesson_name` から自動マッチング
- ✅ 全レコードが有効な `lesson_id` を持つようになった

**実行結果:**
```
✓ 古いcategoryフィールド使用のレコード（2件）を削除
✓ lesson_id が nil のレコード（29件）を lesson_name から自動マッチングして更新

データクリーンアップ完了:
  Total records: 31
  With lesson_id: 31
  Remaining nil: 0
```

---

#### Phase 2: スキーマクリーンアップ

**ファイル**: `db/migrate/20251224053733_cleanup_lesson_records_schema.rb`

```ruby
class CleanupLessonRecordsSchema < ActiveRecord::Migration[8.1]
  def up
    # Step 1: lesson_id を string から bigint に変更
    # 現在のデータは文字列型の数値IDなので、安全に変換可能
    change_column :lesson_records, :lesson_id, :bigint, using: 'lesson_id::bigint'
    puts "✓ lesson_id を string → bigint に変更"

    # Step 2: 不要な category カラムを削除
    # すでにビューからも削除済み、データも全てnilまたは削除済み
    remove_column :lesson_records, :category
    puts "✓ category カラムを削除"
  end

  def down
    # ロールバック: category カラムを復元（ただしデータは空）
    add_column :lesson_records, :category, :string

    # lesson_id を bigint → string に戻す
    change_column :lesson_records, :lesson_id, :string
  end
end
```

**改善点:**
- ✅ `lesson_id` を string型 → bigint型に変更（PostgreSQLのキャスト機能を使用）
- ✅ 不要な `category` カラムを削除

**PostgreSQLの型キャスト機能:**
```ruby
change_column :lesson_records, :lesson_id, :bigint, using: 'lesson_id::bigint'
#                                                           ↑↑↑↑↑↑↑↑↑↑↑
#                                           PostgreSQL固有のキャスト構文
```

`using: 'lesson_id::bigint'` は、PostgreSQLの型キャスト構文を使って、文字列型の数値ID（例: `"123"`）を安全にbigint型（例: `123`）に変換します。Railsの標準的な型変換ではエラーになるケースでも、この構文を使うことで安全に変換できます。

---

#### Phase 3: データ整合性の確保

**ファイル**: `db/migrate/20251224053929_add_foreign_key_constraints_to_lesson_records.rb`

```ruby
class AddForeignKeyConstraintsToLessonRecords < ActiveRecord::Migration[8.1]
  def up
    # Step 1: NOT NULL 制約を追加
    change_column_null :lesson_records, :lesson_id, false
    puts "✓ lesson_id に NOT NULL 制約を追加"

    # Step 2: 外部キー制約を追加
    add_foreign_key :lesson_records, :lessons, column: :lesson_id
    puts "✓ lesson_records → lessons の外部キー制約を追加"

    # Step 3: インデックスを追加（パフォーマンス向上）
    add_index :lesson_records, :lesson_id unless index_exists?(:lesson_records, :lesson_id)
    puts "✓ lesson_id にインデックスを追加"
  end

  def down
    # ロールバック
    remove_index :lesson_records, :lesson_id, if_exists: true
    remove_foreign_key :lesson_records, :lessons
    change_column_null :lesson_records, :lesson_id, true
  end
end
```

**改善点:**
- ✅ NOT NULL制約の追加（`lesson_id` が必須）
- ✅ 外部キー制約の追加（`lesson_records.lesson_id` → `lessons.id`）
- ✅ インデックスの追加（パフォーマンス向上）

**最終的なスキーマ:**
```ruby
# 改善後の lesson_records テーブルのスキーマ
create_table "lesson_records", force: :cascade do |t|
  t.bigint "lesson_id", null: false     # ✅ bigint型、NOT NULL制約
  t.bigint "user_id", null: false
  t.string "lesson_name"
  t.integer "word_count"
  t.integer "mistake_count"
  t.integer "duration_seconds"
  # category カラムは削除済み
  t.datetime "completed_at"
  t.datetime "created_at", null: false
  t.datetime "updated_at", null: false

  # ✅ 外部キー制約あり
  t.index ["lesson_id"], name: "index_lesson_records_on_lesson_id"
  t.index ["user_id"], name: "index_lesson_records_on_user_id"
end

add_foreign_key "lesson_records", "lessons"  # ✅ データ整合性が保証される
add_foreign_key "lesson_records", "users"
```

---

### JSONB型の活用

Flexitypeプロジェクトでは、`lessons` テーブルの `items` カラムにJSONB型を採用しています。これにより、タイピング練習の問題リスト（配列データ）を柔軟に保存できます。

#### スキーマ設計

```ruby
# db/schema.rb（抜粋）
create_table "lessons", force: :cascade do |t|
  t.bigint "user_id", null: false
  t.bigint "category_id", null: false
  t.string "name", null: false
  t.text "description"
  t.jsonb "items", default: [], null: false  # ✅ JSONB型で配列を保存
  t.integer "count", default: 0, null: false
  t.boolean "is_public", default: false, null: false
  # ...
end
```

#### Lessonモデル

```ruby
# app/models/lesson.rb（抜粋）
class Lesson < ApplicationRecord
  belongs_to :user
  belongs_to :category
  has_many :lesson_records, dependent: :destroy

  # バリデーション
  validates :items, presence: true
  validates :count, numericality: { greater_than: 0, less_than_or_equal_to: 100 }

  # JavaScript用のレッスン情報をJSON形式で返す
  def to_lesson_info
    {
      lesson_id: id,
      category_name: category.name,
      lesson_name: name,
      count: count,
      # items: items  # ← JSONB型の配列をそのまま使用
    }
  end
end
```

#### フォームとの連携

ユーザーがレッスンを作成・編集する際、テキストエリアで改行区切りのテキストを入力し、それを配列に変換します：

```ruby
# app/controllers/my/lessons_controller.rb（抜粋）
def create
  @lesson = current_user.lessons.build(lesson_params)

  # items の変換処理: 改行区切りテキスト → 配列
  if lesson_params[:items].is_a?(String)
    @lesson.items = lesson_params[:items].split("\n").map(&:strip).reject(&:blank?)
  end

  @lesson.count = @lesson.items.size

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
```

#### JSONB型の利点

1. **柔軟なデータ構造**: スキーマ変更なしで配列の要素数を自由に変更できる
2. **高速なクエリ**: PostgreSQLの JSONB型は、バイナリ形式で保存されるため高速
3. **インデックス作成可能**: JSONB型のカラムにGINインデックスを作成できる
4. **Rails との親和性**: ActiveRecordで配列として扱える（シリアライズ不要）

#### JSONB型のクエリ例

```ruby
# 特定の単語を含むレッスンを検索（PostgreSQL固有）
Lesson.where("items ? :word", word: "hello")

# JSONB配列の要素数で検索
Lesson.where("jsonb_array_length(items) > ?", 10)

# JSONB配列の最初の要素を取得
Lesson.select("items->0 as first_item")
```

---

### 本番環境での教訓（Day 21）

Day 21では、レッスンのDB化（YAML → PostgreSQL）を実施しましたが、本番環境へのデプロイ時に重大な問題が発生しました。

#### 問題: レッスンデータの消失

**症状:**
- 本番環境にデプロイ後、全てのレッスンが表示されなくなった
- トップページが空っぽになり、ユーザーが練習できない状態に

**原因:**
1. マイグレーション（`rails db:migrate`）でテーブル構造は変更された
2. しかし、YAMLからDBへのデータ移行スクリプトを実行していなかった
3. 開発環境では手動で `rails runner` を実行していたが、本番環境で忘れていた

**復旧手順:**

1. **Rakeタスクの作成:**
```ruby
# lib/tasks/migrate_lessons_from_yaml.rake
namespace :lessons do
  desc "Migrate lessons from YAML to PostgreSQL"
  task migrate_from_yaml: :environment do
    yaml_file = Rails.root.join("config", "typing_lessons.yml")
    data = YAML.load_file(yaml_file)

    official_user = User.find_by(email: ENV["ADMIN_EMAILS"].split(",").first)

    data["categories"].each do |category_data|
      category = Category.create!(
        name: category_data["name"],
        description: category_data["description"],
        display_order: category_data["display_order"],
        # ...
      )

      category_data["lessons"].each do |lesson_data|
        Lesson.create!(
          user: official_user,
          category: category,
          name: lesson_data["name"],
          items: lesson_data["items"],
          count: lesson_data["items"].size,
          # ...
        )
      end
    end

    puts "✓ #{Category.count}カテゴリー、#{Lesson.count}レッスンを移行しました"
  end
end
```

2. **コミット・プッシュして再デプロイ:**
```bash
git add lib/tasks/migrate_lessons_from_yaml.rake
git commit -m "レッスンデータ移行用のRakeタスクを追加"
git push origin feature/lesson-db-migration
kamal deploy  # 再デプロイ
```

3. **本番環境でRakeタスクを実行:**
```bash
kamal app exec --roles=web 'bin/rails lessons:migrate_from_yaml'
```

4. **結果確認:**
```
✓ 6カテゴリー、16レッスンを移行しました
```

#### 教訓

**1. DB構造変更（マイグレーション）≠ データ移行**
- マイグレーションはテーブル構造を変更する
- データ移行は、既存データを新しい構造に適合させる
- 両者は別物であり、個別に実施する必要がある

**2. データ移行スクリプトは必ずRakeタスク化**
- `rails runner` での手動実行は、本番環境で忘れやすい
- Rakeタスク化することで、デプロイ手順書に明記できる
- 再実行可能性（冪等性）を確保する

**3. 本番デプロイ後は必ずデータ確認**
- デプロイ後、すぐにブラウザでアプリケーションを確認
- データが正しく表示されるか、機能が正常に動作するか検証
- エラーログを確認（Kamalの場合: `kamal app logs`）

**4. デプロイチェックリストの作成**
```markdown
# 本番デプロイチェックリスト

## デプロイ前
- [ ] マイグレーションファイルの確認（down メソッドの実装）
- [ ] データ移行スクリプトのRakeタスク化
- [ ] Seedデータの準備（必要に応じて）
- [ ] RuboCopとBrakemanの実行（0件を確認）

## デプロイ中
- [ ] `kamal deploy` の実行
- [ ] デプロイログの確認（エラーがないか）
- [ ] データ移行Rakeタスクの実行（必要に応じて）

## デプロイ後
- [ ] アプリケーションが正常に起動するか
- [ ] データが正しく表示されるか
- [ ] 主要機能が正常に動作するか
- [ ] エラーログの確認
```

---

### 解説

#### なぜ3段階に分けるのか

**1. リスクの分離**

各フェーズを独立したマイグレーションにすることで、問題が発生した場合でも個別にロールバックが可能です。

```bash
# Phase 3でエラーが発生した場合、Phase 3だけロールバック
rails db:rollback

# Phase 1とPhase 2は正常に実行された状態を保つ
```

**2. デバッグの容易性**

各フェーズで `puts` を使って実行結果を出力することで、どのステップで問題が発生したかを特定しやすくなります。

```ruby
# Phase 1の実行結果
✓ 古いcategoryフィールド使用のレコード（2件）を削除
✓ lesson_id が nil のレコード（29件）を lesson_name から自動マッチングして更新

データクリーンアップ完了:
  Total records: 31
  With lesson_id: 31
  Remaining nil: 0
```

**3. 安全性の確保**

データクリーンアップ（Phase 1）を先に実行することで、型変更（Phase 2）や制約追加（Phase 3）が安全に実行できます。

```ruby
# Phase 1でnilデータを削除してから、Phase 3でNOT NULL制約を追加
# → nilデータが残っていると、NOT NULL制約の追加がエラーになる
```

---

#### PostgreSQLの型キャスト機能の仕組み

PostgreSQLの型キャスト構文（`::`）は、データ型を変換するための強力な機能です。

**基本構文:**
```sql
SELECT '123'::integer;     -- 文字列 → 整数
SELECT '2025-01-01'::date; -- 文字列 → 日付
SELECT 1::text;            -- 整数 → 文字列
```

**Railsマイグレーションでの活用:**
```ruby
# 通常の型変更（エラーになる可能性）
change_column :lesson_records, :lesson_id, :bigint
# → string型の"123"をbigintに変換できない

# PostgreSQLのキャスト機能を使った型変更（安全）
change_column :lesson_records, :lesson_id, :bigint, using: 'lesson_id::bigint'
# → "123"（string）→ 123（bigint）に変換される
```

**注意点:**
- キャスト可能なデータのみが対象（例: `"abc"` → bigintは不可）
- Phase 1でデータをクリーンアップしてから、Phase 2で型変更を実施する

---

#### 外部キー制約とインデックスの関係

**外部キー制約:**
```ruby
add_foreign_key :lesson_records, :lessons, column: :lesson_id
```

外部キー制約により、以下が保証されます：
- `lesson_records.lesson_id` は、必ず `lessons.id` に存在する値でなければならない
- 存在しないレッスンへの参照を防止（データ整合性の保証）
- 親レコード（Lesson）を削除すると、子レコード（LessonRecord）も削除される（`dependent: :destroy`）

**インデックス:**
```ruby
add_index :lesson_records, :lesson_id
```

インデックスにより、以下が向上します：
- JOINクエリのパフォーマンス向上
- `WHERE lesson_id = ?` のような検索クエリが高速化

**セット運用のベストプラクティス:**
- 外部キー制約を追加する場合、必ずインデックスも追加する
- インデックスなしだと、外部キー制約のチェック時にフルテーブルスキャンが発生し、パフォーマンスが低下する

---

### Flexitypeプロジェクトでの実例

#### 実際のマイグレーション実行結果

**Phase 1実行:**
```bash
$ rails db:migrate:up VERSION=20251224053646
== 20251224053646 CleanupLessonRecordsData: migrating ========================
✓ 古いcategoryフィールド使用のレコード（2件)を削除
✓ lesson_id が nil のレコード（29件）を lesson_name から自動マッチングして更新

データクリーンアップ完了:
  Total records: 31
  With lesson_id: 31
  Remaining nil: 0
== 20251224053646 CleanupLessonRecordsData: migrated (0.0234s) ===============
```

**Phase 2実行:**
```bash
$ rails db:migrate:up VERSION=20251224053733
== 20251224053733 CleanupLessonRecordsSchema: migrating ======================
✓ lesson_id を string → bigint に変更
✓ category カラムを削除
== 20251224053733 CleanupLessonRecordsSchema: migrated (0.0156s) =============
```

**Phase 3実行:**
```bash
$ rails db:migrate:up VERSION=20251224053929
== 20251224053929 AddForeignKeyConstraintsToLessonRecords: migrating =========
✓ lesson_id に NOT NULL 制約を追加
✓ lesson_records → lessons の外部キー制約を追加
✓ lesson_id にインデックスを追加
== 20251224053929 AddForeignKeyConstraintsToLessonRecords: migrated (0.0089s)
```

#### LessonとCategoryモデルでの活用

```ruby
# app/models/lesson.rb
class Lesson < ApplicationRecord
  belongs_to :user
  belongs_to :category
  has_many :lesson_records, dependent: :destroy

  # カテゴリーの設定を継承（delegate パターン）
  delegate :requires_login, :premium, to: :category

  # バリデーション
  validates :items, presence: true  # JSONB型、配列が空でないことを検証

  # JavaScript用のレッスン情報をJSON形式で返す
  def to_lesson_info
    {
      lesson_id: id,                    # ✅ bigint型のID
      category_name: category.name,     # ✅ 関連付けを通じて取得
      lesson_name: name,
      items: items,                     # ✅ JSONB型の配列をそのまま返す
      count: count
    }
  end
end
```

```ruby
# app/models/category.rb
class Category < ApplicationRecord
  has_many :lessons, dependent: :destroy

  # バリデーション
  validates :name, presence: true, uniqueness: true

  # スコープ
  scope :ordered, -> { order(display_order: :asc) }
  scope :published, -> { where(published: true) }
end
```

**使用箇所:**

1. **LessonsController#show:**
```ruby
# app/controllers/lessons_controller.rb
def show
  @lesson = Lesson.find(params[:id])
  @lesson_info = @lesson.to_lesson_info  # ✅ JSONB型のitemsをJavaScriptに渡す
end
```

2. **JavaScript（タイピング練習）:**
```javascript
// app/javascript/controllers/typing_controller.js
fetch(`/lessons/${lessonId}`)
  .then(response => response.json())
  .then(data => {
    this.items = data.items;  // ✅ JSONB型の配列を直接使用
    this.startTyping();
  });
```

3. **練習記録の保存:**
```javascript
// 練習完了時にPOSTリクエスト
const recordData = {
  lesson_id: lessonInfo.lesson_id,  // ✅ bigint型のIDを送信
  word_count: completedWords,
  mistake_count: mistakes,
  duration_seconds: elapsedTime,
  completed_at: new Date().toISOString()
};

fetch('/my/history', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ lesson_record: recordData })
});
```

#### 外部キー制約の効果

**制約なし（改善前）:**
```ruby
# 存在しないレッスンへの参照が可能（データ不整合）
LessonRecord.create!(
  lesson_id: 99999,  # 存在しないID
  user_id: 1,
  # ...
)
# → 保存成功（問題あり）
```

**制約あり（改善後）:**
```ruby
# 存在しないレッスンへの参照を防止
LessonRecord.create!(
  lesson_id: 99999,  # 存在しないID
  user_id: 1,
  # ...
)
# → ActiveRecord::InvalidForeignKey エラー
# → データ整合性が保証される
```

---

## 💡 まとめ

### 重要ポイント

- ✅ **3段階マイグレーション戦略**により、データ移行のリスクを最小化できる
  - Phase 1: データクリーンアップ（古いデータ削除、nil データ自動マッチング）
  - Phase 2: スキーマクリーンアップ（型変更、不要カラム削除）
  - Phase 3: データ整合性確保（NOT NULL、外部キー、インデックス）

- ✅ **PostgreSQLの型キャスト機能**（`using: 'column::type'`）を活用することで、安全な型変換が可能
  - 文字列型の数値ID → bigint型に変換
  - Railsの標準的な型変換ではエラーになるケースでも対応可能

- ✅ **外部キー制約とNOT NULL制約**により、データ整合性が保証される
  - 存在しないレッスンへの参照を防止
  - nilデータの保存を防止
  - データベースレベルでの整合性チェック

- ✅ **JSONB型の活用**により、柔軟なデータ構造を実現できる
  - スキーマ変更なしで配列の要素数を自由に変更
  - PostgreSQLのクエリ機能で高速な検索が可能
  - ActiveRecordで配列として扱える（シリアライズ不要）

- ✅ **本番環境でのデータ移行**では、以下のベストプラクティスを守る
  - データ移行スクリプトは必ずRakeタスク化
  - デプロイチェックリストを作成し、忘れずに実施
  - デプロイ後は必ずデータ確認

### 次のステップ

このトピックを理解したら、以下に進むことをお勧めします：

- [ActiveRecordスコープとクエリ最適化](../02_intermediate/05_activerecord_scopes.md)
- [RSpecによるモデルテスト](../02_intermediate/06_rspec_models.md)
- [レビューテスト: データベース設計](../../reviews/review_04_database_design.md)

---

## 🔗 関連教材

- [Delegateパターンとコード整理](../02_intermediate/02_delegate_pattern.md)
- [Turbo Framesの活用](../02_intermediate/03_turbo_frames.md)
- [レビューテスト: データベース設計](../../reviews/review_04_database_design.md)

---

## 📝 演習問題（オプション）

### 問題1: JSONB型のマイグレーション

以下の要件を満たすマイグレーションを作成してください：

**要件:**
- `articles` テーブルに `metadata` カラムを追加（JSONB型）
- デフォルト値は空のハッシュ `{}`
- NOT NULL制約を付ける

<details>
<summary>解答例を表示</summary>

```ruby
class AddMetadataToArticles < ActiveRecord::Migration[8.1]
  def change
    add_column :articles, :metadata, :jsonb, default: {}, null: false
    add_index :articles, :metadata, using: :gin  # GINインデックスを追加
  end
end
```

**解説:**
- `jsonb` 型を指定することで、PostgreSQLのJSONB型カラムが作成される
- `default: {}` で空のハッシュをデフォルト値に設定
- `null: false` でNOT NULL制約を追加
- `using: :gin` でGINインデックスを作成（JSONB型の検索を高速化）

</details>

---

### 問題2: 3段階マイグレーション戦略

以下の状況で、3段階マイグレーション戦略を適用してください：

**現状:**
- `orders` テーブルに `product_name` カラム（string型）がある
- `products` テーブルに製品マスターがある
- 100件の注文レコードがあり、そのうち10件は `product_name` が nil

**目標:**
- `orders.product_id` カラム（bigint型、外部キー）を追加
- `product_name` から `product_id` を自動マッチング
- `product_name` カラムを削除（非正規化の解消）

<details>
<summary>解答例を表示</summary>

**Phase 1: データクリーンアップ**
```ruby
class CleanupOrdersData < ActiveRecord::Migration[8.1]
  def up
    # Step 1: product_name が nil の注文を削除（またはデフォルト製品に設定）
    Order.where(product_name: nil).delete_all
    puts "✓ product_name が nil の注文（10件）を削除"

    # Step 2: product_id カラムを追加（一時的に null 許可）
    add_column :orders, :product_id, :bigint
    puts "✓ product_id カラムを追加"

    # Step 3: product_name から product_id を自動マッチング
    Order.where(product_id: nil).find_each do |order|
      matching_product = Product.find_by(name: order.product_name)

      if matching_product
        order.update_column(:product_id, matching_product.id)
      else
        puts "⚠️  Warning: No matching product for order ID #{order.id}, product_name: #{order.product_name}"
      end
    end
    puts "✓ product_name から product_id を自動マッチング完了"
  end

  def down
    remove_column :orders, :product_id
  end
end
```

**Phase 2: スキーマクリーンアップ**
```ruby
class CleanupOrdersSchema < ActiveRecord::Migration[8.1]
  def up
    # product_name カラムを削除
    remove_column :orders, :product_name
    puts "✓ product_name カラムを削除"
  end

  def down
    add_column :orders, :product_name, :string
  end
end
```

**Phase 3: データ整合性の確保**
```ruby
class AddForeignKeyConstraintsToOrders < ActiveRecord::Migration[8.1]
  def up
    # Step 1: NOT NULL 制約を追加
    change_column_null :orders, :product_id, false
    puts "✓ product_id に NOT NULL 制約を追加"

    # Step 2: 外部キー制約を追加
    add_foreign_key :orders, :products, column: :product_id
    puts "✓ orders → products の外部キー制約を追加"

    # Step 3: インデックスを追加
    add_index :orders, :product_id unless index_exists?(:orders, :product_id)
    puts "✓ product_id にインデックスを追加"
  end

  def down
    remove_index :orders, :product_id, if_exists: true
    remove_foreign_key :orders, :products
    change_column_null :orders, :product_id, true
  end
end
```

**ポイント:**
- Phase 1で nil データを削除してから、Phase 3でNOT NULL制約を追加
- product_id カラムはPhase 1で追加し、Phase 2で product_name を削除
- 各フェーズで `puts` を使って実行結果を出力し、デバッグを容易に

</details>

---

**作成日**: 2026-01-01
**難易度**: 🟡 中級
**推定学習時間**: 2〜3時間
