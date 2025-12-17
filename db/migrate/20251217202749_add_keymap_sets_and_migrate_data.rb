class AddKeymapSetsAndMigrateData < ActiveRecord::Migration[8.1]
  def up
    # 1. keymap_sets テーブルを作成
    create_table :keymap_sets do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false, limit: 50
      t.text :description, limit: 500
      t.boolean :is_public, default: false, null: false
      t.integer :forked_from_id

      t.timestamps
    end

    add_index :keymap_sets, [ :user_id, :name ]

    # 2. keymaps テーブルに keymap_set_id を追加（まずは nullable）
    add_reference :keymaps, :keymap_set, foreign_key: true

    # 3. 既存データの移行
    User.find_each do |user|
      # ユーザーのKeymapが存在する場合のみKeymap Setを作成
      next unless user.keymaps.exists?

      keymap_set = user.keymap_sets.create!(
        name: "デフォルト",
        description: "初期キーマップ",
        is_public: false
      )

      # ユーザーの既存Keymapにkeymap_set_idを設定
      user.keymaps.update_all(keymap_set_id: keymap_set.id)
    end

    # 4. keymap_set_id を NOT NULL に変更（データ移行完了後）
    change_column_null :keymaps, :keymap_set_id, false

    # 5. インデックスを追加
    add_index :keymaps, [ :keymap_set_id, :layer, :key_position ], unique: true, name: "index_keymaps_on_keymap_set_and_layer_and_position"
  end

  def down
    # ロールバック処理
    remove_index :keymaps, name: "index_keymaps_on_keymap_set_and_layer_and_position"
    remove_reference :keymaps, :keymap_set, foreign_key: true
    drop_table :keymap_sets
  end
end
