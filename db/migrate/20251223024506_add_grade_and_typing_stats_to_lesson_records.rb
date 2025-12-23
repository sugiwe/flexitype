class AddGradeAndTypingStatsToLessonRecords < ActiveRecord::Migration[8.1]
  def change
    add_column :lesson_records, :typed_chars, :integer
    add_column :lesson_records, :wpm, :integer
    add_column :lesson_records, :grade, :string, limit: 20
  end
end
