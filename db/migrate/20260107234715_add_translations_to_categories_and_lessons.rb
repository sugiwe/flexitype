class AddTranslationsToCategoriesAndLessons < ActiveRecord::Migration[8.1]
  def change
    # Categories に多言語対応カラムを追加
    add_column :categories, :name_translations, :jsonb, default: {}
    add_column :categories, :description_translations, :jsonb, default: {}

    # Lessons に多言語対応カラムを追加
    add_column :lessons, :name_translations, :jsonb, default: {}
    add_column :lessons, :description_translations, :jsonb, default: {}
  end
end
