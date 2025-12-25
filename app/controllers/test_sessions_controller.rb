# テスト環境でのみ使用するセッションコントローラー
# システムテストでログイン状態を簡単に設定するために使用
class TestSessionsController < ApplicationController
  # テスト環境以外では404を返す
  before_action :ensure_test_environment

  def create
    user_id = params[:user_id]
    session[:user_id] = user_id
    head :ok
  end

  def destroy
    session[:user_id] = nil
    head :ok
  end

  private

  def ensure_test_environment
    raise ActionController::RoutingError, "Not Found" unless Rails.env.test?
  end
end
