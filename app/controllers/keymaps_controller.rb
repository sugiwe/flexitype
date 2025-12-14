class KeymapsController < ApplicationController
  before_action :require_login

  def index
    # 全レイヤーのキーマップを取得
    @keymaps = current_user.keymaps.group_by(&:layer)
  end

  def edit
    # 編集画面を表示（デフォルトキーマップをベースにユーザーのキーマップをマージ）
    @keymaps = {}
    (0..5).each do |layer|
      # デフォルトキーマップを取得
      default_keymap = Keymap.default_keymap[layer] || {}
      # ユーザーのキーマップを取得
      user_keymap = Keymap.for_user_layer(current_user.id, layer)
      # デフォルトにユーザーのキーマップをマージ（ユーザーの設定が優先）
      @keymaps[layer] = default_keymap.merge(user_keymap)
    end
  end

  def update
    # キーマップを一括保存
    keymaps_params = keymap_params

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

  def default
    # デフォルトキーマップを返す（JSON形式）
    render json: Keymap.default_keymap
  end

  private

  def require_login
    unless logged_in?
      redirect_to root_path, alert: "ログインが必要です"
    end
  end

  def keymap_params
    # keymapsパラメータを許可（ネストしたハッシュ形式）
    # 形式: { "0" => { "L0-R0" => "Q|q", ... }, "1" => { ... }, ... }
    # レイヤー番号とキー位置は動的なため、permit!を使用
    # セキュリティ: Keymap.bulk_upsertでバリデーションを実施
    params.require(:keymaps).permit! # brakeman:skip
  end
end
