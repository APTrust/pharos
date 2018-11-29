FactoryBot.define do
  factory :user, class: 'User' do
    name { Faker::Name.name }
    email { "#{Faker::Internet.user_name}@#{Faker::Internet.domain_name}" }
    phone_number { 4345551234 }
    password { %w(Password514 thisisareallylongpasswordtesting).sample }
    roles { [Role.where(name: 'public').first_or_create] }
    institution_id { FactoryBot.create(:member_institution).id }
    deactivated_at { nil }

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
