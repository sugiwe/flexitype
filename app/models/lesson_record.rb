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
    grade_key = grade.presence || "baby"
    LessonGrades::DEFINITIONS[grade_key] || LessonGrades::DEFINITIONS["baby"]
  end

  # グレード名を取得（i18n対応、後方互換性あり）
  def grade_name
    grade_value = grade.presence || "baby"

    # 新しいデータ（キー形式: legendary/adult/young/child/baby）の場合は翻訳
    if LessonGrades::DEFINITIONS.key?(grade_value)
      I18n.t("grades.#{grade_value}.name")
    else
      # 古いデータ（日本語名）の場合はそのまま返す（後方互換性）
      grade_value
    end
  end

  # グレード説明を取得（i18n対応、後方互換性あり）
  def grade_description
    grade_value = grade.presence || "baby"

    # 新しいデータ（キー形式）の場合は翻訳
    if LessonGrades::DEFINITIONS.key?(grade_value)
      I18n.t("grades.#{grade_value}.description")
    else
      # 古いデータの場合は空文字を返す（説明は保存していない）
      ""
    end
  end

  def grade_emoji
    grade_info[:emoji]
  end

  def grade_color
    grade_info[:color]
  end

  # クラスメソッド: 統計値からグレードを計算（外部から呼び出し可能）
  def self.calculate_grade_from_stats(accuracy, wpm)
    determine_grade(accuracy, wpm)
  end

  # レッスン名を取得（i18n対応）
  def lesson_name
    # lesson_idがある場合は動的に翻訳を返す（新しいデータ）
    if lesson.present?
      lesson.translated_name
    else
      # lesson_idがない場合はカラムの値を返す（古いデータの後方互換性）
      read_attribute(:lesson_name)
    end
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

    self.grade = self.class.determine_grade(accuracy, wpm)
  end

  # クラスメソッド: グレード判定ロジックの共通実装
  def self.determine_grade(accuracy, wpm)
    if accuracy >= 98 && wpm >= 80
      "legendary"
    elsif accuracy >= 90 && wpm >= 50
      "adult"
    elsif accuracy >= 80 && wpm >= 30
      "young"
    elsif accuracy >= 70 && wpm >= 15
      "child"
    else
      "baby"
    end
  end
end
