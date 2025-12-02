class User < ApplicationRecord
  validates :google_uid, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true

  # Google IDトークンのペイロードからユーザーを検索または作成
  def self.from_google(payload)
    where(google_uid: payload["sub"]).first_or_create do |user|
      user.email = payload["email"]
      user.name = payload["name"]
    end
  end

  # 許可リストに含まれているかチェック
  def self.email_allowed?(email)
    allowed_emails = Rails.application.config.allowed_emails
    return true if allowed_emails.empty? # 許可リストが空なら全員許可（開発時用）
    allowed_emails.include?(email)
  end
end
