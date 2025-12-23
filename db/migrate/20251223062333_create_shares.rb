class CreateShares < ActiveRecord::Migration[8.1]
  def change
    create_table :shares do |t|
      t.references :lesson_record, null: false, foreign_key: true
      t.string :token, null: false

      t.timestamps
    end
    add_index :shares, :token, unique: true
  end
end
