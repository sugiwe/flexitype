class Keymap < ApplicationRecord
  belongs_to :user

  validates :layer, presence: true, inclusion: { in: 0..5 }
  validates :key_position, presence: true
  validates :character, presence: true, length: { maximum: 20 }
  validates :key_position, uniqueness: { scope: [:user_id, :layer] }

  # 特定のユーザーとレイヤーのキーマップをハッシュ形式で取得
  # @param user_id [Integer] ユーザーID
  # @param layer [Integer] レイヤー番号（0-5）
  # @return [Hash] キー位置をキー、文字を値とするハッシュ
  def self.for_user_layer(user_id, layer)
    where(user_id: user_id, layer: layer)
      .index_by(&:key_position)
      .transform_values(&:character)
  end

  # キーマップを一括で更新（upsert）
  # @param user_id [Integer] ユーザーID
  # @param layer [Integer] レイヤー番号（0-5）
  # @param keymap_hash [Hash] キー位置 => 文字のハッシュ
  def self.bulk_upsert(user_id, layer, keymap_hash)
    keymap_hash.each do |position, char|
      next if char.blank?

      keymap = find_or_initialize_by(
        user_id: user_id,
        layer: layer,
        key_position: position
      )
      keymap.character = char
      keymap.save!
    end
  end
end
