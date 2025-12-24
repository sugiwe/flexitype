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
