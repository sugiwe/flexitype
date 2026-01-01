# Review Test #04: データベース設計とマイグレーション戦略

**難易度**: 🟡 中級
**推定時間**: 30分〜1時間
**学習トピック**: [データベース設計とマイグレーション戦略](../topics/02_intermediate/04_database_design.md)

---

## 前提条件

あなたはFlexitypeプロジェクトのコードレビュアーです。
以下のPRがレビュー待ちになっています。

## PR概要

- **タイトル**: レッスン記録の外部キー制約追加
- **変更ファイル数**: 1ファイル
- **目的**: `lesson_records` テーブルに外部キー制約を追加し、データ整合性を保証する

## 変更内容

### 1. `db/migrate/20251224100000_add_lesson_foreign_key.rb` (新規作成)

```ruby
class AddLessonForeignKey < ActiveRecord::Migration[8.1]
  def change
    # 外部キー制約を追加
    add_foreign_key :lesson_records, :lessons, column: :lesson_id

    # インデックスを追加
    add_index :lesson_records, :lesson_id
  end
end
```

**約6行のコード**

### 現在のスキーマ状態

```ruby
# db/schema.rb（抜粋）
create_table "lesson_records", force: :cascade do |t|
  t.string "lesson_id"              # ⚠️ string型
  t.bigint "user_id", null: false
  t.string "lesson_name"
  t.integer "word_count"
  t.integer "mistake_count"
  t.integer "duration_seconds"
  t.string "category"               # ⚠️ 古いカラム
  t.datetime "completed_at"
  t.datetime "created_at", null: false
  t.datetime "updated_at", null: false
end

create_table "lessons", force: :cascade do |t|
  t.bigint "user_id", null: false
  t.bigint "category_id", null: false
  t.string "name", null: false
  t.jsonb "items", default: [], null: false
  t.integer "count", default: 0, null: false
  # ...
end
```

### データベースの実態

```sql
-- lesson_records テーブルの分析結果
総レコード数: 33件
  - category フィールドあり: 2件（2025-12-16のYAMLベース）
  - lesson_id が nil: 29件
  - lesson_id あり（文字列ID）: 4件
```

---

## レビュー課題

### Q1. スキーマ設計の問題点（初級）🟢

このマイグレーションファイルと現在のスキーマを見て、以下の問題点を指摘してください。

1. `lesson_id` カラムの型について、どのような問題がありますか？
2. 外部キー制約を追加する前に、データに対してどのような問題が発生する可能性がありますか？
3. `category` カラムについて、どのような問題が考えられますか？

**回答時間の目安**: 5分

<details>
<summary>解答を表示</summary>

### A1. スキーマ設計の問題点

**1. `lesson_id` カラムの型の問題:**

現在、`lesson_id` は string型ですが、`lessons.id` は bigint型です。これにより、以下の問題が発生します：

- **型不一致エラー**: `LessonRecord.joins(:lesson)` などのJOINクエリで、`operator does not exist: bigint = character varying` エラーが発生する
- **パフォーマンス低下**: string型と bigint型の比較は、型変換が必要なため遅い
- **インデックス非効率**: string型のインデックスは、bigint型より非効率

**解決策**: `lesson_id` を bigint型に変更する必要があります。

**2. 外部キー制約を追加する前のデータ問題:**

現在のデータ状態を見ると、以下の問題があります：

- **29件のレコードで `lesson_id` が nil**: 外部キー制約は nil を許可しますが、これらのレコードは有効なレッスンと関連付けられていません
- **2件のレコードで `category` フィールドを使用**: これらは古いデータ構造で、現在のLessonモデルと互換性がありません
- **データ整合性の欠如**: 外部キー制約を追加する前に、これらのデータをクリーンアップする必要があります

**解決策**: 外部キー制約を追加する前に、データクリーンアップが必要です。

**3. `category` カラムの問題:**

- **非正規化**: レッスン名とカテゴリー名を両方保存することで、データの冗長性が発生
- **古いデータ構造の名残**: 現在のLessonモデルは `category_id` を持っているため、`category` string型カラムは不要
- **データの不整合**: カテゴリー名が変更された場合、過去のレコードと現在のカテゴリー名が一致しなくなる

**解決策**: `category` カラムを削除し、`lesson.category.name` を通じて取得するべきです。

</details>

---

### Q2. マイグレーション戦略の問題（中級）🟡

