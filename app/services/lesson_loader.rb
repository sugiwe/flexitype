# frozen_string_literal: true

# レッスンデータをYAMLファイルから読み込むサービスクラス
# 数値IDベースでレッスンを管理（将来的なDB化を見据えた設計）
class LessonLoader
  LESSONS_FILE = Rails.root.join("config/typing_lessons.yml")

  # 全レッスンデータを読み込む（カテゴリごと）
  def self.all_lessons
    @all_lessons ||= YAML.load_file(LESSONS_FILE)["lessons"]
  end

  # 全レッスンをフラットな配列として取得（ID順）
  def self.all_lessons_flat
    @all_lessons_flat ||= begin
      lessons = []
      all_lessons.each_value do |category_data|
        category_data["lessons"].each do |lesson|
          lesson["category"] = category_data["category"]
          lesson["category_description"] = category_data["description"]
          lesson["requires_login"] = category_data["requires_login"]
          lesson["premium"] = category_data["premium"]
          lessons << lesson
        end
      end
      lessons.sort_by { |l| l["id"] }
    end
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

  # 数値IDから特定のレッスンを取得
  def self.find_lesson(id)
    id = id.to_i
    all_lessons_flat.find { |lesson| lesson["id"] == id }
  end

  # レッスンIDから練習用の単語/文章リストを取得
  def self.get_practice_items(id)
    lesson = find_lesson(id)
    return [] unless lesson

    # itemsフィールドから指定された数だけランダムに取得
    items = lesson["items"] || []
    count = lesson["count"] || 20

    # ランダムに並び替えて指定数だけ取得
    items.shuffle.take(count)
  end

  # レッスンIDから完全なレッスン情報を取得
  def self.get_lesson_info(id)
    lesson = find_lesson(id)
    return nil unless lesson

    {
      id: lesson["id"],
      category_name: lesson["category"],
      category_description: lesson["category_description"],
      lesson_name: lesson["name"],
      lesson_description: lesson["description"],
      lesson_type: lesson["type"],
      count: lesson["count"],
      requires_login: lesson["requires_login"],
      premium: lesson["premium"]
    }
  end
end
