require 'spec_helper'

RSpec.describe InstitutionsController, type: :controller do
  before :all do
    GenericFile.delete_all
    IntellectualObject.delete_all
    User.delete_all
    Institution.delete_all
    WorkItem.delete_all
    BulkDeleteJob.delete_all
  end

  after do
    GenericFile.delete_all
    IntellectualObject.delete_all
    User.delete_all
    Institution.delete_all
    WorkItem.delete_all
    BulkDeleteJob.delete_all
  end

  let(:institution_one) { FactoryBot.create(:member_institution) }
  let(:institution_two) { FactoryBot.create(:member_institution) }
  let(:institution_three) { FactoryBot.create(:member_institution) }

  let(:institution_four) { FactoryBot.create(:member_institution, identifier: 'has-a-dash.and-more.edu') }
  let(:institution_five) { FactoryBot.create(:member_institution, identifier: 'virginia.edu') }
  let(:institution_six) { FactoryBot.create(:member_institution, identifier: 'test-virginia.edu') }
  let(:institution_seven) { FactoryBot.create(:member_institution, identifier: 'somewhere-test-virginia.edu') }
  let(:institution_eight) { FactoryBot.create(:member_institution, identifier: 'sub.virginia.edu') }

  let(:admin_user) { FactoryBot.create(:user, :admin, institution_id: institution_one.id, encrypted_api_secret_key: '1234-5678') }
  let(:institutional_user) { FactoryBot.create(:user, :institutional_user, institution_id: institution_two.id) }
  let(:institutional_admin) { FactoryBot.create(:user, :institutional_admin, institution_id: institution_three.id) }
  let(:object_one) { FactoryBot.create(:intellectual_object, institution: institution_one)}
  let(:object_two) { FactoryBot.create(:intellectual_object, institution: institution_two)}
  let(:object_three) { FactoryBot.create(:intellectual_object, institution: institution_three)}
  let(:file_one) { FactoryBot.create(:generic_file, intellectual_object: object_one) }
  let(:file_two) { FactoryBot.create(:generic_file, intellectual_object: object_two) }
  let(:file_three) { FactoryBot.create(:generic_file, intellectual_object: object_three) }

  describe 'GET #index' do
    describe 'for admin users' do
      before do
        sign_in admin_user
        session[:verified] = true
      end

      it 'responds successfully with an HTTP 200 status code' do
        get :index
        expect(response).to be_successful
      end

      it 'renders the index template' do
        get :index
        expect(response).to render_template('index')
      end

      it 'assigns all institutions as @institutions' do
        get :index
        assigns(:institutions).should include(admin_user.institution)
      end
    end
  end

  describe 'GET #index for admin API' do
    describe 'for admin users' do
      before do
        sign_in admin_user
        session[:verified] = true
      end

      it 'returns bucket names for all @institutions' do
        get :index, format: :json
        assigns(:institutions).should include(admin_user.institution)
        data = JSON.parse(response.body)
        data['results'].each do |inst|
          expect(inst['receiving_bucket']).to include(".receiving.")
          expect(inst['restore_bucket']).to include(".restore.")
        end
      end

      it 'filters by bucket name' do
        get :index, format: :json, params: { receiving_bucket: admin_user.institution.receiving_bucket }
        assigns(:institutions).should include(admin_user.institution)
        assigns(:institutions).should_not include(institutional_admin.institution)

        get :index, format: :json, params: { receiving_bucket: institutional_admin.institution.receiving_bucket }
        assigns(:institutions).should include(institutional_admin.institution)
        assigns(:institutions).should_not include(admin_user.institution)
      end

    end
  end


  describe 'GET #new' do
    describe 'for admin users' do
      before do
        sign_in admin_user
        session[:verified] = true
      end

      it 'responds successfully' do
        get :new
        expect(response).to be_successful
      end
    end
  end

  describe 'GET #show' do
    describe 'for admin user' do
      before do
        sign_in admin_user
        session[:verified] = true
      end

      it 'responds successfully with an HTTP 200 status code' do
        get :show, params: { institution_identifier: admin_user.institution.to_param }
        expect(response).to be_successful
        expect(response.status).to eq(200)
      end

      it 'responds with 200 status code when identifier contains dashes' do
        [institution_four, institution_five, institution_six, institution_seven, institution_eight].each do |inst|
          get :show, params: { institution_identifier: inst.identifier }
          expect(response).to be_successful
          expect(response.status).to eq(200)
        end
      end

      it 'renders the show template' do
        get :show, params: { institution_identifier: admin_user.institution.to_param }
        expect(response).to render_template('show')
      end

      it 'assigns the requested institution as @institution' do
        get :show, params: { institution_identifier: admin_user.institution.to_param }
        assigns(:institution).should eq( admin_user.institution)
      end

    end

    describe 'for institutional_admin user' do
      before do
        sign_in institutional_admin
        session[:verified] = true
      end

      it 'responds successfully with an HTTP 200 status code' do
        get :show, params: { institution_identifier: institutional_admin.institution.to_param }
        expect(response).to be_successful
        expect(response.status).to eq(200)
      end

      it 'renders the show template' do
        get :show, params: { institution_identifier: institutional_admin.institution.to_param }
        expect(response).to render_template('show')
      end

      it 'assigns the requested institution as @institution' do
        get :show, params: { institution_identifier: institutional_admin.institution.to_param }
        assigns(:institution).should eq(institutional_admin.institution)
      end
    end

    describe 'for institutional_user user' do
      before do
        sign_in institutional_user
        session[:verified] = true
      end
      it 'responds successfully with an HTTP 200 status code' do
        get :show, params: { institution_identifier: institutional_user.institution.to_param }
        expect(response).to be_successful
        expect(response.status).to eq(200)
      end

      it 'renders the show template' do
        get :show, params: { institution_identifier: institutional_user.institution.to_param }
        expect(response).to render_template('show')
      end

      it 'assigns the requested institution as @institution' do
        get :show, params: { institution_identifier: institutional_user.institution.to_param }
        assigns(:institution).should eq(institutional_user.institution)
      end
    end

    describe 'for an API user' do
      before do
        sign_in admin_user
        session[:verified] = true
      end
      it 'responds successfully with an HTTP 200 status code' do
        get :show, params: { institution_identifier: admin_user.institution.identifier }
        expect(response).to be_successful
        expect(response.status).to eq(200)
        assigns(:institution).should eq(admin_user.institution)
        assigns(:institution).receiving_bucket.should eq(admin_user.institution.receiving_bucket)
        assigns(:institution).restore_bucket.should eq(admin_user.institution.restore_bucket)
      end

      it 'should provide a 404 code when an incorrect identifier is provided' do
        get :show, params: { institution_identifier: CGI.escape('notreal.edu') }, format: 'json'
        expect(response.status).to eq(404)
      end
    end
  end

  describe 'GET #show for admin API' do
    describe 'for admin users' do
      before do
        sign_in admin_user
        session[:verified] = true
      end

      it 'returns an institution with bucket names' do
        get :show, params: { institution_identifier: institutional_user.institution.to_param }, format: :json
        assigns(:institution).id.should equal(institutional_user.institution.id)
        data = JSON.parse(response.body)
        expect(data['receiving_bucket']).to include('aptrust.receiving.test')
        expect(data['restore_bucket']).to include('aptrust.restore.test')
      end
    end
  end

  describe 'GET edit' do
    after { inst1.destroy }

    describe 'when not signed in' do
      let(:inst1) { FactoryBot.create(:member_institution) }
      let(:inst2) { FactoryBot.create(:subscription_institution) }

      it 'should redirect to login for member institutions' do
        get :edit, params: { institution_identifier: inst1 }
        expect(response).to redirect_to root_url + 'users/sign_in'
      end

      it 'should redirect to login for subscriber institutions' do
        get :edit, params: { institution_identifier: inst2 }
        expect(response).to redirect_to root_url + 'users/sign_in'
      end
    end

    describe 'when signed in' do
      after { user.destroy }

      describe 'as an institutional_user' do
        let(:inst1) { FactoryBot.create(:member_institution) }
        let(:inst2) { FactoryBot.create(:subscription_institution) }
        let(:user) { FactoryBot.create(:user, :institutional_user, institution_id: inst1.id) }
        before do
          sign_in user
          session[:verified] = true
        end

        it 'should be unauthorized for member institutions' do
          get :edit, params: { institution_identifier: inst1 }
          expect(response).to redirect_to root_url
          expect(flash[:alert]).to eq 'You are not authorized to access this page.'
        end

        it 'should be unauthorized for subscription institutions' do
          get :edit, params: { institution_identifier: inst2 }
          expect(response).to redirect_to root_url
          expect(flash[:alert]).to eq 'You are not authorized to access this page.'
        end
      end

      describe 'as an institutional_admin' do
        let(:inst1) { FactoryBot.create(:member_institution) }
        let(:inst2) { FactoryBot.create(:member_institution) }
        let(:inst3) { FactoryBot.create(:subscription_institution) }
        let(:inst4) { FactoryBot.create(:subscription_institution) }
        let(:user) { FactoryBot.create(:user, :institutional_admin, institution_id: inst1.id) }
        let(:user2) { FactoryBot.create(:user, :institutional_admin, institution_id: inst3.id) }
        #before do
        #   sign_in user
        #   session[:verified] = true
        # }

        describe 'editing my own institution' do
          it 'should show the institution edit form for member institutions' do
            sign_in user
            session[:verified] = true
            get :edit, params: { institution_identifier: inst1 }
            expect(response).to be_successful
          end

          it 'should show the institution edit form for subscription institutions' do
            sign_in user2
            session[:verified] = true
            get :edit, params: { institution_identifier: inst3 }
            expect(response).to be_successful
          end
        end

        describe 'editing an institution other than my own' do
          it 'should be unauthorized for member institutions' do
            sign_in user
            session[:verified] = true
            get :edit, params: { institution_identifier: inst2 }
            expect(response).to redirect_to root_url
            expect(flash[:alert]).to eq 'You are not authorized to access this page.'
          end

          it 'should be unauthorized for subscription institutions' do
            sign_in user2
            session[:verified] = true
            get :edit, params: { institution_identifier: inst4 }
            expect(response).to redirect_to root_url
            expect(flash[:alert]).to eq 'You are not authorized to access this page.'
          end
        end
      end

      describe 'as an admin' do
        let(:inst1) { FactoryBot.create(:member_institution) }
        let(:inst2) { FactoryBot.create(:subscription_institution) }
        let(:user) { FactoryBot.create(:user, :admin, institution_id: inst1.id) }
        before do
          sign_in user
          session[:verified] = true
        end

        it 'should show the institution edit form for member institutions' do
          get :edit, params: { institution_identifier: inst1 }
          expect(response).to be_successful
        end

        it 'should show the institution edit form for subscriptions institutions' do
          get :edit, params: { institution_identifier: inst2 }
          expect(response).to be_successful
        end
      end
    end
  end


  describe 'GET #deposit_summary for admin API' do
    describe 'for admin users' do
      before do
        sign_in admin_user
        session[:verified] = true
      end

      it 'returns deposit stats for all institutions' do
        get :deposit_summary, params: { end_date: '2098-12-31' }, format: :json
        data = JSON.parse(response.body)
        expect(data['end_date']).to eq('2098-12-31')
        expect(data['institutions'].keys.length).to eq(Institution.all.count)
        data['institutions'].each do |key, value|
          expect(key.length).to be > 4
          expect(value).to be >= 0
        end
      end
    end
  end



  describe 'PATCH update' do

    describe 'when not signed in' do
      let(:inst1) { FactoryBot.create(:member_institution) }
      let(:inst2) { FactoryBot.create(:subscription_institution) }
      it 'should redirect to login for member institutions' do
        patch :update, params: { institution_identifier: inst1, institution: {name: 'Foo' } }
        expect(response).to redirect_to root_url + 'users/sign_in'
      end

      it 'should redirect to login for subscription institutions' do
        patch :update, params: { institution_identifier: inst2, institution: {name: 'Foo' } }
        expect(response).to redirect_to root_url + 'users/sign_in'
      end
    end

    describe 'when signed in' do
      let(:user) { FactoryBot.create(:user, :admin) }
      let(:inst1) { FactoryBot.create(:member_institution) }
      let(:inst2) { FactoryBot.create(:subscription_institution) }
      before do
        sign_in user
        session[:verified] = true
      end

      it 'should update fields for member institutions' do
        patch :update, params: { institution_identifier: inst1, institution: {name: 'Foo'} }
        expect(response).to redirect_to institution_path(inst1)
        expect(assigns(:institution).name).to eq 'Foo'
      end

      it 'should update fields for subscription institutions' do
        patch :update, params: { institution_identifier: inst2, institution: {name: 'Foo'} }
        expect(response).to redirect_to institution_path(inst2)
        expect(assigns(:institution).name).to eq 'Foo'
      end

      it 'should ignore updates to read only fields' do
        test_inst = FactoryBot.create(:member_institution, identifier: 'test.edu')
        patch :update, params: { institution_identifier: test_inst, institution: {name: 'Foo', identifier: 'foo.edu',
                                                                                  receiving_bucket: 'something.else.foo.edu',
                                                                                  restore_bucket: 'something.restore.foo.edu' } }
        expect(assigns(:institution).name).to eq 'Foo'
        expect(assigns(:institution).identifier).not_to eq 'foo.edu'
        expect(assigns(:institution).receiving_bucket).not_to eq 'something.else.foo.edu'
        expect(assigns(:institution).receiving_bucket).to eq "#{Pharos::Application.config.pharos_receiving_bucket_prefix}test.edu"
        expect(assigns(:institution).restore_bucket).not_to eq 'something.restore.foo.edu'
        expect(assigns(:institution).restore_bucket).to eq "#{Pharos::Application.config.pharos_restore_bucket_prefix}test.edu"
      end
    end
  end

  describe 'POST create' do
    describe 'with admin user' do
      let (:current_member) { FactoryBot.create(:member_institution) }
      let (:attributes) { FactoryBot.attributes_for(:member_institution) }
      let (:attributes2) { FactoryBot.attributes_for(:subscription_institution, member_institution_id: current_member.id) }
      let (:attributes3) { FactoryBot.attributes_for(:member_institution, receiving_bucket: nil, restore_bucket: nil) }
      let (:attributes4) { FactoryBot.attributes_for(:member_institution, receiving_bucket: 'something.delete.test.edu', restore_bucket: 'something.test.edu') }

      before do
        sign_in admin_user
        session[:verified] = true
        current_member.save! #needs to be instantiated before the test below
      end

      it 'should reject when there are no parameters' do
        expect {
          post :create, params: {}
        }.to raise_error ActionController::ParameterMissing
      end

      it 'should accept good parameters for member institutions' do
        expect {
          post :create, params: { institution: attributes }
        }.to change(Institution, :count).by(1)
        response.should redirect_to institution_url(assigns[:institution])
        assigns[:institution].should be_kind_of Institution
      end

      it 'should accept good parameters for subscription institutions' do
        expect {
          post :create, params: { institution: attributes2 }
        }.to change(Institution, :count).by(1)
        response.should redirect_to institution_url(assigns[:institution])
        assigns[:institution].should be_kind_of Institution
      end

      it 'should successfully set bucket names when none are given in the creation params' do
        expect {
          post :create, params: { institution: attributes3 }
        }.to change(Institution, :count).by(1)
        response.should redirect_to institution_url(assigns[:institution])
        assigns[:institution].should be_kind_of Institution
        inst = assigns[:institution]
        expect(inst.receiving_bucket).to eq "#{Pharos::Application.config.pharos_receiving_bucket_prefix}#{inst.identifier}"
        expect(inst.restore_bucket).to eq "#{Pharos::Application.config.pharos_restore_bucket_prefix}#{inst.identifier}"
      end

      it 'should override bucket names given in the parameters and set expected ones' do
        expect {
          post :create, params: { institution: attributes4 }
        }.to change(Institution, :count).by(1)
        response.should redirect_to institution_url(assigns[:institution])
        assigns[:institution].should be_kind_of Institution
        inst = assigns[:institution]
        expect(inst.receiving_bucket).not_to eq 'something.delete.test.edu'
        expect(inst.restore_bucket).not_to eq 'something.test.edu'
        expect(inst.receiving_bucket).to eq "#{Pharos::Application.config.pharos_receiving_bucket_prefix}#{inst.identifier}"
        expect(inst.restore_bucket).to eq "#{Pharos::Application.config.pharos_restore_bucket_prefix}#{inst.identifier}"
      end
    end

    describe 'with institutional admin user' do
      let (:current_member) { FactoryBot.create(:member_institution) }
      let (:attributes) { FactoryBot.attributes_for(:member_institution) }
      let (:attributes2) { FactoryBot.attributes_for(:subscription_institution, member_institution_id: current_member.id) }
      before do
        sign_in institutional_admin
        session[:verified] = true
        #current_member.save! #needs to be instantiated before the test below
      end

      it 'should be unauthorized for member institutions' do
        expect {
          post :create, params: { institution: attributes }
        }.to_not change(Institution, :count)
        expect(response).to redirect_to root_path
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end

      it 'should be unauthorized for subscription institutions' do
        current_member.save!
        expect {
          post :create, params: { institution: attributes2 }
        }.to_not change(Institution, :count)
        expect(response).to redirect_to root_path
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
    end
  end

  describe 'GET single_snapshot' do
    describe 'for admin user' do
      before do
        sign_in admin_user
        session[:verified] = true
      end

      it 'responds successfully and creates a snapshot' do
        get :single_snapshot, params: { institution_identifier: admin_user.institution.to_param }
        #expect(response).to be_successful
        expect(response.status).to eq(302)
        expect(flash[:notice]).to eq "A snapshot of #{admin_user.institution.name} has been taken and archived on #{assigns(:snapshots).first.audit_date}. Please see the reports page for that analysis."
        expect(assigns(:snapshots).first.apt_bytes).to eq 0
        expect(assigns(:snapshots).first.cost).to eq 0.00
      end

    end

    describe 'for institutional_admin user' do
      before do
        sign_in institutional_admin
        session[:verified] = true
      end

      it 'responds unauthorized' do
        get :single_snapshot, params: { institution_identifier: institutional_admin.institution.to_param }
        expect(response).to redirect_to root_path
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end

    end

    describe 'for institutional_user user' do
      before do
        sign_in institutional_user
        session[:verified] = true
      end

      it 'responds unauthorized' do
        get :single_snapshot, params: { institution_identifier: institutional_user.institution.to_param }
        expect(response).to redirect_to root_path
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
    end
  end

  describe 'GET group_snapshot' do
    describe 'for admin user' do
      before do
        sign_in admin_user
        session[:verified] = true
      end

      it 'responds successfully and creates a snapshot' do
        get :group_snapshot, params: { }
        expect(response.status).to eq(302)
        expect(flash[:notice]).to eq "A snapshot of all Member Institutions has been taken and archived on #{assigns(:snapshots).first.first.audit_date}. Please see the reports page for that analysis."
        expect(assigns(:snapshots).first.first.apt_bytes).to eq 0
        expect(assigns(:snapshots).first.first.cost).to eq 0.00
        email = ActionMailer::Base.deliveries.last
        expect(email.body.encoded).to include("Here are the latest snapshot results for the #{Rails.env.capitalize} repository broken down by institution.")
      end

      it 'responds successfully and creates a snapshot (JSON)' do
        get :group_snapshot, params: { }, format: :json
        expect(response).to be_successful
        expect(assigns(:snapshots).first.first.apt_bytes).to eq 0
        expect(assigns(:snapshots).first.first.cost).to eq 0.00
        data = JSON.parse(response.body)
        expect(data['snapshots'][0][0].has_key?('institution_id')).to be true
        expect(data['snapshots'][0][1].has_key?('institution_id')).to be true
        email = ActionMailer::Base.deliveries.last
        expect(email.body.encoded).to include("Here are the latest snapshot results for the #{Rails.env.capitalize} repository broken down by institution.")
      end
    end

    describe 'for institutional_admin user' do
      before do
        sign_in institutional_admin
        session[:verified] = true
      end

      it 'responds unauthorized' do
        get :group_snapshot, params: { }
        expect(response).to redirect_to root_path
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end

    end

    describe 'for institutional_user user' do
      before do
        sign_in institutional_user
        session[:verified] = true
      end

      it 'responds unauthorized' do
        get :group_snapshot, params: { }
        expect(response).to redirect_to root_path
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
    end
  end

  describe 'GET deactivate' do
    describe 'for admin user' do
      before do
        sign_in admin_user
        session[:verified] = true
      end

      it 'responds successfully and deactivates the institution and associated users' do
        institution_two.name
        institutional_user.name
        get :deactivate, params: { institution_identifier: institution_two.identifier }
        expect(response).to be_successful
        expect(flash[:notice]).to eq "All users at #{institution_two.name} have been deactivated."
        expect(assigns[:institution]).to eq institution_two
        expect(assigns[:institution].deactivated_at).not_to be_nil
        expect(assigns[:institution].deactivated?).to eq true
        expect(assigns[:institution].users.first.deactivated?).to eq true
        expect(assigns[:institution].users.first.deactivated_at).not_to be_nil
        expect(assigns[:institution].users.first.encrypted_api_secret_key).to eq ''
      end

    end

    describe 'for institutional_admin user' do
      before do
        sign_in institutional_admin
        session[:verified] = true
      end

      it 'responds unauthorized' do
        get :deactivate, params: { institution_identifier: institutional_admin.institution.to_param }
        expect(response).to redirect_to root_path
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end

    end

    describe 'for institutional_user user' do
      before do
        sign_in institutional_user
        session[:verified] = true
      end

      it 'responds unauthorized' do
        get :deactivate, params: { institution_identifier: institutional_user.institution.to_param }
        expect(response).to redirect_to root_path
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
    end
  end

  describe 'GET reactivate' do
    describe 'for admin user' do
      before do
        sign_in admin_user
        session[:verified] = true
      end

      it 'responds successfully and reactivates the institution and associated users' do
        get :deactivate, params: { institution_identifier: institution_one.identifier }
        expect(assigns[:institution]).to eq institution_one
        expect(assigns[:institution].deactivated_at).not_to be_nil
        expect(assigns[:institution].deactivated?).to eq true
        expect(assigns[:institution].users.first.deactivated?).to eq true
        expect(assigns[:institution].users.first.deactivated_at).not_to be_nil
        expect(assigns[:institution].users.first.encrypted_api_secret_key).to eq ''
        get :reactivate, params: { institution_identifier: institution_one.to_param }
        expect(response).to be_successful
        expect(flash[:notice]).to eq "All users at #{admin_user.institution.name} have been reactivated."
        expect(assigns[:institution]).to eq institution_one
        expect(assigns[:institution].deactivated_at).to be_nil
        expect(assigns[:institution].deactivated?).to eq false
        expect(assigns[:institution].users.first.deactivated?).to eq false
        expect(assigns[:institution].users.first.deactivated_at).to be_nil
        expect(assigns[:institution].users.first.encrypted_api_secret_key).to eq ''
      end

    end

    describe 'for institutional_admin user' do
      before do
        sign_in institutional_admin
        session[:verified] = true
      end

      it 'responds unauthorized' do
        get :reactivate, params: { institution_identifier: institutional_admin.institution.to_param }
        expect(response).to redirect_to root_path
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end

    end

    describe 'for institutional_user user' do
      before do
        sign_in institutional_user
        session[:verified] = true
      end

      it 'responds unauthorized' do
        get :reactivate, params: { institution_identifier: institutional_user.institution.to_param }
        expect(response).to redirect_to root_path
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
    end
  end

  describe 'GET mass_force_password_update' do
    describe 'for institutional_admin' do
      before do
        sign_in admin_user
        session[:verified] = true
      end

      it 'responds successfully and sets all associated users to need a password update' do
        5.times do
          FactoryBot.create(:user, :institutional_user, institution_id: admin_user.institution.id)
        end
        get :mass_forced_password_update, params: { institution_identifier: admin_user.institution.to_param }
        expect(response).to redirect_to institution_path(admin_user.institution)
        expect(flash[:notice]).to eq "All users at #{admin_user.institution.name} will be forced to change their password upon next login. If you forced password changes at your own institution, you will not be forced to change your own password but it is highly encouraged."
        admin_user.institution.users.each do |usr|
          expect(usr.force_password_update).to eq true unless usr.id == admin_user.id
        end
      end
    end

    describe 'for institutional_admin user' do
      before do
        sign_in institutional_admin
        session[:verified] = true
      end

      it 'responds successfully' do
        get :mass_forced_password_update, params: { institution_identifier: institutional_admin.institution.to_param }
        expect(response).to redirect_to institution_path(institutional_admin.institution)
        expect(flash[:notice]).to eq "All users at #{institutional_admin.institution.name} will be forced to change their password upon next login. If you forced password changes at your own institution, you will not be forced to change your own password but it is highly encouraged."
      end

    end

    describe 'for institutional_user user' do
      before do
        sign_in institutional_user
        session[:verified] = true
      end

      it 'responds unauthorized' do
        get :mass_forced_password_update, params: { institution_identifier: institutional_user.institution.to_param }
        expect(response).to redirect_to root_path
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
    end
  end

  describe 'GET enable_otp' do
    describe 'for an institutional admin' do
      before do
        sign_in institutional_admin
        session[:verified] = true
      end

      it 'enables two factor authentication for all users at an institution' do
        get :enable_otp, params: { institution_identifier: institutional_admin.institution.to_param }
        expect(assigns[:institution].otp_enabled).to eq true
      end
    end

    describe 'for institutional_user user' do
      before do
        sign_in institutional_user
        session[:verified] = true
      end

      it 'responds unauthorized' do
        get :enable_otp, params: { institution_identifier: institutional_user.institution.to_param }
        expect(response).to redirect_to root_path
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
    end
  end

  describe 'GET disable_otp' do
    describe 'for an institutional admin' do
      before do
        sign_in institutional_admin
        session[:verified] = true
      end

      it 'allows two factor authentication to be turned off for all users at an institution' do
        get :enable_otp, params: { institution_identifier: institutional_admin.institution.to_param }
        get :disable_otp, params: { institution_identifier: institutional_admin.institution.to_param }
        expect(assigns[:institution].otp_enabled).to eq false
      end
    end

    describe 'for institutional_user user' do
      before do
        sign_in institutional_user
        session[:verified] = true
      end

      it 'responds unauthorized' do
        get :disable_otp, params: { institution_identifier: institutional_user.institution.to_param }
        expect(response).to redirect_to root_path
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
    end
  end

  describe 'POST trigger_bulk_delete' do
    describe 'for admin user' do
      before do
        sign_in admin_user
        session[:verified] = true
      end

      it 'responds successfully and sends an email to an institutional admin asking for confirmation of a bulk delete' do
        obj1 = FactoryBot.create(:intellectual_object, state: 'A', institution: institution_one)
        obj2 = FactoryBot.create(:intellectual_object, state: 'A', institution: institution_one)
        obj3 = FactoryBot.create(:intellectual_object, state: 'D', institution: institution_one)
        obj4 = FactoryBot.create(:intellectual_object, state: 'A', institution: institution_one)
        obj5 = FactoryBot.create(:intellectual_object, state: 'A', institution: institution_one)
        file1 = FactoryBot.create(:generic_file, intellectual_object: obj4, state: 'A')
        file2 = FactoryBot.create(:generic_file, intellectual_object: obj5, state: 'A')
        file3 = FactoryBot.create(:generic_file, intellectual_object: obj3, state: 'D')
        count_before = Email.all.count
        ident_hash = [obj1.identifier, obj2.identifier, obj3.identifier, file1.identifier, file2.identifier, file3.identifier]
        post :trigger_bulk_delete, params: { institution_identifier: institution_one.identifier }, body: { ident_list: ident_hash }.to_json, format: :json
        expect(assigns[:institution]).to eq institution_one
        expect(assigns[:ident_list].count).to eq 6
        expect(assigns[:bulk_job].intellectual_objects.count).to eq 2
        expect(assigns[:bulk_job].intellectual_objects.map &:identifier).to eq [obj1.identifier, obj2.identifier]
        expect(assigns[:bulk_job].generic_files.count).to eq 2
        expect(assigns[:bulk_job].generic_files.map &:identifier).to eq [file1.identifier, file2.identifier]
        expect(assigns[:forbidden_idents].count).to eq 2
        expect(assigns[:forbidden_idents][obj3.identifier]).to eq 'This item has already been deleted.'
        expect(assigns[:forbidden_idents][file3.identifier]).to eq 'This item has already been deleted.'
        count_after = Email.all.count
        expect(count_after).to eq count_before + 1
        token = ConfirmationToken.where(institution_id: institution_one.id).first
        email = ActionMailer::Base.deliveries.last
        expect(email.body.encoded).to include("http://localhost:3000/#{CGI.escape(institution_one.identifier)}/confirm_bulk_delete_institution?bulk_delete_job_id=#{assigns[:bulk_job].id}&confirmation_token=#{token.token}")
      end

    end

    describe 'for institutional_admin user' do
      before do
        sign_in institutional_admin
        session[:verified] = true
      end

      it 'responds unauthorized' do
        post :trigger_bulk_delete, params: { institution_identifier: institutional_admin.institution.to_param }, format: :html
        expect(response).to redirect_to root_path
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end

    end

    describe 'for institutional_user user' do
      before do
        sign_in institutional_user
        session[:verified] = true
      end

      it 'responds unauthorized' do
        post :trigger_bulk_delete, params: { institution_identifier: institutional_user.institution.to_param }, format: :html
        expect(response).to redirect_to root_path
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
    end
  end

  describe 'POST partial_confirmation_bulk_delete' do
    describe 'for admin user' do
      before do
        sign_in admin_user
        session[:verified] = true
      end

      it 'responds unauthorized' do
        post :partial_confirmation_bulk_delete, params: { institution_identifier: admin_user.institution.to_param }
        expect(response).to redirect_to root_path
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end

    end

    describe 'for institutional_admin user' do
      before do
        sign_in institutional_admin
        session[:verified] = true
      end

      it 'responds successfully and sends an email to aptrust admins requesting additional confirmation' do
        obj1 = FactoryBot.create(:intellectual_object, state: 'A', institution: institution_three)
        obj2 = FactoryBot.create(:intellectual_object, state: 'A', institution: institution_three)
        obj4 = FactoryBot.create(:intellectual_object, state: 'A', institution: institution_three)
        obj5 = FactoryBot.create(:intellectual_object, state: 'A', institution: institution_three)
        file1 = FactoryBot.create(:generic_file, intellectual_object: obj4, state: 'A')
        file2 = FactoryBot.create(:generic_file, intellectual_object: obj5, state: 'A')
        token = FactoryBot.create(:confirmation_token, institution: institution_three)
        apt = FactoryBot.create(:aptrust)
        extra_admin = FactoryBot.create(:user, :admin, institution: apt)
        count_before = Email.all.count
        bulk_job = FactoryBot.create(:bulk_delete_job, institution_id: institution_three.id, requested_by: extra_admin.email)
        bulk_job.intellectual_objects.push(obj1)
        bulk_job.intellectual_objects.push(obj2)
        bulk_job.generic_files.push(file1)
        bulk_job.generic_files.push(file2)
        post :partial_confirmation_bulk_delete, params: { institution_identifier: institution_three.identifier, confirmation_token: token.token, bulk_delete_job_id: bulk_job.id }
        expect(assigns[:institution]).to eq institution_three
        expect(assigns[:bulk_job].institutional_approver).to eq institutional_admin.email
        expect(assigns[:bulk_job].institutional_approval_at).not_to be_nil
        count_after = Email.all.count
        expect(count_after).to eq count_before + 1
        new_token = ConfirmationToken.where(institution_id: institution_three.id).first
        expect(assigns[:institution].confirmation_token).to eq new_token
        expect(new_token.token).not_to eq token.token
        email = ActionMailer::Base.deliveries.last
        expect(email.body.encoded).to include("http://localhost:3000/#{CGI.escape(institution_three.identifier)}/confirm_bulk_delete_admin?bulk_delete_job_id=#{bulk_job.id}&confirmation_token=#{new_token.token}")
      end

      it 'responds unsuccessfully if the confirmation token is invalid' do
        obj1 = FactoryBot.create(:intellectual_object, state: 'A', institution: institution_three)
        obj2 = FactoryBot.create(:intellectual_object, state: 'A', institution: institution_three)
        obj4 = FactoryBot.create(:intellectual_object, state: 'A', institution: institution_three)
        obj5 = FactoryBot.create(:intellectual_object, state: 'A', institution: institution_three)
        file1 = FactoryBot.create(:generic_file, intellectual_object: obj4, state: 'A')
        file2 = FactoryBot.create(:generic_file, intellectual_object: obj5, state: 'A')
        token = FactoryBot.create(:confirmation_token, institution: institution_three)
        apt = FactoryBot.create(:aptrust)
        extra_admin = FactoryBot.create(:user, :admin, institution: apt)
        bulk_job = FactoryBot.create(:bulk_delete_job, institution_id: institution_three.id, requested_by: extra_admin.email)
        bulk_job.intellectual_objects.push(obj1)
        bulk_job.intellectual_objects.push(obj2)
        bulk_job.generic_files.push(file1)
        bulk_job.generic_files.push(file2)
        post :partial_confirmation_bulk_delete, params: { institution_identifier: institution_three.identifier, confirmation_token: SecureRandom.hex, bulk_delete_job_id: bulk_job.id}
        expect(assigns[:institution]).to eq institution_three
        expect(response).to redirect_to institution_url(institution_three)
        expect(flash[:alert]).to eq 'Your bulk deletion event cannot be queued at this time due to an invalid confirmation token. ' +
                                          'Please contact your APTrust administrator for more information.'
      end

    end

    describe 'for institutional_user user' do
      before do
        sign_in institutional_user
        session[:verified] = true
      end

      it 'responds unauthorized' do
        post :partial_confirmation_bulk_delete, params: { institution_identifier: institutional_user.institution.to_param }
        expect(response).to redirect_to root_path
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
    end
  end

  describe 'POST final_confirmation_bulk_delete' do
    describe 'for admin user' do
      before do
        sign_in admin_user
        session[:verified] = true
      end

      it 'responds successfully and queues items for deletion' do
        obj1 = FactoryBot.create(:intellectual_object, state: 'A', institution: institution_three)
        obj2 = FactoryBot.create(:intellectual_object, state: 'A', institution: institution_three)
        count = 0
        5.times do
          count += 1
          FactoryBot.create(:generic_file, identifier: "test.edu/tester/data/file#{count}.pdf", intellectual_object: obj1, state: 'A')
          FactoryBot.create(:generic_file, identifier: "test.edu/tester/data/photo#{count}.pdf", intellectual_object: obj2, state: 'A')
        end
        obj4 = FactoryBot.create(:intellectual_object, state: 'A', institution: institution_three)
        obj5 = FactoryBot.create(:intellectual_object, state: 'A', institution: institution_three)
        file1 = FactoryBot.create(:generic_file, intellectual_object: obj4, state: 'A')
        file2 = FactoryBot.create(:generic_file, intellectual_object: obj5, state: 'A')
        item1 = FactoryBot.create(:ingested_item, object_identifier: obj1.identifier, intellectual_object: obj1)
        item2 = FactoryBot.create(:ingested_item, object_identifier: obj2.identifier, intellectual_object: obj2)
        item3 = FactoryBot.create(:ingested_item, object_identifier: obj4.identifier, intellectual_object: obj4)
        item4 = FactoryBot.create(:ingested_item, object_identifier: obj5.identifier, intellectual_object: obj5)
        apt = FactoryBot.create(:aptrust)
        extra_admin = FactoryBot.create(:user, :admin, institution: apt)
        bulk_job = FactoryBot.create(:bulk_delete_job, institution_id: institution_three.id, requested_by: extra_admin.email, institutional_approver: institutional_admin.email)
        bulk_job.intellectual_objects.push(obj1)
        bulk_job.intellectual_objects.push(obj2)
        bulk_job.generic_files.push(file1)
        bulk_job.generic_files.push(file2)
        token = FactoryBot.create(:confirmation_token, institution: institution_three)
        count_before = Email.all.count
        post :final_confirmation_bulk_delete, params: { institution_identifier: institution_three.identifier, confirmation_token: token.token, bulk_delete_job_id: bulk_job.id }
        assigns[:t].join
        expect(assigns[:institution]).to eq institution_three
        expect(assigns[:bulk_job].institutional_approver).to eq institutional_admin.email
        expect(assigns[:bulk_job].aptrust_approver).to eq admin_user.email
        expect(assigns[:bulk_job].aptrust_approval_at).not_to be_nil
        count_after = Email.all.count
        expect(count_after).to eq count_before + 1
        email = ActionMailer::Base.deliveries.last
        expect(email.body.encoded).to include("This email notification is to inform you that a bulk deletion job requested by #{extra_admin.name}")
        expect(email.body.encoded).to include("and approved by #{institutional_admin.name} and #{admin_user.name}")

        reloaded_object = IntellectualObject.find(obj1.id)
        expect(reloaded_object.state).to eq 'A'
        expect(reloaded_object.premis_events.count).to eq 0
        delete_items = WorkItem.with_action('Delete').with_object_identifier(reloaded_object.identifier)
        expect(delete_items.count).to eq 5
        expect(delete_items[0].inst_approver).to eq institutional_admin.email
        expect(delete_items[0].aptrust_approver).to eq admin_user.email
        expect(delete_items[1].inst_approver).to eq institutional_admin.email
        expect(delete_items[1].aptrust_approver).to eq admin_user.email
        expect(delete_items[2].inst_approver).to eq institutional_admin.email
        expect(delete_items[2].aptrust_approver).to eq admin_user.email
        expect(delete_items[3].inst_approver).to eq institutional_admin.email
        expect(delete_items[3].aptrust_approver).to eq admin_user.email
        expect(delete_items[4].inst_approver).to eq institutional_admin.email
        expect(delete_items[4].aptrust_approver).to eq admin_user.email

        reloaded_object = IntellectualObject.find(obj2.id)
        expect(reloaded_object.state).to eq 'A'
        expect(reloaded_object.premis_events.count).to eq 0
        delete_items = WorkItem.with_action('Delete').with_object_identifier(reloaded_object.identifier)
        expect(delete_items.count).to eq 5
        expect(delete_items[0].inst_approver).to eq institutional_admin.email
        expect(delete_items[0].aptrust_approver).to eq admin_user.email
        expect(delete_items[1].inst_approver).to eq institutional_admin.email
        expect(delete_items[1].aptrust_approver).to eq admin_user.email
        expect(delete_items[2].inst_approver).to eq institutional_admin.email
        expect(delete_items[2].aptrust_approver).to eq admin_user.email
        expect(delete_items[3].inst_approver).to eq institutional_admin.email
        expect(delete_items[3].aptrust_approver).to eq admin_user.email
        expect(delete_items[4].inst_approver).to eq institutional_admin.email
        expect(delete_items[4].aptrust_approver).to eq admin_user.email

        reloaded_object = GenericFile.find(file1.id)
        expect(reloaded_object.state).to eq 'A'
        delete_item = WorkItem.with_action('Delete').with_file_identifier(reloaded_object.identifier).first
        expect(delete_item).not_to be_nil
        expect(delete_item.inst_approver).to eq institutional_admin.email
        expect(delete_item.aptrust_approver).to eq admin_user.email

        reloaded_object = GenericFile.find(file2.id)
        expect(reloaded_object.state).to eq 'A'
        delete_item = WorkItem.with_action('Delete').with_file_identifier(reloaded_object.identifier).first
        expect(delete_item).not_to be_nil
        expect(delete_item.inst_approver).to eq institutional_admin.email
        expect(delete_item.aptrust_approver).to eq admin_user.email
      end

      it 'responds unsuccessfully if the confirmation token is invalid' do
        obj1 = FactoryBot.create(:intellectual_object, state: 'A', institution: institution_three)
        obj2 = FactoryBot.create(:intellectual_object, state: 'A', institution: institution_three)
        obj4 = FactoryBot.create(:intellectual_object, state: 'A', institution: institution_three)
        obj5 = FactoryBot.create(:intellectual_object, state: 'A', institution: institution_three)
        file1 = FactoryBot.create(:generic_file, intellectual_object: obj4, state: 'A')
        file2 = FactoryBot.create(:generic_file, intellectual_object: obj5, state: 'A')
        token = FactoryBot.create(:confirmation_token, institution: institution_three)
        apt = FactoryBot.create(:aptrust)
        extra_admin = FactoryBot.create(:user, :admin, institution: apt)
        bulk_job = FactoryBot.create(:bulk_delete_job, institution_id: institution_three.id, requested_by: extra_admin.email, institutional_approver: institutional_admin.email)
        bulk_job.intellectual_objects.push(obj1)
        bulk_job.intellectual_objects.push(obj2)
        bulk_job.generic_files.push(file1)
        bulk_job.generic_files.push(file2)
        post :final_confirmation_bulk_delete, params: { institution_identifier: institution_three.identifier, confirmation_token: SecureRandom.hex, bulk_delete_job_id: bulk_job.id }
        expect(assigns[:institution]).to eq institution_three
        expect(response).to redirect_to root_path
        expect(flash[:alert]).to eq 'This bulk deletion request cannot be completed at this time due to an invalid confirmation token. ' +
                                        'Please contact your APTrust administrator for more information.'
      end

    end

    describe 'for institutional_admin user' do
      before do
        sign_in institutional_admin
        session[:verified] = true
      end

      it 'responds unauthorized' do
        post :final_confirmation_bulk_delete, params: { institution_identifier: institutional_admin.institution.to_param }
        expect(response).to redirect_to root_path
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end

    end

    describe 'for institutional_user user' do
      before do
        sign_in institutional_user
        session[:verified] = true
      end

      it 'responds unauthorized' do
        post :final_confirmation_bulk_delete, params: { institution_identifier: institutional_user.institution.to_param }
        expect(response).to redirect_to root_path
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
    end
  end

  describe 'POST finished_bulk_delete' do

    describe 'for admin user' do
      before do
        sign_in admin_user
        session[:verified] = true
      end

      it 'responds successfully and marks the items as deleted' do
        obj1 = FactoryBot.create(:intellectual_object, state: 'A', institution: institution_three)
        obj2 = FactoryBot.create(:intellectual_object, state: 'A', institution: institution_three)
        obj4 = FactoryBot.create(:intellectual_object, state: 'A', institution: institution_three)
        obj5 = FactoryBot.create(:intellectual_object, state: 'A', institution: institution_three)
        file1 = FactoryBot.create(:generic_file, intellectual_object: obj4, state: 'A')
        file2 = FactoryBot.create(:generic_file, intellectual_object: obj5, state: 'A')
        item1 = FactoryBot.create(:work_item, object_identifier: obj1.identifier, intellectual_object: obj1, action: 'Delete', status: 'Success', stage: 'Resolve')
        item2 = FactoryBot.create(:work_item, object_identifier: obj2.identifier, intellectual_object: obj2, action: 'Delete', status: 'Success', stage: 'Resolve')
        item3 = FactoryBot.create(:work_item, object_identifier: obj4.identifier, intellectual_object: obj4, generic_file_identifier: file1.identifier, generic_file: file1, action: 'Delete', status: 'Success', stage: 'Resolve')
        item4 = FactoryBot.create(:work_item, object_identifier: obj5.identifier, intellectual_object: obj5, generic_file_identifier: file2.identifier, generic_file: file2, action: 'Delete', status: 'Success', stage: 'Resolve')
        apt = FactoryBot.create(:aptrust)
        extra_admin = FactoryBot.create(:user, :admin, institution: apt)
        count_before = Email.all.count
        bulk_job = FactoryBot.create(:bulk_delete_job, institution_id: institution_three.id, requested_by: admin_user.email, institutional_approver: institutional_admin.email, aptrust_approver: extra_admin.email)
        bulk_job.intellectual_objects.push(obj1)
        bulk_job.intellectual_objects.push(obj2)
        bulk_job.generic_files.push(file1)
        bulk_job.generic_files.push(file2)
        post :finished_bulk_delete, params: { institution_identifier: institution_three.identifier, bulk_delete_job_id: bulk_job.id }
        expect(assigns[:institution]).to eq institution_three
        expect(assigns[:bulk_job]).to eq bulk_job
        expect(flash[:notice]).to eq "Bulk deletion job for #{institution_three.name} has been completed."
        count_after = Email.all.count
        expect(count_after).to eq count_before + 1
        email = ActionMailer::Base.deliveries.last
        expect(email.body.encoded).to include("a bulk deletion job requested by #{admin_user.name}")
        expect(email.body.encoded).to include("and approved by #{institutional_admin.name} and #{extra_admin.name} has successfully finished")

        reloaded_object = IntellectualObject.find(obj1.id)
        expect(reloaded_object.state).to eq 'D'
        expect(reloaded_object.premis_events.count).to eq 1
        expect(reloaded_object.premis_events[0].event_type).to eq Pharos::Application::PHAROS_EVENT_TYPES['delete']

        reloaded_object = IntellectualObject.find(obj2.id)
        expect(reloaded_object.state).to eq 'D'
        expect(reloaded_object.premis_events.count).to eq 1
        expect(reloaded_object.premis_events[0].event_type).to eq Pharos::Application::PHAROS_EVENT_TYPES['delete']

        reloaded_object = GenericFile.find(file1.id)
        expect(reloaded_object.state).to eq 'D'

        reloaded_object = GenericFile.find(file2.id)
        expect(reloaded_object.state).to eq 'D'
      end
    end

    describe 'for institutional_admin user' do
      before do
        sign_in institutional_admin
        session[:verified] = true
      end

      it 'responds unauthorized' do
        post :finished_bulk_delete, params: { institution_identifier: institutional_admin.institution.to_param }
        expect(response).to redirect_to root_path
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end

    end

    describe 'for institutional_user user' do
      before do
        sign_in institutional_user
        session[:verified] = true
      end

      it 'responds unauthorized' do
        post :finished_bulk_delete, params: { institution_identifier: institutional_user.institution.to_param }
        expect(response).to redirect_to root_path
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
    end

  end

  describe 'GET deletion_notifications' do
    describe 'for admin user' do
      before do
        sign_in admin_user
        session[:verified] = true
      end

      it 'responds successfully and sends out an deletion notification email with a CSV attachment' do
        extra_user = FactoryBot.create(:user, :institutional_admin, institution_id: institution_three.id)
        obj1 = FactoryBot.create(:intellectual_object, state: 'D', institution: institution_three)
        obj2 = FactoryBot.create(:intellectual_object, state: 'D', institution: institution_three)
        obj3 = FactoryBot.create(:intellectual_object, state: 'D', institution: institution_three)
        file1 = FactoryBot.create(:generic_file, intellectual_object: obj1, state: 'D')
        file2 = FactoryBot.create(:generic_file, intellectual_object: obj2, state: 'D')
        file3 = FactoryBot.create(:generic_file, intellectual_object: obj3, state: 'D')
        sleep 1
        item1 = FactoryBot.create(:work_item, object_identifier: obj1.identifier, intellectual_object: obj1, generic_file_identifier: file1.identifier, generic_file: file1, action: 'Delete', status: 'Success', stage: 'Resolve', institution_id: institution_three.id)
        item2 = FactoryBot.create(:work_item, object_identifier: obj2.identifier, intellectual_object: obj2, generic_file_identifier: file2.identifier, generic_file: file2, action: 'Delete', status: 'Success', stage: 'Resolve', institution_id: institution_three.id)
        item3 = FactoryBot.create(:work_item, object_identifier: obj3.identifier, intellectual_object: obj3, generic_file_identifier: file3.identifier, generic_file: file3, action: 'Delete', status: 'Success', stage: 'Resolve', institution_id: institution_three.id)
        item3.created_at = Time.now - 2.month
        item3.save!
        count_before = Email.all.count
        get :deletion_notifications
        count_after = Email.all.count
        expect(count_after).to eq count_before + 1
        email = ActionMailer::Base.deliveries.last
        expect(email.body.encoded).to include('new deletion requests that have completed')
        expect(email.attachments.count).to eq(1)
        expect(email.attachments[0].filename).to eq('deletions.zip')
        expect(email.attachments[0].content_type).to eq('application/zip')
        Institution.remove_directory('test')
      end
    end

    describe 'for institutional_admin user' do
      before do
        sign_in institutional_admin
        session[:verified] = true
      end

      it 'responds unauthorized' do
        get :deletion_notifications
        expect(response).to redirect_to root_path
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end

    end

    describe 'for institutional_user user' do
      before do
        sign_in institutional_user
        session[:verified] = true
      end

      it 'responds unauthorized' do
        get :deletion_notifications
        expect(response).to redirect_to root_path
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
    end
  end
end
