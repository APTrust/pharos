# == Schema Information
#
# Table name: institutions
#
#  id                    :integer          not null, primary key
#  name                  :string
#  identifier            :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  state                 :string
#  type                  :string
#  member_institution_id :integer
#  deactivated_at        :datetime
#  otp_enabled           :boolean
#  receiving_bucket      :string           not null
#  restore_bucket        :string           not null
#
FactoryBot.define do

  sequence(:name) { |n| "#{Faker::Company.name} #{n}" }
  sequence(:identifier) { |n| "#{n}#{Faker::Internet.domain_word}.#{Pharos::Application::VALID_DOMAINS.sample}"}

  factory :member_institution do
    name
    identifier
    type { 'MemberInstitution' }
    deactivated_at { nil }
    receiving_bucket { "#{Pharos::Application.config.pharos_receiving_bucket_prefix}#{identifier}" }
    restore_bucket { "#{Pharos::Application.config.pharos_restore_bucket_prefix}#{identifier}" }
  end

  factory :subscription_institution do
    name
    identifier
    type { 'SubscriptionInstitution' }
    member_institution_id { FactoryBot.create(:member_institution).id }
    deactivated_at { nil }
    receiving_bucket { "#{Pharos::Application.config.pharos_receiving_bucket_prefix}#{identifier}" }
    restore_bucket { "#{Pharos::Application.config.pharos_restore_bucket_prefix}#{identifier}" }
  end

  factory :aptrust, class: 'Institution' do
    name { 'APTrust' }
    identifier { 'aptrust.org' }
    type { 'MemberInstitution' }
    deactivated_at { nil }
    receiving_bucket { "#{Pharos::Application.config.pharos_receiving_bucket_prefix}#{identifier}" }
    restore_bucket { "#{Pharos::Application.config.pharos_restore_bucket_prefix}#{identifier}" }
  end
end
