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

    # JavaScript使用時（Selenium）は、GETでセッションを設定
    # rack_test使用時は、POSTでセッションを設定
    if page.driver.is_a?(Capybara::RackTest::Driver)
      page.driver.post "/test/sessions", user_id: user.id
    else
      # Seleniumドライバーの場合は、GET経由でセッションを設定
      visit "/test/sessions?user_id=#{user.id}"
    end

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
