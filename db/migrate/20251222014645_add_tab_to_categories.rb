class AddTabToCategories < ActiveRecord::Migration[8.1]
  def up
    add_column :categories, :tab, :string, null: false, default: "basics"
    add_index :categories, :tab

    # 既存カテゴリーにtab値を設定
    reversible do |dir|
      dir.up do
        # タブ1: 基礎トレーニング
        Category.where(name: [ "基礎練習", "指別練習" ]).update_all(tab: "basics")

        # タブ2: 英語練習
        Category.where(name: [ "単語練習", "テーマ別" ]).update_all(tab: "english")

        # タブ4: プログラミング
        Category.where(name: [ "プログラミング" ]).update_all(tab: "programming")

        # 短文練習は、レッスン内容で判別
        short_sentence_category = Category.find_by(name: "短文練習")
        if short_sentence_category
          # プログラミングフレーズを含む場合はプログラミングタブ
          if short_sentence_category.lessons.exists?(name: "プログラミングフレーズ")
            short_sentence_category.update_column(:tab, "programming")
          else
            short_sentence_category.update_column(:tab, "english")
          end
        end
      end
    end
  end

  def down
    remove_index :categories, :tab
    remove_column :categories, :tab
  end
end
