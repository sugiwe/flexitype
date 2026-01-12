class My::KeymapsController < My::ApplicationController
  before_action :set_keymap_set, only: [ :edit, :update, :destroy ]

  def index
    # ユーザーのキーマップセット一覧を取得
    @keymap_sets = current_user.keymap_sets.order(created_at: :desc)
  end

  def new
    # 新規キーマップセット作成フォーム
    @keymap_set = current_user.keymap_sets.build
    # 提案slugを生成（keymap-1, keymap-2...）
    @keymap_set.slug = KeymapSet.generate_next_slug(current_user)
  end

  def create
    # 新規キーマップセットを作成
    @keymap_set = current_user.keymap_sets.build(keymap_set_params)

    if @keymap_set.save
      redirect_to edit_my_keymap_path(@keymap_set), notice: "キーマップ「#{@keymap_set.name}」を作成しました。キー配置を設定してください。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # 編集画面を表示（デフォルトキーマップをベースにユーザーのキーマップをマージ）
    @keymaps = {}
    (0..5).each do |layer|
      # デフォルトキーマップを取得
      default_keymap = Keymap.default_keymap[layer] || {}
      # このキーマップセットのキーマップを取得
      user_keymap = Keymap.where(keymap_set: @keymap_set, layer: layer)
                          .pluck(:key_position, :character)
                          .to_h
      # デフォルトにユーザーのキーマップをマージ（ユーザーの設定が優先）
      @keymaps[layer] = default_keymap.merge(user_keymap)
    end
  end

  def update
    return reset_keymap if params[:reset_to_default]
    return set_active_keymap if params[:active]
    return update_basic_info if basic_info_only?

    update_keymaps
  end

  def destroy
    # 特定のキーマップセットを削除
    # KeymapSetを削除すると、dependent: :destroyでKeymapも自動削除される

    # 削除可能かチェック（最も古いキーマップセットは削除不可）
    unless @keymap_set.deletable?
      redirect_to my_keymaps_path, alert: "最初のキーマップは削除できません"
      return
    end

    @keymap_set.destroy!
    redirect_to my_keymaps_path, notice: "キーマップ「#{@keymap_set.name}」を削除しました"
  end

  private

  def set_keymap_set
    @keymap_set = current_user.keymap_sets.find_by!(slug: params[:slug])
  end

  def keymap_set_params
    params.require(:keymap_set).permit(:name, :description, :slug, :keyboard_type)
  end

  def keymap_params
    # keymapsパラメータを許可（ネストしたハッシュ形式）
    # 形式: { "0" => { "0-0" => "Q|q", ... }, "1" => { ... }, ... }
    # レイヤー0-5のみ許可し、各レイヤー内の動的なキー位置を許可
    params.require(:keymaps).permit(
      "0": {},
      "1": {},
      "2": {},
      "3": {},
      "4": {},
      "5": {}
    )
  end

  # 基本情報のみの更新かどうか
  def basic_info_only?
    params[:keymap_set].present? && params[:keymaps].blank?
  end

  # キーマップをアクティブに設定
  def set_active_keymap
    current_user.update!(active_keymap_set: @keymap_set)
    redirect_to my_keymaps_path, notice: "キーマップ「#{@keymap_set.name}」を使用中に設定しました"
  rescue StandardError => e
    Rails.logger.error "Set active keymap error: #{e.message}"
    redirect_to my_keymaps_path, alert: "キーマップの設定に失敗しました"
  end

  # キーマップをデフォルト設定にリセット
  def reset_keymap
    @keymap_set.keymaps.destroy_all
    render json: { success: true, message: "キーマップをデフォルト設定に戻しました" }
  rescue StandardError => e
    Rails.logger.error "Keymap reset error: #{e.message}"
    render json: { success: false, error: "リセット中にエラーが発生しました" }, status: :unprocessable_entity
  end

  # 基本情報（name, description, slug）を更新
  def update_basic_info
    if @keymap_set.update(keymap_set_params)
      redirect_to edit_my_keymap_path(@keymap_set), notice: "基本情報を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # キーマップデータを一括保存
  def update_keymaps
    keymaps_params = keymap_params

    ActiveRecord::Base.transaction do
      # 基本情報も一緒に保存（name, descriptionが含まれていれば）
      @keymap_set.update!(keymap_set_params) if params[:keymap_set].present?

      keymaps_params.each do |layer, keymap_hash|
        keymap_hash.each do |position, char|
          # 空文字も含めて常に保存（デフォルトキーマップを上書きするため）
          keymap = current_user.keymaps.find_or_initialize_by(
            keymap_set: @keymap_set,
            layer: layer.to_i,
            key_position: position
          )
          keymap.character = char
          keymap.save!
        end
      end
    end

    render json: { success: true, message: "キーマップ「#{@keymap_set.name}」を保存しました" }
  rescue StandardError => e
    Rails.logger.error "Keymap save error: #{e.message}"
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end
end