このマイグレーションを本番環境で実行すると、どのようなエラーが発生する可能性がありますか？

1. 外部キー制約の追加で発生する可能性のあるエラーを2つ挙げてください
2. NOT NULL制約がない場合、どのような問題が発生しますか？
3. 型不一致（string vs bigint）による具体的なエラーメッセージを予想してください

**回答時間の目安**: 10分

<details>
<summary>解答を表示</summary>

### A2. マイグレーション戦略の問題

**1. 外部キー制約の追加で発生する可能性のあるエラー:**

**エラー1: 型不一致エラー**
```
PG::DatatypeMismatch: ERROR: foreign key constraint "fk_rails_..."
cannot be implemented
DETAIL: Key columns "lesson_id" and "id" are of incompatible types:
character varying and bigint.
```

原因: `lesson_records.lesson_id` は string型だが、`lessons.id` は bigint型。PostgreSQLは異なる型同士の外部キー制約を許可しません。

**エラー2: 参照整合性違反エラー**
```
PG::ForeignKeyViolation: ERROR: insert or update on table "lesson_records"
violates foreign key constraint "fk_rails_..."
DETAIL: Key (lesson_id)=(99999) is not present in table "lessons".
```

原因: 既存のレコードに、`lessons` テーブルに存在しない `lesson_id` が含まれている場合（例: nil や存在しないIDの文字列）。

**2. NOT NULL制約がない場合の問題:**

NOT NULL制約がないと、以下の問題が発生します：

- **nilデータの保存が可能**: `lesson_id: nil` で保存できてしまい、レッスンと関連付けられない記録が作成される
- **JOINクエリの結果が不完全**: `LessonRecord.joins(:lesson)` で `lesson_id` が nil のレコードは除外される（内部結合のため）
- **ビジネスロジックの破綻**: レッスン名や統計情報を取得できず、アプリケーションエラーが発生

**解決策**: 外部キー制約を追加する前に、NOT NULL制約を追加する必要があります。

**3. 型不一致による具体的なエラーメッセージ:**

**マイグレーション実行時:**
```bash
$ rails db:migrate
== 20251224100000 AddLessonForeignKey: migrating =============================
-- add_foreign_key(:lesson_records, :lessons, {:column=>:lesson_id})
rails aborted!
StandardError: An error has occurred, this and all later migrations canceled:

PG::DatatypeMismatch: ERROR:  foreign key constraint "fk_rails_abc123"
cannot be implemented
DETAIL:  Key columns "lesson_id" and "id" are of incompatible types:
character varying and bigint.
```

**ActiveRecordでのJOINクエリ時:**
```ruby
LessonRecord.joins(:lesson)
# => ActiveRecord::StatementInvalid: PG::UndefinedFunction: ERROR:
#    operator does not exist: bigint = character varying
#    HINT:  No operator matches the given name and argument types.
#    You might need to add explicit type casts.
```

</details>

---

### Q3. 3段階マイグレーション戦略の提案（中級〜上級）🟡🔴

このPRを承認する代わりに、3段階マイグレーション戦略を提案してください。

1. Phase 1（データクリーンアップ）でどのような処理を実施すべきですか？具体的なコードで示してください
2. Phase 2（スキーマクリーンアップ）でどのような処理を実施すべきですか？PostgreSQLの型キャスト機能（`using: 'column::type'`）を使った解決方法を示してください
3. Phase 3（データ整合性確保）でどのような処理を実施すべきですか？外部キー制約、NOT NULL制約、インデックスの追加順序に注意してください

**回答時間の目安**: 15分

<details>
<summary>解答を表示</summary>

### A3. 3段階マイグレーション戦略の提案

#### Phase 1: データクリーンアップ

```ruby
class CleanupLessonRecordsData < ActiveRecord::Migration[8.1]
  def up
    # Step 1: 古いデータ（category フィールド使用）を削除
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

**ポイント:**
- 古いデータ（`category` フィールド使用）を削除
- nil の `lesson_id` を `lesson_name` から自動マッチング
- 結果を `puts` で出力し、確認しやすくする
- `update_column` を使って、バリデーションをスキップ（高速化）

---

#### Phase 2: スキーマクリーンアップ

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

**ポイント:**
- **PostgreSQLの型キャスト機能を使用**: `using: 'lesson_id::bigint'`
  - 文字列型の数値ID（例: `"123"`）をbigint型（例: `123`）に変換
  - Railsの標準的な型変換ではエラーになるケースでも対応可能
- 不要な `category` カラムを削除（非正規化の解消）
- `down` メソッドでロールバック可能にする（ただしデータは復元できない）

**PostgreSQLキャスト構文の仕組み:**
```sql
-- PostgreSQLのキャスト構文
SELECT '123'::bigint;  -- "123"（string）→ 123（bigint）
SELECT '456'::integer; -- "456"（string）→ 456（integer）

