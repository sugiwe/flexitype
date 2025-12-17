class KeymapSet < ApplicationRecord
  belongs_to :user
  has_many :keymaps, dependent: :destroy

  validates :name, presence: true, length: { maximum: 50 }
  validates :description, length: { maximum: 500 }, allow_blank: true

  scope :published, -> { where(is_public: true) }
end
