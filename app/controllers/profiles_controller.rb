class ProfilesController < ApplicationController
  include UserStatistics

  def show
    # /@username 形式のユーザープロフィール表示
    username = params[:username]

    # usernameで検索（大文字小文字を区別しない）
    @user = User.find_by("LOWER(username) = ?", username.downcase)

    unless @user
      redirect_to root_path, alert: "ユーザーが見つかりませんでした"
      return
    end

    # 統計情報を読み込む（Concern使用）
    load_user_statistics(@user)
  end
end
