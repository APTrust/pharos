require 'spec_helper'

RSpec.describe InstitutionsController, type: :controller do
  before :all do
    Institution.destroy_all
  end

  after do
    Institution.destroy_all
  end

  let(:admin_user) { FactoryGirl.create(:user, :admin) }
  let(:institutional_user) { FactoryGirl.create(:user, :institutional_user) }
  let(:institutional_admin) { FactoryGirl.create(:user, :institutional_admin) }

  describe 'GET #index' do
    describe 'for admin users' do
      before do
        sign_in admin_user
      end

      it 'responds successfully with an HTTP 200 status code' do
        get :index
        expect(response).to be_success
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

  describe 'GET #new' do
    describe 'for admin users' do
      before do
        sign_in admin_user
      end

      it 'responds successfully' do
        get :new
        expect(response).to be_success
      end
    end
  end

  describe 'GET #show' do
    describe 'for admin user' do
      before do
        sign_in admin_user
      end

      it 'responds successfully with an HTTP 200 status code' do
        get :show, institution_identifier: admin_user.institution.to_param
        expect(response).to be_success
        expect(response.status).to eq(200)
      end

      it 'renders the show template' do
        get :show, institution_identifier: admin_user.institution.to_param
        expect(response).to render_template('show')
      end

      it 'assigns the requested institution as @institution' do
        get :show, institution_identifier: admin_user.institution.to_param
        assigns(:institution).should eq( admin_user.institution)
      end

    end

    describe 'for institutional_admin user' do
      before do
        sign_in institutional_admin
      end

      it 'responds successfully with an HTTP 200 status code' do
        get :show, institution_identifier: institutional_admin.institution.to_param
        expect(response).to be_success
        expect(response.status).to eq(200)
      end

      it 'renders the show template' do
        get :show, institution_identifier: institutional_admin.institution.to_param
        expect(response).to render_template('show')
      end

      it 'assigns the requested institution as @institution' do
        get :show, institution_identifier: institutional_admin.institution.to_param
        assigns(:institution).should eq(institutional_admin.institution)
      end
    end

    describe 'for institutional_user user' do
      before do
        sign_in institutional_user
      end
      it 'responds successfully with an HTTP 200 status code' do
        get :show, institution_identifier: institutional_user.institution.to_param
        expect(response).to be_success
        expect(response.status).to eq(200)
      end

      it 'renders the show template' do
        get :show, institution_identifier: institutional_user.institution.to_param
        expect(response).to render_template('show')
      end

      it 'assigns the requested institution as @institution' do
        get :show, institution_identifier: institutional_user.institution.to_param
        assigns(:institution).should eq(institutional_user.institution)
      end
    end

    describe 'for an API user' do
      before do
        sign_in admin_user
      end
      it 'responds successfully with an HTTP 200 status code' do
        get :show, institution_identifier: CGI.escape(admin_user.institution.to_param)
        expect(response).to be_success
        expect(response.status).to eq(200)
      end

      it 'should provide a 404 code when an incorrect identifier is provided' do
        get :show, institution_identifier: CGI.escape('notreal.edu'), format: 'json'
        expect(response.status).to eq(404)
      end
    end
  end

  describe 'GET edit' do
    after { inst1.destroy }

    describe 'when not signed in' do
      let(:inst1) { FactoryGirl.create(:institution) }
      it 'should redirect to login' do
        get :edit, institution_identifier: inst1
        expect(response).to redirect_to root_url + 'users/sign_in'
      end
    end

    describe 'when signed in' do
      after { user.destroy }
      describe 'as an institutional_user' do
        let(:inst1) { FactoryGirl.create(:institution) }
        let(:user) { FactoryGirl.create(:user, :institutional_user, institution_id: inst1.id) }
        before { sign_in user }
        it 'should be unauthorized' do
          get :edit, institution_identifier: inst1
          expect(response).to redirect_to root_url
          expect(flash[:alert]).to eq 'You are not authorized to access this page.'
        end
      end

      describe 'as an institutional_admin' do
        let(:inst1) { FactoryGirl.create(:institution) }
        let(:inst2) { FactoryGirl.create(:institution) }
        let(:user) { FactoryGirl.create(:user, :institutional_admin, institution_id: inst1.id) }
        before { sign_in user }
        describe 'editing my own institution' do
          it 'should show the institution edit form' do
            get :edit, institution_identifier: inst1
            expect(response).to be_successful
          end
        end
        describe 'editing an institution other than my own' do
          it 'should be unauthorized' do
            get :edit, institution_identifier: inst2
            expect(response).to redirect_to root_url
            expect(flash[:alert]).to eq 'You are not authorized to access this page.'
          end
        end
      end

      describe 'as an admin' do
        let(:inst1) { FactoryGirl.create(:institution) }
        let(:user) { FactoryGirl.create(:user, :admin, institution_id: inst1.id) }
        before { sign_in user }
        it 'should show the institution edit form' do
          get :edit, institution_identifier: inst1
          expect(response).to be_successful
        end
      end
    end
  end

  describe 'PATCH update' do

    describe 'when not signed in' do
      let(:inst1) { FactoryGirl.create(:institution) }
      it 'should redirect to login' do
        patch :update, institution_identifier: inst1, institution: {name: 'Foo' }
        expect(response).to redirect_to root_url + 'users/sign_in'
      end
    end

    describe 'when signed in' do
      let(:user) { FactoryGirl.create(:user, :admin) }
      let(:inst1) { FactoryGirl.create(:institution) }
      before {
        sign_in user
      }

      it 'should update fields' do
        patch :update, institution_identifier: inst1, institution: {name: 'Foo'}
        expect(response).to redirect_to institution_path(inst1)
        expect(assigns(:institution).name).to eq 'Foo'
      end
    end
  end

  describe 'POST create' do
    describe 'with admin user' do
      let (:attributes) { FactoryGirl.attributes_for(:institution) }

      before do
        sign_in admin_user
      end

      it 'should reject when there are no parameters' do
        expect {
          post :create, {}
        }.to raise_error ActionController::ParameterMissing
      end

      it 'should accept good parameters' do
        expect {
          post :create, institution: attributes
        }.to change(Institution, :count).by(1)
        response.should redirect_to institution_url(assigns[:institution])
        assigns[:institution].should be_kind_of Institution
      end
    end
    describe 'with institutional admin user' do
      let (:attributes) { FactoryGirl.attributes_for(:institution) }
      before do
        sign_in institutional_admin
      end

      it 'should be unauthorized' do
        expect {
          post :create, institution: attributes
        }.to_not change(Institution, :count)
        expect(response).to redirect_to root_path
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
    end
  end
end
