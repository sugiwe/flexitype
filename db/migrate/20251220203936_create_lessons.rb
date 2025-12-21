class CreateLessons < ActiveRecord::Migration[8.1]
  def change
    create_table :lessons do |t|
      t.references :user, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.string :name, null: false, limit: 100
      t.text :description, limit: 500
      t.jsonb :items, null: false, default: []
      t.integer :count, default: 20, null: false
      t.boolean :is_public, default: false, null: false
      t.boolean :requires_login, default: false, null: false
      t.boolean :premium, default: false, null: false

      t.timestamps
    end

    add_index :lessons, [ :user_id, :name ]
    add_index :lessons, :is_public
  end
end
