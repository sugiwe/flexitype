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
