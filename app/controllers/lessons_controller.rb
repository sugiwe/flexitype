class LessonsController < ApplicationController
  def show
    # レッスンを取得
    @lesson = Lesson.includes(:category).find_by(id: params[:id])

    # レッスンが見つからない場合は404
    unless @lesson
      redirect_to root_path, alert: "レッスンが見つかりませんでした。"
      return
    end

    # 練習用の単語/文章を取得（ランダム）
    @words = @lesson.items.shuffle.take(@lesson.count)

    # キーマップを読み込む（ユーザーのキーマップまたはデフォルト）
    user_id = logged_in? ? current_user.id : nil
    @keymaps = Keymap.all_layers_for_user_or_default(user_id)
  end
end
