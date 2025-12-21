class AddPublishedToCategories < ActiveRecord::Migration[8.1]
  def change
    add_column :categories, :published, :boolean, default: true, null: false

    # 既存のカテゴリーを全て公開済みに設定
    reversible do |dir|
      dir.up do
        Category.update_all(published: true)
      end
    end
  end
end
