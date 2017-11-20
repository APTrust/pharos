FactoryBot.define do
  factory :confirmation_token do
    token { SecureRandom.hex }
    intellectual_object { FactoryBot.create(:intellectual_object) }
  end
end