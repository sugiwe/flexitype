class LessonsController < ApplicationController
  def show
    # URLパラメータから数値IDを取得
    lesson_id = params[:id]

    # レッスン情報を取得
    @lesson_info = LessonLoader.get_lesson_info(lesson_id)

    # 練習用の単語/文章を取得
    @words = LessonLoader.get_lesson_items(lesson_id)

    # レッスンが見つからない場合は404
    if @lesson_info.nil? || @words.empty?
      redirect_to root_path, alert: "レッスンが見つかりませんでした。"
      return
    end

    # キーマップを読み込む（ユーザーのキーマップまたはデフォルト）
    user_id = logged_in? ? current_user.id : nil
    @keymaps = Keymap.all_layers_for_user_or_default(user_id)
  end
end
