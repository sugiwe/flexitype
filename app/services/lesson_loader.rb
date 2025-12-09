# frozen_string_literal: true

# レッスンデータをYAMLファイルから読み込むサービスクラス
class LessonLoader
  LESSONS_FILE = Rails.root.join("config/typing_lessons.yml")

  # 全レッスンデータを読み込む
  def self.all_lessons
    @all_lessons ||= YAML.load_file(LESSONS_FILE)["lessons"]
  end

  # カテゴリごとにグループ化されたレッスンを取得
  # ログイン状態に応じてフィルタリング
  def self.available_categories(logged_in: false)
    all_lessons.each_with_object({}) do |(key, category_data), result|
      # ログイン要件をチェック
      next if category_data["requires_login"] && !logged_in
      # プレミアム要件をチェック（将来的に実装）
      next if category_data["premium"]

      result[key] = category_data
    end
  end

  # 特定のレッスンを取得
  def self.find_lesson(category_key, lesson_id)
    category = all_lessons[category_key]
    return nil unless category

    category["lessons"]&.find { |lesson| lesson["id"] == lesson_id }
  end

  # レッスンIDから練習用の単語/文章リストを取得
  def self.get_practice_items(category_key, lesson_id)
    lesson = find_lesson(category_key, lesson_id)
    return [] unless lesson

    # itemsフィールドから指定された数だけランダムに取得
    items = lesson["items"] || []
    count = lesson["count"] || 20

    # ランダムに並び替えて指定数だけ取得
    items.shuffle.take(count)
  end

  # カテゴリキーとレッスンIDから完全なレッスン情報を取得
  def self.get_lesson_info(category_key, lesson_id)
    category = all_lessons[category_key]
    return nil unless category

    lesson = find_lesson(category_key, lesson_id)
    return nil unless lesson

    {
      category_name: category["category"],
      category_description: category["description"],
      lesson_name: lesson["name"],
      lesson_description: lesson["description"],
      lesson_type: lesson["type"],
      count: lesson["count"]
    }
  end
end
