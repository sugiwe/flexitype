class RenameCategoriesWithTabInfo < ActiveRecord::Migration[8.1]
  def up
    # 既存カテゴリー名にタブ情報を付与
    Category.find_by(name: "指別練習")&.update!(name: "指別練習（基礎）")
    Category.find_by(name: "基礎練習")&.update!(name: "基礎練習（基礎）")
    Category.find_by(name: "単語練習")&.update!(name: "単語練習（英語）")
    Category.find_by(name: "テーマ別")&.update!(name: "テーマ別（英語）")

    # 「プログラミング」→「単語練習（プログラミング）」に改名
    programming_category = Category.find_by(name: "プログラミング")
    programming_category&.update!(name: "単語練習（プログラミング）")

    # 「短文練習」→「フレーズ練習（プログラミング）」に改名
    short_sentence_category = Category.find_by(name: "短文練習")
    short_sentence_category&.update!(name: "フレーズ練習（プログラミング）")
  end

  def down
    # ロールバック時は元の名前に戻す
    Category.find_by(name: "指別練習（基礎）")&.update!(name: "指別練習")
    Category.find_by(name: "基礎練習（基礎）")&.update!(name: "基礎練習")
    Category.find_by(name: "単語練習（英語）")&.update!(name: "単語練習")
    Category.find_by(name: "テーマ別（英語）")&.update!(name: "テーマ別")
    Category.find_by(name: "単語練習（プログラミング）")&.update!(name: "プログラミング")
    Category.find_by(name: "フレーズ練習（プログラミング）")&.update!(name: "短文練習")
  end
end
