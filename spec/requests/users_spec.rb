require 'spec_helper'

describe 'Users' do

  after do
    Institution.destroy_all
  end

  describe 'DELETE users', :type => :feature do
    before do
      @user = FactoryGirl.create(:user, :admin)
      @user2 = FactoryGirl.create(:user)
    end

    it 'should provide message after delete with name of deleted instituion' do
      login_as(@user)
      visit('/users')
      expect {
        within(:xpath, "//tr[@id='#{@user2.id}']") do
          click_link 'Delete'
        end
      }.to change(User, :count).by(-1)
      page.should have_content "#{@user2.name} was deleted."
    end
  end
end