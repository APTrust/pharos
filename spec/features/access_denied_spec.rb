require 'spec_helper'

feature 'Access Denied' do
  before do
    @user = FactoryBot.create(:user)
    @institution = FactoryBot.create(:member_institution)
  end

  scenario 'Unauthorized user tries to view page' do
    login_as(@user)
    inject_session verified: true

    # Visit the path of an institution that is not the user's
    visit(institution_path(@institution))

    expect(page).to have_content 'You are not authorized to access this page.'
    current_path.should == root_path
  end
end