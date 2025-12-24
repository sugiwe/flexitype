# frozen_string_literal: true

# 開発環境専用の簡易ログインコントローラー
# Google認証をスキップしてログイン/ログアウトを行う
# 本番環境では動作しない（routes.rbで制限）
class Dev::SessionsController < ApplicationController
  # 開発環境のみ許可（ルーティングでも制限しているが念のため）
  before_action :development_only

  def index
    @users = User.all
  end

  def create
    user = User.find(params[:user_id])
    session[:user_id] = user.id
    redirect_to root_path, notice: "#{user.name}としてログインしました（開発環境）"
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path, notice: "ログアウトしました（開発環境）"
  end

  private

  def development_only
    unless Rails.env.development?
      render plain: "Not Found", status: :not_found
    end
  end
end
