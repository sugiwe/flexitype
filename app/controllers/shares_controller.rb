class SharesController < ApplicationController
  include TwitterShareable

  layout "share", only: [ :show ]

  def create
    # ログインチェック
    unless logged_in?
      respond_to do |format|
        format.html do
          flash[:alert] = t("flash.require_login")
          redirect_to root_path
        end
        format.json { render json: { success: false, error: t("flash.require_login") }, status: :unauthorized }
      end
      return
    end

    # LessonRecordを取得
    lesson_record = current_user.lesson_records.find(params[:lesson_record_id])

    # 既存のShareを探す、なければ作成（重複防止）
    share = lesson_record.shares.first_or_create!

    respond_to do |format|
      format.html do
        # フォームからのPOST: Twitter シェア画面に直接リダイレクト
        redirect_to twitter_share_url(share), allow_other_host: true
      end
      format.json do
        # JavaScriptからのPOST: JSON を返す（既存の動作を維持）
        render json: {
          success: true,
          share_url: share_url(share.token),
          twitter_url: twitter_share_url(share)
        }
      end
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html do
        flash[:alert] = t("share.errors.lesson_record_not_found")
        redirect_to my_history_index_path
      end
      format.json { render json: { success: false, error: t("share.errors.lesson_record_not_found") }, status: :not_found }
    end
  end

  def show
    @share = Share.find_by!(token: params[:token])

    # period_summaryの場合、統計データを取得
    if @share.period_summary?
      @period_data = @share.period_summary_data
      unless @period_data
        flash[:alert] = t("share.errors.period_data_not_found")
        redirect_to root_path and return
      end
    end

    # PNG形式のリクエストは廃止（静的画像を使用）
    respond_to do |format|
      format.html # ランディングページを表示（OGPメタタグはビューで設定）
      format.png { head :not_found }  # PNGリクエストは404を返す
    end
  end

  # TODO: 将来実装 - 動的OGP画像生成
  # def generate_share_image(share)
  #   # MiniMagickでテンプレート画像にテキストを合成
  # end
end
