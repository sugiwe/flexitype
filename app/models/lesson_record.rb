class LessonRecord < ApplicationRecord
  belongs_to :user
  belongs_to :lesson, optional: true  # データ移行完了後にoptionalを外す
  has_many :shares

  # バリデーション
  validates :word_count, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :correct_count, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :mistake_count, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :accuracy, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :duration_seconds, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # WPMとグレードを自動計算
  before_save :calculate_wpm
  before_save :calculate_grade

  # スコープ: 完了日時降順
  scope :recent, -> { order(completed_at: :desc) }

  # ヘルパーメソッド: グレード情報を取得
  def grade_info
    return LessonGrades::DEFINITIONS["baby"] if grade.blank?
    LessonGrades::DEFINITIONS.values.find { |g| g[:name] == grade } || LessonGrades::DEFINITIONS["baby"]
  end

  def grade_emoji
    grade_info[:emoji]
  end

  def grade_color
    grade_info[:color]
  end

  def grade_description
    grade_info[:description]
  end

  private

  def calculate_wpm
    return if typed_chars.nil? || duration_seconds.nil? || duration_seconds.zero?

    # CPM = タイプ数 / 秒数 × 60
    cpm = (typed_chars.to_f / duration_seconds) * 60

    # WPM = CPM / 5（業界標準: 5文字 = 1単語）
    self.wpm = (cpm / 5.0).round
  end

  def calculate_grade
    return if accuracy.nil? || wpm.nil?

    self.grade = if accuracy >= 98 && wpm >= 80
      LessonGrades::DEFINITIONS["legendary"][:name]
    elsif accuracy >= 90 && wpm >= 50
      LessonGrades::DEFINITIONS["adult"][:name]
    elsif accuracy >= 80 && wpm >= 30
      LessonGrades::DEFINITIONS["young"][:name]
    elsif accuracy >= 70 && wpm >= 15
      LessonGrades::DEFINITIONS["child"][:name]
    else
      LessonGrades::DEFINITIONS["baby"][:name]
    end
  end
end
