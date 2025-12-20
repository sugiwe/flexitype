class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.string :name, null: false, limit: 50
      t.text :description, limit: 200
      t.integer :display_order, default: 0, null: false
      t.boolean :requires_login, default: false, null: false
      t.boolean :premium, default: false, null: false

      t.timestamps
    end

    add_index :categories, :name, unique: true
  end
end
