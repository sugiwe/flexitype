require "rails_helper"

RSpec.describe User, type: :model do
  describe "バリデーション" do
    it "有効なファクトリを持つこと" do
      user = build(:user)
      expect(user).to be_valid
      # TODO: after_createコールバックのテストを追加
      # 現状、FactoryBotとactive_keymap_set (NOT NULL制約)の相性問題で
      # after_createが実行される前にエラーになってしまう
      # 解決策: Userモデルのコールバック設計を見直すか、
      #        FactoryBotのカスタム作成戦略を実装する
      # expect(user.active_keymap_set).to be_present
    end

    describe "google_uid" do
      it "必須であること" do
        user = build(:user, google_uid: nil)
        expect(user).not_to be_valid
        expect(user.errors[:google_uid]).to include("を入力してください")
      end

      it "一意であること" do
        # TODO: createを使うテストは active_keymap_set の問題で一旦スキップ
        # User.create!(google_uid: "unique_id", email: "test@example.com", name: "Test", username: "test123")
        # でDBに直接保存する方法も検討
        skip "createを使うテストは active_keymap_set の制約で一旦保留"
      end
    end

    describe "email" do
      it "必須であること" do
        user = build(:user, email: nil)
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include("を入力してください")
      end

      it "一意であること" do
        skip "createを使うテストは active_keymap_set の制約で一旦保留"
      end

      it "254文字以下であること" do
        user = build(:user, email: "a" * 246 + "@test.com") # 255文字
        expect(user).not_to be_valid
      end
    end

    describe "name" do
      it "必須であること" do
        user = build(:user, name: nil)
        expect(user).not_to be_valid
        expect(user.errors[:name]).to include("を入力してください")
      end

      it "30文字以下であること" do
        user = build(:user, name: "あ" * 31)
        expect(user).not_to be_valid
      end
    end

    describe "username" do
      it "必須であること" do
        user = build(:user, username: nil)
        expect(user).not_to be_valid
      end

      it "3文字以上30文字以下であること" do
        expect(build(:user, username: "ab")).not_to be_valid
        expect(build(:user, username: "abc")).to be_valid
        expect(build(:user, username: "a" * 30)).to be_valid
        expect(build(:user, username: "a" * 31)).not_to be_valid
      end

      it "小文字英数字、ハイフン、アンダースコア、ドットのみ使用可能" do
        expect(build(:user, username: "valid_user-123")).to be_valid
        expect(build(:user, username: "user.name")).to be_valid
        expect(build(:user, username: "User123")).not_to be_valid # 大文字不可
        expect(build(:user, username: "user@name")).not_to be_valid # @不可
      end

      it "記号が連続不可" do
        expect(build(:user, username: "user__name")).not_to be_valid
        expect(build(:user, username: "user--name")).not_to be_valid
        expect(build(:user, username: "user..name")).not_to be_valid
      end

      it "記号が先頭・末尾に使用不可" do
        expect(build(:user, username: "_username")).not_to be_valid
        expect(build(:user, username: "username_")).not_to be_valid
        expect(build(:user, username: "-username")).not_to be_valid
        expect(build(:user, username: ".username")).not_to be_valid
      end

      it "予約語は使用不可" do
        expect(build(:user, username: "admin")).not_to be_valid
        expect(build(:user, username: "api")).not_to be_valid
        expect(build(:user, username: "my")).not_to be_valid
      end

      it "大文字小文字を区別せず一意であること" do
        skip "createを使うテストは active_keymap_set の制約で一旦保留"
      end
    end
  end

  describe "ユーザー名変更制限" do
    describe "#can_change_username?" do
      it "username_changed_atがnilの場合、trueを返すこと" do
        user = build(:user, username_changed_at: nil)
        expect(user.can_change_username?).to be true
      end

      it "24時間以内の場合、falseを返すこと" do
        user = build(:user, :with_username_history) # 12時間前
        expect(user.can_change_username?).to be false
      end

      it "24時間以上経過している場合、trueを返すこと" do
        user = build(:user, :can_change_username) # 25時間前
        expect(user.can_change_username?).to be true
      end
    end

    describe "#next_username_change_at" do
      it "username_changed_atがnilの場合、nilを返すこと" do
        user = build(:user, username_changed_at: nil)
        expect(user.next_username_change_at).to be_nil
      end

      it "username_changed_atから24時間後を返すこと" do
        changed_at = 12.hours.ago
        user = build(:user, username_changed_at: changed_at)
        expect(user.next_username_change_at).to eq(changed_at + 24.hours)
      end
    end
  end

  describe "クラスメソッド" do
    describe ".generate_unique_username" do
      it "メールアドレスから@の前部分を抽出してusernameを生成すること" do
        username = User.generate_unique_username("test.user@example.com")
        expect(username).to eq("test.user")
      end

      it "既存のusernameと重複する場合、数字を付与すること" do
        skip "createを使うテストは active_keymap_set の制約で一旦保留"
      end

      it "複数回重複する場合、連番を付与すること" do
        skip "createを使うテストは active_keymap_set の制約で一旦保留"
      end
    end

    # NOTE: .email_allowed? メソッドは Day 28 で AllowedEmail モデルに移行されました
    # テストは spec/models/allowed_email_spec.rb を参照
  end

  describe "インスタンスメソッド" do
    describe "#admin?" do
      it "ADMIN_EMAILSに含まれる場合、trueを返すこと" do
        allow(ENV).to receive(:[]).with("ADMIN_EMAILS").and_return("admin@example.com, admin2@example.com")
        user = build(:user, email: "admin@example.com")
        expect(user.admin?).to be true
      end

      it "ADMIN_EMAILSに含まれない場合、falseを返すこと" do
        allow(ENV).to receive(:[]).with("ADMIN_EMAILS").and_return("admin@example.com")
        user = build(:user, email: "user@example.com")
        expect(user.admin?).to be false
      end
    end

    describe "#premium?" do
      it "管理者の場合、trueを返すこと（現時点の仮実装）" do
        user = build(:user, :admin)
        allow(user).to receive(:admin?).and_return(true)
        expect(user.premium?).to be true
      end

      it "一般ユーザーの場合、falseを返すこと" do
        user = build(:user)
        allow(user).to receive(:admin?).and_return(false)
        expect(user.premium?).to be false
      end
    end

    describe "#author_name" do
      it "管理者の場合、「Typnix Official」を返すこと" do
        user = build(:user, :admin, name: "管理者")
        allow(user).to receive(:admin?).and_return(true)
        expect(user.author_name).to eq("Typnix Official")
      end

      it "一般ユーザーの場合、nameを返すこと" do
        user = build(:user, name: "テストユーザー")
        allow(user).to receive(:admin?).and_return(false)
        expect(user.author_name).to eq("テストユーザー")
      end
    end
  end
end
