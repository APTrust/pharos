# == Schema Information
#
# Table name: users
#
#  id                        :integer          not null, primary key
#  name                      :string
#  email                     :string
#  phone_number              :string
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  encrypted_password        :string           default(""), not null
#  reset_password_token      :string
#  reset_password_sent_at    :datetime
#  remember_created_at       :datetime
#  sign_in_count             :integer          default(0), not null
#  current_sign_in_at        :datetime
#  last_sign_in_at           :datetime
#  current_sign_in_ip        :string
#  last_sign_in_ip           :string
#  institution_id            :integer
#  encrypted_api_secret_key  :text
#  deactivated_at            :datetime
#  password_changed_at       :datetime
#  encrypted_otp_secret      :string
#  encrypted_otp_secret_iv   :string
#  encrypted_otp_secret_salt :string
#  consumed_timestep         :integer
#  otp_required_for_login    :boolean
#  enabled_two_factor        :boolean          default(FALSE)
#  confirmed_two_factor      :boolean          default(FALSE)
#  otp_backup_codes          :string           is an Array
#  authy_id                  :string
#  last_sign_in_with_authy   :datetime
#  authy_status              :string
#  email_verified            :boolean          default(FALSE)
#  initial_password_updated  :boolean          default(FALSE)
#  force_password_update     :boolean          default(FALSE)
#  account_confirmed         :boolean          default(TRUE)
#  grace_period              :datetime
#
FactoryBot.define do
  factory :user, class: 'User' do
    name { Faker::Name.name }
    email { "#{Faker::Internet.user_name}@#{Faker::Internet.domain_name}" }
    phone_number { 4345551234 }
    password { %w(Password514 thisisareallylongpasswordtesting).sample }
    roles { [Role.where(name: 'public').first_or_create] }
    institution_id { FactoryBot.create(:member_institution).id }
    deactivated_at { nil }
    enabled_two_factor { true }
    confirmed_two_factor { true }
    email_verified { true }
    initial_password_updated { true }
    force_password_update { false }
    account_confirmed { true }
    sign_in_count { 5 }
    grace_period { Time.now }

    factory :aptrust_user, class: 'User' do
      roles { [Role.where(name: 'admin').first_or_create] }
      institution_id {
        aptrust_institution = Institution.where(name: 'APTrust')
        if aptrust_institution.count == 1
          aptrust_institution.first.id
        elsif aptrust_institution.count > 1
          raise 'There should never be more than one institution with the name APTrust'
        else
          FactoryBot.create(:aptrust).id
        end
      }
    end

    trait :admin do
      roles { [Role.where(name: 'admin').first_or_create] }
    end

    trait :institutional_admin do
      roles { [Role.where(name: 'institutional_admin').first_or_create]}
    end

    trait :institutional_user do
      roles { [Role.where(name: 'institutional_user').first_or_create] }
    end
  end
end
