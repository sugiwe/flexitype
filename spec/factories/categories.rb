FactoryBot.define do
  factory :category do
    sequence(:name) { |n| "テストカテゴリー#{n}" }
    description { Faker::Lorem.sentence }
    tab { "basics" }
    display_order { 1 }
    published { true }
    requires_login { false }
    premium { false }

    # 公開済み（デフォルト）
    trait :published do
      published { true }
    end

    # 非公開
    trait :unpublished do
      published { false }
    end

    # ログイン必須
    trait :requires_login do
      requires_login { true }
    end

    # プレミアム限定
    trait :premium do
      premium { true }
    end

    # 各タブ用のトレイト
    trait :basics do
      tab { "basics" }
      name { "基礎トレーニング" }
    end

    trait :english do
      tab { "english" }
      name { "英語練習" }
    end

    trait :japanese do
      tab { "japanese" }
      name { "日本語練習" }
    end

    trait :programming do
      tab { "programming" }
      name { "プログラミング" }
    end
  end
end
