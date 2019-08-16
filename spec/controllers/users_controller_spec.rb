require 'spec_helper'

RSpec.describe UsersController, type: :controller do
  after :all do
    User.delete_all
    Institution.delete_all
  end

  describe 'An APTrust Administrator' do
    let(:admin_user) { FactoryBot.create(:user, :admin) }
    let(:institutional_admin) { FactoryBot.create(:user, :institutional_admin)}
    let(:stale_user) { FactoryBot.create(:user) }

    before do
      sign_in admin_user
      session[:verified] = true
    end

    describe 'who gets a list of users' do
      let!(:institutional_admin) { FactoryBot.create(:user, :institutional_admin)}
      let!(:institutional_user) { FactoryBot.create(:user, :institutional_user)}
      it 'should see all the users' do
        get :index
        response.should be_successful
        expect(assigns[:users]).to include(admin_user, institutional_admin, institutional_user)
      end
    end

    it 'should be able to perform yearly account confirmations' do
      get :account_confirmations, format: :html
      expect(response.status).to eq(302)
      expect(flash[:notice]).to eq('All users except admins have been sent their yearly account confirmation email.')
      User.all.each do |user|
        unless user.admin?
          expect(user.account_confirmed).to eq false
          token = ConfirmationToken.where(user_id: user.id).first
          expect(token).not_to be_nil
          email = ActionMailer::Base.deliveries.last
          expect(email.body.encoded).to include('You will have two weeks to confirm your account before your account will be deactivated.')
        end
      end
    end

    it 'should be able to resend an account confirmation email' do
      get :indiv_confirmation_email, params: { id: institutional_admin }
      expect(response.status).to eq(302)
      expect(assigns[:user].account_confirmed).to eq false
      token = ConfirmationToken.where(user_id: assigns[:user].id).first
      expect(token).not_to be_nil
      email = ActionMailer::Base.deliveries.last
      expect(email.body.encoded).to include('You will have two weeks to confirm your account before your account will be deactivated.')
      expect(email.body.encoded).to include("http://localhost:3000/users/#{assigns[:user].id}/confirm_account?confirmation_token=#{token.token}")
    end

    it 'can show an Institutional Administrators' do
      get :show, params: { id: institutional_admin }
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
      let(:attributes) { FactoryBot.attributes_for(:user, role_ids: institutional_admin_role_id, grace_period: nil) }
      let(:other_attributes) { FactoryBot.attributes_for(:user, role_ids: institutional_admin_role_id) }

      it 'unless no parameters are passed' do
        expect {
          post :create, params: {}
        }.to_not change(User, :count)
      end

      it 'when the parameters are valid' do
        expect {
          post :create, params: { user: attributes }
        }.to change(User, :count).by(1)
        response.should redirect_to user_url(assigns[:user])
        expect(assigns[:user]).to be_institutional_admin
        expect(assigns[:user].grace_period).not_to be_nil
      end

      it 'and will send a welcome email to the new user' do
        expect{
          post :create, params: { user: other_attributes }
        }.to change(User, :count).by(1)
        email = ActionMailer::Base.deliveries.last
        expect(email.body.encoded).to include('An account with a temporary password has been created for you.')
        expect(email.body.encoded).to include('Temporary password: ABCabc-')
      end
    end

    it 'can edit Institutional Administrators' do
      get :edit, params: { id: institutional_admin }
      response.should be_successful
      expect(assigns[:user]).to eq institutional_admin
    end

    it 'can perform a password reset' do
      password = institutional_admin.password
      get :admin_password_reset, params: { id: institutional_admin }
      expect(assigns[:user]).to eq institutional_admin
      expect(assigns[:user].password).not_to eq password
      email = ActionMailer::Base.deliveries.last
      expect(email.body.encoded).to include('Your new password is ')
      expect(flash[:notice]).to eq "Password has been reset for #{institutional_admin.email}. They will be notified of their new password via email."
    end

    it 'can deactivate a user' do
      get :deactivate, params: { id: institutional_admin }
      expect(assigns[:user]).to eq institutional_admin
      expect(assigns[:user].deactivated_at).not_to be_nil
      expect(assigns[:user].encrypted_api_secret_key).to eq ''
    end

    it 'can reactivate a user' do
      get :reactivate, params: { id: institutional_admin }
      expect(assigns[:user]).to eq institutional_admin
      expect(assigns[:user].deactivated_at).to be_nil
    end

    describe 'enabling two factor authentication' do
      let(:admin_user) { FactoryBot.create(:user, :admin) }
      let(:user_at_institution) {  FactoryBot.create(:user, :institutional_user, institution_id: admin_user.institution_id) }
      let(:user_of_different_institution) {  FactoryBot.create(:user, :institutional_user) }
      it 'for myself should succeed' do
        admin_user.enabled_two_factor = false
        admin_user.save!
        get :enable_otp, params: { id: admin_user.id, phone_number: '8055559014' }, format: :json
        expect(response.status).to eq(200)
        expect(assigns[:user].enabled_two_factor).to eq true
        expect(assigns[:codes]).not_to be_nil
      end

      it 'for another user at my institution should succeed' do
        user_at_institution.enabled_two_factor = false
        user_at_institution.save!
        get :enable_otp, params: { id: user_at_institution.id, phone_number: '8055559014' }, format: :json
        expect(response.status).to eq(200)
        expect(assigns[:user].enabled_two_factor).to eq true
        expect(assigns[:codes]).not_to be_nil
      end

      it 'for another user not at my institution should succeed' do
        user_of_different_institution.enabled_two_factor = false
        user_of_different_institution.save!
        get :enable_otp, params: { id: user_of_different_institution.id, phone_number: '8055559014' }, format: :json
        expect(response.status).to eq(200)
        expect(assigns[:user].enabled_two_factor).to eq true
        expect(assigns[:codes]).not_to be_nil
      end
    end

    describe 'disabling two factor authentication' do
      let(:admin_user) { FactoryBot.create(:user, :admin) }
      let(:user_at_institution) {  FactoryBot.create(:user, :institutional_user, institution_id: admin_user.institution_id) }
      let(:user_of_different_institution) {  FactoryBot.create(:user, :institutional_user) }

      it 'for myself should fail' do  # admins are required to use two factor authentication
        admin_user.enabled_two_factor = true
        admin_user.save!
        get :disable_otp, params: { id: admin_user.id }, format: :html
        expect(response.status).to eq(200)
        expect(assigns[:user].enabled_two_factor).to eq true
      end

      it 'for another user at my institution should succeed' do
        user_at_institution.enabled_two_factor = true
        user_at_institution.save!
        get :disable_otp, params: { id: user_at_institution.id }, format: :html
        expect(response.status).to eq(200)
        expect(assigns[:user].enabled_two_factor).to eq false
      end

      it 'for another user not at my institution should succeed' do
        user_of_different_institution.enabled_two_factor = true
        user_of_different_institution.save!
        get :disable_otp, params: { id: user_of_different_institution.id }, format: :html
        expect(response.status).to eq(200)
        expect(assigns[:user].enabled_two_factor).to eq false
      end
    end

    describe 'generating backup two factor authentication codes' do
      let(:admin_user) { FactoryBot.create(:user, :admin) }
      let(:user_at_institution) {  FactoryBot.create(:user, :institutional_user, institution_id: admin_user.institution_id) }
      let(:user_of_different_institution) {  FactoryBot.create(:user, :institutional_user) }

      it 'for myself should succeed' do
        old_codes = admin_user.generate_otp_backup_codes!
        admin_user.save!
        get :generate_backup_codes, params: { id: admin_user.id }, format: :json
        expect(response.status).to eq(200)
        expect(assigns[:codes[0]]).not_to eq old_codes[0]
      end

      it 'for another user at my institution should succeed' do
        old_codes = user_at_institution.generate_otp_backup_codes!
        user_at_institution.save!
        get :generate_backup_codes, params: { id: user_at_institution.id }, format: :json
        expect(response.status).to eq(200)
        expect(assigns[:codes[0]]).not_to eq old_codes[0]
      end

      it 'for another user not at my institution should succeed' do
        old_codes = user_of_different_institution.generate_otp_backup_codes!
        user_of_different_institution.save!
        get :generate_backup_codes, params: { id: user_of_different_institution.id }, format: :json
        expect(response.status).to eq(200)
        expect(assigns[:codes[0]]).not_to eq old_codes[0]
      end
    end

    describe 'can update Institutional Administrators' do
      let(:institutional_admin) { FactoryBot.create(:user, :institutional_admin)}

      it 'when the parameters are valid' do
        put :update, params: { id: institutional_admin, user: {name: 'Frankie'} }
        response.should redirect_to user_url(institutional_admin)
        expect(flash[:notice]).to eq 'User was successfully updated.'
        expect(assigns[:user].name).to eq 'Frankie'
      end
      it 'when the parameters are invalid' do
        put :update, params: { id: institutional_admin, user: {phone_number: 'f121'} }
        response.should be_successful
        expect(assigns[:user].errors.include?(:phone_number)).to be true
      end

      it 'cannot set api_secret_key in an update' do
        patch :update, params: { id: institutional_admin, user: { name: 'Frankie', api_secret_key: '123' } }
        institutional_admin.reload

        expect(institutional_admin.name).to eq 'Frankie'
        expect(institutional_admin.encrypted_api_secret_key).to be_nil
        expect(institutional_admin.api_secret_key).to be_nil
        response.should redirect_to user_url(institutional_admin)
      end

      it 'cannot set encrypted_api_secret_key in an update' do
        patch :update, params: { id: institutional_admin, user: { name: 'Frankie', encrypted_api_secret_key: '123' } }
        institutional_admin.reload

        expect(institutional_admin.name).to eq 'Frankie'
        expect(institutional_admin.encrypted_api_secret_key).to be_nil
        expect(institutional_admin.api_secret_key).to be_nil
        response.should redirect_to user_url(institutional_admin)
      end
    end

    describe 'while testing forced_redirections' do
      let(:admin_user_two) { FactoryBot.create(:user, :admin, account_confirmed: false) }
      let(:valid_key) { '123' }
      let(:api_user) { FactoryBot.create(:user, :admin, account_confirmed: false, api_secret_key: valid_key, enabled_two_factor: false,
                                         confirmed_two_factor: false, email_verified: false, initial_password_updated: false,
                                         force_password_update: true) }
      let(:initial_headers) {{ 'CONTENT_TYPE' => 'application/json', 'HTTP_ACCEPT' => 'application/json' }}

      it 'for non API calls should get caught' do
        sign_in admin_user_two
        get :index
        response.should redirect_to user_url(admin_user_two)
        flash[:error].should eq('You must confirm your account every year, please do that by clicking the link in your confirmation email.')
      end

      describe 'for API calls' do
        let(:login_headers) {{ 'X-Pharos-API-User' => api_user.email, 'X-Pharos-API-Key' => valid_key }}
        it 'should not get caught' do
          get :index
          response.should be_successful
        end
      end
    end

    it 'can send a stale user notification' do
      stale_user.created_at = DateTime.now - (ENV['PHAROS_2FA_GRACE_PERIOD'].to_i - 1).days
      stale_user.save!
      get :stale_user_notification, format: :html
      expect(response.status).to eq(302)
      email = ActionMailer::Base.deliveries.last
      expect(email.body.encoded).to include('Here are the latest stale users')
      expect(email.body.encoded).to include(stale_user.name)
      expect(email.body.encoded).to include(stale_user.email)
      expect(flash[:notice]).to eq 'The stale user notification email has been sent to the team.'
    end

  end

  describe 'An Institutional Administrator' do
    let(:institutional_admin) { FactoryBot.create(:user, :institutional_admin)}
    let(:institutional_user) { FactoryBot.create(:user, :institutional_user, institution_id: institutional_admin.institution.id) }
    let(:other_user) { FactoryBot.create(:user, :institutional_user) }

    before do
      sign_in institutional_admin
      session[:verified] = true
    end

    describe 'who gets a list of users' do
      let!(:user_at_institution) {  FactoryBot.create(:user, :institutional_user, institution_id: institutional_admin.institution_id) }
      let!(:user_of_different_institution) {  FactoryBot.create(:user, :institutional_user) }
      it 'can only see users in their institution' do
        get :index
        response.should be_successful
        expect(assigns[:users]).to include user_at_institution
        expect(assigns[:users]).to_not include user_of_different_institution
      end
    end

    describe 'show an Institutional User' do
      describe 'at my institution' do
        let(:user_at_institution) {  FactoryBot.create(:user, :institutional_user, institution_id: institutional_admin.institution_id) }
        it 'can show the Institutional Users for my institution' do
          get :show, params: { id: user_at_institution }
          response.should be_successful
          expect(assigns[:user]).to eq user_at_institution
        end
      end

      describe 'at a different institution' do
        let(:user_of_different_institution) {  FactoryBot.create(:user, :institutional_user) }
        it "can't show" do
          get :show, params: { id: user_of_different_institution }
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
        let(:attributes) { FactoryBot.attributes_for(:user) }
        it "shouldn't work" do
          expect {
            post :create, params: { user: attributes }
          }.not_to change(User, :count)
          response.should redirect_to root_path
          expect(flash[:alert]).to eq 'You are not authorized to access this page.'
        end
      end

      describe 'at my institution' do
        describe 'with institutional_user role' do
          let(:institutional_user_role_id) { Role.where(name: 'institutional_user').first_or_create.id}
          let(:attributes) { FactoryBot.attributes_for(:user, institution_id: institutional_admin.institution_id, role_ids: institutional_user_role_id) }
          let(:no_capital) { FactoryBot.attributes_for(:user, institution_id: institutional_admin.institution_id, role_ids: institutional_user_role_id, password: 'password15') }
          let(:no_lowercase) { FactoryBot.attributes_for(:user, institution_id: institutional_admin.institution_id, role_ids: institutional_user_role_id, password: 'PASSWORD15') }
          let(:no_digits) { FactoryBot.attributes_for(:user, institution_id: institutional_admin.institution_id, role_ids: institutional_user_role_id, password: 'Password') }
          let(:too_short) { FactoryBot.attributes_for(:user, institution_id: institutional_admin.institution_id, role_ids: institutional_user_role_id, password: 'password') }
          let(:complicated) { FactoryBot.attributes_for(:user, institution_id: institutional_admin.institution_id, role_ids: institutional_user_role_id, password: 'GoodPassword14') }
          let(:long_enough) { FactoryBot.attributes_for(:user, institution_id: institutional_admin.institution_id, role_ids: institutional_user_role_id, password: 'afunnythinghappenedonthewaytotheforum') }

          it 'should be successful' do
            expect {
              post :create, params: { user: attributes }
            }.to change(User, :count).by(1)
            response.should redirect_to user_url(assigns[:user])
            expect(assigns[:user]).to be_institutional_user
          end

          it 'should reject a password that is too short' do
            expect {
              post :create, params: { user: too_short }
            }.to_not change(User, :count)
          end

          it 'should accept a password that is short but has capitals, lowercase, and digits' do
            expect {
              post :create, params: { user: complicated }
            }.to change(User, :count).by(1)
          end

          it 'should accept a password that has no capitals, lowercase, or digits but is long' do
            expect {
              post :create, params: { user: long_enough }
            }.to change(User, :count).by(1)
          end

        end

        describe 'with institutional_admin role' do
          let(:institutional_admin_role_id) {Role.where(name: 'institutional_admin').first_or_create.id}
          let(:attributes) { FactoryBot.attributes_for(:user, institution_id: institutional_admin.institution_id, role_ids: institutional_admin_role_id) }
          it 'should be successful' do
            expect {
              post :create, params: { user: attributes }
            }.to change(User, :count).by(1)
            response.should redirect_to user_url(assigns[:user])
            expect(assigns[:user]).to be_institutional_admin
          end
        end

        describe 'with admin role' do
          let(:admin_role_id) { Role.where(name: 'admin').first_or_create.id}
          let(:attributes) { FactoryBot.attributes_for(:user, institution_id: institutional_admin.institution_id, role_ids: admin_role_id) }
          it 'should be forbidden' do
            expect {
              post :create, params: { user: attributes }
            }.not_to change(User, :count)
            response.should redirect_to root_path
            expect(flash[:alert]).to eq 'You are not authorized to access this page.'
          end
        end
      end
    end

    describe 'editing Institutional User' do
      describe 'from my institution' do
        let(:user_at_institution) {  FactoryBot.create(:user, :institutional_user, institution_id: institutional_admin.institution_id) }
        it 'should be successful' do
          get :edit, params: { id: user_at_institution }
          response.should be_successful
          expect(assigns[:user]).to eq user_at_institution
        end
      end
      describe 'from another institution' do
        let(:user_of_different_institution) {  FactoryBot.create(:user, :institutional_user) }
        it 'should show an error' do
          get :edit, params: { id: user_of_different_institution }
          response.should be_redirect
          expect(flash[:alert]).to eq 'You are not authorized to access this page.'
        end
      end
    end

    describe 'can update Institutional users' do
      let(:institutional_admin) { FactoryBot.create(:user, :institutional_admin)}
      describe 'from my institution' do
        let(:user_at_institution) {  FactoryBot.create(:user, :institutional_user, institution_id: institutional_admin.institution_id) }
        it 'should be successful' do
          patch :update, params: { id: user_at_institution, user: {name: 'Frankie'} }
          response.should redirect_to user_url(user_at_institution)
          expect(assigns[:user]).to eq user_at_institution
        end
      end
      describe 'from another institution' do
        let(:user_of_different_institution) {  FactoryBot.create(:user, :institutional_user) }
        it 'should show an error message' do
          patch :update, params: { id: user_of_different_institution, user: {name: 'Frankie'} }
          response.should be_redirect
          expect(flash[:alert]).to eq 'You are not authorized to access this page.'
        end
      end
    end

    describe 'can deactivate users' do
      let(:institutional_admin) { FactoryBot.create(:user, :institutional_admin)}
      describe 'from my institution' do
        let(:user_at_institution) {  FactoryBot.create(:user, :institutional_user, institution_id: institutional_admin.institution_id) }
        it 'should be successful' do
          get :deactivate, params: { id: user_at_institution }
          response.should redirect_to user_url(user_at_institution)
          expect(assigns[:user]).to eq user_at_institution
          expect(assigns[:user].deactivated_at).to_not be_nil
        end
      end
      describe 'from another institution' do
        let(:user_of_different_institution) {  FactoryBot.create(:user, :institutional_user) }
        it 'should not succeed' do
          get :deactivate, params: { id: user_of_different_institution }, format: :json
          response.should be_redirect
        end
      end
    end

    describe 'can reactivate users' do
      let(:institutional_admin) { FactoryBot.create(:user, :institutional_admin)}
      describe 'from my institution' do
        let(:user_at_institution) {  FactoryBot.create(:user, :institutional_user, institution_id: institutional_admin.institution_id) }
        it 'should be successful' do
          get :reactivate, params: { id: user_at_institution }
          response.should redirect_to user_url(user_at_institution)
          expect(assigns[:user]).to eq user_at_institution
          expect(assigns[:user].deactivated_at).to be_nil
        end
      end
      describe 'from another institution' do
        let(:user_of_different_institution) {  FactoryBot.create(:user, :institutional_user) }
        it 'should not succeed' do
          get :reactivate, params: { id: user_of_different_institution }, format: :json
          response.should be_redirect
        end
      end
    end

    it 'should not be able to perform vacuum operations' do
      get :vacuum, params: { vacuum_target: 'snapshots' }, format: :json
      expect(response.status).to eq(403)
    end

    it 'should not be able to send a stale user notification' do
      get :stale_user_notification, format: :json
      expect(response.status).to eq(403)
    end

    it 'should not be able to perform yearly account confirmations' do
      get :account_confirmations, format: :json
      expect(response.status).to eq(403)
    end

    it 'should be able to resend an account confirmation email for a user at own institution' do
      get :indiv_confirmation_email, params: { id: institutional_user }
      expect(response.status).to eq(302)
      expect(assigns[:user].account_confirmed).to eq false
      token = ConfirmationToken.where(user_id: assigns[:user].id).first
      expect(token).not_to be_nil
      email = ActionMailer::Base.deliveries.last
      expect(email.body.encoded).to include('You will have two weeks to confirm your account before your account will be deactivated.')
      expect(email.body.encoded).to include("http://localhost:3000/users/#{assigns[:user].id}/confirm_account?confirmation_token=#{token.token}")
    end

    it 'should not be able to resend an account confirmation email for a user at another institution' do
      get :indiv_confirmation_email, params: { id: other_user }, format: :json
      expect(response.status).to eq(403)
    end

    describe 'enabling two factor authentication' do
      let(:institutional_admin) { FactoryBot.create(:user, :institutional_admin)}
      let(:user_at_institution) {  FactoryBot.create(:user, :institutional_user, institution_id: institutional_admin.institution_id) }
      let(:user_of_different_institution) {  FactoryBot.create(:user, :institutional_user) }
      it 'for myself should succeed' do
        institutional_admin.enabled_two_factor = false
        institutional_admin.save!
        get :enable_otp, params: { id: institutional_admin.id, phone_number: '8055559014' }, format: :json
        expect(response.status).to eq(200)
        expect(assigns[:user].enabled_two_factor).to eq true
        expect(assigns[:codes]).not_to be_nil
      end

      it 'for another user at my institution should succeed' do
        user_at_institution.enabled_two_factor = false
        user_at_institution.save!
        get :enable_otp, params: { id: user_at_institution.id, phone_number: '8055559014' }, format: :json
        expect(response.status).to eq(200)
        expect(assigns[:user].enabled_two_factor).to eq true
        expect(assigns[:codes]).not_to be_nil
      end

      it 'for another user not at my institution should not succeed' do
        user_of_different_institution.enabled_two_factor = false
        user_of_different_institution.save!
        get :enable_otp, params: { id: user_of_different_institution.id, phone_number: '8055559014' }, format: :json
        expect(response.status).to eq(403)
      end
    end

    describe 'disabling two factor authentication' do
      let(:institutional_admin) { FactoryBot.create(:user, :institutional_admin)}
      let(:user_at_institution) {  FactoryBot.create(:user, :institutional_user, institution_id: institutional_admin.institution_id) }
      let(:user_of_different_institution) {  FactoryBot.create(:user, :institutional_user) }
      it 'for myself should fail' do # admins are required to use two factor authentication
        institutional_admin.enabled_two_factor = true
        institutional_admin.save!
        get :disable_otp, params: { id: institutional_admin.id }, format: :html
        expect(response.status).to eq(200)
        expect(assigns[:user].enabled_two_factor).to eq true
      end

      it 'for another user at my institution should succeed' do
        user_at_institution.enabled_two_factor = true
        user_at_institution.save!
        get :disable_otp, params: { id: user_at_institution.id }, format: :html
        expect(response.status).to eq(200)
        expect(assigns[:user].enabled_two_factor).to eq false
      end

      it 'for another user not at my institution should not succeed' do
        user_of_different_institution.enabled_two_factor = true
        user_of_different_institution.save!
        get :disable_otp, params: { id: user_of_different_institution.id }, format: :json
        expect(response.status).to eq(403)
      end
    end

    describe 'generating backup two factor authentication codes' do
      let(:institutional_admin) { FactoryBot.create(:user, :institutional_admin)}
      let(:user_at_institution) {  FactoryBot.create(:user, :institutional_user, institution_id: institutional_admin.institution_id) }
      let(:user_of_different_institution) {  FactoryBot.create(:user, :institutional_user) }

      it 'for myself should succeed' do
        old_codes = institutional_admin.generate_otp_backup_codes!
        institutional_admin.save!
        get :generate_backup_codes, params: { id: institutional_admin.id }, format: :json
        expect(response.status).to eq(200)
        expect(assigns[:codes[0]]).not_to eq old_codes[0]
      end

      it 'for another user at my institution should succeed' do
        old_codes = user_at_institution.generate_otp_backup_codes!
        user_at_institution.save!
        get :generate_backup_codes, params: { id: user_at_institution.id }, format: :json
        expect(response.status).to eq(200)
        expect(assigns[:codes[0]]).not_to eq old_codes[0]
      end

      it 'for another user not at my institution should not succeed' do
        old_codes = user_of_different_institution.generate_otp_backup_codes!
        user_of_different_institution.save!
        get :generate_backup_codes, params: { id: user_of_different_institution.id }, format: :json
        expect(response.status).to eq(403)
      end
    end

    describe 'updating password' do
      let(:institutional_admin) { FactoryBot.create(:user, :institutional_admin, initial_password_updated: false, password: 'testpassword')}

      it 'for myself should succeed and update initial_password_updated if false' do
        get :update_password, params: { id: institutional_admin.id, user: { password: 'newpassword', password_confirmation: 'newpassword', current_password: 'testpassword' } }
        expect(response.status).to eq(302)
        expect(assigns[:user].initial_password_updated).to eq true
        expect(assigns[:user].email_verified).to eq true
      end

      it 'should not work if the password is the same as one of a previous three passwords' do
        get :update_password, params: { id: institutional_admin.id, user: { password: 'newpassword', password_confirmation: 'newpassword', current_password: 'testpassword' } }
        expect(response.status).to eq(302)
        get :update_password, params: { id: institutional_admin.id, user: { password: 'testpassword', password_confirmation: 'testpassword', current_password: 'newpassword' } }
        expect(assigns(:user).errors[:password]).to eq ['was used previously.']
      end
    end

    describe 'verifying email' do
      let(:institutional_admin) { FactoryBot.create(:user, :institutional_admin, email_verified: false)}

      it '#GET verify email should send an email with instructions on verifying my email address' do
        get :verify_email, params: { id: institutional_admin.id }
        expect(response.status).to eq(200)
        email = ActionMailer::Base.deliveries.last
        token = ConfirmationToken.where(user_id: institutional_admin.id).first
        expect(email.body.encoded).to include("http://localhost:3000/users/#{institutional_admin.id}/email_confirmation?confirmation_token=#{token.token}")
      end

      it '#GET email_confirmation should succeed if confirmation token is correct and update email_verified' do
        get :verify_email, params: { id: institutional_admin.id }
        token = ConfirmationToken.where(user_id: institutional_admin.id).first
        get :email_confirmation, params: { id: institutional_admin.id, confirmation_token: token.token }
        expect(response.status).to eq(200)
        expect(assigns[:user].email_verified).to eq true
        expect(flash[:notice]).to eq 'Your email has been successfully verified.'
      end

      it '#GET email_confirmation should fail if token is incorrect' do
        get :verify_email, params: { id: institutional_admin.id }
        token = ConfirmationToken.where(user_id: institutional_admin.id).first
        get :email_confirmation, params: { id: institutional_admin.id, confirmation_token: SecureRandom.hex }
        expect(response.status).to eq(200)
        expect(assigns[:user].email_verified).to eq false
        expect(flash[:error]).to eq 'Invalid confirmation token.'
      end
    end

    describe 'forcing a user to update their password' do
      let(:institutional_admin) { FactoryBot.create(:user, :institutional_admin, force_password_update: false)}
      let(:user_at_institution) {  FactoryBot.create(:user, :institutional_user, institution_id: institutional_admin.institution_id, force_password_update: false) }
      let(:user_of_different_institution) {  FactoryBot.create(:user, :institutional_user, force_password_update: false) }

      it 'at my own institution should succeed' do
        get :forced_password_update, params: { id: user_at_institution.id }
        expect(response.status).to eq(302)
        expect(assigns[:user].force_password_update).to eq true
        expect(flash[:notice]).to eq "#{assigns[:user].name} will be forced to change their password upon next login."
      end

      it 'at another institution should not succeed' do
        get :forced_password_update, params: { id: user_of_different_institution.id }, format: :json
        expect(response.status).to eq(403)
      end
    end

  end

  describe 'An Institutional User' do
    let!(:user) { FactoryBot.create(:user, :institutional_user)}
    let!(:other_user) { FactoryBot.create(:user, :institutional_user) }
    before do
      sign_in user
      session[:verified] = true
    end

    it 'generates a new API key' do
      patch :generate_api_key, params: { id: user.id }
      user.reload

      expect(assigns[:user]).to eq user
      response.should redirect_to user_path(user)
      expect(assigns[:user].api_secret_key).to_not be_nil
      expect(user.encrypted_api_secret_key).to_not be_nil
      flash[:notice].should =~ /#{assigns[:user].api_secret_key}/
    end

    it 'prints a message if it is unable to make the key' do
      User.any_instance.should_receive(:save).and_return(false)
      patch :generate_api_key, params: { id: user.id }
      user.reload

      response.should redirect_to user_path(user)
      expect(flash[:alert]).to eq 'ERROR: Unable to create API key.'
      expect(user.api_secret_key).to be_nil
      expect(user.encrypted_api_secret_key).to be_nil
    end

    it 'should not be able to perform vacuum operations' do
      get :vacuum, params: { vacuum_target: 'snapshots' }, format: :json
      expect(response.status).to eq(403)
    end

    it 'should not be able to send a stale user notification' do
      get :stale_user_notification, format: :json
      expect(response.status).to eq(403)
    end

    it 'should not be able to perform yearly account confirmations' do
      get :account_confirmations, format: :json
      expect(response.status).to eq(403)
    end

    it 'should be able to resend an account confirmation email for themselves' do
      get :indiv_confirmation_email, params: { id: user }
      expect(response.status).to eq(302)
      expect(assigns[:user].account_confirmed).to eq false
      token = ConfirmationToken.where(user_id: assigns[:user].id).first
      expect(token).not_to be_nil
      email = ActionMailer::Base.deliveries.last
      expect(email.body.encoded).to include('You will have two weeks to confirm your account before your account will be deactivated.')
      expect(email.body.encoded).to include("http://localhost:3000/users/#{assigns[:user].id}/confirm_account?confirmation_token=#{token.token}")
    end

    it 'should not be able to resend an account confirmation email for someone else' do
      get :indiv_confirmation_email, params: { id: other_user }, format: :json
      expect(response.status).to eq(403)
    end

    it 'should properly confirm an account once the confirmation link has been clicked' do
      get :indiv_confirmation_email, params: { id: user }
      token = ConfirmationToken.where(user_id: assigns[:user].id).first
      expect(assigns[:user].account_confirmed).to eq false
      get :confirm_account, params: { id: user, confirmation_token: token.token }
      expect(assigns[:user].account_confirmed).to eq true
      expect(response.status).to eq(302)
      expect(flash[:notice]).to eq 'Your account has been confirmed for the next year.'
    end

    it 'should not be able to deactivate users' do
      get :deactivate, params: { id: user.id }, format: :json
      expect(response.status).to eq(403)
    end

    it 'should not be able to reactivate users' do
      get :reactivate, params: { id: user.id }, format: :json
      expect(response.status).to eq(403)
    end

    describe 'enabling two factor authentication' do
      it 'for myself should succeed' do
        user.enabled_two_factor = false
        user.save!
        get :enable_otp, params: { id: user.id, phone_number: '8055559014' }, format: :json
        expect(response.status).to eq(200)
        expect(assigns[:user].enabled_two_factor).to eq true
        expect(assigns[:codes]).not_to be_nil
      end

      it 'for another user should not succeed' do
        other_user.enabled_two_factor = false
        other_user.save!
        get :enable_otp, params: { id: other_user.id, phone_number: '8055559014' }, format: :json
        expect(response.status).to eq(403)
      end
    end

    describe 'disabling two factor authentication' do
      it 'for myself should succeed' do
        user.enabled_two_factor = true
        user.save!
        get :disable_otp, params: { id: user.id }, format: :html
        expect(response.status).to eq(200)
        expect(assigns[:user].enabled_two_factor).to eq false
      end

      it 'for myself should fail if I am required to use 2FA' do
        user.enabled_two_factor = true
        user.institution.otp_enabled = true
        user.save!
        user.institution.save!
        get :disable_otp, params: { id: user.id }, format: :html
        expect(response.status).to eq(200)
        expect(assigns[:user].enabled_two_factor).to eq true
      end

      it 'for another user should not succeed' do
        other_user.enabled_two_factor = true
        other_user.save!
        get :disable_otp, params: { id: other_user.id }, format: :json
        expect(response.status).to eq(403)
      end
    end

    describe 'generating backup two factor authentication codes' do
      it 'for myself should succeed' do
        old_codes = user.generate_otp_backup_codes!
        user.save!
        get :generate_backup_codes, params: { id: user.id }, format: :json
        expect(response.status).to eq(200)
        expect(assigns[:codes[0]]).not_to eq old_codes[0]
      end

      it 'for another user should not succeed' do
        old_codes = other_user.generate_otp_backup_codes!
        other_user.save!
        get :generate_backup_codes, params: { id: other_user.id }, format: :json
        expect(response.status).to eq(403)
      end

    end

    describe 'updating password' do
      let(:user) { FactoryBot.create(:user, :institutional_admin, initial_password_updated: false, password: 'testpassword')}

      it 'for myself should succeed and update initial_password_updated if false' do
        get :update_password, params: { id: user.id, user: { password: 'newpassword', password_confirmation: 'newpassword', current_password: 'testpassword' } }
        expect(response.status).to eq(302)
        expect(assigns[:user].initial_password_updated).to eq true
        expect(assigns[:user].email_verified).to eq true
      end
    end

    describe 'verifying email' do
      let(:user) { FactoryBot.create(:user, :institutional_admin, email_verified: false)}

      it '#GET verify email should send an email with instructions on verifying my email address' do
        get :verify_email, params: { id: user.id }
        expect(response.status).to eq(200)
        email = ActionMailer::Base.deliveries.last
        token = ConfirmationToken.where(user_id: user.id).first
        expect(email.body.encoded).to include("http://localhost:3000/users/#{user.id}/email_confirmation?confirmation_token=#{token.token}")
      end

      it '#GET email_confirmation should succeed if confirmation token is correct and update email_verified' do
        get :verify_email, params: { id: user.id }
        token = ConfirmationToken.where(user_id: user.id).first
        get :email_confirmation, params: { id: user.id, confirmation_token: token.token }
        expect(response.status).to eq(200)
        expect(assigns[:user].email_verified).to eq true
        expect(flash[:notice]).to eq 'Your email has been successfully verified.'
      end

      it '#GET email_confirmation should fail if token is incorrect' do
        get :verify_email, params: { id: user.id }
        token = ConfirmationToken.where(user_id: user.id).first
        get :email_confirmation, params: { id: user.id, confirmation_token: SecureRandom.hex }
        expect(response.status).to eq(200)
        expect(assigns[:user].email_verified).to eq false
        expect(flash[:error]).to eq 'Invalid confirmation token.'
      end
    end

  end
end
