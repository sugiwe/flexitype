class PracticeController < ApplicationController
  def index
    # YAMLファイルから単語データを読み込む
    words_data = YAML.load_file(Rails.root.join("config", "typing_words.yml"))
    @words = words_data["beginner"]

    # キーマップを読み込む（ユーザーのキーマップまたはデフォルト）
    user_id = logged_in? ? current_user.id : nil
    @keymaps = Keymap.all_layers_for_user_or_default(user_id)
  end
end
