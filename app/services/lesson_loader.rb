# frozen_string_literal: true

# レッスンデータをDBから読み込むサービスクラス
# Lessonモデルと Categoryモデルを使用
class LessonLoader
  # 全レッスンデータを読み込む（カテゴリごと）
  # 戻り値: Hash形式（YAMLからの移行互換性のため）
  def self.all_lessons
    # カテゴリーごとにハッシュを構築
    Category.ordered.includes(:lessons).each_with_object({}) do |category, result|
      # カテゴリーキーはIDベースで生成（日本語名に対応）
      key = "category_#{category.id}"

      result[key] = {
        "category" => category.name,
        "description" => category.description,
        "requires_login" => category.requires_login,
        "premium" => category.premium,
        "lessons" => category.lessons.map do |lesson|
          {
            "id" => lesson.id,
            "name" => lesson.name,
            "description" => lesson.description,
            "items" => lesson.items,
            "count" => lesson.count
          }
        end
      }
    end
  end

  # 全レッスンをフラットな配列として取得（ID順）
  def self.all_lessons_flat
    Lesson.includes(:category).order(:id).map do |lesson|
      {
        "id" => lesson.id,
        "name" => lesson.name,
        "description" => lesson.description,
        "items" => lesson.items,
        "count" => lesson.count,
        "category" => lesson.category.name,
        "category_description" => lesson.category.description,
        "requires_login" => lesson.requires_login,
        "premium" => lesson.premium
      }
    end
  end

  # カテゴリごとにグループ化されたレッスンを取得
  # ログイン状態に応じてフィルタリング
  def self.available_categories(logged_in: false)
    categories = Category.ordered.includes(:lessons).free

    # ログイン要件でフィルタリング
    unless logged_in
      categories = categories.where(requires_login: false)
    end

    # ハッシュ形式で返す（YAMLからの移行互換性のため）
    categories.each_with_object({}) do |category, result|
      # カテゴリーキーはIDベースで生成（日本語名に対応）
      key = "category_#{category.id}"

      result[key] = {
        "category" => category.name,
        "description" => category.description,
        "requires_login" => category.requires_login,
        "premium" => category.premium,
        "lessons" => category.lessons.map do |lesson|
          {
            "id" => lesson.id,
            "name" => lesson.name,
            "description" => lesson.description,
            "items" => lesson.items,
            "count" => lesson.count
          }
        end
      }
    end
  end

  # 数値IDから特定のレッスンを取得
  def self.find_lesson(id)
    lesson = Lesson.includes(:category).find_by(id: id.to_i)
    return nil unless lesson

    {
      "id" => lesson.id,
      "name" => lesson.name,
      "description" => lesson.description,
      "items" => lesson.items,
      "count" => lesson.count,
      "category" => lesson.category.name,
      "category_description" => lesson.category.description,
      "requires_login" => lesson.requires_login,
      "premium" => lesson.premium
    }
  end

  # レッスンIDから練習用の単語/文章リストを取得
  def self.get_lesson_items(id)
    lesson = Lesson.find_by(id: id.to_i)
    return [] unless lesson

    # itemsフィールドから指定された数だけランダムに取得
    items = lesson.items || []
    count = lesson.count || 20

    # ランダムに並び替えて指定数だけ取得
    items.shuffle.take(count)
  end

  # レッスンIDから完全なレッスン情報を取得
  def self.get_lesson_info(id)
    lesson = Lesson.includes(:category).find_by(id: id.to_i)
    return nil unless lesson

    {
      id: lesson.id,
      category_name: lesson.category.name,
      category_description: lesson.category.description,
      lesson_name: lesson.name,
      lesson_description: lesson.description,
      count: lesson.count,
      requires_login: lesson.requires_login,
      premium: lesson.premium
    }
  end
end
