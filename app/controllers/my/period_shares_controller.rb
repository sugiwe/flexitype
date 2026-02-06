# frozen_string_literal: true

module My
  class PeriodSharesController < ApplicationController
    include PeriodHelper
    include TwitterShareable

    before_action :require_login

    # POST /my/period_shares
    def create
      period = params[:period]
      unless Share::PERIODS.key?(period.to_sym)
        redirect_to my_history_index_path, alert: "無効な期間です" and return
      end

      # 期間の日付範囲を計算
      date_range = calculate_date_range(period, timezone: current_user.time_zone)

      # 期間内に練習記録があるかチェック
      records = current_user.lesson_records.where(completed_at: date_range)
      if records.empty?
        period_display = Share::PERIODS[period.to_sym]
        redirect_to my_history_index_path, alert: "#{period_display}の練習記録がありません。練習してからシェアしてください！" and return
      end

      # Share作成（トークンは自動生成）
      @share = current_user.shares.build(
        share_type: "period_summary",
        period: period,
        start_date: date_range.begin.to_date,
        end_date: date_range.end.to_date
      )

      if @share.save
        # 既存の単一レッスン記録シェアと同じ挙動: Twitter シェア画面に直接リダイレクト
        redirect_to twitter_share_url(@share), allow_other_host: true
      else
        redirect_to my_history_index_path, alert: "シェアURLの作成に失敗しました"
      end
    end

    private

    def require_login
      redirect_to root_path, alert: "ログインしてください" unless logged_in?
    end
  end
end
