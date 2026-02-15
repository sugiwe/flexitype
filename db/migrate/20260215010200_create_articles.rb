class CreateArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :articles do |t|
      t.string :title, null: false, limit: 100
      t.string :slug, null: false, limit: 100
      t.text :content, null: false
      t.text :excerpt
      t.integer :category, null: false, default: 0
      t.datetime :published_at
      t.references :author, foreign_key: { to_table: :users }, null: true
      t.integer :view_count, default: 0, null: false

      t.timestamps
    end
    add_index :articles, :slug, unique: true
    add_index :articles, :category
    add_index :articles, :published_at
  end
end
