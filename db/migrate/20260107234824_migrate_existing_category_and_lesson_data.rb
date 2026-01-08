class MigrateExistingCategoryAndLessonData < ActiveRecord::Migration[8.1]
  def up
    # 既存のCategoryデータを日本語翻訳として移行
    Category.find_each do |category|
      category.update_columns(
        name_translations: { "ja" => category.name },
        description_translations: { "ja" => category.description.to_s }
      )
    end

    # 既存のLessonデータを日本語翻訳として移行
    Lesson.find_each do |lesson|
      lesson.update_columns(
        name_translations: { "ja" => lesson.name },
        description_translations: { "ja" => lesson.description.to_s }
      )
    end
  end

  def down
    # ロールバック時は何もしない（既存データを保護）
  end
end