-- Railsマイグレーションでの使用例
change_column :lesson_records, :lesson_id, :bigint, using: 'lesson_id::bigint'
#                                                           ↑↑↑↑↑↑↑↑↑↑↑
#                                           PostgreSQL固有のキャスト構文
```

---

#### Phase 3: データ整合性の確保

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

**ポイント:**
- **順序が重要**:
  1. NOT NULL制約（必須データの保証）
  2. 外部キー制約（参照整合性の保証）
  3. インデックス（パフォーマンス向上）
- `unless index_exists?` で重複インデックス作成を防止
  - Rails 8では `unless_exists:` オプションが存在しないため、条件分岐を使用
- `down` メソッドで逆順にロールバック

**外部キー制約とインデックスの関係:**
- 外部キー制約を追加する場合、必ずインデックスも追加する
- インデックスなしだと、外部キー制約のチェック時にフルテーブルスキャンが発生し、パフォーマンスが低下
- セット運用がベストプラクティス

**コード削減効果:**
- 元のPR: 1つのマイグレーションファイル、約6行
- 改善後: 3つのマイグレーションファイル、合計約80行
- **リスク削減効果**: 各フェーズで問題が発生した場合でも、個別にロールバックが可能

</details>

---

### Q4. JSONB型の設計判断と本番環境でのデータ移行戦略（上級）🔴

このPRには含まれていませんが、Lessonモデルでは `items` カラムにJSONB型を使用しています。以下について考察してください。

1. JSONB型を使う判断基準は何ですか？どのような場合にJSONB型が適切で、どのような場合に別テーブルに分けるべきですか？
2. Day 21の本番環境でのデータ消失事故について、どのような対策を取るべきでしたか？デプロイチェックリストを3つ以上提案してください
3. もし本番環境で外部キー制約の追加に失敗した場合、どのようにリカバリーすべきですか？具体的な手順を示してください

**回答時間の目安**: 10分

<details>
<summary>解答を表示</summary>

### A4. JSONB型の設計判断と本番環境でのデータ移行戦略

#### 1. JSONB型を使う判断基準

**JSONB型が適切な場合:**

- **柔軟なデータ構造が必要**: スキーマが頻繁に変わる、または要素数が不定
- **配列やハッシュをそのまま保存**: タイピング練習の問題リスト（文字列の配列）など
- **検索頻度が低い**: 主にIDで取得し、詳細データを一括で表示する場合
- **リレーションシップが不要**: 他のテーブルとのJOINが不要な場合

**Flexitypeでの使用例:**
```ruby
# app/models/lesson.rb
class Lesson < ApplicationRecord
  # items: ["apple", "banana", "cherry", ...]
  validates :items, presence: true
end

# JSONB型の利点:
# - 問題数（count）を動的に変更できる
# - スキーマ変更なしで新しい問題を追加
# - 配列として簡単にアクセス可能
```

**別テーブルに分けるべき場合:**

- **検索が必要**: 特定の単語を含むレッスンを検索する場合
- **リレーションシップが必要**: 問題ごとに難易度、カテゴリーなどのメタデータが必要
- **データ量が大きい**: 1レッスンあたり100個以上の問題がある場合
- **頻繁な更新**: 問題を個別に更新する必要がある場合

**別テーブル設計の例:**
```ruby
# app/models/lesson_item.rb
class LessonItem < ApplicationRecord
  belongs_to :lesson
  validates :content, presence: true
end

# 検索が容易:
LessonItem.where("content LIKE ?", "%apple%")

