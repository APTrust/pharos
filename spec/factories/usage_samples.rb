# == Schema Information
#
# Table name: usage_samples
#
#  id             :integer          not null, primary key
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  institution_id :string
#  data           :text
#

FactoryBot.define do
  factory :usage_sample do
    institution { nil }
    data { 'MyText' }
  end
end
