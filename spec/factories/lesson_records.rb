FactoryBot.define do
  factory :lesson_record do
    association :user
    association :lesson
    word_count { 100 }
    correct_count { 95 }
    mistake_count { 5 }
    accuracy { 95.0 }
    typed_chars { 500 }
    duration_seconds { 60 }
    completed_at { Time.current }

    # WPMとgradeはbefore_saveコールバックで自動計算されるため指定不要
    # wpm { 100 }
    # grade { "熟練のカワウソ" }

    # 伝説のカワウソ級（正答率98%以上、WPM 80以上）
    trait :legendary do
      accuracy { 99.0 }
      typed_chars { 800 }  # WPM = (800 / 60) * 60 / 5 = 160
      duration_seconds { 60 }
    end

    # 熟練のカワウソ級（正答率90%以上、WPM 50以上）
    trait :adult do
      accuracy { 95.0 }
      typed_chars { 500 }  # WPM = (500 / 60) * 60 / 5 = 100
      duration_seconds { 60 }
    end

    # 若手のカワウソ級（正答率80%以上、WPM 30以上）
    trait :young do
      accuracy { 85.0 }
      typed_chars { 300 }  # WPM = (300 / 60) * 60 / 5 = 60
      duration_seconds { 60 }
    end

    # 子どものカワウソ級（正答率70%以上、WPM 15以上）
    trait :child do
      accuracy { 75.0 }
      typed_chars { 150 }  # WPM = (150 / 60) * 60 / 5 = 30
      duration_seconds { 60 }
    end

    # 赤ちゃんカワウソ級（それ以下）
    trait :baby do
      accuracy { 60.0 }
      typed_chars { 50 }   # WPM = (50 / 60) * 60 / 5 = 10
      duration_seconds { 60 }
    end

    # 完璧な成績
    trait :perfect do
      accuracy { 100.0 }
      correct_count { 100 }
      mistake_count { 0 }
    end
  end
end
