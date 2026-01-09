class LessonsController < ApplicationController
  def show
    # レッスンを取得
    @lesson = Lesson.includes(:category).find_by(id: params[:id])

    # レッスンが見つからない場合は404
    unless @lesson
      redirect_to root_path, alert: "レッスンが見つかりませんでした。"
      return
    end

    # 要ログインレッスンのアクセス制御
    if @lesson.requires_login && !logged_in?
      redirect_to root_path, alert: "このレッスンを利用するにはログインが必要です。"
      return
    end

    # 練習用の単語/文章を取得（ランダム）
    @words = @lesson.items.shuffle.take(@lesson.count)

    # キーマップを読み込む（ユーザーのキーマップまたはデフォルト）
    user_id = logged_in? ? current_user.id : nil
    @keymaps = Keymap.all_layers_for_user_or_default(user_id)

    # グレード定義に画像パスとi18n翻訳を追加してJavaScriptに渡す
    @grades_with_paths = LessonGrades::DEFINITIONS.each_with_object({}) do |(grade_key, grade), hash|
      hash[grade_key] = grade.merge(
        image_path: view_context.asset_path(grade[:image]),
        name: I18n.t("grades.#{grade_key}.name"),
        description: I18n.t("grades.#{grade_key}.description")
      )
    end
  end
end
