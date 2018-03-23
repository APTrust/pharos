require 'spec_helper'

RSpec.describe ReportsController, type: :controller do
  before :all do
    Institution.delete_all
    IntellectualObject.delete_all
    GenericFile.delete_all

    @institution_two = FactoryBot.create(:member_institution, identifier: 'aptrust.org')
    @institution_one =  FactoryBot.create(:subscription_institution, member_institution_id: @institution_two.id)
    @admin_user = FactoryBot.create(:user, :admin, institution: @institution_one)
    @institutional_user = FactoryBot.create(:user, :institutional_user, institution: @institution_two)
    @institutional_admin = FactoryBot.create(:user, :institutional_admin, institution: @institution_two)
    @institutional_admin_two = FactoryBot.create(:user, :institutional_admin, institution: @institution_one)
    @intellectual_object_one = FactoryBot.create(:intellectual_object, institution: @institution_one, access: 'institution')
    @intellectual_object_two = FactoryBot.create(:intellectual_object, institution: @institution_two, access: 'institution')
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
        expect(assigns(:overview_report)[:generic_files]).to eq(1)
        expect(assigns(:overview_report)[:intellectual_objects]).to eq(1)
        expect(assigns(:overview_report)[:average_file_size]).to eq(@generic_file_one.size)
        expect(assigns(:inst_breakdown_report).keys.size).to eq(1)
      end

      it 'responds successfully with an HTTP 200 status code for another institution' do
        get :index, params: { identifier: @institution_two.identifier }
        expect(response).to be_success
        expect(assigns(:overview_report)[:generic_files]).to eq(1)
        expect(assigns(:overview_report)[:intellectual_objects]).to eq(1)
        expect(assigns(:overview_report)[:average_file_size]).to eq(@generic_file_two.size)
        expect(assigns(:inst_breakdown_report).keys.size).to eq(1)
      end
    end

    describe 'for institutional admin users' do
      before do
        sign_in @institutional_admin
      end

      it 'responds successfully with an HTTP 200 status code for own institution' do
        get :index, params: { identifier: @institution_two.identifier }
        expect(response).to be_success
        expect(assigns(:overview_report)[:generic_files]).to eq(1)
        expect(assigns(:overview_report)[:intellectual_objects]).to eq(1)
        expect(assigns(:overview_report)[:average_file_size]).to eq(@generic_file_two.size)
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
        expect(assigns(:overview_report)[:generic_files]).to eq(1)
        expect(assigns(:overview_report)[:intellectual_objects]).to eq(1)
        expect(assigns(:overview_report)[:average_file_size]).to eq(@generic_file_one.size)
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
        expect(assigns(:overview_report)[:generic_files]).to eq(1)
        expect(assigns(:overview_report)[:intellectual_objects]).to eq(1)
        expect(assigns(:overview_report)[:average_file_size]).to eq(@generic_file_two.size)
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

  describe 'GET #general' do
    describe 'for admin users' do
      before do
        sign_in @admin_user
      end

      it 'responds successfully with an HTTP 200 status code for own institution' do
        get :general, params: { identifier: @institution_one.identifier }
        expect(response).to be_success
        expect(assigns(:basic_report)[:generic_files]).to eq(1)
        expect(assigns(:basic_report)[:intellectual_objects]).to eq(1)
        expect(assigns(:basic_report)[:average_file_size]).to eq(@generic_file_one.size)
      end

      it 'responds successfully with an HTTP 200 status code for another institution' do
        get :general, params: { identifier: @institution_two.identifier }
        expect(response).to be_success
        expect(assigns(:basic_report)[:generic_files]).to eq(1)
        expect(assigns(:basic_report)[:intellectual_objects]).to eq(1)
        expect(assigns(:basic_report)[:average_file_size]).to eq(@generic_file_two.size)
      end
    end

    describe 'for institutional admin users' do
      before do
        sign_in @institutional_admin
      end

      it 'responds successfully with an HTTP 200 status code for own institution' do
        get :general, params: { identifier: @institution_two.identifier }
        expect(response).to be_success
        expect(assigns(:basic_report)[:generic_files]).to eq(1)
        expect(assigns(:basic_report)[:intellectual_objects]).to eq(1)
        expect(assigns(:basic_report)[:average_file_size]).to eq(@generic_file_two.size)
      end

      it 'denies access when the institution is not their own (html)' do
        get :general, params: { identifier: @institution_one.identifier }
        expect(response.status).to eq(302)
        flash[:alert].should =~ /You are not authorized/
      end

      it 'denies access when the institution is not their own (json)' do
        get :general, params: { identifier: @institution_one.identifier }, format: :json
        expect(response.status).to eq(403)
      end
    end
  end

  describe 'GET #subscribers' do
    describe 'for admin users' do
      before do
        sign_in @admin_user
      end

      it 'responds successfully with an HTTP 200 status code for own institution' do
        get :subscribers, params: { identifier: @institution_one.identifier }
        expect(response).to be_success
        expect(assigns(:subscriber_report)).to eq({})
      end

      it 'responds successfully with an HTTP 200 status code for another institution' do
        get :subscribers, params: { identifier: @institution_two.identifier }
        expect(response).to be_success
        expect(assigns(:subscriber_report).keys.size).to eq(2)
      end
    end

    describe 'for institutional admin users' do
      before do
        sign_in @institutional_admin
      end

      it 'responds successfully with an HTTP 200 status code for own institution' do
        get :subscribers, params: { identifier: @institution_two.identifier }
        expect(response).to be_success
        expect(assigns(:subscriber_report).keys.size).to eq(2)
      end

      it 'denies access when the institution is not their own (html)' do
        get :subscribers, params: { identifier: @institution_one.identifier }
        expect(response.status).to eq(302)
        flash[:alert].should =~ /You are not authorized/
      end

      it 'denies access when the institution is not their own (json)' do
        get :subscribers, params: { identifier: @institution_one.identifier }, format: :json
        expect(response.status).to eq(403)
      end
    end
  end

  describe 'GET #cost' do
    describe 'for admin users' do
      before do
        sign_in @admin_user
      end

      it 'responds successfully with an HTTP 200 status code for own institution' do
        get :cost, params: { identifier: @institution_one.identifier }
        expect(response).to be_success
        expect(assigns(:cost_report)[:total_file_size]).to eq(@generic_file_one.size)
      end

      it 'responds successfully with an HTTP 200 status code for another institution' do
        get :cost, params: { identifier: @institution_two.identifier }
        expect(response).to be_success
        expect(assigns(:cost_report)[:total_file_size]).to eq(@generic_file_two.size)
        expect(assigns(:cost_report)[:subscribers]['total_bytes']).to eq(@generic_file_two.size + @generic_file_one.size)
      end
    end

    describe 'for institutional admin users' do
      before do
        sign_in @institutional_admin
      end

      it 'responds successfully with an HTTP 200 status code for own institution' do
        get :cost, params: { identifier: @institution_two.identifier }
        expect(response).to be_success
        expect(assigns(:cost_report)[:total_file_size]).to eq(@generic_file_two.size)
        expect(assigns(:cost_report)[:subscribers]['total_bytes']).to eq(@generic_file_two.size + @generic_file_one.size)
      end

      it 'denies access when the institution is not their own (html)' do
        get :cost, params: { identifier: @institution_one.identifier }
        expect(response.status).to eq(302)
        flash[:alert].should =~ /You are not authorized/
      end

      it 'denies access when the institution is not their own (json)' do
        get :cost, params: { identifier: @institution_one.identifier }, format: :json
        expect(response.status).to eq(403)
      end
    end
  end

  describe 'GET #timeline' do
    describe 'for admin users' do
      before do
        sign_in @admin_user
      end

      it 'responds successfully with an HTTP 200 status code for own institution' do
        get :timeline, params: { identifier: @institution_one.identifier }
        expect(response).to be_success
        expect(assigns(:timeline_report).size).to eq(2)
        report = assigns(:timeline_report)
        expect(report[0][report[0].length - 1]).to eq 'December 2014'
        expect(report[1][0]).to eq @generic_file_one.size
      end

      it 'responds successfully with an HTTP 200 status code for another institution' do
        get :timeline, params: { identifier: @institution_two.identifier }
        expect(response).to be_success
        expect(assigns(:timeline_report).size).to eq(2)
        report = assigns(:timeline_report)
        expect(report[0][report[0].length - 1]).to eq 'December 2014'
        expect(report[1][0]).to eq @generic_file_two.size
      end
    end

    describe 'for institutional admin users' do
      before do
        sign_in @institutional_admin
      end

      it 'responds successfully with an HTTP 200 status code for own institution' do
        get :timeline, params: { identifier: @institution_two.identifier }
        expect(response).to be_success
        expect(assigns(:timeline_report).size).to eq(2)
        report = assigns(:timeline_report)
        expect(report[0][report[0].length - 1]).to eq 'December 2014'
        expect(report[1][0]).to eq @generic_file_two.size
      end

      it 'denies access when the institution is not their own (html)' do
        get :timeline, params: { identifier: @institution_one.identifier }
        expect(response.status).to eq(302)
        flash[:alert].should =~ /You are not authorized/
      end

      it 'denies access when the institution is not their own (json)' do
        get :timeline, params: { identifier: @institution_one.identifier }, format: :json
        expect(response.status).to eq(403)
      end
    end
  end

  describe 'GET #mimetype' do
    describe 'for admin users' do
      before do
        sign_in @admin_user
      end

      it 'responds successfully with an HTTP 200 status code for own institution' do
        get :mimetype, params: { identifier: @institution_one.identifier }
        expect(response).to be_success
        expect(assigns(:mimetype_report)['all']).to eq(@generic_file_one.size)
        expect(assigns(:mimetype_report).keys).to include @generic_file_one.file_format
      end

      it 'responds successfully with an HTTP 200 status code for another institution' do
        get :mimetype, params: { identifier: @institution_two.identifier }
        expect(response).to be_success
        expect(assigns(:mimetype_report)['all']).to eq(@generic_file_two.size)
        expect(assigns(:mimetype_report).keys).to include @generic_file_two.file_format
      end
    end

    describe 'for institutional admin users' do
      before do
        sign_in @institutional_admin
      end

      it 'responds successfully with an HTTP 200 status code for own institution' do
        get :mimetype, params: { identifier: @institution_two.identifier }
        expect(response).to be_success
        expect(assigns(:mimetype_report)['all']).to eq(@generic_file_two.size)
        expect(assigns(:mimetype_report).keys).to include @generic_file_two.file_format
      end

      it 'denies access when the institution is not their own (html)' do
        get :mimetype, params: { identifier: @institution_one.identifier }
        expect(response.status).to eq(302)
        flash[:alert].should =~ /You are not authorized/
      end

      it 'denies access when the institution is not their own (json)' do
        get :mimetype, params: { identifier: @institution_one.identifier }, format: :json
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
        expect(assigns(:inst_breakdown_report).keys.size).to eq(1)
      end
    end

    describe 'for institutional admin users with access' do
      before do
        sign_in @institutional_admin
      end

      it 'responds successfully with an HTTP 200 status code' do
        get :institution_breakdown
        expect(response).to be_success
        expect(assigns(:inst_breakdown_report).keys.size).to eq(1)
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

  describe 'GET #object_report' do
    describe 'for admin users' do
      before do
        sign_in @admin_user
      end

      it 'responds successfully with an HTTP 200 status code for own institution' do
        get :object_report, params: { intellectual_object_identifier: @intellectual_object_one.identifier }
        expect(response).to be_success
        expect(assigns(:object_report)[:active_files]).to eq(1)
        expect(assigns(:object_report)[:processing_files]).to eq(0)
        expect(assigns(:object_report)[:deleted_files]).to eq(0)
        expect(assigns(:object_report)[:bytes_by_format].keys).to include @generic_file_one.file_format
      end

      it 'responds successfully with an HTTP 200 status code for another institution' do
        get :object_report, params: { intellectual_object_identifier: @intellectual_object_two.identifier }
        expect(response).to be_success
        expect(assigns(:object_report)[:active_files]).to eq(1)
        expect(assigns(:object_report)[:processing_files]).to eq(0)
        expect(assigns(:object_report)[:deleted_files]).to eq(0)
        expect(assigns(:object_report)[:bytes_by_format].keys).to include @generic_file_two.file_format
      end
    end

    describe 'for institutional admin users' do
      before do
        sign_in @institutional_admin
      end

      it 'responds successfully with an HTTP 200 status code for own institution' do
        get :object_report, params: { intellectual_object_identifier: @intellectual_object_two.identifier }
        expect(response).to be_success
        expect(assigns(:object_report)[:active_files]).to eq(1)
        expect(assigns(:object_report)[:processing_files]).to eq(0)
        expect(assigns(:object_report)[:deleted_files]).to eq(0)
        expect(assigns(:object_report)[:bytes_by_format].keys).to include @generic_file_two.file_format
      end

      it 'denies access when the institution is not their own (html)' do
        get :object_report, params: { intellectual_object_identifier: @intellectual_object_one.identifier }
        expect(response.status).to eq(302)
        flash[:alert].should =~ /You are not authorized/
      end

      it 'denies access when the institution is not their own (json)' do
        get :object_report, params: { intellectual_object_identifier: @intellectual_object_one.identifier }, format: :json
        expect(response.status).to eq(403)
      end
    end
  end

end
