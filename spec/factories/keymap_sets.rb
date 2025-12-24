FactoryBot.define do
  factory :keymap_set do
    association :user
    name { "テストキーマップ#{Faker::Number.unique.number(digits: 2)}" }
    sequence(:slug) { |n| "test-keymap-#{n}" }
    description { Faker::Lorem.sentence }
    is_public { false }

    # 公開キーマップ
    trait :public do
      is_public { true }
    end

    # デフォルト風のキーマップ
    trait :default_like do
      name { "Cornix デフォルト" }
      description { "デフォルトキーマップ（Mac配列ベース）" }
    end
  end
end
