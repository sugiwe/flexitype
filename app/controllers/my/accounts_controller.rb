class My::AccountsController < My::ApplicationController
  def edit
    @user = current_user
  end

  def update
    @user = current_user
    username_will_change = account_params[:username].present? && @user.username != account_params[:username]

    if @user.update(account_params)
      # usernameが実際に変更された場合、username_changed_atを更新
      @user.update_column(:username_changed_at, Time.current) if username_will_change
      redirect_to edit_my_account_path, notice: "アカウント設定を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def account_params
    params.require(:user).permit(:name, :username)
  end
end
