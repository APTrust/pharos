FactoryBot.define do
  factory :snapshot do
    audit_date { Time.now }
    institution_id { FactoryBot.create(:institution).id }
    apt_bytes { rand(20000000..500000000000) }
    cost { (apt_bytes * 0.000000000381988).round(2) }
    snapshot_type { ['Individual', 'Subscribers Included'].sample }
  end
end
