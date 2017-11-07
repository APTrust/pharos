require 'spec_helper'

RSpec.describe ReportsController, type: :controller do
  before :all do
    Institution.delete_all
    IntellectualObject.delete_all
    GenericFile.delete_all

    @institution_one =  FactoryBot.create(:subscription_institution)
    @institution_two = FactoryBot.create(:member_institution, identifier: 'aptrust.org')
    @admin_user = FactoryBot.create(:user, :admin, institution: @institution_one)
    @institutional_user = FactoryBot.create(:user, :institutional_user, institution: @institution_two)
    @institutional_admin = FactoryBot.create(:user, :institutional_admin, institution: @institution_two)
    @institutional_admin_two = FactoryBot.create(:user, :institutional_admin, institution: @institution_one)
    @intellectual_object_one = FactoryBot.create(:intellectual_object, institution: @institution_one)
    @intellectual_object_two = FactoryBot.create(:intellectual_object, institution: @institution_two)
    @generic_file_one = FactoryBot.create(:generic_file, intellectual_object: @intellectual_object_one)
    @generic_file_two = FactoryBot.create(:generic_file, intellectual_object: @intellectual_object_two)
  end

  after :all do
    Institution.delete_all
    IntellectualObject.delete_all
    GenericFile.delete_all
  end

  describe 'GET #index' do
    describe 'for admin users' do
      before do
        sign_in @admin_user
      end

      it 'responds successfully with an HTTP 200 status code for own institution' do
        get :index, params: { identifier: @institution_one.identifier }
        expect(response).to be_success
      end

      it 'responds successfully with an HTTP 200 status code for another institution' do
        get :index, params: { identifier: @institution_two.identifier }
        expect(response).to be_success
      end
    end

    describe 'for institutional admin users' do
      before do
        sign_in @institutional_admin
      end

      it 'responds successfully with an HTTP 200 status code for own institution' do
        get :index, params: { identifier: @institution_two.identifier }
        expect(response).to be_success
      end

      it 'denies access when the institution is not their own (html)' do
        get :index, params: { identifier: @institution_one.identifier }
        expect(response.status).to eq(302)
        flash[:alert].should =~ /You are not authorized/
      end

      it 'denies access when the institution is not their own (json)' do
        get :index, params: { identifier: @institution_one.identifier }, format: :json
        expect(response.status).to eq(403)
      end
    end

  end

  describe 'GET #overview' do
    describe 'for admin users' do
      before do
        sign_in @admin_user
      end

      it 'responds successfully with an HTTP 200 status code for own institution' do
        get :overview, params: { identifier: @institution_one.identifier }
        expect(response).to be_success
        expect(assigns(:report)[:generic_files]).to eq(1)
        expect(assigns(:report)[:intellectual_objects]).to eq(1)
        expect(assigns(:report)[:average_file_size]).to eq(@generic_file_one.size)
      end

      it 'responds successfully with an HTTP 200 status code for another institution' do
        get :overview, params: { identifier: @institution_two.identifier }
        expect(response).to be_success
      end
    end

    describe 'for institutional admin users' do
      before do
        sign_in @institutional_admin
      end

      it 'responds successfully with an HTTP 200 status code for own institution' do
        get :overview, params: { identifier: @institution_two.identifier }
        expect(response).to be_success
        expect(assigns(:report)[:generic_files]).to eq(1)
        expect(assigns(:report)[:intellectual_objects]).to eq(1)
        expect(assigns(:report)[:average_file_size]).to eq(@generic_file_two.size)
      end

      it 'denies access when the institution is not their own (html)' do
        get :overview, params: { identifier: @institution_one.identifier }
        expect(response.status).to eq(302)
        flash[:alert].should =~ /You are not authorized/
      end

      it 'denies access when the institution is not their own (json)' do
        get :overview, params: { identifier: @institution_one.identifier }, format: :json
        expect(response.status).to eq(403)
      end
    end
  end

  describe 'GET #institution_breakdown' do
    describe 'for admin users' do
      before do
        sign_in @admin_user
      end

      it 'responds successfully with an HTTP 200 status code' do
        get :institution_breakdown
        expect(response).to be_success
        expect(assigns(:report).keys.size).to eq(3)
      end
    end

    describe 'for institutional admin users with access' do
      before do
        sign_in @institutional_admin
      end

      it 'responds successfully with an HTTP 200 status code' do
        get :institution_breakdown
        expect(response).to be_success
        expect(assigns(:report).keys.size).to eq(3)
      end
    end

    describe 'for institutional admin users without access' do
      before do
        sign_in @institutional_admin_two
      end

      it 'denies access' do
        get :institution_breakdown
        expect(response.status).to eq(302)
      end

      it 'denies access in JSON' do
        get :institution_breakdown, format: :json
        expect(response.status).to eq(403)
      end
    end
  end

end
