module Admin
  class CategoriesController < Admin::ApplicationController
    before_action :set_category, only: [ :edit, :update, :destroy ]

    def index
      @categories = Category.ordered
    end

    def new
      @category = Category.new
    end

    def create
      @category = Category.new(category_params)

      if @category.save
        redirect_to admin_categories_path, notice: "カテゴリー「#{@category.name}」を作成しました"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @category.update(category_params)
        redirect_to admin_categories_path, notice: "カテゴリー「#{@category.name}」を更新しました"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @category.lessons.exists?
        redirect_to admin_categories_path, alert: "このカテゴリーにはレッスンが紐付いているため削除できません"
      else
        @category.destroy
        redirect_to admin_categories_path, notice: "カテゴリー「#{@category.name}」を削除しました"
      end
    end

    private

    def set_category
      @category = Category.find(params[:id])
    end

    def category_params
      params.require(:category).permit(:name, :description, :display_order, :published, :requires_login, :premium)
    end
  end
end
