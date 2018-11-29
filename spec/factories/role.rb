# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :admin_role, class: 'Role' do
    name { 'admin' }
  end

  factory :institutional_admin_role, class: 'Role' do
    name { 'institutional_admin' }
  end

  factory :institutional_user_role, class: 'Role' do
    name { 'institutional_user' }
  end
end