# ただし、レコード数が増えるとパフォーマンスが低下
```

**判断基準まとめ:**
| 要件 | JSONB型 | 別テーブル |
|------|---------|-----------|
| 柔軟なデータ構造 | ✅ | ❌ |
| 検索頻度 | 低い | 高い |
| リレーションシップ | 不要 | 必要 |
| データ量 | 小〜中 | 大 |
| 更新頻度 | 低い | 高い |

---

#### 2. Day 21の本番環境でのデータ消失事故の対策

**事故の概要（Day 21）:**
- レッスンのDB化（YAML → PostgreSQL）を実施
- マイグレーション（`rails db:migrate`）でテーブル構造は変更された
- しかし、YAMLからDBへのデータ移行スクリプトを実行していなかった
- 本番環境で全てのレッスンが表示されなくなった

**デプロイチェックリスト（提案）:**

**1. デプロイ前チェック:**
- [ ] **マイグレーションファイルの確認**
  - `up` メソッドと `down` メソッドが正しく実装されているか
  - ロールバック可能か（`IrreversibleMigration` の場合は理由を明記）
  - `puts` で実行結果を出力しているか（デバッグ用）

- [ ] **データ移行スクリプトのRakeタスク化**
  - `lib/tasks/` にRakeタスクを作成
  - 冪等性（べきとうせい）を確保（複数回実行しても安全）
  - 実行結果を出力（何件移行したか）

- [ ] **ローカル環境でのテスト**
  - `rails db:migrate` でマイグレーションが正常に実行されるか
  - データ移行Rakeタスクが正常に実行されるか
  - アプリケーションが正常に動作するか

**2. デプロイ中チェック:**
- [ ] **デプロイログの確認**
  - `kamal deploy` の実行ログを確認
  - エラーメッセージがないか
  - マイグレーションが正常に実行されたか

- [ ] **データ移行Rakeタスクの実行**
  - デプロイ後、Rakeタスクを実行
  - 実行結果を確認（何件移行したか）

**3. デプロイ後チェック:**
- [ ] **アプリケーションの起動確認**
  - ブラウザでアプリケーションにアクセス
  - トップページが正常に表示されるか
  - レッスン一覧が表示されるか

- [ ] **主要機能の動作確認**
  - タイピング練習が開始できるか
  - 練習記録が保存されるか
  - エラーページが表示されないか

- [ ] **エラーログの確認**
  - Kamalの場合: `kamal app logs`
  - 500エラー、データベースエラーがないか
  - JavaScript エラーがないか

**4. ロールバック計画:**
- [ ] **ロールバック手順の準備**
  - `rails db:rollback` でマイグレーションを戻せるか
  - データベースバックアップからの復元手順
  - 前のバージョンへのロールバック手順（`kamal rollback`）

**追加の対策:**
- **ステージング環境の構築**: 本番環境と同じ構成で、デプロイ前にテスト
- **データベースバックアップの自動化**: デプロイ前に自動的にバックアップを取得
- **モニタリングツールの導入**: エラートラッキング（Sentry）、パフォーマンス監視

---

#### 3. 本番環境で外部キー制約の追加に失敗した場合のリカバリー手順

**シナリオ1: 型不一致エラーで失敗**

**エラー内容:**
```
PG::DatatypeMismatch: ERROR: foreign key constraint "fk_rails_..."
cannot be implemented
DETAIL: Key columns "lesson_id" and "id" are of incompatible types:
character varying and bigint.
```

**リカバリー手順:**

1. **マイグレーションのロールバック:**
```bash
# ローカル環境で確認
kamal app exec --roles=web 'bin/rails db:rollback'
```

2. **3段階マイグレーション戦略の作成:**
   - Phase 1: データクリーンアップ（前述）
   - Phase 2: スキーマクリーンアップ（型変換）
   - Phase 3: データ整合性確保（外部キー制約）

3. **再デプロイ:**
```bash
git add db/migrate/
git commit -m "外部キー制約追加を3段階マイグレーションに変更"
git push origin feature/add-foreign-keys
kamal deploy
```

4. **各フェーズの実行確認:**
```bash
# Phase 1実行
kamal app exec --roles=web 'bin/rails db:migrate:up VERSION=20251224053646'

# Phase 2実行
kamal app exec --roles=web 'bin/rails db:migrate:up VERSION=20251224053733'

