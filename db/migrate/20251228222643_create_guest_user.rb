class CreateGuestUser < ActiveRecord::Migration[8.1]
  def up
    # ゲストユーザーを作成（未ログインユーザーの練習記録用）
    # このユーザーは削除しないこと
    User.create!(
      google_uid: "guest-system-user",
      email: "guest@system.local",
      name: "未ログインユーザー",
      username: "guest"
      # active_keymap_setはafter_createコールバックで自動設定される
    )
  end

  def down
    # ロールバック時はゲストユーザーを削除
    User.find_by(username: "guest")&.destroy
  end
end
