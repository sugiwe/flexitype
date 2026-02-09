# frozen_string_literal: true

module PeriodHelper
  # 期間に対応する日付範囲を計算
  # @param period [String, Symbol] 期間（today, yesterday, this_week, last_week, this_month, last_month）
  # @param timezone [String] タイムゾーン（ActiveSupport::TimeZone形式）
  # @return [Range<Time>] 開始日時..終了日時
  def calculate_date_range(period, timezone: "Tokyo")
    now = Time.current.in_time_zone(timezone)

    case period.to_sym
    when :today
      now.beginning_of_day..now.end_of_day
    when :yesterday
      yesterday = 1.day.ago.in_time_zone(timezone)
      yesterday.beginning_of_day..yesterday.end_of_day
    when :this_week
      # ISO week: 月曜始まり、日曜終わり
      now.beginning_of_week(:monday)..now.end_of_week(:sunday)
    when :last_week
      last_week = now - 1.week
      last_week.beginning_of_week(:monday)..last_week.end_of_week(:sunday)
    when :this_month
      now.beginning_of_month..now.end_of_month
    when :last_month
      last_month = now - 1.month
      last_month.beginning_of_month..last_month.end_of_month
    end
  end

  # 期間の表示名を取得（i18n対応）
  # @param period [String, Symbol] 期間
  # @return [String] 表示名
  def period_display(period)
    I18n.t("history.share.periods.#{period}")
  end

  # 期間の説明（日付付き）を取得
  # @param period [String, Symbol] 期間
  # @param timezone [String] タイムゾーン
  # @return [String] 期間の説明（例: "今週 (2026-02-03 〜 2026-02-09)"）
  def period_description(period, timezone: "Tokyo")
    range = calculate_date_range(period, timezone: timezone)
    return "" unless range

    start_date = range.begin.to_date
    end_date = range.end.to_date

    "#{period_display(period)} (#{start_date.strftime('%Y-%m-%d')} 〜 #{end_date.strftime('%Y-%m-%d')})"
  end
end
