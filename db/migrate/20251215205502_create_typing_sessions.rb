class CreateTypingSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :typing_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :category
      t.string :lesson_id
      t.string :lesson_name
      t.integer :word_count, null: false, default: 0
      t.integer :correct_count, null: false, default: 0
      t.integer :mistake_count, null: false, default: 0
      t.decimal :accuracy, precision: 5, scale: 2
      t.integer :duration_seconds
      t.datetime :completed_at

      t.timestamps
    end

    # 履歴一覧取得用のインデックス（ユーザーごと、完了日時降順）
    add_index :typing_sessions, [ :user_id, :completed_at ], order: { completed_at: :desc }
    # 古い履歴削除用のインデックス（ユーザーごと、作成日時降順）
    add_index :typing_sessions, [ :user_id, :created_at ], order: { created_at: :desc }
  end
end
