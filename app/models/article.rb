class Article < ApplicationRecord
  belongs_to :author, class_name: "User", optional: true

  # ActiveStorage画像添付
  has_one_attached :thumbnail  # サムネイル（1枚）
  has_many_attached :images    # 本文用画像（複数枚）

  enum :category, {
    typing_tips: 0,
    keyboard_basics: 1,
    keyboard_reviews: 2,
    customization: 3,
    typnix_guides: 4,
    community: 5
  }

  validates :title, presence: true, length: { maximum: 100 }
  validates :slug, uniqueness: true,
            format: { with: /\A[a-z0-9-]+\z/ }, length: { maximum: 100 }, allow_blank: true
  validates :content, presence: true
  validates :category, presence: true
  validate :slug_must_exist_after_generation
  validate :thumbnail_validation

  scope :published, -> { where.not(published_at: nil).where("published_at <= ?", Time.current) }
  scope :recent, -> { order(published_at: :desc, created_at: :desc) }
  scope :by_category, ->(category) { where(category: category) }
  scope :popular, -> { order(view_count: :desc) }

  before_validation :normalize_slug
  before_validation :generate_slug, if: :should_generate_slug?

  def published?
    published_at.present? && published_at <= Time.current
  end

  def to_param
    slug
  end

  def increment_view_count!
    increment!(:view_count)
  end

  def author_name
    author&.username || "Typnix"
  end

  def meta_description
    excerpt.presence || content.truncate(160, separator: " ", omission: "...")
  end

  private

  def normalize_slug
    self.slug = nil if slug == ""
  end

  def should_generate_slug?
    slug.blank? && title.present?
  end

  def slug_must_exist_after_generation
    if slug.blank?
      errors.add(:slug, :blank)
    end
  end

  def generate_slug
    base_slug = title.parameterize
    candidate = base_slug
    counter = 1

    while Article.exists?(slug: candidate)
      candidate = "#{base_slug}-#{counter}"
      counter += 1
    end

    self.slug = candidate
  end

  def thumbnail_validation
    return unless thumbnail.attached?

    # ファイルサイズ制限（5MB以内）
    if thumbnail.blob.byte_size > 5.megabytes
      errors.add(:thumbnail, "のサイズは5MB以下にしてください")
    end

    # 画像形式チェック
    unless thumbnail.content_type.in?(%w[image/jpeg image/png image/gif image/webp])
      errors.add(:thumbnail, "はJPEG、PNG、GIF、WebP形式のみ対応しています")
    end
  end
end
