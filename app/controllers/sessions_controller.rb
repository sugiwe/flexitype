class SessionsController < ApplicationController
  def create
    validator = GoogleIDToken::Validator.new
    client_id = Rails.application.credentials.dig(:google, :client_id)

    begin
      payload = validator.check(params[:credential], client_id)
      email = payload["email"]

      # 許可リストチェック
      unless User.email_allowed?(email)
        render json: { error: "このメールアドレスはログインを許可されていません" }, status: :forbidden
        return
      end

      user = User.from_google(payload)
      session[:user_id] = user.id

      render json: { success: true, redirect_url: root_path }
    rescue GoogleIDToken::ValidationError => e
      render json: { error: "認証に失敗しました: #{e.message}" }, status: :unauthorized
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path, notice: "ログアウトしました"
  end
end
