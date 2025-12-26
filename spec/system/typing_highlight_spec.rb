require "rails_helper"

RSpec.describe "タイピング練習のキーハイライト", type: :system do
  let(:user) { create(:user) }
  let(:category) { create(:category, tab: "basics", published: true) }
  let(:lesson) { create(:lesson, category: category, items: [ "hello", "world" ], count: 2) }
  let(:keymap_set) { create(:keymap_set, user: user, name: "テスト用キーマップ") }

  # "hello"と"world"を打つための最小限のキーマップを作成
  # keymap_setの作成時にデフォルトキーマップがコピーされているので
  # 必要な文字だけを上書き設定する
  before do
    # h: L2-R0（左手中指）
    keymap_set.keymaps.find_by(layer: 0, key_position: "L2-R0").update(character: "h")
    # e: L0-R2（左手薬指）
    keymap_set.keymaps.find_by(layer: 0, key_position: "L0-R2").update(character: "e")
    # l: L2-R3（左手人差し指）
    keymap_set.keymaps.find_by(layer: 0, key_position: "L2-R3").update(character: "l")
    # o: R2-R2（右手中指）
    keymap_set.keymaps.find_by(layer: 0, key_position: "R2-R2").update(character: "o")
    # w: L1-R1（左手小指）
    keymap_set.keymaps.find_by(layer: 0, key_position: "L1-R1").update(character: "w")
    # r: L1-R4（左手人差し指）
    keymap_set.keymaps.find_by(layer: 0, key_position: "L1-R4").update(character: "r")
    # d: L2-R2（左手薬指）
    keymap_set.keymaps.find_by(layer: 0, key_position: "L2-R2").update(character: "d")

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
        page.has_selector?('.key.ring-2[data-position="L2-R0"]') || # h
        page.has_selector?('.key.ring-2[data-position="L1-R1"]')    # w
      ).to be true
    end

    it "対応する指ガイドもハイライトされる" do
      login_as_user(user)
      visit lesson_path(lesson)

      # 指ガイドがハイライトされることを確認
      # "h"（left-middle）または"w"（left-pinky）
      expect(
        page.has_selector?('.finger-guide.ring-2[data-finger="left-middle"]') || # h
        page.has_selector?('.finger-guide.ring-2[data-finger="left-pinky"]')    # w
      ).to be true
    end
  end

  describe "文字入力後のハイライト変化", js: true do
    # テストを確実にするため、itemsを固定
    let(:lesson) { create(:lesson, category: category, items: [ "hello" ], count: 1) }

    it "正しい文字を入力すると次のキーがハイライトされる" do
      login_as_user(user)
      visit lesson_path(lesson)

      # 最初は"h"（L2-R0）がハイライトされる
      expect(page).to have_selector('.key.ring-2[data-position="L2-R0"]')

      # "h"を入力
      input_field = page.find('[data-typing-target="input"]', visible: :all)
      input_field.send_keys("h")

      # 少し待機（Stimulus Controllerの処理を待つ）
      sleep 0.1

      # 次の文字"e"（L0-R2）がハイライトされる
      expect(page).to have_selector('.key.ring-2[data-position="L0-R2"]')
      expect(page).to have_selector('.finger-guide.ring-2[data-finger="left-ring"]')
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
      expect(page).to have_selector('.key.ring-2[data-position="L0-R2"]')

      # BackSpaceで削除
      input_field.send_keys(:backspace)
      sleep 0.1

      # "h"に戻る
      expect(page).to have_selector('.key.ring-2[data-position="L2-R0"]')
    end
  end

  describe "レイヤー切り替え", js: true do
    let(:lesson) { create(:lesson, category: category, items: [ "X" ], count: 1) }

    before do
      # Layer 1に大文字"X"を追加（デフォルトキーマップにない文字を使用）
      keymap_set.keymaps.find_by(layer: 1, key_position: "L2-R0").update(character: "X")
      # Layer 0のL2-R0は使わない文字に設定（Xを検索してもLayer 0で見つからないようにする）
      keymap_set.keymaps.find_by(layer: 0, key_position: "L2-R0").update(character: "")
      # レイヤー切り替えキー（Layer1/Lyr1）をLayer 0に追加
      keymap_set.keymaps.find_by(layer: 0, key_position: "L3-R3").update(character: "Layer1")
    end

    it "大文字が必要な場合はレイヤーボタンとターゲットキーの両方がハイライトされる" do
      login_as_user(user)
      visit lesson_path(lesson)

      # 最初の文字"X"はLayer 1にあるため
      # 1. Layer1キー（L3-R3）がハイライトされる
      expect(page).to have_selector('.key.ring-2[data-position="L3-R3"]')

      # 2. "X"のキー（L2-R0）もハイライトされる
      expect(page).to have_selector('.key.ring-2[data-position="L2-R0"]')
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
