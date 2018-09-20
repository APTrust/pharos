FactoryBot.define do
  factory :confirmation_token do
    token { SecureRandom.hex }
  end

  factory :object_confirmation_token do
    token { SecureRandom.hex }
    intellectual_object { FactoryBot.create(:intellectual_object) }
  end

  factory :file_confirmation_token do
    token { SecureRandom.hex }
    generic_file { FactoryBot.create(:generic_file) }
  end

  factory :bulk_confirmation_token do
    token { SecureRandom.hex }
    institution { FactoryBot.create(:institution) }
  end
end