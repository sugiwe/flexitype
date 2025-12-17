class User < ApplicationRecord
  has_many :keymap_sets, dependent: :destroy
  has_many :keymaps, dependent: :destroy
  has_many :typing_sessions, dependent: :destroy

  validates :google_uid, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true, length: { maximum: 254 }
  validates :name, presence: true, length: { maximum: 30 }
  validates :icon_url, length: { maximum: 4096 }, allow_blank: true
  validates :history_limit, presence: true, numericality: { greater_than: 0 }
  validates :username, presence: true, uniqueness: { case_sensitive: false },
                       format: { with: /\A[a-z0-9]+(?:[._-][a-z0-9]+)*\z/,
                                message: "は半角英数字、ハイフン、アンダースコア、ドットのみ使用できます（記号は連続不可、先頭・末尾不可）" },
                       length: { minimum: 3, maximum: 30 }

  # Google IDトークンのペイロードからユーザーを検索または作成
  def self.from_google(payload)
    where(google_uid: payload["sub"]).first_or_create do |user|
      user.email = payload["email"]
      user.name = payload["name"]
      user.icon_url = payload["picture"]
      user.username = generate_unique_username(payload["email"])
    end
  end

  # Gmailアドレスからユニークなusernameを生成
  def self.generate_unique_username(email)
    # Gmailアドレスの@の前の部分を取得し、小文字化
    username_base = email.split("@").first.downcase

    # 既存のusernameと重複しないようにする
    username = username_base
    counter = 1
    while exists?(username: username)
      username = "#{username_base}#{counter}"
      counter += 1
    end

    username
  end

  # 許可リストに含まれているかチェック
  def self.email_allowed?(email)
    allowed_emails = Rails.application.config.allowed_emails

    # 開発環境では空なら全員許可、本番環境では空なら全員拒否（安全性重視）
    return true if allowed_emails.empty? && !Rails.env.production?

    allowed_emails.include?(email)
  end

  # 古い履歴を削除（history_limitを超えた分）
  def cleanup_old_typing_sessions
    sessions = typing_sessions.order(created_at: :desc)
    sessions.offset(history_limit).destroy_all
  end
end
