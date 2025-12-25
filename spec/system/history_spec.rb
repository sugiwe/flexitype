require "rails_helper"

RSpec.describe "練習履歴閲覧フロー", type: :system do
  let(:user) { create(:user) }
  let!(:category) { create(:category, name: "基礎トレーニング") }
  let!(:lesson) { create(:lesson, category: category, name: "ホームポジション練習") }

  before do
    login_as_user(user)
  end

  describe "練習履歴一覧ページ" do
    let!(:recent_record) { create(:lesson_record, user: user, lesson: lesson, completed_at: 1.day.ago) }
    let!(:old_record) { create(:lesson_record, user: user, lesson: lesson, completed_at: 2.months.ago) }

    it "練習履歴が表示される" do
      visit my_history_index_path

      # ページタイトルが表示される
      expect(page).to have_content("練習履歴")

      # 履歴テーブルが表示される
      expect(page).to have_selector("tbody tr", count: 2)
    end

    it "期間フィルターが動作する（直近1ヶ月）" do
      visit my_history_index_path

      # 直近1ヶ月タブをクリック
      click_link "直近1ヶ月"

      # 直近1ヶ月の履歴のみ表示される
      within("#history_content") do
        # 2ヶ月前の記録は表示されない（要素数で確認）
        expect(page).to have_selector("tbody tr", count: 1)
      end
    end

    it "期間フィルターが動作する（直近1週間）" do
      visit my_history_index_path

      # 直近1週間タブをクリック
      click_link "直近1週間"

      # 直近1週間の履歴のみ表示される
      within("#history_content") do
        expect(page).to have_selector("tbody tr", count: 1)
      end
    end
  end

  describe "ページネーション" do
    before do
      # 25件の練習記録を作成（1ページ20件なので2ページになる）
      25.times do
        create(:lesson_record, user: user, lesson: lesson)
      end
    end

    it "ページネーションが動作する" do
      visit my_history_index_path

      # 1ページ目には20件表示される
      expect(page).to have_selector("tbody tr", count: 20)

      # 2ページ目へのリンクが表示される
      expect(page).to have_link("2")

      # 2ページ目に移動
      click_link "2"

      # 2ページ目には5件表示される
      expect(page).to have_selector("tbody tr", count: 5)
    end
  end

  describe "未ログインユーザー" do
    it "練習履歴ページにアクセスできない" do
      logout
      visit my_history_index_path

      # ルートページにリダイレクトされる
      expect(page).to have_current_path(root_path)
    end
  end
end
