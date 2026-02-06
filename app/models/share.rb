class Share < ApplicationRecord
  belongs_to :lesson_record, optional: true
  belongs_to :user, optional: true

  # 定数定義
  SHARE_TYPES = %w[single period_summary].freeze
  PERIODS = {
    today: "今日",
    yesterday: "昨日",
    this_week: "今週",
    last_week: "先週",
    this_month: "今月",
    last_month: "先月"
  }.freeze

  # バリデーション
  validates :token, presence: true, uniqueness: true
  validates :share_type, presence: true, inclusion: { in: SHARE_TYPES }
  validates :period, inclusion: { in: PERIODS.keys.map(&:to_s) }, allow_nil: true, if: :period_summary?
  validates :lesson_record_id, presence: true, if: :single?
  validates :user_id, presence: true, if: :period_summary?
  validates :start_date, presence: true, if: :period_summary?
  validates :end_date, presence: true, if: :period_summary?

  # トークン生成
  before_validation :generate_token, on: :create

  # スコープ
  scope :singles, -> { where(share_type: "single") }
  scope :period_summaries, -> { where(share_type: "period_summary") }

  # シェアタイプ判定
  def single?
    share_type == "single"
  end

  def period_summary?
    share_type == "period_summary"
  end

  # LessonRecordのデータを委譲（singleタイプのみ）
  delegate :accuracy, :wpm, :duration_seconds, :mistake_count,
           :grade, :grade_emoji, :grade_color, :grade_description, :grade_name,
           :lesson_name,
           to: :lesson_record, allow_nil: true

  # グレード画像を取得
  def grade_image
    lesson_record&.grade_info&.[](:image)
  end

  # カテゴリー名を取得
  def category_name
    lesson_record&.lesson&.category&.translated_name || "不明"
  end

  # 期間サマリーのデータを計算して返す
  def period_summary_data
    return nil unless period_summary?

    records = user.lesson_records.where(completed_at: start_date.beginning_of_day..end_date.end_of_day)

    return nil if records.empty?

    {
      count: records.count,
      avg_accuracy: records.average(:accuracy)&.round(2),
      avg_wpm: records.average(:wpm)&.round,
      avg_grade: calculate_average_grade(records)
    }
  end

  # 期間の日本語表示
  def period_display
    PERIODS[period.to_sym] if period.present?
  end

  # 期間の詳細表示（日付範囲）
  def period_date_range
    return nil unless period_summary? && start_date && end_date

    if start_date == end_date
      start_date.strftime("%Y年%-m月%-d日")
    else
      "#{start_date.strftime('%Y年%-m月%-d日')}〜#{end_date.strftime('%-m月%-d日')}"
    end
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(16)
  end

  def calculate_average_grade(records)
    return nil if records.empty?

    avg_accuracy = records.average(:accuracy).to_f
    avg_wpm = records.average(:wpm).to_f

    # LessonRecordのグレード判定ロジックを再利用
    LessonRecord.calculate_grade_from_stats(avg_accuracy, avg_wpm)
  end
end
