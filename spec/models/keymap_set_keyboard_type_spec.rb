require "rails_helper"

# KeymapSetのキーボードタイプ関連機能のテスト
# 今回追加した新機能（複数キーボードタイプ対応、デフォルトキーマップの動的読み込み）をテスト
RSpec.describe KeymapSet, type: :model do
  describe "キーボードタイプ関連" do
    describe "#keyboard_config" do
      it "keyboard_typeに対応する設定を返すこと" do
        keymap_set = build(:keymap_set, keyboard_type: "split_4x6")
        config = keymap_set.keyboard_config

        expect(config[:name]).to eq("4×6分割型（オーソリニア）")
        expect(config[:grid_type]).to eq(:split)
        expect(config[:rows_left]).to eq(4)
        expect(config[:cols_left]).to eq(6)
      end

      it "存在しないkeyboard_typeの場合、split_4x6にフォールバックすること" do
        keymap_set = build(:keymap_set, keyboard_type: "nonexistent")
        config = keymap_set.keyboard_config

        expect(config[:name]).to eq("4×6分割型（オーソリニア）")
      end
    end

    describe "#split_keyboard?" do
      it "分割型キーボードの場合、trueを返すこと" do
        keymap_set = build(:keymap_set, keyboard_type: "split_4x6")
        expect(keymap_set.split_keyboard?).to be true
      end

      it "一体型キーボードの場合、falseを返すこと" do
        keymap_set = build(:keymap_set, keyboard_type: "ortho_4x12")
        expect(keymap_set.split_keyboard?).to be false
      end
    end

    describe "#ortho_keyboard?" do
      it "一体型キーボードの場合、trueを返すこと" do
        keymap_set = build(:keymap_set, keyboard_type: "ortho_4x12")
        expect(keymap_set.ortho_keyboard?).to be true
      end

      it "分割型キーボードの場合、falseを返すこと" do
        keymap_set = build(:keymap_set, keyboard_type: "split_4x6")
        expect(keymap_set.ortho_keyboard?).to be false
      end
    end

    describe "#left_hand_positions" do
      it "split_4x6の左手キー位置を返すこと" do
        keymap_set = build(:keymap_set, keyboard_type: "split_4x6")
        positions = keymap_set.left_hand_positions

        expect(positions.count).to eq(24)  # 4行×6列
        expect(positions).to include("0-0", "0-5", "3-0", "3-5")
        expect(positions).not_to include("6-0")  # 右手の位置は含まない
      end

      it "一体型キーボードの場合、空配列を返すこと" do
        keymap_set = build(:keymap_set, keyboard_type: "ortho_4x12")
        expect(keymap_set.left_hand_positions).to eq([])
      end
    end

    describe "#right_hand_positions" do
      it "split_4x6の右手キー位置を返すこと" do
        keymap_set = build(:keymap_set, keyboard_type: "split_4x6")
        positions = keymap_set.right_hand_positions

        expect(positions.count).to eq(24)  # 4行×6列
        expect(positions).to include("6-0", "6-5", "9-0", "9-5")
        expect(positions).not_to include("0-0")  # 左手の位置は含まない
      end

      it "一体型キーボードの場合、空配列を返すこと" do
        keymap_set = build(:keymap_set, keyboard_type: "ortho_4x12")
        expect(keymap_set.right_hand_positions).to eq([])
      end
    end

    describe "#all_key_positions" do
      it "split_4x6の全キー位置を返すこと" do
        keymap_set = build(:keymap_set, keyboard_type: "split_4x6")
        positions = keymap_set.all_key_positions

        expect(positions.count).to eq(48)  # 24（左）+ 24（右）
        expect(positions).to include("0-0", "3-5", "6-0", "9-5")
      end

      it "ortho_4x12の全キー位置を返すこと" do
        keymap_set = build(:keymap_set, keyboard_type: "ortho_4x12")
        positions = keymap_set.all_key_positions

        expect(positions.count).to eq(48)  # 4行×12列
        expect(positions).to include("0-0", "0-11", "3-0", "3-11")
      end
    end
  end

  describe "デフォルトキーマップのコピー" do
    describe "split_4x6" do
      it "48キーのデフォルトキーマップがコピーされること" do
        user = create(:user)

        # after_createコールバックをスキップしてKeymap SetをInsert
        keymap_set_id = ActiveRecord::Base.connection.execute(
          "INSERT INTO keymap_sets (user_id, name, slug, keyboard_type, created_at, updated_at) " \
          "VALUES (#{user.id}, 'Test Split 4x6', 'test-split-4x6-#{SecureRandom.hex(4)}', 'split_4x6', NOW(), NOW()) " \
          "RETURNING id"
        )[0]['id'].to_i

        keymap_set = KeymapSet.find(keymap_set_id)

        # copy_default_keymapを手動実行
        keymap_set.send(:copy_default_keymap)

        # キーマップが作成されていることを確認
        expect(keymap_set.keymaps.count).to be > 0
        expect(keymap_set.keymaps.where(layer: 0).count).to eq(48)  # Layer 0に48キー

        # サンプルキーの確認
        expect(keymap_set.keymaps.find_by(layer: 0, key_position: "0-0")&.character).to eq("tab")
        expect(keymap_set.keymaps.find_by(layer: 0, key_position: "6-0")&.character).to eq("Y|y")

        # クリーンアップ
        keymap_set.destroy
      end
    end

    describe "ortho_4x12" do
      it "48キーのデフォルトキーマップがコピーされること" do
        user = create(:user)

        keymap_set_id = ActiveRecord::Base.connection.execute(
          "INSERT INTO keymap_sets (user_id, name, slug, keyboard_type, created_at, updated_at) " \
          "VALUES (#{user.id}, 'Test Ortho 4x12', 'test-ortho-4x12-#{SecureRandom.hex(4)}', 'ortho_4x12', NOW(), NOW()) " \
          "RETURNING id"
        )[0]['id'].to_i

        keymap_set = KeymapSet.find(keymap_set_id)
        keymap_set.send(:copy_default_keymap)

        # 48キー（4×12）が作成されていることを確認
        expect(keymap_set.keymaps.where(layer: 0).count).to eq(48)

        # 12列目のキーが存在することを確認
        expect(keymap_set.keymaps.find_by(layer: 0, key_position: "0-11")&.character).to eq("bs")
        expect(keymap_set.keymaps.find_by(layer: 0, key_position: "3-11")&.character).to eq("→")

        # クリーンアップ
        keymap_set.destroy
      end

      it "Layer 0に48キー、Layer 1に22キーが作成されること" do
        user = create(:user)

        keymap_set_id = ActiveRecord::Base.connection.execute(
          "INSERT INTO keymap_sets (user_id, name, slug, keyboard_type, created_at, updated_at) " \
          "VALUES (#{user.id}, 'Test Ortho Layers', 'test-ortho-layers-#{SecureRandom.hex(4)}', 'ortho_4x12', NOW(), NOW()) " \
          "RETURNING id"
        )[0]['id'].to_i

        keymap_set = KeymapSet.find(keymap_set_id)
        keymap_set.send(:copy_default_keymap)

        # Layer 0: 48キー（全キー設定あり）
        expect(keymap_set.keymaps.where(layer: 0).count).to eq(48)

        # Layer 1: 24キー（数字・記号と修飾キー）
        # 内訳: 1行目12キー（tab + 数字記号10個 + bs）+ 2行目2キー（caps, ent）+ 3行目1キー（shift）+ 4行目9キー（ctrl~layer2）
        expect(keymap_set.keymaps.where(layer: 1).count).to eq(24)

        # Layer 2-5: 空欄（デフォルトYAMLで空文字のためスキップされる）
        expect(keymap_set.keymaps.where(layer: 2).count).to eq(0)
        expect(keymap_set.keymaps.where(layer: 5).count).to eq(0)

        # クリーンアップ
        keymap_set.destroy
      end
    end
  end
end
