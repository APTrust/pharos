require 'spec_helper'

RSpec.describe UsersController, type: :controller do
  after do
    Institution.destroy_all
  end

  describe 'An APTrust Administrator' do
    let(:admin_user) { FactoryGirl.create(:user, :admin) }
    let(:institutional_admin) { FactoryGirl.create(:user, :institutional_admin)}

    before { sign_in admin_user }

    describe 'who gets a list of users' do
      let!(:institutional_admin) { FactoryGirl.create(:user, :institutional_admin)}
      let!(:institutional_user) { FactoryGirl.create(:user, :institutional_user)}
      it 'should see all the users' do
        get :index
        response.should be_successful
        expect(assigns[:users]).to include(admin_user, institutional_admin, institutional_user)
      end
    end

    it 'can show an Institutional Administrators' do
      get :show, id: institutional_admin
      response.should be_successful
      expect(assigns[:user]).to eq institutional_admin
    end

    it 'can load a form to create a new user' do
      get :new
      response.should be_successful
      expect(assigns[:user]).to be_kind_of User
    end

    describe 'can create Institutional Administrators' do
      let(:institutional_admin_role_id) { Role.where(name: 'institutional_admin').first_or_create.id}
      let(:attributes) { FactoryGirl.attributes_for(:user, role_ids: institutional_admin_role_id) }

      it 'unless no parameters are passed' do
        expect {
          post :create, {}
        }.to_not change(User, :count)
      end

      it 'when the parameters are valid' do
        expect {
          post :create, user: attributes
        }.to change(User, :count).by(1)
        response.should redirect_to user_url(assigns[:user])
        expect(assigns[:user]).to be_institutional_admin
      end
    end

    it 'can edit Institutional Administrators' do
      get :edit, id: institutional_admin
      response.should be_successful
      expect(assigns[:user]).to eq institutional_admin
    end

    it 'can perform a password reset' do
      password = institutional_admin.password
      get :admin_password_reset, id: institutional_admin
      expect(assigns[:user]).to eq institutional_admin
      expect(assigns[:user].password).not_to eq password
    end

    describe 'can update Institutional Administrators' do
      let(:institutional_admin) { FactoryGirl.create(:user, :institutional_admin)}

      it 'when the parameters are valid' do
        put :update, id: institutional_admin, user: {name: 'Frankie'}
        response.should redirect_to user_url(institutional_admin)
        expect(flash[:notice]).to eq 'User was successfully updated.'
        expect(assigns[:user].name).to eq 'Frankie'
      end
      it 'when the parameters are invalid' do
        put :update, id: institutional_admin, user: {phone_number: 'f121'}
        response.should be_successful
        expect(assigns[:user].errors.include?(:phone_number)).to be true
      end

      it 'cannot set api_secret_key in an update' do
        patch :update, id: institutional_admin, user: { name: 'Frankie', api_secret_key: '123' }
        institutional_admin.reload

        expect(institutional_admin.name).to eq 'Frankie'
        expect(institutional_admin.encrypted_api_secret_key).to be_nil
        expect(institutional_admin.api_secret_key).to be_nil
        response.should redirect_to user_url(institutional_admin)
      end

      it 'cannot set encrypted_api_secret_key in an update' do
        patch :update, id: institutional_admin, user: { name: 'Frankie', encrypted_api_secret_key: '123' }
        institutional_admin.reload

        expect(institutional_admin.name).to eq 'Frankie'
        expect(institutional_admin.encrypted_api_secret_key).to be_nil
        expect(institutional_admin.api_secret_key).to be_nil
        response.should redirect_to user_url(institutional_admin)
      end
    end
  end

  describe 'An Institutional Administrator' do
    let(:institutional_admin) { FactoryGirl.create(:user, :institutional_admin)}

    before { sign_in institutional_admin }

    describe 'who gets a list of users' do
      let!(:user_at_institution) {  FactoryGirl.create(:user, :institutional_user, institution_id: institutional_admin.institution_id) }
      let!(:user_of_different_institution) {  FactoryGirl.create(:user, :institutional_user) }
      it 'can only see users in their institution' do
        get :index
        response.should be_successful
        expect(assigns[:users]).to include user_at_institution
        expect(assigns[:users]).to_not include user_of_different_institution
      end
    end

    describe 'show an Institutinal User' do
      describe 'at my institution' do
        let(:user_at_institution) {  FactoryGirl.create(:user, :institutional_user, institution_id: institutional_admin.institution_id) }
        it 'can show the Institutional Users for my institution' do
          get :show, id: user_at_institution
          response.should be_successful
          expect(assigns[:user]).to eq user_at_institution
        end
      end

      describe 'at a different institution' do
        let(:user_of_different_institution) {  FactoryGirl.create(:user, :institutional_user) }
        it "can't show" do
          get :show, id: user_of_different_institution
          response.should redirect_to root_url
          expect(flash[:alert]).to eq 'You are not authorized to access this page.'
        end
      end
    end

    it 'can load a form to create a new user' do
      get :new
      response.should be_successful
      expect(assigns[:user]).to be_kind_of User
    end

    describe 'creating a User' do

      describe 'at another institution' do
        let(:attributes) { FactoryGirl.attributes_for(:user) }
        it "shouldn't work" do
          expect {
            post :create, user: attributes
          }.not_to change(User, :count)
          response.should redirect_to root_path
          expect(flash[:alert]).to eq 'You are not authorized to access this page.'
        end
      end

      describe 'at my institution' do
        describe 'with institutional_user role' do
          let(:institutional_user_role_id) { Role.where(name: 'institutional_user').first_or_create.id}
          let(:attributes) { FactoryGirl.attributes_for(:user, :institution_id=>institutional_admin.institution_id, role_ids: institutional_user_role_id) }
          it 'should be successful' do
            expect {
              post :create, user: attributes
            }.to change(User, :count).by(1)
            response.should redirect_to user_url(assigns[:user])
            expect(assigns[:user]).to be_institutional_user
          end
        end

        describe 'with institutional_admin role' do
          let(:institutional_admin_role_id) {Role.where(name: 'institutional_admin').first_or_create.id}
          let(:attributes) { FactoryGirl.attributes_for(:user, institution_id: institutional_admin.institution_id, role_ids: institutional_admin_role_id) }
          it 'should be successful' do
            expect {
              post :create, user: attributes
            }.to change(User, :count).by(1)
            response.should redirect_to user_url(assigns[:user])
            expect(assigns[:user]).to be_institutional_admin
          end
        end

        describe 'with admin role' do
          let(:admin_role_id) { Role.where(name: 'admin').first_or_create.id}
          let(:attributes) { FactoryGirl.attributes_for(:user, institution_id: institutional_admin.institution_id, role_ids: admin_role_id) }
          it 'should be forbidden' do
            expect {
              post :create, user: attributes
            }.not_to change(User, :count)
            response.should redirect_to root_path
            expect(flash[:alert]).to eq 'You are not authorized to access this page.'
          end
        end
      end
    end

    describe 'editing Institutional User' do
      describe 'from my institution' do
        let(:user_at_institution) {  FactoryGirl.create(:user, :institutional_user, institution_id: institutional_admin.institution_id) }
        it 'should be successful' do
          get :edit, id: user_at_institution
          response.should be_successful
          expect(assigns[:user]).to eq user_at_institution
        end
      end
      describe 'from another institution' do
        let(:user_of_different_institution) {  FactoryGirl.create(:user, :institutional_user) }
        it 'should show an error' do
          get :edit, id: user_of_different_institution
          response.should be_redirect
          expect(flash[:alert]).to eq 'You are not authorized to access this page.'
        end
      end
    end

    describe 'can update Institutional users' do
      let(:institutional_admin) { FactoryGirl.create(:user, :institutional_admin)}
      describe 'from my institution' do
        let(:user_at_institution) {  FactoryGirl.create(:user, :institutional_user, institution_id: institutional_admin.institution_id) }
        it 'should be successful' do
          patch :update, id: user_at_institution, user: {name: 'Frankie'}
          response.should redirect_to user_url(user_at_institution)
          expect(assigns[:user]).to eq user_at_institution
        end
      end
      describe 'from another institution' do
        let(:user_of_different_institution) {  FactoryGirl.create(:user, :institutional_user) }
        it 'should show an error message' do
          patch :update, id: user_of_different_institution, user: {name: 'Frankie'}
          response.should be_redirect
          expect(flash[:alert]).to eq 'You are not authorized to access this page.'
        end
      end
    end
  end

  describe 'An Institutional User' do
    let!(:user) { FactoryGirl.create(:user, :institutional_user)}
    before { sign_in user }

    it 'generates a new API key' do
      patch :generate_api_key, id: user.id
      user.reload

      expect(assigns[:user]).to eq user
      response.should redirect_to user_path(user)
      expect(assigns[:user].api_secret_key).to_not be_nil
      expect(user.encrypted_api_secret_key).to_not be_nil
      flash[:notice].should =~ /#{assigns[:user].api_secret_key}/
    end

    it 'prints a message if it is unable to make the key' do
      User.any_instance.should_receive(:save).and_return(false)
      patch :generate_api_key, id: user.id
      user.reload

      response.should redirect_to user_path(user)
      expect(flash[:alert]).to eq 'ERROR: Unable to create API key.'
      expect(user.api_secret_key).to be_nil
      expect(user.encrypted_api_secret_key).to be_nil
    end
  end
end
