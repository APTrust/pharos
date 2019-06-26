FactoryBot.define do

  sequence(:name) { |n| "#{Faker::Company.name} #{n}" }
  sequence(:identifier) { |n| "#{n}#{Faker::Internet.domain_word}.com"}
  sequence(:dpn_uuid) { |n| "#{n}#{SecureRandom.uuid}"}

  factory :member_institution do
    name
    identifier
    dpn_uuid
    type { 'MemberInstitution' }
    deactivated_at { nil }
    # repo_receiving_bucket { "aptrust.receiving.#{identifier}" }
    # repo_restore_bucket { "aptrust.restore.#{identifier}" }
    # demo_receiving_bucket { "aptrust.receiving.test.#{identifier}" }
    # demo_restore_bucket { "aptrust.restore.test.#{identifier}" }
  end

  factory :subscription_institution do
    name
    identifier
    dpn_uuid
    type { 'SubscriptionInstitution' }
    member_institution_id { FactoryBot.create(:member_institution).id }
    deactivated_at { nil }
    # repo_receiving_bucket { "aptrust.receiving.#{identifier}" }
    # repo_restore_bucket { "aptrust.restore.#{identifier}" }
    # demo_receiving_bucket { "aptrust.receiving.test.#{identifier}" }
    # demo_restore_bucket { "aptrust.restore.test.#{identifier}" }
  end

  factory :aptrust, class: 'Institution' do
    name { 'APTrust' }
    identifier { 'aptrust.org' }
    dpn_uuid { '' }
    type { 'MemberInstitution' }
    deactivated_at { nil }
    # repo_receiving_bucket { "aptrust.receiving.#{identifier}" }
    # repo_restore_bucket { "aptrust.restore.#{identifier}" }
    # demo_receiving_bucket { "aptrust.receiving.test.#{identifier}" }
    # demo_restore_bucket { "aptrust.restore.test.#{identifier}" }
  end
end