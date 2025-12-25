# Google ID Token のモック設定
#
# システムテストでGoogle認証をシミュレートするための設定
# 実際のGoogle APIを呼ばずに、テスト用のペイロードを返す

RSpec.configure do |config|
  config.before(:each, type: :system) do
    # GoogleIDToken::Validatorをモック化
    allow_any_instance_of(GoogleIDToken::Validator).to receive(:check) do |_instance, _credential, _client_id|
      # テスト用のペイロード（Google APIのレスポンスをシミュレート）
      {
        "iss" => "https://accounts.google.com",
        "sub" => "123456789",
        "email" => "test@example.com",
        "email_verified" => true,
        "name" => "Test User",
        "picture" => "https://example.com/photo.jpg",
        "iat" => Time.now.to_i,
        "exp" => (Time.now + 1.hour).to_i
      }
    end
  end
end
