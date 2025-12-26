class Lesson < ApplicationRecord
  belongs_to :user
  belongs_to :category
  has_many :lesson_records, dependent: :destroy

  # カテゴリーの設定を継承
  delegate :requires_login, :premium, to: :category

  # バリデーション
  validates :name, presence: true, length: { maximum: 100 }
  validates :description, length: { maximum: 500 }, allow_blank: true
  validates :items, presence: true
  validates :count, numericality: { greater_than: 0, less_than_or_equal_to: 100 }

  # スコープ
  scope :ordered, -> { order(display_order: :asc, id: :asc) }
  scope :official, -> { joins(:user).where(users: { admin: true }) }
  scope :user_created, -> { joins(:user).where.not(users: { admin: true }) }
  scope :published, -> { where(is_public: true) }
  scope :free, -> { joins(:category).where(categories: { premium: false }) }
  scope :premium, -> { joins(:category).where(categories: { premium: true }) }
  scope :available_for_guest, -> { joins(:category).where(categories: { requires_login: false }) }

  # 特定ユーザーに表示可能なレッスンを取得
  # 管理者: 全レッスン
  # 一般ユーザー: 公式レッスン + 自分のレッスン + 公開レッスン
  scope :visible_to, ->(user) {
    if user&.admin?
      all
    else
      left_joins(:user).where(
        "lessons.user_id = :user_id OR lessons.is_public = true OR users.admin = true",
        user_id: user&.id
      ).distinct
    end
  }

  # 公式レッスンかどうかを判定
  def official?
    user&.admin?
  end

  # JavaScript用のレッスン情報をJSON形式で返す
  def to_lesson_info
    {
      lesson_id: id,
      category_name: category.name,
      category_description: category.description,
      lesson_name: name,
      lesson_description: description,
      count: count,
      requires_login: category.requires_login,
      premium: category.premium
    }
  end
end
