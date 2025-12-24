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
