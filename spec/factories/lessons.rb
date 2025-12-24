FactoryBot.define do
  factory :lesson do
    association :user
    association :category
    sequence(:name) { |n| "テストレッスン#{n}" }
    description { Faker::Lorem.paragraph }
    items do
      [
        { "type" => "typing", "text" => "hello world" },
        { "type" => "typing", "text" => "test example" }
      ]
    end
    count { 2 }
    is_public { false }

    # 公開レッスン
    trait :public do
      is_public { true }
    end

    # 公式レッスン（管理者作成）
    trait :official do
      association :user, :admin
    end

    # 長いレッスン（100アイテム）
    trait :long do
      count { 100 }
      items do
        Array.new(100) { |i| { "type" => "typing", "text" => "item #{i + 1}" } }
      end
    end
  end
end
