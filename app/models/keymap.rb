class Keymap < ApplicationRecord
  belongs_to :user

  validates :layer, presence: true, inclusion: { in: 0..5 }
  validates :key_position, presence: true
  validates :character, presence: true, length: { maximum: 20 }
  validates :key_position, uniqueness: { scope: [ :user_id, :layer ] }

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

  # デフォルトキーマップを読み込む（YAMLファイルから）
  # @return [Hash] レイヤー番号 => { キー位置 => 文字 } のハッシュ
  def self.default_keymap
    @default_keymap ||= begin
      yaml_path = Rails.root.join("config", "default_keymap.yml")
      yaml_data = YAML.load_file(yaml_path)

      # layer_0 -> 0, layer_1 -> 1 のように変換
      yaml_data.transform_keys { |k| k.gsub("layer_", "").to_i }
    end
  end

  # ユーザーのキーマップまたはデフォルトキーマップを取得
  # @param user_id [Integer, nil] ユーザーID（nilの場合はデフォルトを返す）
  # @param layer [Integer] レイヤー番号（0-5）
  # @return [Hash] キー位置 => 文字のハッシュ
  def self.for_user_or_default(user_id, layer)
    if user_id.present?
      user_keymap = for_user_layer(user_id, layer)
      # ユーザーのキーマップが存在する場合はそれを返す
      return user_keymap if user_keymap.present?
    end

    # ユーザーIDがnilまたはキーマップが未設定の場合はデフォルトを返す
    default_keymap[layer] || {}
  end

  # ユーザーの全レイヤーのキーマップまたはデフォルトキーマップを取得
  # @param user_id [Integer, nil] ユーザーID（nilの場合はデフォルトを返す）
  # @return [Hash] レイヤー番号 => { キー位置 => 文字 } のハッシュ
  def self.all_layers_for_user_or_default(user_id)
    (0..5).each_with_object({}) do |layer, result|
      result[layer] = for_user_or_default(user_id, layer)
    end
  end
end
