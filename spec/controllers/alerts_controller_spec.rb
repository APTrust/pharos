require 'spec_helper'

RSpec.describe AlertsController, type: :controller do
  before :all do
    WorkItem.delete_all
    DpnWorkItem.delete_all
    PremisEvent.delete_all
    User.delete_all
    Institution.delete_all

    @institution_one =  FactoryBot.create(:member_institution, identifier: 'aptrust.org')
    @institution_two = FactoryBot.create(:subscription_institution)
    @admin_user = FactoryBot.create(:user, :admin, institution: @institution_one)
    @institutional_admin = FactoryBot.create(:user, :institutional_admin, institution: @institution_two)
    @institutional_user = FactoryBot.create(:user, :institutional_user, institution: @institution_two)
    @failed_fixity = FactoryBot.create(:premis_event_fixity_check_fail, institution: @institution_two)
    @failed_fixity_two = FactoryBot.create(:premis_event_fixity_check_fail, created_at: (Time.now - 36.hours))
    @ingest_fail = FactoryBot.create(:work_item, action: Pharos::Application::PHAROS_ACTIONS['ingest'], status: Pharos::Application::PHAROS_STATUSES['fail'])
    @restore_fail = FactoryBot.create(:work_item, action: Pharos::Application::PHAROS_ACTIONS['restore'], status: Pharos::Application::PHAROS_STATUSES['fail'])
    @delete_fail = FactoryBot.create(:work_item, action: Pharos::Application::PHAROS_ACTIONS['delete'], status: Pharos::Application::PHAROS_STATUSES['fail'])
    @dpn_ingest_fail = FactoryBot.create(:work_item, action: Pharos::Application::PHAROS_ACTIONS['dpn'], status: Pharos::Application::PHAROS_STATUSES['fail'])
    @stalled = FactoryBot.create(:work_item, queued_at: Time.now - 13.hours, status: Pharos::Application::PHAROS_STATUSES['pend'])
    @stalled_dpn = FactoryBot.create(:dpn_work_item, queued_at: Time.now - 25.hours, completed_at: nil)
  end

  after :all do
    WorkItem.delete_all
    DpnWorkItem.delete_all
    PremisEvent.delete_all
    User.delete_all
    Institution.delete_all
  end

  describe 'GET #index' do
    describe 'for admin users' do
      before do
        sign_in @admin_user
        session[:verified] = true
      end

      it 'returns a list of each possible alert type from the last 24 hours (html)' do
        get :index
        expect(response).to be_successful
        expect(response).to render_template('index')
        assigns(:alerts_list)[:failed_fixity_checks].first.should eq(@failed_fixity)
        assigns(:alerts_list)[:failed_ingests].first.should eq(@ingest_fail)
        assigns(:alerts_list)[:failed_restorations].first.should eq(@restore_fail)
        assigns(:alerts_list)[:failed_deletions].first.should eq(@delete_fail)
        assigns(:alerts_list)[:failed_dpn_ingests].first.should eq(@dpn_ingest_fail)
        assigns(:alerts_list)[:stalled_dpn_replications].first.should eq(@stalled_dpn)
        assigns(:alerts_list)[:stalled_work_items].first.should eq(@stalled)
      end

      it 'returns only the specified alert type if the type parameter is used (json)' do
        get :index, params: { type: 'fixity' }, format: :json
        expect(response).to be_successful
        assigns(:alerts_list)[:failed_fixity_checks].count.should eq 1
        assigns(:alerts_list)[:failed_ingests].should be nil
      end

      it 'filters by the since parameter when supplied' do
        get :index, params: { since: (Time.now - 48.hours) }
        expect(response).to be_successful
        assigns(:alerts_list)[:failed_fixity_checks].count.should eq 2
      end
    end

    describe 'for institutional admins' do
      before do
        sign_in @institutional_admin
        session[:verified] = true
      end

      it 'allows access only to alerts on their content (html)' do
        get :index, params: { since: (Time.now - 48.hours) }
        expect(response).to be_successful
        assigns(:alerts_list)[:failed_fixity_checks].first.should eq(@failed_fixity)
        assigns(:alerts_list)[:failed_fixity_checks].count.should eq 1
      end
    end

    describe 'for institutional users' do
      before do
        sign_in @institutional_user
        session[:verified] = true
      end

      it 'denies access (html)' do
        get :index
        expect(response.status).to eq(302)
      end

      it 'denies access (json)' do
        get :index, format: :json
        expect(response.status).to eq(403)
      end
    end
  end

  describe 'GET #summary' do
    describe 'for admin users' do
      before do
        sign_in @admin_user
        session[:verified] = true
      end

      it 'returns a list of alert counts (html)' do
        get :summary
        expect(response).to be_successful
        expect(response).to render_template('summary')
        assigns(:alerts_summary)[:failed_fixity_count].should eq 1
        assigns(:alerts_summary)[:failed_ingest_count].should eq 1
        assigns(:alerts_summary)[:failed_restoration_count].should eq 1
        assigns(:alerts_summary)[:failed_deletion_count].should eq 1
        assigns(:alerts_summary)[:failed_dpn_ingest_count].should eq 1
        assigns(:alerts_summary)[:stalled_dpn_replication_count].should eq 1
        assigns(:alerts_summary)[:stalled_work_item_count].should eq 1
      end

      it 'returns a list of alert counts (json)' do
        get :summary, format: :json
        expect(response).to be_successful
        assigns(:alerts_summary)[:failed_fixity_count].should eq 1
        assigns(:alerts_summary)[:failed_ingest_count].should eq 1
        assigns(:alerts_summary)[:failed_restoration_count].should eq 1
        assigns(:alerts_summary)[:failed_deletion_count].should eq 1
        assigns(:alerts_summary)[:failed_dpn_ingest_count].should eq 1
        assigns(:alerts_summary)[:stalled_dpn_replication_count].should eq 1
        assigns(:alerts_summary)[:stalled_work_item_count].should eq 1
      end

      it 'filters by the since parameter when supplied' do
        get :summary, params: { since: (Time.now - 48.hours) }
        assigns(:alerts_summary)[:failed_fixity_count].should eq 2
      end
    end

    describe 'for institutional admins' do
      before do
        sign_in @institutional_admin
        session[:verified] = true
      end

      it 'allows access (html)' do
        get :summary
        expect(response).to be_successful
      end
    end

    describe 'for institutional users' do
      before do
        sign_in @institutional_user
        session[:verified] = true
      end

      it 'denies access (html)' do
        get :summary
        expect(response.status).to eq(302)
      end

      it 'denies access (json)' do
        get :summary, format: :json
        expect(response.status).to eq(403)
      end
    end
  end


end