FactoryBot.define do
  factory :keymap do
    association :keymap_set
    user { keymap_set.user }
    layer { 0 }
    key_position { "L0-R0" }
    character { "a" }

    # よく使うキーのトレイト
    trait :key_h do
      key_position { "L2-R0" }
      character { "h" }
    end

    trait :key_e do
      key_position { "L0-R2" }
      character { "e" }
    end

    trait :key_l do
      key_position { "L2-R3" }
      character { "l" }
    end

    trait :key_o do
      key_position { "R2-R2" }
      character { "o" }
    end

    trait :key_w do
      key_position { "L1-R1" }
      character { "w" }
    end

    trait :key_r do
      key_position { "L1-R4" }
      character { "r" }
    end

    trait :key_d do
      key_position { "L2-R2" }
      character { "d" }
    end
  end
end
