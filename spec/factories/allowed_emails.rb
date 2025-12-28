FactoryBot.define do
  factory :allowed_email do
    email { "MyString" }
    active { false }
    note { "MyText" }
  end
end