# Phase 3実行
kamal app exec --roles=web 'bin/rails db:migrate:up VERSION=20251224053929'
```

---

**シナリオ2: 参照整合性違反エラーで失敗**

**エラー内容:**
```
PG::ForeignKeyViolation: ERROR: insert or update on table "lesson_records"
violates foreign key constraint "fk_rails_..."
DETAIL: Key (lesson_id)=(99999) is not present in table "lessons".
```

**リカバリー手順:**

1. **マイグレーションのロールバック:**
```bash
kamal app exec --roles=web 'bin/rails db:rollback'
```

2. **不正なデータの調査:**
```bash
# 本番環境で不正なデータを確認
kamal app exec --roles=web 'bin/rails runner "
  invalid_records = LessonRecord.left_joins(:lesson).where(lessons: { id: nil })
  puts \"Invalid records: #{invalid_records.count}\"
  invalid_records.each do |record|
    puts \"ID: #{record.id}, lesson_id: #{record.lesson_id}\"
  end
"'
```

3. **データクリーンアップマイグレーションの作成:**
```ruby
class CleanupInvalidLessonRecords < ActiveRecord::Migration[8.1]
  def up
    # 存在しないレッスンへの参照を持つレコードを削除
    invalid_records = LessonRecord.left_joins(:lesson).where(lessons: { id: nil })
    count = invalid_records.count
    invalid_records.delete_all
    puts "✓ 不正なレコード（#{count}件）を削除"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
```

4. **再デプロイと外部キー制約の再試行:**
```bash
git add db/migrate/
git commit -m "不正なレコードをクリーンアップしてから外部キー制約を追加"
kamal deploy
```

---

**シナリオ3: ダウンタイムを最小化したい場合**

**戦略: Bluegreen Deployment（新旧バージョンの並行稼働）**

1. **Phase 1, 2を先にデプロイ（外部キー制約なし）:**
   - データクリーンアップと型変換のみ実施
   - アプリケーションは正常に動作

2. **アプリケーションの動作確認:**
   - データが正しく表示されるか
   - 新規レコード作成が正常に動作するか

3. **Phase 3を別のデプロイで実施（外部キー制約追加）:**
   - アプリケーションのダウンタイムなし
   - 外部キー制約追加中もアプリケーションは動作

**メリット:**
- ダウンタイムを最小化
- 各フェーズで問題が発生した場合でも、ロールバックが容易
- ユーザーへの影響を最小限に抑える

#### まとめ

外部キー制約の追加に失敗した場合のリカバリーのポイント:

1. **冷静にロールバック**: まずマイグレーションをロールバックして、安定した状態に戻す
2. **問題の原因を特定**: エラーメッセージを読み、データの実態を調査
3. **段階的にアプローチ**: 3段階マイグレーション戦略で、各フェーズを個別に実施
4. **本番環境でのテスト**: 各フェーズで実行結果を確認し、次のフェーズに進む
5. **ダウンタイムの最小化**: 可能であれば、外部キー制約なしでアプリケーションを稼働させ、後から制約を追加

</details>

---

## 総合評価

### 基準

- **Q1を正解**: スキーマ設計の基本的な問題点を理解している
- **Q2を正解**: マイグレーション実行時のエラーを予測し、リスクを理解している
- **Q3を正解**: 3段階マイグレーション戦略を理解し、実践できる
- **Q4を正解**: JSONB型の設計判断、本番環境でのデータ移行戦略を理解している

### 次のステップ

- **Q1のみ正解**: スキーマ設計の基本を理解しています。マイグレーション戦略について、さらに学習しましょう。[トピック教材](../topics/02_intermediate/04_database_design.md)の「実装後」セクションを再読してください。

- **Q1-Q2正解**: マイグレーション実行時のエラーを予測できます。3段階マイグレーション戦略について学び、実際のコードを書いてみましょう。

- **Q1-Q3正解**: 3段階マイグレーション戦略を理解しています。JSONB型の設計判断や本番環境でのデータ移行について、さらに学習しましょう。Day 21の日報を読み、実際の事故事例から学んでください。

- **全問正解**: データベース設計とマイグレーション戦略を完全に理解しています！次は、[ActiveRecordスコープとクエリ最適化](../topics/02_intermediate/05_activerecord_scopes.md)に進み、さらなるスキルアップを目指しましょう。

## 参考資料

- [データベース設計とマイグレーション戦略](../topics/02_intermediate/04_database_design.md)
- [Delegateパターンとコード整理](../topics/02_intermediate/02_delegate_pattern.md)
- Day 21の日報: `docs/daily_reports/2025-12-21.md`
- Day 24の日報: `docs/daily_reports/2025-12-24.md`
- 実際のPR: #96

---

**作成日**: 2026-01-01
**難易度**: 🟡 中級
**推定時間**: 30分〜1時間
