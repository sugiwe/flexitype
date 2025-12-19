class AddSlugToKeymapSets < ActiveRecord::Migration[8.1]
  def change
    # まずnullableでカラムを追加
    add_column :keymap_sets, :slug, :string, limit: 50

    # 既存データにslugを生成
    User.find_each do |user|
      user.keymap_sets.order(:created_at).each_with_index do |keymap_set, index|
        counter = index + 1
        candidate_slug = "keymap-#{counter}"

        # 重複チェック（万が一のため）
        while user.keymap_sets.exists?(slug: candidate_slug)
          counter += 1
          candidate_slug = "keymap-#{counter}"
        end

        keymap_set.update_column(:slug, candidate_slug)
      end
    end

    # データ移行完了後にNOT NULL制約を追加
    change_column_null :keymap_sets, :slug, false

    # インデックスを追加
    add_index :keymap_sets, [ :user_id, :slug ], unique: true
    add_index :keymap_sets, :slug
  end
end
