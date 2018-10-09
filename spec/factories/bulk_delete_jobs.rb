FactoryBot.define do
  factory :bulk_delete_job do
    requested_by { FactoryBot.create(:user, :admin).email }
    institutional_approver { FactoryBot.create(:user, :institutional_admin).email }
    aptrust_approver { FactoryBot.create(:user, :admin).email }
    institutional_approval_at { Time.now.to_s }
    aptrust_approval_at { Time.now.to_s }
    institution_id { FactoryBot.create(:member_institution).id }
  end
end
