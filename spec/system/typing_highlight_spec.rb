require "rails_helper"

RSpec.describe "タイピング練習のキーハイライト", type: :system do
  let(:user) { create(:user) }
  let(:category) { create(:category, tab: "basics", published: true) }
  let(:lesson) { create(:lesson, category: category, items: [ "hello", "world" ], count: 2) }
  let(:keymap_set) { create(:keymap_set, user: user, name: "テスト用キーマップ") }

  # "hello"と"world"を打つための最小限のキーマップを作成
  # keymap_setの作成時にデフォルトキーマップがコピーされているので
  # デフォルトで既に設定されている文字はそのまま使用できる
  before do
    # デフォルトキーマップで既に設定されている文字:
    # h: 7-0（右手、H|h）
    # e: 0-3（左手、E|e）
    # l: 7-3（右手、L|l）
    # o: 6-3（右手、O|o）
    # w: 0-2（左手、W|w）
    # r: 0-4（左手、R|r）
    # d: 1-3（左手、D|d）
    # → デフォルトキーマップに全て含まれているので、特に設定不要

    # ユーザーのアクティブキーマップに設定
    user.update(active_keymap_set: keymap_set)
  end

  describe "初期表示時のキーハイライト", js: true do
    it "最初の文字に対応するキーが正しくハイライトされる" do
      login_as_user(user)
      visit lesson_path(lesson)

      # レッスン画面が表示されることを確認
      expect(page).to have_selector("[data-typing-target='lessonScreen']", visible: true)

      # 最初の単語の最初の文字がハイライトされる
      # レッスンのitemsは["hello", "world"]だが、ランダム表示されるため
      # "h"または"w"のどちらかがハイライトされる
      expect(
        page.has_selector?('.key.ring-2[data-position="7-0"]') || # h (右手)
        page.has_selector?('.key.ring-2[data-position="0-2"]')    # w (左手)
      ).to be true
    end

    it "対応する指ガイドもハイライトされる" do
      login_as_user(user)
      visit lesson_path(lesson)

      # 指ガイドがハイライトされることを確認
      # "h"（right-index: 右手人差し指、7-0）または"w"（left-ring: 左手薬指、0-2）
      expect(
        page.has_selector?('.finger-guide.ring-2[data-finger="right-index"]') || # h
        page.has_selector?('.finger-guide.ring-2[data-finger="left-ring"]')      # w
      ).to be true
    end
  end

  describe "文字入力後のハイライト変化", js: true do
    # テストを確実にするため、itemsを固定
    let(:lesson) { create(:lesson, category: category, items: [ "hello" ], count: 1) }

    it "正しい文字を入力すると次のキーがハイライトされる" do
      login_as_user(user)
      visit lesson_path(lesson)

      # 最初は"h"（7-0: 右手人差し指）がハイライトされる
      expect(page).to have_selector('.key.ring-2[data-position="7-0"]')

      # "h"を入力
      input_field = page.find('[data-typing-target="input"]', visible: :all)
      input_field.send_keys("h")

      # 少し待機（Stimulus Controllerの処理を待つ）
      sleep 0.1

      # 次の文字"e"（0-3: 左手中指）がハイライトされる
      expect(page).to have_selector('.key.ring-2[data-position="0-3"]')
      expect(page).to have_selector('.finger-guide.ring-2[data-finger="left-middle"]')
    end

    it "間違った文字を入力すると現在の文字が赤くハイライトされる" do
      login_as_user(user)
      visit lesson_path(lesson)

      # 間違った文字"x"を入力
      input_field = page.find('[data-typing-target="input"]', visible: :all)
      input_field.send_keys("x")

      # 少し待機
      sleep 0.1

      # 現在の文字が赤くハイライトされる
      display_area = page.find('[data-typing-target="display"]')
      expect(display_area).to have_selector('span.bg-red-100')
    end

    it "BackSpaceで削除すると前の状態に戻る" do
      login_as_user(user)
      visit lesson_path(lesson)

      # "h"を入力
      input_field = page.find('[data-typing-target="input"]', visible: :all)
      input_field.send_keys("h")
      sleep 0.1

      # "e"がハイライトされることを確認
      expect(page).to have_selector('.key.ring-2[data-position="0-3"]')

      # BackSpaceで削除
      input_field.send_keys(:backspace)
      sleep 0.1

      # "h"に戻る
      expect(page).to have_selector('.key.ring-2[data-position="7-0"]')
    end
  end

  describe "レイヤー切り替え", js: true do
    let(:lesson) { create(:lesson, category: category, items: [ "1" ], count: 1) }

    before do
      # Layer 0にない文字をテスト（数字"1"）
      # デフォルトキーマップではLayer 1の0-1に"!|1"が設定されている
      # Layer 0には"1"が存在しないため、レイヤー切り替えが必要
      # → レイヤー切り替えキー（Layer1）は Layer 0 の 3-3 にデフォルトで設定済み
    end

    it "Layer 0にない文字の場合、レイヤーボタンとターゲットキーの両方がハイライトされる" do
      login_as_user(user)
      visit lesson_path(lesson)

      # 最初の文字"1"はLayer 1（0-1）にのみ存在するため
      # 1. Layer1キー（3-3: 左手側レイヤー切り替えキー）がハイライトされる
      expect(page).to have_selector('.key.ring-2[data-position="3-3"]')

      # 2. "1"のキー（0-1: Layer 1の"!|1"の位置）もハイライトされる
      expect(page).to have_selector('.key.ring-2[data-position="0-1"]')
    end
  end

  describe "タイピング完了", js: true do
    let(:lesson) { create(:lesson, category: category, items: [ "he" ], count: 1) }

    it "全ての文字を入力すると完了画面が表示される" do
      login_as_user(user)
      visit lesson_path(lesson)

      # "h"と"e"を入力
      input_field = page.find('[data-typing-target="input"]', visible: :all)
      input_field.send_keys("he")

      # 完了画面が表示されるまで待機（最大5秒）
      expect(page).to have_selector('[data-typing-target="completionScreen"]', visible: true, wait: 5)

      # レッスン画面が非表示になる
      expect(page).to have_selector('[data-typing-target="lessonScreen"]', visible: false)

      # 統計情報が表示される
      expect(page).to have_selector('[data-typing-target="accuracyDisplay"]')
      expect(page).to have_selector('[data-typing-target="wpmDisplay"]')
      expect(page).to have_selector('[data-typing-target="timeDisplay"]')
      expect(page).to have_selector('[data-typing-target="mistakesDisplay"]')
    end
  end
end
