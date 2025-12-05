class CreateKeymaps < ActiveRecord::Migration[8.1]
  def change
    create_table :keymaps do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :layer, null: false
      t.string :key_position, null: false
      t.string :character, null: false

      t.timestamps
    end

    # ユニークインデックス: 同じユーザー・レイヤー・キー位置は1つだけ
    add_index :keymaps, [:user_id, :layer, :key_position], unique: true
  end
end
