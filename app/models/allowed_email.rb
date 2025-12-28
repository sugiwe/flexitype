# frozen_string_literal: true

# 許可メールアドレス管理モデル
#
# ベータ版期間中、ログインを許可するメールアドレスを管理します。
# このモデルは将来的に削除予定です（全員ログインOKになる予定）。
#
# @attr [String] email 許可するメールアドレス
# @attr [Boolean] active 有効/無効フラグ（デフォルト: true）
# @attr [String] note 管理者メモ（誰の依頼で追加したか等）
class AllowedEmail < ApplicationRecord
  # バリデーション
  validates :email,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }

  # スコープ
  scope :active, -> { where(active: true) }

  # メールアドレスの正規化（保存前に小文字化）
  before_validation :normalize_email

  # ログイン許可チェック
  #
  # @param email [String] チェック対象のメールアドレス
  # @return [Boolean] ログインが許可されている場合true
  #
  # NOTE: このメソッドは将来的に削除予定（全員ログインOKになる予定）
  def self.allowed?(email)
    # ログイン制限が無効なら常にtrue
    return true unless Authentication.restrict_login?

    # メールアドレスを小文字化して検索
    active.exists?([ "LOWER(email) = ?", email.to_s.downcase ])
  end

  private

  def normalize_email
    self.email = email.to_s.downcase.strip if email.present?
  end
end
