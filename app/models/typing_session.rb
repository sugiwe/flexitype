class TypingSession < ApplicationRecord
  belongs_to :user

  # バリデーション
  validates :word_count, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :correct_count, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :mistake_count, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :accuracy, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :duration_seconds, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # 作成後、古い履歴を自動削除
  after_create :cleanup_old_sessions

  # スコープ: 完了日時降順
  scope :recent, -> { order(completed_at: :desc) }

  private

  def cleanup_old_sessions
    user.cleanup_old_typing_sessions
  end
end
