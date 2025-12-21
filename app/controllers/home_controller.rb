class HomeController < ApplicationController
  def index
    # ログイン状態に応じて利用可能なカテゴリーを取得
    categories_query = Category.ordered.includes(:lessons).free

    # ログインしていない場合はゲスト向けのみ
    categories_query = categories_query.where(requires_login: false) unless logged_in?

    @categories = categories_query
  end
end
