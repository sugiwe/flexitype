class PracticeController < ApplicationController
  def index
    # URLパラメータからカテゴリとレッスンIDを取得
    category_key = params[:category] || 'word_practice'
    lesson_id = params[:lesson] || 'beginner_words'

    # レッスン情報を取得
    @lesson_info = LessonLoader.get_lesson_info(category_key, lesson_id)

    # 練習用の単語/文章を取得
    @words = LessonLoader.get_practice_items(category_key, lesson_id)

    # 単語が取得できない場合はデフォルトにフォールバック
    if @words.empty?
      words_data = YAML.load_file(Rails.root.join("config", "typing_words.yml"))
      @words = words_data["beginner"] || []
      @lesson_info = {
        category_name: "単語練習",
        lesson_name: "初級単語",
        lesson_description: "短くて簡単な単語",
        lesson_type: "words",
        count: 20
      }
    end

    # キーマップを読み込む（ユーザーのキーマップまたはデフォルト）
    user_id = logged_in? ? current_user.id : nil
    @keymaps = Keymap.all_layers_for_user_or_default(user_id)
  end
end
