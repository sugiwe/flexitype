class User < ApplicationRecord
  has_many :keymap_sets, dependent: :destroy
  has_many :keymaps, dependent: :destroy
  has_many :lessons, dependent: :destroy
  has_many :lesson_records, dependent: :destroy
  belongs_to :active_keymap_set, class_name: "KeymapSet", optional: true

  after_create :create_default_keymap_set

  validates :google_uid, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true, length: { maximum: 254 }
  validates :name, presence: true, length: { maximum: 30 }
  validates :icon_url, length: { maximum: 4096 }, allow_blank: true
  validates :username, presence: true, uniqueness: { case_sensitive: false },
                       format: { with: /\A[a-z0-9]+(?:[._-][a-z0-9]+)*\z/,
                                message: "は半角英数字、ハイフン、アンダースコア、ドットのみ使用できます（記号は連続不可、先頭・末尾不可）" },
                       length: { minimum: 3, maximum: 30 }
  validate :username_not_reserved
  validate :username_change_allowed, if: :username_changed?
  validate :must_have_active_keymap_set_after_creation

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

  # 管理者かどうかを判定
  def admin?
    admin_emails = ENV["ADMIN_EMAILS"]&.split(",")&.map(&:strip) || []
    admin_emails.include?(email)
  end

  # プレミアムユーザーかどうかを判定（将来的にはsubscriptionテーブルを参照）
  def premium?
    # 現時点では管理者のみtrue（仮実装）
    # 将来的には: subscriptions.active.exists? など
    admin?
  end

  # プレミアムユーザーまたは管理者かどうか
  def premium_or_admin?
    premium? || admin?
  end

  # 表示用の名前（公式アカウントは「Typnix Official」）
  def display_name
    admin? ? "Typnix Official" : name
  end

  # 公開されたレッスンのみ取得
  def published_lessons
    lessons.published.includes(:category).order(created_at: :desc)
  end

  # ユーザー名を変更可能かどうか
  def can_change_username?
    username_changed_at.nil? || username_changed_at < 24.hours.ago
  end

  # 次回ユーザー名変更可能日時
  def next_username_change_at
    return nil if username_changed_at.nil?

    username_changed_at + 24.hours
  end

  private

  # ユーザー名が予約語でないかチェック
  def username_not_reserved
    return if username.blank?

    if ReservedUsernames::LIST.include?(username.downcase)
      errors.add(:username, "は予約されているため使用できません")
    end
  end

  # ユーザー名の変更が許可されているかチェック
  def username_change_allowed
    return if new_record? # 新規作成時はチェックしない
    return if can_change_username?

    next_change = next_username_change_at.strftime("%Y年%m月%d日 %H時%M分")
    errors.add(:username, "は24時間に1回しか変更できません（次回変更可能: #{next_change}）")
  end

  # アクティブキーマップセットが必須であることをチェック
  # ただし、作成直後（after_createコールバック実行前）は除外
  def must_have_active_keymap_set_after_creation
    return if new_record? # 新規作成時はチェックしない
    return if active_keymap_set_id.present?

    errors.add(:active_keymap_set, "は必須です")
  end

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
