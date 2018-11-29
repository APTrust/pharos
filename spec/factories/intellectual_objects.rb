FactoryBot.define do

  factory :intellectual_object, class: IntellectualObject do
    institution { FactoryBot.create(:member_institution) }
    title { Faker::Lorem.sentence }
    description { Faker::Lorem.paragraph }
    identifier { "#{institution.identifier}/#{SecureRandom.uuid}" }
    access { ['consortia', 'institution', 'restricted'].sample }
    alt_identifier { '' }
    bag_name { identifier.split('/')[1] }
    bag_group_identifier { '' }
    state { 'A' }
    storage_option { 'Standard' }

    factory :consortial_intellectual_object, class: IntellectualObject do
      access { 'consortia' }
    end

    factory :institutional_intellectual_object, class: IntellectualObject do
      access { 'institution' }
    end

    factory :restricted_intellectual_object, class: IntellectualObject do
      access { 'restricted' }
    end
  end
end
