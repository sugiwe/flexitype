class Admin::UsersController < Admin::ApplicationController
  include UserStatistics

  def index
    @users = User.with_records_count.order(id: :desc).page(params[:page]).per(20)
  end

  def show
    @user = User.find(params[:id])
    # N+1問題を防ぐため includes(:user) を追加
    @lesson_records = @user.lesson_records.includes(:user).recent.page(params[:page]).per(20)

    # 統計情報を読み込む（Concern使用）
    load_user_statistics(@user)
  end
end
