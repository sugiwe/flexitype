class User < ApplicationRecord
  has_many :keymap_sets, dependent: :destroy
  has_many :keymaps, dependent: :destroy
  has_many :lessons, dependent: :destroy
  has_many :lesson_records, dependent: :destroy
  belongs_to :active_keymap_set, class_name: "KeymapSet"

  after_create :create_default_keymap_set

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
  def cleanup_old_lesson_records
    records = lesson_records.order(created_at: :desc)
    records.offset(history_limit).destroy_all
  end

  # 管理者かどうかを判定
  def admin?
    admin_emails = ENV["ADMIN_EMAILS"]&.split(",")&.map(&:strip) || []
    admin_emails.include?(email)
  end

  # 課金ユーザーかどうかを判定（将来的にはsubscriptionテーブルを参照）
  def premium?
    # 現時点では管理者のみtrue（仮実装）
    # 将来的には: subscriptions.active.exists? など
    admin?
  end

  # 課金ユーザーまたは管理者かどうか
  def premium_or_admin?
    premium? || admin?
  end

  private

  # 初期キーマップセットを作成し、アクティブに設定
  def create_default_keymap_set
    default_keymap = keymap_sets.create!(
      name: "マイキーマップ",
      description: "デフォルトキーマップ（Mac配列ベース）です。一般的なMacキーボードの配列を基にしています。このまま練習に使うことも、あなたの実際のキーボード配列に合わせて自由に編集することもできます。将来的には他のユーザーと共有できる機能も予定しています。",
      is_public: false
    )
    # 作成したキーマップを即座にアクティブに設定
    update!(active_keymap_set: default_keymap)
  end
end
