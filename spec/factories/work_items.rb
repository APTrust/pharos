FactoryGirl.define do
  factory :work_item, class: WorkItem do
    name { SecureRandom.uuid + '.tar' }
    etag { SecureRandom.hex }
    bag_date { Time.now.utc }
    user { Faker::Name.name }
    institution { FactoryGirl.create(:institution) }
    bucket { "aptrust.receiving.#{institution.identifier}" }
    date { Time.now.utc }
    note { Faker::Lorem.sentence }
    action { Pharos::Application::PHAROS_ACTIONS.values.sample }
    stage { Pharos::Application::PHAROS_STAGES.values.sample }
    status { Pharos::Application::PHAROS_STATUSES.values.sample }
    outcome { Faker::Lorem.sentence }
    intellectual_object { FactoryGirl.create(:intellectual_object) }
  end

  factory :ingested_item, class: WorkItem do
    name { SecureRandom.uuid + '.tar' }
    etag { SecureRandom.hex }
    bag_date { Time.now.utc }
    user { Faker::Name.name }
    institution { FactoryGirl.create(:institution) }
    bucket { "aptrust.receiving.#{institution.identifier}" }
    date { Time.now.utc }
    note { Faker::Lorem.sentence }
    action { Pharos::Application::PHAROS_ACTIONS['ingest'] }
    stage { Pharos::Application::PHAROS_STAGES['record'] }
    status { Pharos::Application::PHAROS_STATUSES['success'] }
    outcome { Faker::Lorem.sentence }
    object_identifier { FactoryGirl.create(:intellectual_object).identifier }
  end

  factory :work_item_extended, class: WorkItem do
    name { SecureRandom.uuid + '.tar' }
    etag { SecureRandom.hex }
    bag_date { Time.now.utc }
    user { Faker::Name.name }
    institution { FactoryGirl.create(:institution) }
    bucket { "aptrust.receiving.#{institution.identifier}" }
    date { Time.now.utc }
    note { Faker::Lorem.sentence }
    action { Pharos::Application::PHAROS_ACTIONS.values.sample }
    stage { Pharos::Application::PHAROS_STAGES.values.sample }
    status { Pharos::Application::PHAROS_STATUSES.values.sample }
    outcome { Faker::Lorem.sentence }
    node { Faker::Internet.ip_v4_address }
    pid { Random::rand(5000) }
    object_identifier { FactoryGirl.create(:intellectual_object).identifier }
  end

end
