require "rails_helper"

RSpec.describe "レッスン閲覧フロー", type: :system do
  let!(:category) { create(:category, name: "基礎トレーニング", tab: "basics", published: true) }
  let!(:lesson) { create(:lesson, category: category, name: "ホームポジション練習", is_public: true) }

  describe "トップページ" do
    it "レッスン一覧が表示される" do
      visit root_path

      expect(page).to have_content("基礎トレーニング")
      expect(page).to have_content("ホームポジション練習")
    end
  end

  describe "レッスン詳細ページ" do
    it "レッスンを選択してタイピング画面に遷移できる" do
      visit root_path
      click_link "ホームポジション練習"

      expect(page).to have_current_path(lesson_path(lesson), ignore_query: true)

      # タイピング画面の要素が表示されることを確認
      expect(page).to have_selector("[data-typing-target='lessonScreen']")
      expect(page).to have_content("時間計測は最初の入力から開始されます")
    end
  end

  describe "タブ切り替え" do
    let!(:category_english) { create(:category, name: "英語", tab: "english", published: true) }
    let!(:lesson_english) { create(:lesson, category: category_english, name: "英単語練習", is_public: true) }

    it "タブを切り替えてレッスンが表示される" do
      visit root_path

      # デフォルトでは基礎トレーニングが表示される
      expect(page).to have_content("ホームポジション練習")

      # 英語タブに切り替え
      click_link "英語"

      # 英語レッスンが表示される
      expect(page).to have_content("英単語練習")
    end
  end
end
