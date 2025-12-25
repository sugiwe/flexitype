# Capybara設定
#
# システムテスト（E2E）でブラウザ操作をシミュレートするための設定

# デフォルトの待機時間を3秒に設定
# JavaScript操作が完了するまで自動的に待機
Capybara.default_max_wait_time = 3

# サーバーにPumaを使用（Railsのデフォルト）
# Silentオプションでログを抑制
Capybara.server = :puma, { Silent: true }

# デフォルトのドライバを設定
# :selenium_chrome_headless - ヘッドレスChromeを使用（CI/CD環境でも動作）
# Capybara.default_driver = :selenium_chrome_headless
# Capybara.javascript_driver = :selenium_chrome_headless

# ローカル開発時はヘッドレスではないブラウザを使用する場合
# Capybara.default_driver = :selenium_chrome
# Capybara.javascript_driver = :selenium_chrome

RSpec.configure do |config|
  # システムテストの前後でデータベースをクリーンアップ
  config.before(:each, type: :system) do
    driven_by(:rack_test) # JavaScriptが不要な場合はrack_testを使用（高速）
  end

  # JavaScriptが必要なテストではSeleniumを使用
  config.before(:each, type: :system, js: true) do
    driven_by(:selenium_chrome_headless)
  end
end
