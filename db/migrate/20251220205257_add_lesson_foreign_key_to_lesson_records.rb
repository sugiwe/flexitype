class AddLessonForeignKeyToLessonRecords < ActiveRecord::Migration[8.1]
  def change
    # データ移行後に有効化
    # add_foreign_key :lesson_records, :lessons, column: :lesson_id
  end
end
