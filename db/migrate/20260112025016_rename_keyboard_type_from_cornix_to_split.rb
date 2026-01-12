class RenameKeyboardTypeFromCornixToSplit < ActiveRecord::Migration[8.1]
  def up
    # 既存データのkeyboard_typeを更新
    execute "UPDATE keymap_sets SET keyboard_type = 'split_4x6' WHERE keyboard_type = 'cornix_4x6'"

    # デフォルト値を変更
    change_column_default :keymap_sets, :keyboard_type, from: "cornix_4x6", to: "split_4x6"
  end

  def down
    # ロールバック: 元に戻す
    execute "UPDATE keymap_sets SET keyboard_type = 'cornix_4x6' WHERE keyboard_type = 'split_4x6'"

    # デフォルト値を元に戻す
    change_column_default :keymap_sets, :keyboard_type, from: "split_4x6", to: "cornix_4x6"
  end
end
