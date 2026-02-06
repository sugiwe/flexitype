class ChangeSharesLessonRecordIdToOptional < ActiveRecord::Migration[8.1]
  def change
    change_column_null :shares, :lesson_record_id, true
  end
end
