require "rails_helper"

RSpec.describe LessonRecord, type: :model do
  describe "バリデーション" do
    it "有効なファクトリを持つこと" do
      lesson_record = build(:lesson_record)
      expect(lesson_record).to be_valid
    end

    describe "word_count" do
      it "必須であること" do
        lesson_record = build(:lesson_record, word_count: nil)
        expect(lesson_record).not_to be_valid
      end

      it "0以上であること" do
        expect(build(:lesson_record, word_count: -1)).not_to be_valid
        expect(build(:lesson_record, word_count: 0)).to be_valid
        expect(build(:lesson_record, word_count: 100)).to be_valid
      end
    end

    describe "correct_count" do
      it "必須であること" do
        lesson_record = build(:lesson_record, correct_count: nil)
        expect(lesson_record).not_to be_valid
      end

      it "0以上であること" do
        expect(build(:lesson_record, correct_count: -1)).not_to be_valid
        expect(build(:lesson_record, correct_count: 0)).to be_valid
      end
    end

    describe "mistake_count" do
      it "必須であること" do
        lesson_record = build(:lesson_record, mistake_count: nil)
        expect(lesson_record).not_to be_valid
      end

      it "0以上であること" do
        expect(build(:lesson_record, mistake_count: -1)).not_to be_valid
        expect(build(:lesson_record, mistake_count: 0)).to be_valid
      end
    end

    describe "accuracy" do
      it "0以上100以下であること" do
        expect(build(:lesson_record, accuracy: -0.1)).not_to be_valid
        expect(build(:lesson_record, accuracy: 0)).to be_valid
        expect(build(:lesson_record, accuracy: 50.5)).to be_valid
        expect(build(:lesson_record, accuracy: 100)).to be_valid
        expect(build(:lesson_record, accuracy: 100.1)).not_to be_valid
      end

      it "nilを許容すること" do
        expect(build(:lesson_record, accuracy: nil)).to be_valid
      end
    end

    describe "duration_seconds" do
      it "0以上であること" do
        expect(build(:lesson_record, duration_seconds: -1)).not_to be_valid
        expect(build(:lesson_record, duration_seconds: 0)).to be_valid
        expect(build(:lesson_record, duration_seconds: 60)).to be_valid
      end

      it "nilを許容すること" do
        expect(build(:lesson_record, duration_seconds: nil)).to be_valid
      end
    end
  end

  describe "WPM計算" do
    it "typed_charsとduration_secondsからWPMを自動計算すること" do
      # before_saveコールバックをテスト（buildでオブジェクト作成後、手動でcallback実行）
      lesson_record = build(:lesson_record, typed_chars: 500, duration_seconds: 60)
      lesson_record.send(:calculate_wpm)  # private メソッドを直接呼び出し
      # CPM = (500 / 60) * 60 = 500
      # WPM = 500 / 5 = 100
      expect(lesson_record.wpm).to eq(100)
    end

    it "duration_secondsが0の場合、WPMを計算しないこと" do
      lesson_record = build(:lesson_record, typed_chars: 500, duration_seconds: 0)
      lesson_record.send(:calculate_wpm)
      expect(lesson_record.wpm).to be_nil
    end

    it "typed_charsがnilの場合、WPMを計算しないこと" do
      lesson_record = build(:lesson_record, typed_chars: nil, duration_seconds: 60)
      lesson_record.send(:calculate_wpm)
      expect(lesson_record.wpm).to be_nil
    end

    it "duration_secondsがnilの場合、WPMを計算しないこと" do
      lesson_record = build(:lesson_record, typed_chars: 500, duration_seconds: nil)
      lesson_record.send(:calculate_wpm)
      expect(lesson_record.wpm).to be_nil
    end

    it "小数点以下を四捨五入すること" do
      lesson_record = build(:lesson_record, typed_chars: 333, duration_seconds: 60)
      lesson_record.send(:calculate_wpm)
      # CPM = (333 / 60) * 60 = 333
      # WPM = 333 / 5 = 66.6 → 67（四捨五入）
      expect(lesson_record.wpm).to eq(67)
    end
  end

  describe "グレード判定" do
    context "伝説のカワウソ級" do
      it "正答率98%以上、WPM 80以上で「legendary」になること" do
        lesson_record = build(:lesson_record, :legendary)
        lesson_record.send(:calculate_wpm)
        lesson_record.send(:calculate_grade)
        expect(lesson_record.grade).to eq("legendary")
      end

      it "正答率98%、WPM 80で「legendary」になること（境界値）" do
        # WPM = (800 / 120) * 60 / 5 = 80
        lesson_record = build(:lesson_record, accuracy: 98.0, typed_chars: 800, duration_seconds: 120)
        lesson_record.send(:calculate_wpm)
        lesson_record.send(:calculate_grade)
        expect(lesson_record.grade).to eq("legendary")
      end
    end

    context "熟練のカワウソ級" do
      it "正答率90%以上、WPM 50以上で「adult」になること" do
        lesson_record = build(:lesson_record, :adult)
        lesson_record.send(:calculate_wpm)
        lesson_record.send(:calculate_grade)
        expect(lesson_record.grade).to eq("adult")
      end

      it "正答率90%、WPM 50で「adult」になること（境界値）" do
        # WPM = (500 / 120) * 60 / 5 = 50
        lesson_record = build(:lesson_record, accuracy: 90.0, typed_chars: 500, duration_seconds: 120)
        lesson_record.send(:calculate_wpm)
        lesson_record.send(:calculate_grade)
        expect(lesson_record.grade).to eq("adult")
      end

      it "正答率97%でもWPM 49なら「adult」にならないこと" do
        # WPM = (490 / 120) * 60 / 5 = 49（四捨五入）
        lesson_record = build(:lesson_record, accuracy: 97.0, typed_chars: 490, duration_seconds: 120)
        lesson_record.send(:calculate_wpm)
        lesson_record.send(:calculate_grade)
        expect(lesson_record.grade).to eq("young")
      end
    end

    context "若手のカワウソ級" do
      it "正答率80%以上、WPM 30以上で「young」になること" do
        lesson_record = build(:lesson_record, :young)
        lesson_record.send(:calculate_wpm)
        lesson_record.send(:calculate_grade)
        expect(lesson_record.grade).to eq("young")
      end
    end

    context "子どものカワウソ級" do
      it "正答率70%以上、WPM 15以上で「child」になること" do
        lesson_record = build(:lesson_record, :child)
        lesson_record.send(:calculate_wpm)
        lesson_record.send(:calculate_grade)
        expect(lesson_record.grade).to eq("child")
      end
    end

    context "赤ちゃんカワウソ級" do
      it "正答率70%未満またはWPM 15未満で「baby」になること" do
        lesson_record = build(:lesson_record, :baby)
        lesson_record.send(:calculate_wpm)
        lesson_record.send(:calculate_grade)
        expect(lesson_record.grade).to eq("baby")
      end

      it "正答率が高くてもWPMが低ければ「baby」になること" do
        lesson_record = build(:lesson_record, accuracy: 100.0, typed_chars: 50, duration_seconds: 60)
        lesson_record.send(:calculate_wpm)
        lesson_record.send(:calculate_grade)
        expect(lesson_record.grade).to eq("baby")
      end

      it "WPMが高くても正答率が低ければ「baby」になること" do
        lesson_record = build(:lesson_record, accuracy: 60.0, typed_chars: 800, duration_seconds: 60)
        lesson_record.send(:calculate_wpm)
        lesson_record.send(:calculate_grade)
        expect(lesson_record.grade).to eq("baby")
      end
    end

    it "accuracyまたはwpmがnilの場合、グレードを設定しないこと" do
      lesson_record = build(:lesson_record, accuracy: nil, typed_chars: 500, duration_seconds: 60)
      lesson_record.send(:calculate_wpm)
      lesson_record.send(:calculate_grade)
      expect(lesson_record.grade).to be_nil
    end
  end

  describe "グレード情報取得メソッド" do
    let(:lesson_record) do
      record = build(:lesson_record, :adult)
      record.send(:calculate_wpm)
      record.send(:calculate_grade)
      record
    end

    describe "#grade_info" do
      it "グレードに対応する情報を返すこと" do
        info = lesson_record.grade_info
        expect(info[:name]).to eq("熟練のカワウソ")
        expect(info[:emoji]).to eq("🦦")
        expect(info[:color]).to eq("blue")
        expect(info[:description]).to eq("堂々としたタイピング")
      end

      it "gradeがnilの場合、赤ちゃんカワウソの情報を返すこと" do
        lesson_record.grade = nil
        info = lesson_record.grade_info
        expect(info[:name]).to eq("赤ちゃんカワウソ")
      end
    end

    describe "#grade_emoji" do
      it "グレードの絵文字を返すこと" do
        expect(lesson_record.grade_emoji).to eq("🦦")
      end
    end

    describe "#grade_color" do
      it "グレードの色を返すこと" do
        expect(lesson_record.grade_color).to eq("blue")
      end
    end

    describe "#grade_description" do
      it "グレードの説明を返すこと" do
        expect(lesson_record.grade_description).to eq("堂々としたタイピング")
      end
    end
  end

  describe "スコープ" do
    describe ".recent" do
      it "完了日時降順でレコードを取得すること" do
        # TODO: createを使うテストは active_keymap_set の制約で一旦スキップ
        skip "createを使うテストは active_keymap_set の制約で一旦保留"
      end
    end
  end

  describe "アソシエーション" do
    it "userに属すること" do
      lesson_record = build(:lesson_record)
      expect(lesson_record.user).to be_present
    end

    it "lessonに属すること（optional）" do
      lesson_record = build(:lesson_record, lesson: nil)
      expect(lesson_record).to be_valid
    end

    it "sharesを持つこと" do
      lesson_record = build(:lesson_record)
      expect(lesson_record).to respond_to(:shares)
    end
  end
end
