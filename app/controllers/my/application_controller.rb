class My::ApplicationController < ApplicationController
  before_action :require_login

  private

  def require_login
    unless logged_in?
      redirect_to root_path, alert: t("flash.require_login")
    end
  end
end
