FactoryBot.define do
  factory :article do
    sequence(:title) { |n| "記事タイトル #{n}" }
    sequence(:slug) { |n| "article-#{n}" }
    content { "# 記事本文\n\nこれはテスト記事です。" }
    excerpt { "記事の概要文です。" }
    category { :typing_tips }
    published_at { 1.day.ago }
    association :author, factory: :user
    view_count { 0 }

    trait :draft do
      published_at { nil }
    end

    trait :scheduled do
      published_at { 1.week.from_now }
    end

    trait :popular do
      view_count { 1000 }
    end

    trait :keyboard_basics do
      category { :keyboard_basics }
    end

    trait :keyboard_reviews do
      category { :keyboard_reviews }
    end
  end
end
