require "rails_helper"

RSpec.describe "認証フロー", type: :system do
  describe "ログイン状態の確認" do
    it "ログインユーザーのユーザー名が表示される" do
      user = login_as_user
      visit root_path

      # ログイン後はユーザー名が表示される（ユーザーメニュー内）
      expect(page).to have_content(user.name)
    end

    it "未ログインユーザーにはログインエリアが表示される" do
      visit root_path

      # ログイン前はGoogle Sign-In要素が表示される
      expect(page).to have_selector(".g_id_signin")
    end
  end

  describe "ログアウト" do
    it "ログインユーザーがログアウトできる" do
      login_as_user
      visit root_path

      # ユーザーメニューを開く
      find("button[data-action='click->user-menu#toggle']").click

      # ログアウトボタンをクリック
      click_button "ログアウト"

      # ログアウト後はGoogle Sign-In要素が表示される
      expect(page).to have_selector(".g_id_signin")
    end
  end

  describe "マイページアクセス" do
    it "ログイン後にマイページにアクセスできる" do
      login_as_user
      visit my_root_path

      # マイページが表示される
      expect(page).to have_current_path(my_root_path)
      expect(page).to have_content("設定")
    end

    it "未ログインユーザーはマイページにアクセスできない" do
      visit my_root_path

      # ルートページにリダイレクトされる
      expect(page).to have_current_path(root_path)
    end
  end
end
