class PracticeController < ApplicationController
  def index
    # YAMLファイルから単語データを読み込む
    words_data = YAML.load_file(Rails.root.join("config", "typing_words.yml"))
    @words = words_data["beginner"]
  end
end
