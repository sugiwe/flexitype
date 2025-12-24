class HomeController < ApplicationController
  def index
    @tabs = Category.available_tabs
    @current_tab = params[:tab] || "basics"
  end

  private

  def categories_for_tab(tab_key)
    # ログイン状態に応じて利用可能なカテゴリーを取得
    # N+1クエリ防止のためlessons.userも含める
    categories_query = Category.published.ordered.includes(lessons: :user).free.by_tab(tab_key)

    # ログインしていない場合はゲスト向けのみ
    categories_query = categories_query.where(requires_login: false) unless logged_in?

    categories_query
  end

  helper_method :categories_for_tab
end
