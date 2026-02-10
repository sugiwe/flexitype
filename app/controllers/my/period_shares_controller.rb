# frozen_string_literal: true

module My
  class PeriodSharesController < ApplicationController
    include PeriodHelper
    include TwitterShareable

    before_action :require_login

    # POST /my/period_shares
    def create
      period = params[:period]
      unless Share::PERIODS.include?(period.to_sym)
        redirect_to my_history_index_path, alert: t("share.errors.invalid_period") and return
      end

      # 期間の日付範囲を計算
      date_range = calculate_date_range(period, timezone: current_user.time_zone)

      # 期間内に練習記録があるかチェック
      records = current_user.lesson_records.where(completed_at: date_range)
      if records.empty?
        period_display = t("history.share.periods.#{period}")
        redirect_to my_history_index_path, alert: t("share.errors.no_records", period: period_display) and return
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
        redirect_to my_history_index_path, alert: t("share.errors.create_failed")
      end
    end

    private

    def require_login
      redirect_to root_path, alert: t("flash.require_login") unless logged_in?
    end
  end
end
