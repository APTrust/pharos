# == Schema Information
#
# Table name: bulk_delete_jobs
#
#  id                        :bigint           not null, primary key
#  requested_by              :string
#  institutional_approver    :string
#  aptrust_approver          :string
#  institutional_approval_at :datetime
#  aptrust_approval_at       :datetime
#  note                      :text
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  institution_id            :integer          not null
#
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
