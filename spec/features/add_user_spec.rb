require 'spec_helper'

describe 'Adding a new user' do
  before do
    Institution.destroy_all
    FactoryBot.create(:aptrust) if Institution.where(name: 'APTrust').empty?
    Role.where(name: 'institutional_admin').first_or_create
  end

  let(:admin_user) { FactoryBot.create(:user, :admin) }
  it 'should work' do
    login_as admin_user
    inject_session verified: true

    visit '/'
    click_link 'New User'
    fill_in 'Name', with: 'Sonja Something'
    fill_in 'Email', with: 'sonja@example.com'
    fill_in 'Mobile Phone Number', with: '7128582392'
    select 'APTrust', from: 'Institution'
    choose 'Institutional Admin'
    fill_in 'Password', with: 'Password123'
    fill_in 'Password confirmation', with: 'Password123'
    click_button 'Submit'
    expect(page).to have_content 'User was successfully created.'
  end
end