class MakeActiveKeymapSetOptionalInUsers < ActiveRecord::Migration[8.1]
  def change
    change_column_null :users, :active_keymap_set_id, true
  end
end
