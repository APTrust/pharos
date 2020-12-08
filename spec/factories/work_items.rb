# == Schema Information
#
# Table name: work_items
#
#  id                      :integer          not null, primary key
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  intellectual_object_id  :integer
#  generic_file_id         :integer
#  name                    :string
#  etag                    :string
#  bucket                  :string
#  user                    :string
#  note                    :text
#  action                  :string
#  stage                   :string
#  status                  :string
#  outcome                 :text
#  bag_date                :datetime
#  date                    :datetime
#  retry                   :boolean          default(FALSE), not null
#  object_identifier       :string
#  generic_file_identifier :string
#  node                    :string(255)
#  pid                     :integer          default(0)
#  needs_admin_review      :boolean          default(FALSE), not null
#  institution_id          :integer
#  queued_at               :datetime
#  size                    :bigint
#  stage_started_at        :datetime
#  aptrust_approver        :string
#  inst_approver           :string
#
FactoryBot.define do
  factory :work_item, class: WorkItem do
    name { SecureRandom.uuid + '.tar' }
    etag { SecureRandom.hex }
    bag_date { Time.now.utc }
    user { Faker::Name.name }
    institution { FactoryBot.create(:member_institution) }
    bucket { "aptrust.receiving.#{institution.identifier}" }
    date { Time.now.utc }
    note { Faker::Lorem.sentence }
    action { Pharos::Application::PHAROS_ACTIONS.values.sample }
    stage { Pharos::Application::PHAROS_STAGES.values.sample }
    status { Pharos::Application::PHAROS_STATUSES.values.sample }
    outcome { Faker::Lorem.sentence }
    intellectual_object { FactoryBot.create(:intellectual_object) }
  end

  factory :ingested_item, class: WorkItem do
    name { SecureRandom.uuid + '.tar' }
    etag { SecureRandom.hex }
    bag_date { Time.now.utc }
    user { Faker::Name.name }
    institution { FactoryBot.create(:member_institution) }
    bucket { "aptrust.receiving.#{institution.identifier}" }
    date { Time.now.utc }
    note { Faker::Lorem.sentence }
    action { Pharos::Application::PHAROS_ACTIONS['ingest'] }
    stage { Pharos::Application::PHAROS_STAGES['record'] }
    status { Pharos::Application::PHAROS_STATUSES['success'] }
    outcome { Faker::Lorem.sentence }
    object_identifier { FactoryBot.create(:intellectual_object).identifier }
  end

  factory :work_item_extended, class: WorkItem do
    name { SecureRandom.uuid + '.tar' }
    etag { SecureRandom.hex }
    bag_date { Time.now.utc }
    user { Faker::Name.name }
    institution { FactoryBot.create(:member_institution) }
    bucket { "aptrust.receiving.#{institution.identifier}" }
    date { Time.now.utc }
    note { Faker::Lorem.sentence }
    action { Pharos::Application::PHAROS_ACTIONS.values.sample }
    stage { Pharos::Application::PHAROS_STAGES.values.sample }
    status { Pharos::Application::PHAROS_STATUSES.values.sample }
    outcome { Faker::Lorem.sentence }
    node { Faker::Internet.ip_v4_address }
    pid { Random::rand(5000) }
    object_identifier { FactoryBot.create(:intellectual_object).identifier }
  end

end
