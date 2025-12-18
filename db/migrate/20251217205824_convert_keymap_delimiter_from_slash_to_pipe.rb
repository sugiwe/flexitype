class ConvertKeymapDelimiterFromSlashToPipe < ActiveRecord::Migration[8.1]
  def up
    # 既存のキーマップデータのデリミタを "/" から "|" に変換
    # 例: "Q/q" → "Q|q", "!/1" → "!|1"
    Keymap.where("character LIKE '%/%'").find_each do |keymap|
      keymap.update_column(:character, keymap.character.gsub('/', '|'))
    end
  end

  def down
    # ロールバック時は "|" を "/" に戻す
    Keymap.where("character LIKE '%|%'").find_each do |keymap|
      keymap.update_column(:character, keymap.character.gsub('|', '/'))
    end
  end
end
