class My::HistoryController < My::ApplicationController
  def index
    # ページネーション付きで履歴を取得
    @lesson_records = current_user.lesson_records.recent.page(params[:page]).per(20)

    # 統計情報を計算
    @total_count = current_user.lesson_records.count
    @average_accuracy = current_user.lesson_records.average(:accuracy)&.round(1) || 0
  end

  def create
    # レッスン記録データを保存
    @lesson_record = current_user.lesson_records.build(lesson_record_params)
    @lesson_record.completed_at = Time.current

    if @lesson_record.save
      render json: { success: true, message: "練習履歴を保存しました" }
    else
      render json: { success: false, errors: @lesson_record.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def lesson_record_params
    params.require(:lesson_record).permit(
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
