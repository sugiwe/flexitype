# frozen_string_literal: true

Sentry.init do |config|
  # DSN（Data Source Name）を環境変数から取得
  # 本番環境のみ有効化（環境変数が設定されている場合のみ）
  config.dsn = ENV["SENTRY_DSN"]

  # パンくずリストロガーの設定
  # Active SupportのログとHTTPリクエストのログを記録
  config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]

  # 環境設定（Rails環境に合わせる）
  config.environment = Rails.env

  # 本番環境でのみSentryを有効化
  # 開発環境やテスト環境ではSentryを無効化
  config.enabled_environments = %w[production]

  # トレースサンプリングレート（100% = 全エラーを送信）
  # NOTE: 大量のエラーが発生する場合は 0.5（50%）などに調整
  config.traces_sample_rate = 1.0

  # 除外するエラークラス（通知不要なエラー）
  config.excluded_exceptions += [
    "ActionController::RoutingError",  # 404エラー
    "ActiveRecord::RecordNotFound"     # レコードが見つからない
  ]

  # パフォーマンス監視のサンプリングレート
  # NOTE: パフォーマンス監視が不要な場合は 0.0 に設定
  config.traces_sample_rate = 0.1  # 10%のリクエストのみ追跡

  # リリースバージョン（Gitコミットハッシュを使用）
  # デプロイ時にどのバージョンでエラーが発生したかを追跡
  config.release = ENV.fetch("GIT_COMMIT_SHA", "unknown")

  # ユーザーコンテキストの送信（デバッグに有効）
  # NOTE: 個人情報を含む可能性があるため、必要に応じて無効化
  config.send_default_pii = false
end
