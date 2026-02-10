FactoryBot.define do
  factory :share do
    share_type { "single" }
    lesson_record

    # tokenはbefore_validationで自動生成されるため指定不要
    # token { SecureRandom.urlsafe_base64(16) }
  end
end
