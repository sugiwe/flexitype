class KeymapsController < ApplicationController
  before_action :require_login

  def index
    # 全レイヤーのキーマップを取得
    @keymaps = current_user.keymaps.group_by(&:layer)
  end

  def edit
    # 編集画面を表示（既存のキーマップがあれば読み込む）
    @keymaps = {}
    (0..5).each do |layer|
      @keymaps[layer] = Keymap.for_user_layer(current_user.id, layer)
    end
  end

  def update
    # キーマップを一括保存
    keymaps_params = params[:keymaps]

    ActiveRecord::Base.transaction do
      keymaps_params.each do |layer, keymap_hash|
        Keymap.bulk_upsert(current_user.id, layer.to_i, keymap_hash)
      end
    end

    render json: { success: true, message: "キーマップを保存しました" }
  rescue StandardError => e
    Rails.logger.error "Keymap save error: #{e.message}"
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end

  private

  def require_login
    unless logged_in?
      redirect_to root_path, alert: "ログインが必要です"
    end
  end
end
