module Admin
  class ArticlesController < Admin::ApplicationController
    before_action :set_article, only: [ :edit, :update, :destroy ]

    def index
      @filter = params[:filter] || "all"
      @articles = case @filter
      when "published"
        Article.published.recent
      when "draft"
        Article.where(published_at: nil).recent
      when "scheduled"
        Article.where("published_at > ?", Time.current).recent
      else
        Article.recent
      end

      @articles = @articles.page(params[:page]).per(20)
    end

    def new
      @article = Article.new(author: current_user)
    end

    def create
      @article = Article.new(article_params)
      @article.author = current_user

      if @article.save
        redirect_to admin_articles_path, notice: "記事「#{@article.title}」を作成しました"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @article.update(article_params)
        redirect_to admin_articles_path, notice: "記事「#{@article.title}」を更新しました"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      title = @article.title
      @article.destroy
      redirect_to admin_articles_path, notice: "記事「#{title}」を削除しました"
    end

    private

    def set_article
      @article = Article.find_by!(slug: params[:slug])
    end

    def article_params
      params.require(:article).permit(
        :title, :slug, :content, :excerpt, :category, :published_at
      )
    end
  end
end
