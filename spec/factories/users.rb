FactoryBot.define do
  factory :user do
    google_uid { Faker::Internet.uuid }
    email { Faker::Internet.email }
    name { Faker::Name.name }
    username { Faker::Internet.username(specifier: 3..15, separators: %w[. _ -]) }
    icon_url { Faker::Internet.url }

    # build時はactive_keymap_setを仮設定（バリデーションテスト用）
    after(:build) do |user|
      user.active_keymap_set ||= build(:keymap_set, user: user)
    end

    # create時はafter_createコールバックが既に実行されているはず
    # しかし、念のため確認して、なければ作成
    after(:create) do |user|
      unless user.active_keymap_set
        keymap_set = create(:keymap_set, user: user)
        user.update!(active_keymap_set: keymap_set)
      end
    end

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
