FactoryGirl.define do
  factory :user, class: 'User' do
    name { Faker::Name.name }
    email { Faker::Internet.email }
    phone_number { Faker::PhoneNumber.phone_number }
    password { 'password' }
    institution_pid { FactoryGirl.create(:institution).pid }
    roles { [Role.where(name: 'public').first_or_create] }

    factory :aptrust_user, class: 'User' do
      institution_pid {
        aptrust_institution = Institution.where(desc_metadata__name_tesim: 'APTrust')
        if aptrust_institution.count == 1
          aptrust_institution.first.pid
        elsif aptrust_institution.count > 1
          raise 'There should never be more than one institution with the name APTrust'
        else
          FactoryGirl.create(:aptrust).pid
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
