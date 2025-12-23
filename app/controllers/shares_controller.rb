class SharesController < ApplicationController
  layout "share", only: [ :show ]

  def create
    # ログインチェック
    unless logged_in?
      render json: { success: false, error: "ログインが必要です" }, status: :unauthorized
      return
    end

    # LessonRecordを取得
    lesson_record = current_user.lesson_records.find(params[:lesson_record_id])

    # Shareを作成
    share = lesson_record.shares.create!

    # Share URLを返す
    render json: {
      success: true,
      share_url: share_url(share.token),
      twitter_url: twitter_share_url(share)
    }
  rescue ActiveRecord::RecordNotFound
    render json: { success: false, error: "レッスン記録が見つかりません" }, status: :not_found
  end

  def show
    @share = Share.find_by!(token: params[:token])

    # PNG形式のリクエストは廃止（静的画像を使用）
    respond_to do |format|
      format.html # ランディングページを表示（OGPメタタグはビューで設定）
      format.png { head :not_found }  # PNGリクエストは404を返す
    end
  end

  private

  # X（旧Twitter）へのシェアURL
  def twitter_share_url(share)
    text = "Typnixで「#{share.grade_name}」を獲得しました！正答率#{share.accuracy}%、WPM #{share.wpm} 🦦"
    url = share_url(share.token)
    "https://x.com/intent/post?text=#{CGI.escape(text)}&url=#{CGI.escape(url)}"
  end

  # TODO: 将来実装 - 動的OGP画像生成
  # def generate_share_image(share)
  #   # MiniMagickでテンプレート画像にテキストを合成
  # end
end
