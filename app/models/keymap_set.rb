class KeymapSet < ApplicationRecord
  belongs_to :user
  has_many :keymaps, dependent: :destroy

  validates :name, presence: true, length: { maximum: 50 }
  validates :description, length: { maximum: 500 }, allow_blank: true
  validates :slug, presence: true, length: { maximum: 50 },
                   uniqueness: { scope: :user_id },
                   format: { with: /\A[a-z0-9\-]+\z/, message: :invalid_format }
  validate :check_user_keymap_limit, on: :create

  before_validation :generate_slug, if: -> { slug.blank? }
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

  # URL生成時にslugを使用
  def to_param
    slug
  end

  private

  def check_user_keymap_limit
    # 一般ユーザーは2つまで（将来的にプレミアムユーザーは5つまで拡張可能）
    max_keymaps = 2
    current_count = user.keymap_sets.count

    if current_count >= max_keymaps
      errors.add(:base, :keymap_limit, count: max_keymaps)
    end
  end

  # デフォルトキーマップを新規作成されたキーマップセットにコピー
  def copy_default_keymap
    default_keymap = Keymap.default_keymap

    # 全6レイヤー分のデフォルトキーマップをコピー
    default_keymap.each do |layer, keymap_hash|
      keymap_hash.each do |position, character|
        # 空文字の場合はスキップ（未設定として扱う）
        next if character.blank?

        keymaps.create!(
          user: user,
          layer: layer,
          key_position: position,
          character: character
        )
      end
    end
  end

  # slugを自動生成（keymap-{counter}形式、重複時はカウンターを増やす）
  def generate_slug
    self.slug = self.class.generate_next_slug(user)
  end

  # 次に使えるslugを生成（クラスメソッド）
  def self.generate_next_slug(user)
    counter = 1
    candidate_slug = "keymap-#{counter}"

    while user.keymap_sets.exists?(slug: candidate_slug)
      counter += 1
      candidate_slug = "keymap-#{counter}"
    end

    candidate_slug
  end
end
