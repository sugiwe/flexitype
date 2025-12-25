FactoryBot.define do
  factory :user do
    google_uid { Faker::Internet.uuid }
    email { Faker::Internet.email }
    name { Faker::Name.name }
    username { Faker::Internet.username(specifier: 3..15, separators: %w[. _ -]) }
    icon_url { Faker::Internet.url }

    # create時はafter_createコールバックが実行されて自動的にactive_keymap_setが作成される
    # （optional: trueなので、作成時は一時的にNULLでもOK、after_createで設定される）

    # 管理者用のファクトリ（variant）
    trait :admin do
      email { "admin@example.com" } # ADMIN_EMAILSに含まれる前提
    end

    # プレミアムユーザー用（現時点では管理者と同じ）
    trait :premium do
      email { "admin@example.com" }
    end

    # ユーザー名変更履歴あり
    trait :with_username_history do
      username_changed_at { 12.hours.ago }
    end

    # ユーザー名変更可能（24時間以上経過）
    trait :can_change_username do
      username_changed_at { 25.hours.ago }
    end
  end
end
