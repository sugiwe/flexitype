# frozen_string_literal: true

# ユーザー名として使用できない予約語リスト
# /@username の形式でアクセスされるため、アプリケーションのルートと衝突する単語を予約
module ReservedUsernames
  LIST = %w[
    # CRUD・RESTful
    new edit create update destroy show index
    add remove list

    # HTTPメソッド
    get post put patch delete options head

    # 認証・アカウント
    login logout signup signin signout register registration
    users user accounts account
    password passwords confirmation confirmations unlock
    auth session sessions

    # Typnix固有のリソース
    lessons lesson
    keymaps keymap
    categories category
    history histories
    shares share
    my
    practices practice

    # 管理・設定
    admin admins administrator administrators
    settings setting profiles profile dashboard

    # 通知・メッセージ
    notifications notification messages message inbox

    # 課金・決済
    billing payment payments subscriptions subscribe subscription
    premium

    # コンテンツ・メディア
    assets images uploads files downloads download
    blog news feed feeds rss

    # API・Webhook
    api webhooks webhook

    # ヘルプ・情報ページ
    top welcome home
    support about help faq terms privacy contact

    # システム・インフラ
    system root localhost www cdn
    mail email smtp pop imap ftp sftp ssh
    static media public
    staging development production test
    error errors log logs

    # 検索・エクスポート
    search export exports import imports

    # その他の一般的な予約語
    app assets status health ping up
  ].freeze
end
