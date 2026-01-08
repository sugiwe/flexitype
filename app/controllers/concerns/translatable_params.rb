# frozen_string_literal: true

# フォームパラメータから多言語データを設定するConcern
# Category と Lesson の create/update アクションで使用
module TranslatableParams
  extend ActiveSupport::Concern

  private

  # モデルに多言語データを設定
  # @param model [ApplicationRecord] Category または Lesson
  # @param params_hash [ActionController::Parameters] フォームパラメータ
  def set_translations(model, params_hash)
    model.name_translations = {
      "ja" => params_hash[:name],
      "en" => params_hash[:name_en].presence
    }.compact

    model.description_translations = {
      "ja" => params_hash[:description],
      "en" => params_hash[:description_en].presence
    }.compact
  end
end
