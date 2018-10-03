FactoryBot.define do
  factory :dpn_work_item do
    remote_node { %w(chron hathi sdr tdr aptrust).sample }
    processing_node { %w(chron hathi sdr tdr aptrust).sample }
    task { Pharos::Application::DPN_TASKS.sample }
    stage { Pharos::Application::PHAROS_STAGES.values.sample }
    status { Pharos::Application::PHAROS_STATUSES.values.sample }
    identifier { SecureRandom.uuid }
    queued_at { Time.now }
    completed_at { Time.now }
    note { 'This bag completed remarkably fast.' }
    pid { 0 }
    state {  }
  end
end
