class Category < ApplicationRecord
  include Translatable

  has_many :lessons, dependent: :destroy

  # タブ定義（name/descriptionはYMLファイルで管理）
  TABS = {
    basics: { key: "basics", icon: "🔰" },
    english: { key: "english", icon: "🔠" },
    japanese: { key: "japanese", icon: "🌸" },
    programming: { key: "programming", icon: "💻" },
    my_lessons: { key: "my_lessons", icon: "📝", disabled: true },
    community: { key: "community", icon: "👥", disabled: true }
  }.freeze

  # バリデーション
  validates :name, presence: true, length: { maximum: 50 }, uniqueness: true
  validates :description, length: { maximum: 200 }, allow_blank: true
  validates :tab, presence: true, inclusion: { in: TABS.keys.map(&:to_s) }

  # スコープ
  scope :ordered, -> { order(display_order: :asc) }
  scope :published, -> { where(published: true) }
  scope :free, -> { where(premium: false) }
  scope :available_for_guest, -> { where(requires_login: false) }
  scope :by_tab, ->(tab_key) { where(tab: tab_key.to_s) }

  # クラスメソッド
  def self.available_tabs
    TABS.reject { |_key, config| config[:disabled] }
  end

  def self.all_tabs
    TABS
  end

  def self.tab_name(tab_key)
    I18n.t("tabs.#{tab_key}.name", default: tab_key.to_s.titleize)
  end

  def self.tab_description(tab_key)
    I18n.t("tabs.#{tab_key}.description", default: "")
  end
end
