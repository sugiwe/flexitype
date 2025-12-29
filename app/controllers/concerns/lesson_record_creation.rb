module LessonRecordCreation
  extend ActiveSupport::Concern

  private

  # 指定されたユーザーに対してレッスン記録を作成
  # @param user [User] 記録を紐付けるユーザー
  def create_lesson_record_for(user)
    @lesson_record = user.lesson_records.build(lesson_record_params)
    @lesson_record.completed_at = Time.current

    if @lesson_record.save
      render json: { success: true, message: "練習履歴を保存しました", lesson_record_id: @lesson_record.id }
    else
      render json: { success: false, errors: @lesson_record.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # レッスン記録のパラメータを許可
  def lesson_record_params
    params.require(:lesson_record).permit(
      :lesson_id,
      :lesson_name,
      :word_count,
      :correct_count,
      :mistake_count,
      :accuracy,
      :duration_seconds,
      :typed_chars
    )
  end
end
