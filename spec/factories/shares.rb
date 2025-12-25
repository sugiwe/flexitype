FactoryBot.define do
  factory :share do
    association :lesson_record

    # tokenはbefore_validationで自動生成されるため指定不要
    # token { SecureRandom.urlsafe_base64(16) }
  end
end
