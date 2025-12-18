class EnsureAllUsersHaveDefaultKeymapSet < ActiveRecord::Migration[8.1]
  def up
    # キーマップセットを持たないユーザーに「マイキーマップ」を作成
    User.find_each do |user|
      next if user.keymap_sets.exists?

      user.keymap_sets.create!(
        name: "マイキーマップ",
        description: "あなた専用のキーマップです",
        is_public: false
      )
    end
  end

  def down
    # ロールバックは不要（データを削除しない）
  end
end
