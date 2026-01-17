require "rails_helper"

RSpec.describe Keymap, type: :model do
  describe "バリデーション" do
    describe "key_position" do
      it "有効な形式の場合、バリデーションが通ること" do
        keymap_set = build(:keymap_set)
        # split_4x6の範囲内
        expect(build(:keymap, keymap_set: keymap_set, key_position: "0-0")).to be_valid
        expect(build(:keymap, keymap_set: keymap_set, key_position: "11-7")).to be_valid
        # ortho_4x12の範囲内（12列目まで）
        expect(build(:keymap, keymap_set: keymap_set, key_position: "0-11")).to be_valid
        expect(build(:keymap, keymap_set: keymap_set, key_position: "3-11")).to be_valid
      end

      it "無効な形式の場合、バリデーションエラーになること" do
        keymap_set = build(:keymap_set)
        # 行が範囲外（12行目以上）
        expect(build(:keymap, keymap_set: keymap_set, key_position: "12-0")).not_to be_valid
        # 列が範囲外（14列目以上）
        expect(build(:keymap, keymap_set: keymap_set, key_position: "0-14")).not_to be_valid
        # 形式が不正
        expect(build(:keymap, keymap_set: keymap_set, key_position: "a-b")).not_to be_valid
        expect(build(:keymap, keymap_set: keymap_set, key_position: "0_0")).not_to be_valid
      end
    end

    describe "layer" do
      it "0〜5の範囲内であること" do
        keymap_set = build(:keymap_set)
        expect(build(:keymap, keymap_set: keymap_set, layer: 0)).to be_valid
        expect(build(:keymap, keymap_set: keymap_set, layer: 5)).to be_valid
        expect(build(:keymap, keymap_set: keymap_set, layer: 6)).not_to be_valid
        expect(build(:keymap, keymap_set: keymap_set, layer: -1)).not_to be_valid
      end
    end
  end

  describe "クラスメソッド" do
    describe ".default_keymap_for_type" do
      it "split_4x6のデフォルトキーマップを読み込めること" do
        keymap = Keymap.default_keymap_for_type("split_4x6")

        expect(keymap).to be_a(Hash)
        expect(keymap.keys).to match_array([ 0, 1, 2, 3, 4, 5 ])  # 6レイヤー
        expect(keymap[0]).to be_a(Hash)
        expect(keymap[0].keys.count).to eq(48)  # 48キー（4×6 左右）

        # 代表的なキーの存在確認
        expect(keymap[0]["0-0"]).to eq("tab")
        expect(keymap[0]["0-1"]).to eq("Q|q")
        expect(keymap[0]["6-0"]).to eq("Y|y")
      end

      it "ortho_4x12のデフォルトキーマップを読み込めること" do
        keymap = Keymap.default_keymap_for_type("ortho_4x12")

        expect(keymap).to be_a(Hash)
        expect(keymap.keys).to match_array([ 0, 1, 2, 3, 4, 5 ])
        expect(keymap[0]).to be_a(Hash)
        expect(keymap[0].keys.count).to eq(48)  # 48キー（4×12）

        # 12列目（0-11）のキーが存在すること
        expect(keymap[0]["0-11"]).to eq("bs")
        expect(keymap[0]["1-11"]).to eq("ent")
        expect(keymap[0]["3-11"]).to eq("→")
      end

      it "存在しないキーボードタイプの場合、split_4x6にフォールバックすること" do
        keymap = Keymap.default_keymap_for_type("nonexistent_type")

        expect(keymap[0].keys.count).to eq(48)  # split_4x6の48キー
      end

      it "キャッシュが機能すること" do
        # 1回目の呼び出し
        keymap1 = Keymap.default_keymap_for_type("split_4x6")
        # 2回目の呼び出し（キャッシュから取得）
        keymap2 = Keymap.default_keymap_for_type("split_4x6")

        # 同じオブジェクトが返されることを確認（キャッシュされている）
        expect(keymap1.object_id).to eq(keymap2.object_id)
      end
    end

    describe ".default_keymap" do
      it "引数なしの場合、split_4x6のデフォルトキーマップを返すこと（後方互換性）" do
        keymap = Keymap.default_keymap

        expect(keymap[0].keys.count).to eq(48)
        expect(keymap[0]["0-0"]).to eq("tab")
      end
    end
  end
end
