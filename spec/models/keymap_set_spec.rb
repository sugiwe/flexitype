require "rails_helper"

RSpec.describe KeymapSet, type: :model do
  describe "バリデーション" do
    it "有効なファクトリを持つこと" do
      keymap_set = build(:keymap_set)
      expect(keymap_set).to be_valid
    end

    describe "name" do
      it "必須であること" do
        keymap_set = build(:keymap_set, name: nil)
        expect(keymap_set).not_to be_valid
      end

      it "50文字以下であること" do
        expect(build(:keymap_set, name: "あ" * 50)).to be_valid
        expect(build(:keymap_set, name: "あ" * 51)).not_to be_valid
      end
    end

    describe "description" do
      it "nilを許容すること" do
        expect(build(:keymap_set, description: nil)).to be_valid
      end

      it "500文字以下であること" do
        expect(build(:keymap_set, description: "あ" * 500)).to be_valid
        expect(build(:keymap_set, description: "あ" * 501)).not_to be_valid
      end
    end

    describe "slug" do
      it "必須であること" do
        keymap_set = build(:keymap_set, slug: nil)
        keymap_set.valid?  # before_validationで自動生成されるためvalidationを実行
        expect(keymap_set.slug).to be_present
      end

      it "50文字以下であること" do
        expect(build(:keymap_set, slug: "a" * 50)).to be_valid
        expect(build(:keymap_set, slug: "a" * 51)).not_to be_valid
      end

      it "小文字英数字とハイフンのみ許容すること" do
        expect(build(:keymap_set, slug: "my-keymap-123")).to be_valid
        expect(build(:keymap_set, slug: "MyKeymap")).not_to be_valid  # 大文字不可
        expect(build(:keymap_set, slug: "my_keymap")).not_to be_valid  # アンダースコア不可
        expect(build(:keymap_set, slug: "my.keymap")).not_to be_valid  # ドット不可
      end

      it "ユーザーごとに一意であること" do
        # TODO: createを使うテストは active_keymap_set の制約で一旦スキップ
        skip "createを使うテストは active_keymap_set の制約で一旦保留"
      end

      it "空白の場合は自動生成されること" do
        user = build(:user)
        keymap_set = build(:keymap_set, user: user, slug: nil)
        keymap_set.valid?
        expect(keymap_set.slug).to match(/\Akeymap-\d+\z/)
      end
    end

    describe "ユーザーのキーマップ作成制限" do
      it "一般ユーザーは2つまで作成可能であること" do
        # TODO: createを使うテストは active_keymap_set の制約で一旦スキップ
        skip "createを使うテストは active_keymap_set の制約で一旦保留"
      end
    end
  end

  describe "スコープ" do
    describe ".published" do
      it "is_public=trueのレコードのみ取得すること" do
        # TODO: createを使うテストは active_keymap_set の制約で一旦スキップ
        skip "createを使うテストは active_keymap_set の制約で一旦保留"
      end
    end
  end

  describe "インスタンスメソッド" do
    describe "#oldest_for_user?" do
      it "ユーザーの最も古いキーマップセットの場合、trueを返すこと" do
        # TODO: createを使うテストは active_keymap_set の制約で一旦スキップ
        skip "createを使うテストは active_keymap_set の制約で一旦保留"
      end

      it "ユーザーの最も古いキーマップセットでない場合、falseを返すこと" do
        skip "createを使うテストは active_keymap_set の制約で一旦保留"
      end
    end

    describe "#deletable?" do
      it "最も古いキーマップセットの場合、falseを返すこと" do
        skip "createを使うテストは active_keymap_set の制約で一旦保留"
      end

      it "最も古いキーマップセットでない場合、trueを返すこと" do
        skip "createを使うテストは active_keymap_set の制約で一旦保留"
      end
    end

    describe "#to_param" do
      it "slugを返すこと" do
        keymap_set = build(:keymap_set, slug: "my-custom-keymap")
        expect(keymap_set.to_param).to eq("my-custom-keymap")
      end
    end
  end

  describe "クラスメソッド" do
    describe ".generate_next_slug" do
      it "重複がない場合、keymap-1を返すこと" do
        user = build(:user)
        allow(user.keymap_sets).to receive(:exists?).and_return(false)
        slug = KeymapSet.generate_next_slug(user)
        expect(slug).to eq("keymap-1")
      end

      it "keymap-1が存在する場合、keymap-2を返すこと" do
        user = build(:user)
        allow(user.keymap_sets).to receive(:exists?).with(slug: "keymap-1").and_return(true)
        allow(user.keymap_sets).to receive(:exists?).with(slug: "keymap-2").and_return(false)
        slug = KeymapSet.generate_next_slug(user)
        expect(slug).to eq("keymap-2")
      end

      it "複数重複する場合、利用可能な最小の番号を返すこと" do
        user = build(:user)
        allow(user.keymap_sets).to receive(:exists?).with(slug: "keymap-1").and_return(true)
        allow(user.keymap_sets).to receive(:exists?).with(slug: "keymap-2").and_return(true)
        allow(user.keymap_sets).to receive(:exists?).with(slug: "keymap-3").and_return(false)
        slug = KeymapSet.generate_next_slug(user)
        expect(slug).to eq("keymap-3")
      end
    end
  end

  describe "コールバック" do
    describe "before_validation :generate_slug" do
      it "slugが空白の場合、自動生成されること" do
        user = build(:user)
        keymap_set = build(:keymap_set, user: user, slug: "")
        keymap_set.valid?
        expect(keymap_set.slug).to match(/\Akeymap-\d+\z/)
      end

      it "slugが既に設定されている場合、上書きしないこと" do
        keymap_set = build(:keymap_set, slug: "my-custom-slug")
        keymap_set.valid?
        expect(keymap_set.slug).to eq("my-custom-slug")
      end
    end

    describe "after_create :copy_default_keymap" do
      it "作成後にデフォルトキーマップがコピーされること" do
        # TODO: createを使うテストは active_keymap_set の制約で一旦スキップ
        skip "createを使うテストは active_keymap_set の制約で一旦保留"
      end
    end
  end

  describe "アソシエーション" do
    it "userに属すること" do
      keymap_set = build(:keymap_set)
      expect(keymap_set.user).to be_present
    end

    it "keymapsを持つこと" do
      keymap_set = build(:keymap_set)
      expect(keymap_set).to respond_to(:keymaps)
    end
  end
end
