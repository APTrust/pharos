FactoryBot.define do
  factory :bulk_delete_job do
    requested_by { FactoryBot.create(:user, :admin).email }
    institutional_approver { nil }
    aptrust_approver { nil }
    institutional_approval_at { nil }
    aptrust_approval_at { nil }
    institution_id { FactoryBot.create(:member_institution).id }
  end
end
