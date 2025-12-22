class AddActiveKeymapSetToUsers < ActiveRecord::Migration[8.1]
  def change
    # まずnull: trueでカラムを追加
    add_column :users, :active_keymap_set_id, :integer, null: true
    add_index :users, :active_keymap_set_id
    add_foreign_key :users, :keymap_sets, column: :active_keymap_set_id

    # 既存ユーザーに最初のキーマップセットを設定
    reversible do |dir|
      dir.up do
        User.reset_column_information
        KeymapSet.reset_column_information

        User.find_each do |user|
          first_keymap_set = user.keymap_sets.order(created_at: :asc).first

          # キーマップセットがない場合はデフォルトを作成
          if first_keymap_set.nil?
            first_keymap_set = user.keymap_sets.create!(
              name: "マイキーマップ",
              slug: KeymapSet.generate_next_slug(user),
              description: "デフォルトキーマップ（Mac配列ベース）です。",
              is_public: false
            )
          end

          user.update_column(:active_keymap_set_id, first_keymap_set.id)
        end
      end
    end

    # null: falseに変更
    change_column_null :users, :active_keymap_set_id, false
  end
end
