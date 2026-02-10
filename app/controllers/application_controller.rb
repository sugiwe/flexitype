class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  around_action :switch_locale
  around_action :set_time_zone, if: :current_user

  helper_method :current_user, :logged_in?

  private

  def switch_locale(&)
    locale = params[:locale] ||
             cookies[:locale] ||
             I18n.default_locale
    cookies[:locale] = locale
    I18n.with_locale(locale, &)
  end

  def set_time_zone(&)
    Time.use_zone(current_user.time_zone, &)
  end

  def default_url_options
    { locale: I18n.locale }
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    return false unless current_user.present?

    # 🔑 ログイン制限チェック（将来的に削除予定）
    # RESTRICT_LOGIN=falseの場合、この制限はスキップされる
    if Authentication.restrict_login?
      unless AllowedEmail.allowed?(current_user.email)
        Rails.logger.info "Login restricted: #{current_user.email} is not in allowed list"
        return false
      end
    end

    true
  end
end
