class SharesController < ApplicationController
  skip_before_action :require_login  # 認証不要

  def show
    @share = Share.find_by!(token: params[:token])

    respond_to do |format|
      format.html do
        # ランディングページ
        # OGP用のメタタグ設定
        set_meta_tags(
          title: "#{@share.grade_name}を獲得しました！ - Typnix",
          description: "正答率#{@share.accuracy}%、WPM #{@share.wpm}",
          og: {
            title: "#{@share.grade_name}を獲得しました！",
            description: "正答率#{@share.accuracy}%、WPM #{@share.wpm}",
            image: share_url(@share.token, format: :png),
            type: "website"
          },
          twitter: {
            card: "summary_large_image",
            image: share_url(@share.token, format: :png)
          }
        )
      end

      format.png do
        # OGP画像を動的生成
        image_blob = generate_share_image(@share)
        send_data image_blob,
                  type: "image/png",
                  disposition: "inline"
      end
    end
  end

  private

  def generate_share_image(share)
    # TODO: ImageMagick/MiniMagickで画像生成
    # 一旦ダミー実装（次のステップで実装）
    ""
  end
end
