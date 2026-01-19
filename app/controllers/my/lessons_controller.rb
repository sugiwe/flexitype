class My::LessonsController < My::ApplicationController
  include TranslatableParams

  before_action :set_lesson, only: [ :edit, :update, :destroy ]

  def index
    if current_user.admin?
      # 管理者: 全タブ（マイレッスン、コミュニティを除く）
      @tabs = Category.available_tabs
      @current_tab = params[:tab] || "basics"
    else
      # 一般ユーザー: マイレッスンタブのみ
      @tabs = { my_lessons: Category::TABS[:my_lessons].merge(disabled: false) }
      @current_tab = "my_lessons"
    end
  end

  def new
    @lesson = current_user.lessons.build
    @categories = Category.ordered
  end

  def create
    @lesson = current_user.lessons.build(lesson_params.except(:name_en, :description_en))

    # 一般ユーザーは常に非公開（デフォルト値を設定）
    unless current_user.admin?
      @lesson.is_public = false
    end

    set_translations(@lesson, lesson_params)

    if @lesson.save
      redirect_to my_lessons_path, notice: "レッスンを作成しました。"
    else
      @categories = Category.ordered
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @categories = Category.ordered
  end

  def update
    @lesson.assign_attributes(lesson_params.except(:name_en, :description_en))
    set_translations(@lesson, lesson_params)

    if @lesson.save
      redirect_to my_lessons_path, notice: "レッスンを更新しました。"
    else
      @categories = Category.ordered
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @lesson.destroy
    redirect_to my_lessons_path, notice: "レッスンを削除しました。"
  end

  private

  def lessons_for_tab(tab_key)
    if current_user.admin?
      # 管理者: 公式レッスンのみ（自分が作成したレッスン = 公式レッスン）
      current_user.lessons
        .joins(:category)
        .where(categories: { tab: tab_key.to_s })
        .includes(:category, :user)
        .ordered
    else
      # 一般ユーザー: 自分が作成したレッスンのみ
      current_user.lessons
        .joins(:category)
        .where(categories: { tab: tab_key.to_s })
        .includes(:category, :user)
        .ordered
    end
  end

  # フォーム表示用にitemsをフォーマット
  def format_items_for_form(items)
    return "" if items.blank?

    items.map do |item|
      if item.is_a?(Hash)
        # ハッシュ形式の場合
        if item["display"].present?
          # displayがある場合はJSON形式で表示
          item.to_json
        else
          # displayがない場合はtextのみ表示
          item["text"]
        end
      else
        # 文字列の場合はそのまま表示
        item
      end
    end.join("\n")
  end

  helper_method :lessons_for_tab, :format_items_for_form

  def set_lesson
    # 管理者は全レッスンにアクセス可能、一般ユーザーは自分のレッスンのみ
    @lesson = if current_user.admin?
      Lesson.find(params[:id])
    else
      current_user.lessons.find(params[:id])
    end
  end

  def lesson_params
    # paramsを取得
    permitted_params = params.require(:lesson).permit(
      :name, :description, :category_id, :count, :is_public, :items, :display_order,
      :name_en, :description_en
    )

    # itemsをテキストエリアの改行区切りから配列に変換
    if permitted_params[:items].is_a?(String)
      permitted_params[:items] = permitted_params[:items].split("\n").map(&:strip).reject(&:blank?).map do |line|
        # JSON形式かどうかを判定（{で始まる場合）
        if line.start_with?("{")
          begin
            # JSON形式の場合はパース
            JSON.parse(line)
          rescue JSON::ParserError
            # パースエラーの場合は文字列として扱う
            { "text" => line, "display" => nil }
          end
        else
          # 通常の文字列の場合はハッシュに変換
          { "text" => line, "display" => nil }
        end
      end
    end

    permitted_params
  end
end
