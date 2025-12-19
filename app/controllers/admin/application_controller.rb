class Admin::ApplicationController < ApplicationController
  before_action :require_admin!

  private

  def require_admin!
    admin_emails = ENV["ADMIN_EMAILS"]&.split(",")&.map(&:strip) || []
    unless logged_in? && admin_emails.include?(current_user.email)
      redirect_to root_path, alert: "管理者権限が必要です"
    end
  end
end
