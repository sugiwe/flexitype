class My::LessonsController < My::ApplicationController
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
    @lesson = current_user.lessons.build(lesson_params)

    # 一般ユーザーは常に非公開（デフォルト値を設定）
    unless current_user.admin?
      @lesson.is_public = false
    end

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
    if @lesson.update(lesson_params)
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
        .order(created_at: :desc)
    else
      # 一般ユーザー: 自分が作成したレッスンのみ
      current_user.lessons
        .joins(:category)
        .where(categories: { tab: tab_key.to_s })
        .includes(:category, :user)
        .order(created_at: :desc)
    end
  end

  helper_method :lessons_for_tab

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
      :name, :description, :category_id, :count, :is_public, :items
    )

    # itemsをテキストエリアの改行区切りから配列に変換
    if permitted_params[:items].is_a?(String)
      permitted_params[:items] = permitted_params[:items].split("\n").map(&:strip).reject(&:blank?)
    end

    permitted_params
  end
end
