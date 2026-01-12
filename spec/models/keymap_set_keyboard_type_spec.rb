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
        keymap_set = build(:keymap_set, keyboard_type: "ortho_5x14")
        expect(keymap_set.split_keyboard?).to be false
      end
    end

    describe "#ortho_keyboard?" do
      it "一体型キーボードの場合、trueを返すこと" do
        keymap_set = build(:keymap_set, keyboard_type: "ortho_5x14")
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
        keymap_set = build(:keymap_set, keyboard_type: "ortho_5x14")
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
        keymap_set = build(:keymap_set, keyboard_type: "ortho_5x14")
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

      it "ortho_5x14の全キー位置を返すこと" do
        keymap_set = build(:keymap_set, keyboard_type: "ortho_5x14")
        positions = keymap_set.all_key_positions

        expect(positions.count).to eq(70)  # 5行×14列
        expect(positions).to include("0-0", "0-13", "4-0", "4-13")
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

    describe "ortho_5x14" do
      it "70キーのデフォルトキーマップがコピーされること" do
        user = create(:user)

        keymap_set_id = ActiveRecord::Base.connection.execute(
          "INSERT INTO keymap_sets (user_id, name, slug, keyboard_type, created_at, updated_at) " \
          "VALUES (#{user.id}, 'Test Ortho 5x14', 'test-ortho-5x14-#{SecureRandom.hex(4)}', 'ortho_5x14', NOW(), NOW()) " \
          "RETURNING id"
        )[0]['id'].to_i

        keymap_set = KeymapSet.find(keymap_set_id)
        keymap_set.send(:copy_default_keymap)

        # 70キー（5×14）が作成されていることを確認
        expect(keymap_set.keymaps.where(layer: 0).count).to eq(70)

        # 14列目のキーが存在することを確認
        expect(keymap_set.keymaps.find_by(layer: 0, key_position: "0-13")&.character).to eq("bs")
        expect(keymap_set.keymaps.find_by(layer: 0, key_position: "4-13")&.character).to eq("ctrl")

        # クリーンアップ
        keymap_set.destroy
      end

      it "Layer 0に70キー、Layer 1に36キーが作成されること" do
        user = create(:user)

        keymap_set_id = ActiveRecord::Base.connection.execute(
          "INSERT INTO keymap_sets (user_id, name, slug, keyboard_type, created_at, updated_at) " \
          "VALUES (#{user.id}, 'Test Ortho Layers', 'test-ortho-layers-#{SecureRandom.hex(4)}', 'ortho_5x14', NOW(), NOW()) " \
          "RETURNING id"
        )[0]['id'].to_i

        keymap_set = KeymapSet.find(keymap_set_id)
        keymap_set.send(:copy_default_keymap)

        # Layer 0: 70キー（全キー設定あり）
        expect(keymap_set.keymaps.where(layer: 0).count).to eq(70)

        # Layer 1: 36キー（ファンクションキーと一部の修飾キー）
        expect(keymap_set.keymaps.where(layer: 1).count).to eq(36)

        # Layer 2-5: 空欄（デフォルトYAMLで空文字のためスキップされる）
        expect(keymap_set.keymaps.where(layer: 2).count).to eq(0)
        expect(keymap_set.keymaps.where(layer: 5).count).to eq(0)

        # クリーンアップ
        keymap_set.destroy
      end
    end
  end
end
