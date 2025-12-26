class AddDisplayOrderToLessons < ActiveRecord::Migration[8.1]
  def change
    add_column :lessons, :display_order, :integer, default: 0, null: false
    add_index :lessons, [ :category_id, :display_order ]
  end
end
