class Category < ApplicationRecord
  has_many :lessons, dependent: :destroy

  # タブ定義
  TABS = {
    basics: { key: "basics", name: "基礎トレーニング", icon: "🔰", description: "キー配置と指の練習" },
    english: { key: "english", name: "英語練習", icon: "🔠", description: "英単語・フレーズの練習" },
    japanese: { key: "japanese", name: "日本語練習", icon: "🌸", description: "かな・ローマ字入力" },
    programming: { key: "programming", name: "プログラミング", icon: "💻", description: "コード・用語の練習" },
    my_lessons: { key: "my_lessons", name: "マイレッスン", icon: "📝", description: "自作レッスン（準備中）", disabled: true },
    community: { key: "community", name: "コミュニティ", icon: "👥", description: "共有レッスン（準備中）", disabled: true }
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
end
