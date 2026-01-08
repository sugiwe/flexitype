class Share < ApplicationRecord
  belongs_to :lesson_record

  # バリデーション
  validates :token, presence: true, uniqueness: true

  # トークン生成
  before_validation :generate_token, on: :create

  # LessonRecordのデータを委譲
  delegate :accuracy, :wpm, :duration_seconds, :mistake_count,
           :grade, :grade_emoji, :grade_color, :grade_description,
           :lesson_name,
           to: :lesson_record

  # グレード名を取得
  def grade_name
    lesson_record.grade_info[:name]
  end

  # グレード画像を取得
  def grade_image
    lesson_record.grade_info[:image]
  end

  # カテゴリー名を取得
  def category_name
    lesson_record.lesson&.category&.translated_name || "不明"
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(16)
  end
end
