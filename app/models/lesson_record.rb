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

  # 作成後、古い履歴を自動削除
  after_create :cleanup_old_records

  # スコープ: 完了日時降順
  scope :recent, -> { order(completed_at: :desc) }

  # グレード定義（カワウソテーマ・5段階）
  GRADES = {
    "legendary" => {
      name: "伝説のカワウソ",
      emoji: "👑",
      description: "タイピングの神様！",
      color: "yellow",
      accuracy_min: 98,
      wpm_min: 80
    },
    "adult" => {
      name: "大人のカワウソ",
      emoji: "🦦",
      description: "堂々としたタイピング",
      color: "blue",
      accuracy_min: 90,
      wpm_min: 50
    },
    "young" => {
      name: "若手のカワウソ",
      emoji: "🐾",
      description: "すくすく成長中！",
      color: "green",
      accuracy_min: 80,
      wpm_min: 30
    },
    "child" => {
      name: "子どものカワウソ",
      emoji: "🌊",
      description: "元気いっぱい練習中！",
      color: "cyan",
      accuracy_min: 70,
      wpm_min: 15
    },
    "baby" => {
      name: "赤ちゃんカワウソ",
      emoji: "🐣",
      description: "よちよちスタート！",
      color: "gray",
      accuracy_min: 0,
      wpm_min: 0
    }
  }.freeze

  # ヘルパーメソッド: グレード情報を取得
  def grade_info
    return GRADES["baby"] if grade.blank?
    GRADES.values.find { |g| g[:name] == grade } || GRADES["baby"]
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
      GRADES["legendary"][:name]
    elsif accuracy >= 90 && wpm >= 50
      GRADES["adult"][:name]
    elsif accuracy >= 80 && wpm >= 30
      GRADES["young"][:name]
    elsif accuracy >= 70 && wpm >= 15
      GRADES["child"][:name]
    else
      GRADES["baby"][:name]
    end
  end

  def cleanup_old_records
    user.cleanup_old_lesson_records
  end
end
