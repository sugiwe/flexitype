# frozen_string_literal: true

module Admin
  # 許可メールアドレス管理コントローラー
  #
  # 管理者が許可メールアドレスの追加・削除を行うためのCRUDインターフェース。
  # このコントローラーは将来的に削除予定（全員ログインOKになる予定）。
  class AllowedEmailsController < Admin::ApplicationController
    before_action :set_allowed_email, only: [ :destroy, :toggle_notified ]

    # GET /admin/allowed_emails
    def index
      @allowed_emails = AllowedEmail.order(created_at: :desc).page(params[:page]).per(20)
    end

    # GET /admin/allowed_emails/new
    def new
      @allowed_email = AllowedEmail.new
    end

    # POST /admin/allowed_emails
    def create
      @allowed_email = AllowedEmail.new(allowed_email_params)

      if @allowed_email.save
        redirect_to admin_allowed_emails_path, notice: "#{@allowed_email.email} を許可リストに追加しました"
      else
        render :new, status: :unprocessable_entity
      end
    end

    # DELETE /admin/allowed_emails/:id
    def destroy
      email = @allowed_email.email
      @allowed_email.destroy!
      redirect_to admin_allowed_emails_path, notice: "#{email} を許可リストから削除しました"
    end

    # PATCH /admin/allowed_emails/:id/toggle_notified
    def toggle_notified
      if @allowed_email.notified_at.present?
        @allowed_email.update!(notified_at: nil)
      else
        @allowed_email.update!(notified_at: Time.current)
      end

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to admin_allowed_emails_path }
      end
    end

    private

    def set_allowed_email
      @allowed_email = AllowedEmail.find(params[:id])
    end

    def allowed_email_params
      params.require(:allowed_email).permit(:email, :note)
    end
  end
end
