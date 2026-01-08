# frozen_string_literal: true

# 多言語対応を提供するConcern
# name_translations、description_translations カラムを持つモデルに include する
module Translatable
  extend ActiveSupport::Concern

  # 現在のロケールに応じた名前を返す
  # フォールバック: 現在の言語 → 日本語 → 既存のnameカラム
  def translated_name
    name_translations[I18n.locale.to_s].presence ||
      name_translations["ja"].presence ||
      name
  end

  # 現在のロケールに応じた説明を返す
  # フォールバック: 現在の言語 → 日本語 → 既存のdescriptionカラム
  def translated_description
    description_translations[I18n.locale.to_s].presence ||
      description_translations["ja"].presence ||
      description
  end
end
