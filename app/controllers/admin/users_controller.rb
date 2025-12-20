class Admin::UsersController < Admin::ApplicationController
  def index
    @users = User.order(last_sign_in_at: :desc).page(params[:page]).per(20)
  end

  def show
    @user = User.find(params[:id])
    @lesson_records = @user.lesson_records.recent.page(params[:page]).per(20)

    # 統計情報
    @total_records = @user.lesson_records.count
    @average_accuracy = @user.lesson_records.average(:accuracy)&.round(1) || 0
    @total_keymaps = @user.keymap_sets.count
  end
end
