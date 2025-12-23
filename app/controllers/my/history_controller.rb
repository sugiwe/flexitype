class My::HistoryController < My::ApplicationController
  def index
    @period = params[:period] || "all"

    # 期間でフィルタリング
    @filtered_records = filter_by_period(current_user.lesson_records, @period)

    # ページネーション付きで履歴を取得
    @lesson_records = @filtered_records.recent.page(params[:page]).per(20)

    # 統計情報を計算（フィルタリング後のレコードで計算）
    @total_count = @filtered_records.count
    @average_accuracy = @filtered_records.average(:accuracy)&.round(1) || 0
  end

  def create
    # レッスン記録データを保存
    @lesson_record = current_user.lesson_records.build(lesson_record_params)
    @lesson_record.completed_at = Time.current

    if @lesson_record.save
      render json: { success: true, message: "練習履歴を保存しました", lesson_record_id: @lesson_record.id }
    else
      render json: { success: false, errors: @lesson_record.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def filter_by_period(records, period)
    case period
    when "week"
      records.where("completed_at >= ?", 1.week.ago)
    when "month"
      records.where("completed_at >= ?", 1.month.ago)
    else
      records # 全期間
    end
  end

  def lesson_record_params
    params.require(:lesson_record).permit(
      :category,
      :lesson_id,
      :lesson_name,
      :word_count,
      :correct_count,
      :mistake_count,
      :accuracy,
      :duration_seconds,
      :typed_chars
    )
  end
end
