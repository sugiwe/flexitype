class Admin::DashboardController < Admin::ApplicationController
  def index
    # 統計データの取得
    @total_users = User.count
    @total_lesson_records = LessonRecord.count
    @total_keymap_sets = KeymapSet.count
    @total_lessons = LessonLoader.all_lessons_flat.count

    # サブテキスト用の追加統計
    @new_users_this_week = User.where("created_at >= ?", 1.week.ago).count
    @records_today = LessonRecord.where("completed_at >= ?", Time.current.beginning_of_day).count
    @public_keymaps = KeymapSet.where(is_public: true).count
    @lesson_categories_count = LessonLoader.all_lessons_flat.group_by { |lesson| lesson["category"] }.count

    # アクティブユーザー統計
    @active_users_7days = User.where("last_sign_in_at >= ?", 7.days.ago).count
    @active_users_30days = User.where("last_sign_in_at >= ?", 30.days.ago).count
    @records_this_week = LessonRecord.where("completed_at >= ?", 1.week.ago).count

    # 最新10名のユーザー（最終ログイン日時の降順）
    @recent_users = User.order(last_sign_in_at: :desc).limit(10)

    # 最新10件の練習履歴（完了日時の降順）
    @recent_records = LessonRecord.includes(:user).order(completed_at: :desc).limit(10)

    # レッスンカテゴリー統計
    @lesson_categories = LessonLoader.all_lessons_flat.group_by { |lesson| lesson["category"] }

    # 人気レッスンランキング（TOP 10）
    @popular_lessons = LessonRecord
      .where.not(lesson_id: nil)
      .group(:lesson_id, :lesson_name)
      .select("lesson_id, lesson_name, COUNT(*) as lesson_count, AVG(accuracy) as avg_accuracy")
      .order("lesson_count DESC")
      .limit(10)
  end
end
