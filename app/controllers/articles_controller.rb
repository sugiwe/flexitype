class ArticlesController < ApplicationController
  before_action :set_article, only: [ :show ]

  def index
    @category = params[:category]
    @articles = Article.published

    @articles = @articles.by_category(@category) if @category.present?
    @articles = @articles.recent.page(params[:page]).per(12)
  end

  def show
    @article.increment_view_count!
  end

  private

  def set_article
    @article = Article.published.find_by!(slug: params[:slug])
  end
end
