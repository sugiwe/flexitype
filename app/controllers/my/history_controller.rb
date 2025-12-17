class My::HistoryController < My::ApplicationController
  def index
    # ページネーション付きで履歴を取得
    @sessions = current_user.typing_sessions.recent.page(params[:page]).per(20)

    # 統計情報を計算
    @total_count = current_user.typing_sessions.count
    @average_accuracy = current_user.typing_sessions.average(:accuracy)&.round(1) || 0
  end

  def create
    # セッションデータを保存
    @session = current_user.typing_sessions.build(session_params)
    @session.completed_at = Time.current

    if @session.save
      render json: { success: true, message: "練習履歴を保存しました" }
    else
      render json: { success: false, errors: @session.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def session_params
    params.require(:session).permit(
      :category,
      :lesson_id,
      :lesson_name,
      :word_count,
      :correct_count,
      :mistake_count,
      :accuracy,
      :duration_seconds
    )
  end
end
