class RemoveOldKeymapUserIndex < ActiveRecord::Migration[8.1]
  def change
    # 古いユニークインデックスを削除
    # （user_id, layer, key_position）のインデックスは不要
    # 新しい（keymap_set_id, layer, key_position）のインデックスがあるため
    remove_index :keymaps, column: [ :user_id, :layer, :key_position ], if_exists: true
  end
end
