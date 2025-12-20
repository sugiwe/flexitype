class RenameTypingSessionsToLessonRecords < ActiveRecord::Migration[8.1]
  def change
    rename_table :typing_sessions, :lesson_records
  end
end
