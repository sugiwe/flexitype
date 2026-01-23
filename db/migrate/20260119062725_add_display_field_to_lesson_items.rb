class AddDisplayFieldToLessonItems < ActiveRecord::Migration[8.1]
  def up
    # 既存のレッスンアイテムを文字列配列からハッシュ配列に変換
    Lesson.find_each do |lesson|
      next if lesson.items.blank?

      # すでにハッシュ形式の場合はスキップ
      next if lesson.items.first.is_a?(Hash)

      # 文字列配列をハッシュ配列に変換
      lesson.items = lesson.items.map do |item|
        {
          "text" => item,
          "display" => nil
        }
      end

      lesson.save!
    end
  end

  def down
    # ロールバック時は、ハッシュ配列を文字列配列に戻す
    Lesson.find_each do |lesson|
      next if lesson.items.blank?
      next unless lesson.items.first.is_a?(Hash)

      lesson.items = lesson.items.map { |item| item["text"] }
      lesson.save!
    end
  end
end
