class My::LessonRecordsController < My::ApplicationController
  include LessonRecordCreation

  def index
    @period = params[:period] || "all"

    # 期間でフィルタリング
    @filtered_records = filter_by_period(current_user.lesson_records, @period)

    # ページネーション付きで履歴を取得
    @lesson_records = @filtered_records.recent.page(params[:page]).per(20)

    # 統計情報を計算（フィルタリング後のレコードで計算）
    @total_count = @filtered_records.count
    @average_accuracy = @filtered_records.average(:accuracy)&.round(1) || 0
    @average_wpm = @filtered_records.where.not(wpm: nil).average(:wpm)&.round(1) || 0
  end

  def create
    # Concernの共通メソッドを使用
    create_lesson_record_for(current_user)
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
end
