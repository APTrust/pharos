FactoryBot.define do

  sequence(:name) { |n| "#{Faker::Company.name} #{n}" }
  sequence(:brief_name) { |n|  "#{Faker::Lorem.characters rand(3..4)}#{n}"}
  sequence(:identifier) { |n| "#{n}#{Faker::Internet.domain_word}.com"}
  sequence(:dpn_uuid) { |n| "#{n}#{SecureRandom.uuid}"}

  factory :member_institution do
    name
    brief_name
    identifier
    dpn_uuid
    type { 'MemberInstitution' }
    deactivated_at { nil }
  end

  factory :subscription_institution do
    name
    brief_name
    identifier
    dpn_uuid
    type { 'SubscriptionInstitution' }
    member_institution_id { FactoryBot.create(:member_institution).id }
    deactivated_at { nil }
  end

  factory :aptrust, class: 'Institution' do
    name { 'APTrust' }
    brief_name { 'apt' }
    identifier { 'aptrust.org' }
    dpn_uuid { '' }
    type { 'MemberInstitution' }
    deactivated_at { nil }
  end
end