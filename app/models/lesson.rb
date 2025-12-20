class Lesson < ApplicationRecord
  belongs_to :user
  belongs_to :category
  has_many :lesson_records, dependent: :destroy

  # バリデーション
  validates :name, presence: true, length: { maximum: 100 }
  validates :description, length: { maximum: 500 }, allow_blank: true
  validates :items, presence: true
  validates :count, numericality: { greater_than: 0, less_than_or_equal_to: 100 }

  # スコープ
  scope :official, -> { joins(:user).where(users: { admin: true }) }
  scope :user_created, -> { joins(:user).where.not(users: { admin: true }) }
  scope :published, -> { where(is_public: true) }
  scope :free, -> { where(premium: false) }
  scope :premium, -> { where(premium: true) }
  scope :available_for_guest, -> { where(requires_login: false) }

  # 公式レッスンかどうかを判定
  def official?
    user&.admin?
  end

  # JavaScript用のレッスン情報をJSON形式で返す
  def to_lesson_info
    {
      id: id,
      category_name: category.name,
      category_description: category.description,
      lesson_name: name,
      lesson_description: description,
      count: count,
      requires_login: requires_login,
      premium: premium
    }
  end
end
