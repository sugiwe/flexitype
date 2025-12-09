class HomeController < ApplicationController
  def index
    # ログイン状態に応じて利用可能なレッスンを取得
    @categories = LessonLoader.available_categories(logged_in: logged_in?)
  end
end
