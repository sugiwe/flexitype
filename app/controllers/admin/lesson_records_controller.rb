class Admin::LessonRecordsController < Admin::ApplicationController
  def index
    # 全ての練習履歴を新しい順に取得（ページネーション付き、50件/ページ）
    @lesson_records = LessonRecord.includes(:user).order(completed_at: :desc).page(params[:page]).per(50)
  end
end
