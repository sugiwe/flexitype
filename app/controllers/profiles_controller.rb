class ProfilesController < ApplicationController
  def show
    # /@username 形式のユーザープロフィール表示
    username = params[:username]

    # usernameで検索（大文字小文字を区別しない）
    @user = User.find_by("LOWER(username) = ?", username.downcase)

    unless @user
      redirect_to root_path, alert: "ユーザーが見つかりませんでした"
      return
    end

    # 公開する統計情報
    @total_records = @user.lesson_records.count
    @average_accuracy = @user.lesson_records.average(:accuracy)&.round(1) || 0
  end
end
