class AddKeyboardTypeToKeymapSets < ActiveRecord::Migration[8.1]
  def change
    add_column :keymap_sets, :keyboard_type, :string, default: "cornix_4x6", null: false
  end
end
