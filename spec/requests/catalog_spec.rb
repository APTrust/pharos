require 'spec_helper'

describe 'Catalog' do

  after do
    Institution.destroy_all
  end

  describe 'GET #search', :type => :feature do
    before(:each) do
      visit('/')
    end

    describe 'for all users' do
      it 'should have link called Login' do
        expect(page).to have_link 'Login'
      end

      it 'should have APTrust footer information' do
        expect(page).to have_content(/\u00A9 \d{4} - \d{4} Academic Preservation Trust/)
      end
    end

    describe 'for authenticated' do
      describe 'admin users' do
        before(:all) do
          @user = FactoryGirl.create(:user, :admin)
          login_as(@user)
        end

        it 'should have admin dropdown' do
          login_as(@user)
          expect(page).to have_content('Admin')
        end

        it 'should present the users name' do
          login_as(@user)
          expect(page).to have_content("#{@user.name}")
        end
      end

      describe 'institutional_admin users' do
        before(:all) do
          @user = FactoryGirl.create(:aptrust_user, :institutional_admin)
          login_as(@user)
        end

        it 'should have admin dropdown' do
          login_as(@user)
          expect(page).to have_content('Admin')
        end

        it 'should present the users name' do
          login_as(@user)
          expect(page).to have_content("#{@user.name}")
        end
      end

      describe 'institutional_user users' do
        before(:all) do
          @user = FactoryGirl.create(:aptrust_user, :institutional_user)
          login_as(@user)
        end

        it 'should have not admin dropdown' do
          login_as(@user)
          expect(page).to_not have_content('Admin')
        end

        it 'should present the users name' do
          login_as(@user)
          expect(page).to have_content("#{@user.name}")
        end
      end
    end
  end
end
