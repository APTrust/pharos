require 'spec_helper'

describe 'Adding a new user' do
  before do
    Institution.destroy_all
    FactoryGirl.create(:aptrust) if Institution.where(name: 'APTrust').empty?
    Role.where(name: 'institutional_admin').first_or_create
  end

  let(:admin_user) { FactoryGirl.create(:user, :admin) }
  it 'should work' do
    login_as admin_user

    visit '/'
    click_link 'New User'
    fill_in 'Name', with: 'Sonja Something'
    fill_in 'Email', with: 'sonja@example.com'
    fill_in 'Phone number', with: '7128582392'
    select 'APTrust', from: 'Institution'
    choose 'Institutional Admin'
    fill_in 'Password', with: 'password'
    fill_in 'Password confirmation', with: 'password'
    click_button 'Submit'
    expect(page).to have_content 'User was successfully created.'
  end
end