class ConvertKeymapPositionsToNewFormat < ActiveRecord::Migration[8.1]
  def up
    # 古い形式（L0-R0, R0-R0など）から新しい形式（0-0, 6-0など）に変換
    # L0-R0 → 0-0 (左手1行目1列目)
    # R0-R0 → 6-0 (右手1行目1列目、行オフセット+6)

    # 左手（L0〜L3 → 0〜3行）
    (0..3).each do |row|
      (0..5).each do |col|
        old_position = "L#{row}-R#{col}"
        new_position = "#{row}-#{col}"
        execute "UPDATE keymaps SET key_position = '#{new_position}' WHERE key_position = '#{old_position}'"
      end
    end

    # 右手（R0〜R3 → 6〜9行）
    (0..3).each do |row|
      (0..5).each do |col|
        old_position = "R#{row}-R#{col}"
        new_position = "#{row + 6}-#{col}"
        execute "UPDATE keymaps SET key_position = '#{new_position}' WHERE key_position = '#{old_position}'"
      end
    end
  end

  def down
    # ロールバック：新しい形式から古い形式に戻す
    # 左手（0〜3行 → L0〜L3）
    (0..3).each do |row|
      (0..5).each do |col|
        new_position = "#{row}-#{col}"
        old_position = "L#{row}-R#{col}"
        execute "UPDATE keymaps SET key_position = '#{old_position}' WHERE key_position = '#{new_position}'"
      end
    end

    # 右手（6〜9行 → R0〜R3）
    (0..3).each do |row|
      (0..5).each do |col|
        new_position = "#{row + 6}-#{col}"
        old_position = "R#{row}-R#{col}"
        execute "UPDATE keymaps SET key_position = '#{old_position}' WHERE key_position = '#{new_position}'"
      end
    end
  end
end
