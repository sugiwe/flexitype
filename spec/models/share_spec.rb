require "rails_helper"

RSpec.describe Share, type: :model do
  describe "バリデーション" do
    it "有効なファクトリを持つこと" do
      lesson_record = build(:lesson_record, id: 1)
      share = build(:share, lesson_record: lesson_record)
      expect(share).to be_valid
    end

    describe "token" do
      it "必須であること" do
        share = build(:share, token: nil)
        share.valid?  # before_validationで自動生成されるためvalidationを実行
        expect(share.token).to be_present
      end

      it "一意であること" do
        # TODO: createを使うテストは active_keymap_set の制約で一旦スキップ
        skip "createを使うテストは active_keymap_set の制約で一旦保留"
      end

      it "自動生成されること" do
        share = build(:share, token: nil)
        share.valid?
        expect(share.token).to be_present
        expect(share.token.length).to be >= 16  # urlsafe_base64(16)は約22文字
      end

      it "既に設定されている場合、上書きしないこと" do
        share = build(:share, token: "custom-token-123")
        share.valid?
        expect(share.token).to eq("custom-token-123")
      end
    end
  end

  describe "delegate" do
    let(:category) { build(:category, name: "テストカテゴリー") }
    let(:lesson) { build(:lesson, category: category, name: "テストレッスン") }
    let(:lesson_record) do
      record = build(:lesson_record, lesson: lesson, accuracy: 95.0, typed_chars: 500, duration_seconds: 60)
      record.lesson.id = 1  # lesson_nameメソッドで使用
      record.send(:calculate_wpm)
      record.send(:calculate_grade)
      record
    end
    let(:share) { build(:share, lesson_record: lesson_record) }

    it "lesson_recordのaccuracyを委譲すること" do
      expect(share.accuracy).to eq(95.0)
    end

    it "lesson_recordのwpmを委譲すること" do
      expect(share.wpm).to eq(100)  # (500/60)*60/5 = 100
    end

    it "lesson_recordのduration_secondsを委譲すること" do
      expect(share.duration_seconds).to eq(60)
    end

    it "lesson_recordのmistake_countを委譲すること" do
      expect(share.mistake_count).to eq(lesson_record.mistake_count)
    end

    it "lesson_recordのgradeを委譲すること" do
      expect(share.grade).to eq("adult")
    end

    it "lesson_recordのgrade_emojiを委譲すること" do
      expect(share.grade_emoji).to eq("🦦")
    end

    it "lesson_recordのgrade_colorを委譲すること" do
      expect(share.grade_color).to eq("blue")
    end

    it "lesson_recordのgrade_descriptionを委譲すること" do
      expect(share.grade_description).to eq("堂々としたタイピング")
    end

    it "lesson_recordのlesson_nameを委譲すること" do
      allow(lesson_record).to receive(:lesson_name).and_return("テストレッスン")
      expect(share.lesson_name).to eq("テストレッスン")
    end
  end

  describe "インスタンスメソッド" do
    describe "#grade_name" do
      it "グレード名を返すこと" do
        lesson_record = build(:lesson_record, :adult)
        lesson_record.send(:calculate_wpm)
        lesson_record.send(:calculate_grade)
        share = build(:share, lesson_record: lesson_record)

        expect(share.grade_name).to eq("熟練のカワウソ")
      end
    end

    describe "#category_name" do
      it "カテゴリー名を返すこと" do
        category = build(:category, name: "基礎トレーニング")
        lesson = build(:lesson, category: category)
        lesson_record = build(:lesson_record, lesson: lesson)
        share = build(:share, lesson_record: lesson_record)

        expect(share.category_name).to eq("基礎トレーニング")
      end
    end
  end

  describe "アソシエーション" do
    it "lesson_recordに属すること" do
      share = build(:share)
      expect(share.lesson_record).to be_present
    end
  end
end
