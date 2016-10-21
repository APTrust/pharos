FactoryGirl.define do
  factory :dpn_work_item do
    node { 'aptrust' }
    task { Pharos::Application::DPN_TASKS.sample }
    identifier { SecureRandom.uuid }
    queued_at { Time.now }
    completed_at { Time.now }
    note { 'This bag completed remarkably fast.' }
  end
end
