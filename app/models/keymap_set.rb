class KeymapSet < ApplicationRecord
  belongs_to :user
  has_many :keymaps, dependent: :destroy

  validates :name, presence: true, length: { maximum: 50 }
  validates :description, length: { maximum: 500 }, allow_blank: true
  validate :check_user_keymap_limit, on: :create

  after_create :copy_default_keymap

  scope :published, -> { where(is_public: true) }

  # ユーザーの最も古いキーマップセットかどうか（削除不可の判定）
  def oldest_for_user?
    user.keymap_sets.order(:created_at).first == self
  end

  # 削除可能かどうか
  def deletable?
    !oldest_for_user?
  end

  private

  def check_user_keymap_limit
    # 無課金ユーザーは2つまで（将来的に課金ユーザーは5つまで拡張可能）
    max_keymaps = 2
    current_count = user.keymap_sets.count

    if current_count >= max_keymaps
      errors.add(:base, "キーマップは#{max_keymaps}つまでしか作成できません")
    end
  end

  # デフォルトキーマップを新規作成されたキーマップセットにコピー
  def copy_default_keymap
    default_keymap = Keymap.default_keymap

    # 全6レイヤー分のデフォルトキーマップをコピー
    default_keymap.each do |layer, keymap_hash|
      keymap_hash.each do |position, character|
        keymaps.create!(
          user: user,
          layer: layer,
          key_position: position,
          character: character
        )
      end
    end
  end
end
