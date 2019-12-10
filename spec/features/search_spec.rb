require 'spec_helper'

describe 'Searching' do

  let(:user) { FactoryBot.create(:user, :institutional_user) }
  it 'should work' do
    login_as user
    inject_session verified: true

    visit '/'
    click_link 'Objects'
    expect(page).to have_content "Objects for #{user.institution.name}"
    click_button('search-btn')
  end
end