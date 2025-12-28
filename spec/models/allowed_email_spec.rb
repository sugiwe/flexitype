require 'rails_helper'

RSpec.describe AllowedEmail, type: :model do
  describe "validations" do
    it "メールアドレスが必須" do
      allowed_email = AllowedEmail.new(email: nil)
      expect(allowed_email).not_to be_valid
      expect(allowed_email.errors[:email]).to include("を入力してください")
    end

    it "有効なメールアドレス形式である必要がある" do
      allowed_email = AllowedEmail.new(email: "invalid-email")
      expect(allowed_email).not_to be_valid
      expect(allowed_email.errors[:email]).to be_present
    end

    it "メールアドレスが重複していない" do
      AllowedEmail.create!(email: "test@example.com")
      duplicate = AllowedEmail.new(email: "test@example.com")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email]).to include("はすでに存在します")
    end

    it "大文字小文字を区別せずに一意性をチェック" do
      AllowedEmail.create!(email: "test@example.com")
      duplicate = AllowedEmail.new(email: "TEST@example.com")
      expect(duplicate).not_to be_valid
    end
  end

  describe "callbacks" do
    it "保存前にメールアドレスを小文字化する" do
      allowed_email = AllowedEmail.create!(email: "TEST@EXAMPLE.COM")
      expect(allowed_email.email).to eq("test@example.com")
    end

    it "保存前にメールアドレスの空白を削除する" do
      allowed_email = AllowedEmail.create!(email: "  test@example.com  ")
      expect(allowed_email.email).to eq("test@example.com")
    end
  end

  describe ".allowed?" do
    before do
      # フィーチャーフラグをデフォルト（有効）に設定
      allow(Authentication).to receive(:restrict_login?).and_return(true)
    end

    context "ログイン制限が有効な場合" do
      it "許可リストに含まれるメールアドレスはtrueを返す" do
        AllowedEmail.create!(email: "allowed@example.com", active: true)
        expect(AllowedEmail.allowed?("allowed@example.com")).to be true
      end

      it "許可リストに含まれないメールアドレスはfalseを返す" do
        expect(AllowedEmail.allowed?("not-allowed@example.com")).to be false
      end

      it "無効化されたメールアドレスはfalseを返す" do
        AllowedEmail.create!(email: "inactive@example.com", active: false)
        expect(AllowedEmail.allowed?("inactive@example.com")).to be false
      end

      it "大文字小文字を区別せずにチェック" do
        AllowedEmail.create!(email: "test@example.com", active: true)
        expect(AllowedEmail.allowed?("TEST@EXAMPLE.COM")).to be true
      end
    end

    context "ログイン制限が無効な場合" do
      before do
        allow(Authentication).to receive(:restrict_login?).and_return(false)
      end

      it "どんなメールアドレスでもtrueを返す" do
        expect(AllowedEmail.allowed?("anyone@example.com")).to be true
      end

      it "許可リストに含まれなくてもtrueを返す" do
        expect(AllowedEmail.allowed?("not-in-list@example.com")).to be true
      end
    end
  end

  describe "scopes" do
    it ".activeは有効なメールアドレスのみを返す" do
      active1 = AllowedEmail.create!(email: "active1@example.com", active: true)
      active2 = AllowedEmail.create!(email: "active2@example.com", active: true)
      AllowedEmail.create!(email: "inactive@example.com", active: false)

      expect(AllowedEmail.active).to contain_exactly(active1, active2)
    end
  end
end
