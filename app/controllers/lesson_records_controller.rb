class LessonRecordsController < ApplicationController
  include LessonRecordCreation

  # 未ログインユーザーでもアクセス可能
  # ログイン済みの場合は current_user に紐付け、未ログインの場合はゲストユーザーに紐付け

  def create
    # ログイン済みの場合は current_user、未ログインの場合はゲストユーザー
    user = logged_in? ? current_user : User.find_by!(username: "guest")
    create_lesson_record_for(user)
  end
end
