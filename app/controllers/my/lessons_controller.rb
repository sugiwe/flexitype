class My::LessonsController < My::ApplicationController
  before_action :set_lesson, only: [ :edit, :update, :destroy ]

  def index
    # visible_toスコープを使用（公式 + 自分 + 公開）
    @lessons = Lesson.visible_to(current_user)
      .includes(:category, :user)
      .order(created_at: :desc)
  end

  def new
    @lesson = current_user.lessons.build
    @categories = Category.ordered
  end

  def create
    @lesson = current_user.lessons.build(lesson_params)

    # 一般ユーザーは常に無料・非公開（デフォルト値を設定）
    unless current_user.admin?
      @lesson.premium = false
      @lesson.requires_login = false
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
    # 一般ユーザーのpremium/requires_loginフラグ変更を防止
    if current_user.admin?
      update_params = lesson_params
    else
      update_params = lesson_params.except(:premium, :requires_login)
    end

    if @lesson.update(update_params)
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
    permitted_params = if current_user.admin?
      params.require(:lesson).permit(
        :name, :description, :category_id, :count, :is_public,
        :premium, :requires_login, :items
      )
    else
      params.require(:lesson).permit(
        :name, :description, :category_id, :count, :is_public, :items
      )
    end

    # itemsをテキストエリアの改行区切りから配列に変換
    if permitted_params[:items].is_a?(String)
      permitted_params[:items] = permitted_params[:items].split("\n").map(&:strip).reject(&:blank?)
    end

    permitted_params
  end
end
