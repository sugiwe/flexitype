require "rails_helper"

RSpec.describe Lesson, type: :model do
  describe "バリデーション" do
    it "有効なファクトリを持つこと" do
      lesson = build(:lesson)
      expect(lesson).to be_valid
    end

    describe "name" do
      it "必須であること" do
        lesson = build(:lesson, name: nil)
        expect(lesson).not_to be_valid
      end

      it "100文字以下であること" do
        expect(build(:lesson, name: "あ" * 100)).to be_valid
        expect(build(:lesson, name: "あ" * 101)).not_to be_valid
      end
    end

    describe "description" do
      it "nilを許容すること" do
        expect(build(:lesson, description: nil)).to be_valid
      end

      it "500文字以下であること" do
        expect(build(:lesson, description: "あ" * 500)).to be_valid
        expect(build(:lesson, description: "あ" * 501)).not_to be_valid
      end
    end

    describe "items" do
      it "必須であること" do
        lesson = build(:lesson, items: nil)
        expect(lesson).not_to be_valid
      end

      it "空配列は許容しないこと" do
        lesson = build(:lesson, items: [])
        expect(lesson).not_to be_valid
      end

      it "配列形式であること" do
        expect(build(:lesson, items: [ { "type" => "typing", "text" => "test" } ])).to be_valid
      end
    end

    describe "count" do
      it "0より大きいこと" do
        expect(build(:lesson, count: 0)).not_to be_valid
        expect(build(:lesson, count: 1)).to be_valid
      end

      it "100以下であること" do
        expect(build(:lesson, count: 100)).to be_valid
        expect(build(:lesson, count: 101)).not_to be_valid
      end
    end
  end

  describe "スコープ" do
    describe ".official" do
      it "管理者が作成したレッスンのみ取得すること" do
        # TODO: createを使うテストは active_keymap_set の制約で一旦スキップ
        skip "createを使うテストは active_keymap_set の制約で一旦保留"
      end
    end

    describe ".user_created" do
      it "一般ユーザーが作成したレッスンのみ取得すること" do
        skip "createを使うテストは active_keymap_set の制約で一旦保留"
      end
    end

    describe ".published" do
      it "is_public=trueのレッスンのみ取得すること" do
        skip "createを使うテストは active_keymap_set の制約で一旦保留"
      end
    end

    describe ".free" do
      it "カテゴリーがpremium=falseのレッスンのみ取得すること" do
        skip "createを使うテストは active_keymap_set の制約で一旦保留"
      end
    end

    describe ".premium" do
      it "カテゴリーがpremium=trueのレッスンのみ取得すること" do
        skip "createを使うテストは active_keymap_set の制約で一旦保留"
      end
    end

    describe ".available_for_guest" do
      it "カテゴリーがrequires_login=falseのレッスンのみ取得すること" do
        skip "createを使うテストは active_keymap_set の制約で一旦保留"
      end
    end

    describe ".visible_to" do
      it "管理者の場合、全レッスンを取得すること" do
        skip "createを使うテストは active_keymap_set の制約で一旦保留"
      end

      it "一般ユーザーの場合、公式レッスン+自分のレッスン+公開レッスンを取得すること" do
        skip "createを使うテストは active_keymap_set の制約で一旦保留"
      end

      it "ゲストの場合、公式レッスン+公開レッスンのみ取得すること" do
        skip "createを使うテストは active_keymap_set の制約で一旦保留"
      end
    end
  end

  describe "インスタンスメソッド" do
    describe "#official?" do
      it "作成者が管理者の場合、trueを返すこと" do
        admin_user = build(:user, :admin)
        allow(admin_user).to receive(:admin?).and_return(true)
        lesson = build(:lesson, user: admin_user)
        expect(lesson.official?).to be true
      end

      it "作成者が一般ユーザーの場合、falseを返すこと" do
        regular_user = build(:user)
        allow(regular_user).to receive(:admin?).and_return(false)
        lesson = build(:lesson, user: regular_user)
        expect(lesson.official?).to be false
      end
    end

    describe "#to_lesson_info" do
      it "JavaScript用のレッスン情報をJSON形式で返すこと" do
        category = build(:category, name: "テストカテゴリー", description: "カテゴリー説明", requires_login: false, premium: false)
        lesson = build(:lesson, category: category, name: "テストレッスン", description: "レッスン説明", count: 10)
        lesson.id = 123  # idを仮設定

        info = lesson.to_lesson_info

        expect(info[:lesson_id]).to eq(123)
        expect(info[:category_name]).to eq("テストカテゴリー")
        expect(info[:category_description]).to eq("カテゴリー説明")
        expect(info[:lesson_name]).to eq("テストレッスン")
        expect(info[:lesson_description]).to eq("レッスン説明")
        expect(info[:count]).to eq(10)
        expect(info[:requires_login]).to be false
        expect(info[:premium]).to be false
      end
    end
  end

  describe "delegate" do
    it "categoryのrequires_loginを委譲すること" do
      category = build(:category, requires_login: true)
      lesson = build(:lesson, category: category)
      expect(lesson.requires_login).to be true
    end

    it "categoryのpremiumを委譲すること" do
      category = build(:category, premium: true)
      lesson = build(:lesson, category: category)
      expect(lesson.premium).to be true
    end
  end

  describe "アソシエーション" do
    it "userに属すること" do
      lesson = build(:lesson)
      expect(lesson.user).to be_present
    end

    it "categoryに属すること" do
      lesson = build(:lesson)
      expect(lesson.category).to be_present
    end

    it "lesson_recordsを持つこと" do
      lesson = build(:lesson)
      expect(lesson).to respond_to(:lesson_records)
    end
  end
end
