class Admin::UsersController < Admin::ApplicationController
  def index
    @users = User.order(last_sign_in_at: :desc).page(params[:page]).per(20)
  end

  def show
    @user = User.find(params[:id])
    @typing_sessions = @user.typing_sessions.recent.page(params[:page]).per(20)

    # 統計情報
    @total_sessions = @user.typing_sessions.count
    @average_accuracy = @user.typing_sessions.average(:accuracy)&.round(1) || 0
    @total_keymaps = @user.keymap_sets.count
  end
end
