# frozen_string_literal: true

# ユーザー統計情報の読み込みを共通化するConcern
# ProfilesControllerとAdmin::UsersControllerで使用
module UserStatistics
  extend ActiveSupport::Concern

  private

  # ユーザーの統計情報を読み込む
  # @param user [User] 統計情報を取得するユーザー
  def load_user_statistics(user)
    @total_records = user.lesson_records.count
    @average_accuracy = user.lesson_records.average(:accuracy)&.round(1) || 0
    @published_lessons = user.published_lessons
  end
end
