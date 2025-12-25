# システムテスト用ヘルパーメソッド
#
# システムテスト（E2E）で共通的に使用するヘルパーメソッドを定義

module SystemHelpers
  # ユーザーとしてログインする
  #
  # @param user [User, nil] ログインするユーザー（nilの場合は新規作成）
  # @return [User] ログインしたユーザー
  #
  # @example
  #   user = login_as_user
  #   visit my_history_path
  #
  # @example 既存のユーザーでログイン
  #   admin_user = create(:user, :admin)
  #   login_as_user(admin_user)
  #
  def login_as_user(user = nil)
    user ||= create(:user)

    # Test用エンドポイントを使ってセッションを設定
    page.driver.post "/test/sessions", user_id: user.id

    user
  end

  # ログアウトする
  #
  # @example
  #   logout
  #
  def logout
    # Test用エンドポイントを使ってセッションをクリア
    page.driver.delete "/test/sessions"
  end
end

RSpec.configure do |config|
  config.include SystemHelpers, type: :system
end
