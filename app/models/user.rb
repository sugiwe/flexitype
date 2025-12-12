class User < ApplicationRecord
  has_many :keymaps, dependent: :destroy

  validates :google_uid, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true, length: { maximum: 254 }
  validates :name, presence: true, length: { maximum: 30 }
  validates :icon_url, length: { maximum: 4096 }, allow_blank: true

  # Google IDトークンのペイロードからユーザーを検索または作成
  def self.from_google(payload)
    where(google_uid: payload["sub"]).first_or_create do |user|
      user.email = payload["email"]
      user.name = payload["name"]
      user.icon_url = payload["picture"]
    end
  end

  # 許可リストに含まれているかチェック
  def self.email_allowed?(email)
    allowed_emails = Rails.application.config.allowed_emails

    # 開発環境では空なら全員許可、本番環境では空なら全員拒否（安全性重視）
    return true if allowed_emails.empty? && !Rails.env.production?

    allowed_emails.include?(email)
  end
end
