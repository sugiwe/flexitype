class MigrateAllowedEmailsFromEnv < ActiveRecord::Migration[8.1]
  def up
    # 環境変数からメールアドレスを読み込み
    # 開発環境では .env から、本番環境では .kamal/secrets から読み込まれる
    allowed_emails = ENV["ALLOWED_EMAILS"]&.split(",")&.map(&:strip) || []

    if allowed_emails.empty?
      puts "⚠️  ALLOWED_EMAILS環境変数が設定されていません。スキップします。"
      return
    end

    allowed_emails.each do |email|
      # 既に登録されている場合はスキップ
      next if AllowedEmail.exists?([ "LOWER(email) = ?", email.downcase ])

      AllowedEmail.create!(
        email: email,
        note: "環境変数から自動移行（#{Time.current.strftime('%Y-%m-%d')}）"
      )
      puts "✅ 追加: #{email}"
    end

    puts "✅ #{allowed_emails.size}件のメールアドレスをDBに移行しました"
  end

  def down
    # 環境変数から移行したデータを削除
    AllowedEmail.where("note LIKE ?", "環境変数から自動移行%").destroy_all
    puts "✅ 環境変数から移行したメールアドレスを削除しました"
  end
end
