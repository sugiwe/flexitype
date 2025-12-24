class Admin::UsersController < Admin::ApplicationController
  include UserStatistics

  def index
    @users = User.order(last_sign_in_at: :desc).page(params[:page]).per(20)
  end

  def show
    @user = User.find(params[:id])
    @lesson_records = @user.lesson_records.recent.page(params[:page]).per(20)

    # 統計情報を読み込む（Concern使用）
    load_user_statistics(@user)

    # Admin独自の統計情報
    @total_keymaps = @user.keymap_sets.count
  end
end
