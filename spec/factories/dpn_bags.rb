FactoryBot.define do
  factory :dpn_bag do
    institution { FactoryBot.create(:member_institution) }
    object_identifier { "#{institution.identifier}/#{SecureRandom.uuid}" }
    dpn_identifier { SecureRandom.uuid }
    dpn_size { rand(20000..500000000) }
    node_1 { %w(chron hathi sdr tdr aptrust).sample }
    node_2 { %w(chron hathi sdr tdr aptrust).sample }
    node_3 { %w(chron hathi sdr tdr aptrust).sample }
    dpn_created_at { Time.now }
    dpn_updated_at { Time.now }
  end
end
