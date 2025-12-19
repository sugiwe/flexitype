class Admin::DashboardController < Admin::ApplicationController
  def index
    # 統計データの取得
    @total_users = User.count
    @total_typing_sessions = TypingSession.count
    @total_keymap_sets = KeymapSet.count
    @total_lessons = LessonLoader.all_lessons_flat.count

    # 最新10名のユーザー（最終ログイン日時の降順）
    @recent_users = User.order(last_sign_in_at: :desc).limit(10)

    # 最新10件の練習履歴（完了日時の降順）
    @recent_sessions = TypingSession.includes(:user).order(completed_at: :desc).limit(10)

    # レッスンカテゴリー統計
    @lesson_categories = LessonLoader.all_lessons_flat.group_by { |lesson| lesson["category"] }
  end
end
