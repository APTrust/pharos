FactoryGirl.define do
  factory :checksum do
    algorithm { 'sha256' }
    datetime { Time.now.to_s }
    digest { SecureRandom.hex }
  end
end
