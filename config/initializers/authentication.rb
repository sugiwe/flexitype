# frozen_string_literal: true

# 認証関連の設定モジュール
#
# ログイン制限機能を制御するためのフィーチャーフラグを提供します。
# このモジュールは将来的に削除予定です（ベータ版終了後、全員ログインOKになる予定）。
module Authentication
  # ログイン制限を有効にするかどうか
  #
  # @return [Boolean] ログイン制限が有効な場合true
  #
  # @example ベータ版期間中（デフォルト）
  #   Authentication.restrict_login? #=> true
  #
  # @example 全員ログインOKの場合（.kamal/secretsで RESTRICT_LOGIN=false に設定）
  #   Authentication.restrict_login? #=> false
  #
  # NOTE: ベータ版終了後に RESTRICT_LOGIN=false に切り替える予定
  def self.restrict_login?
    ENV.fetch("RESTRICT_LOGIN", "true") == "true"
  end
end
