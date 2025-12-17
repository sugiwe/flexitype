class ProfilesController < ApplicationController
  def show
    # /@username 形式のユーザープロフィール表示
    username = params[:username]

    # TODO: 将来的にusernameカラムを追加したら、username経由で検索
    # 現在は最小限の実装として、IDでの検索のみ対応
    # 例: /@1 でユーザーID=1のプロフィールを表示

    if username =~ /\A\d+\z/
      # 数値のみの場合はIDとして検索
      @user = User.find_by(id: username)
    else
      # 将来実装: usernameカラムで検索
      @user = nil
    end

    unless @user
      redirect_to root_path, alert: "ユーザーが見つかりませんでした"
      return
    end

    # 公開する統計情報
    @total_sessions = @user.typing_sessions.count
    @average_accuracy = @user.typing_sessions.average(:accuracy)&.round(1) || 0
  end
end
