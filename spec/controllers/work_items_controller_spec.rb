require 'spec_helper'

RSpec.describe WorkItemsController, type: :controller do
  let(:institution) { FactoryGirl.create(:institution) }
  let(:admin_user) { FactoryGirl.create(:user, :admin) }
  let(:institutional_admin) { FactoryGirl.create(:user, :institutional_admin, institution_id: institution.id) }

  let!(:item) { FactoryGirl.create(:work_item, action: Pharos::Application::PHAROS_ACTIONS['fixity'], status: Pharos::Application::PHAROS_STATUSES['success']) }
  let!(:user_item) { FactoryGirl.create(:work_item, action: Pharos::Application::PHAROS_ACTIONS['fixity'], institution: institution.identifier, status: Pharos::Application::PHAROS_STATUSES['fail']) }

  after do
    WorkItem.destroy_all
    Institution.destroy_all
    User.destroy_all
  end

  describe 'GET #index' do
    describe 'for admin user' do
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

      it 'assigns the requested institution as @institution' do
        get :index
        assigns(:institution).should eq( admin_user.institution)
      end

      it 'assigns @counts' do
        get :index
        assigns(:counts).should include(Pharos::Application::PHAROS_ACTIONS['ingest'])
      end

    end

    describe 'for institutional admin' do
      before do
        sign_in institutional_admin
      end

      it 'assigns the requested items as @items' do
        get :index
        assigns(:items).should include(user_item)
      end

      it 'assigns @counts' do
        get :index
        assigns(:counts).should include(Pharos::Application::PHAROS_ACTIONS['ingest'])
      end

    end
  end

  describe 'GET #show' do
    describe 'for admin user' do
      before do
        sign_in admin_user
      end
      it 'responds successfully with an HTTP 200 status code' do
        get :show, id: item.id
        expect(response).to be_success
      end

      it 'renders the show template' do
        get :show, id: item.id
        expect(response).to render_template('show')
      end

      it 'assigns the requested item as @work_item' do
        get :show, id: item.id
        assigns(:work_item).id.should eq(item.id)
      end

      it 'assigns the requested institution as @institution' do
        get :show, id: item.id
        assigns(:institution).should eq( admin_user.institution)
      end

      it 'exposes :state, :node, or :pid for the admin user' do
        get :show, id: item.id, format: :json
        data = JSON.parse(response.body)
        expect(data).to have_key('state')
        expect(data).to have_key('node')
        expect(data).to have_key('pid')
      end

      it 'returns 404, not 500, for item not found' do
        expect {
          get :show,
              etag: 'does not exist',
              name: 'duznot igzist',
              bag_date: '1901-01-01' }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    describe 'for institutional admin' do
      before do
        sign_in institutional_admin
      end

      # it 'restricts API usage' do
      #   get :show, etag: item.etag, name: item.name, bag_date: item.bag_date, format: 'json'
      #   expect(response.status).to eq 403
      # end

      it 'does not expose :state, :node, or :pid to non-admins' do
        get :show, id: item.id, format: :json
        data = JSON.parse(response.body)
        expect(data).to_not have_key('state')
        expect(data).to_not have_key('node')
        expect(data).to_not have_key('pid')
      end

    end
  end

  # Special show method for the admin API that exposes some attributes
  # of WorkItem that we don't want to show to normal users.
  describe 'GET #api_show' do
    describe 'for admin user' do
      before do
        sign_in admin_user
      end

      it 'does expose :state, :node, or :id through admin #api_show' do
        get :show, id: item.id, format: :json
        data = JSON.parse(response.body)
        expect(data).to have_key('state')
        expect(data).to have_key('node')
        expect(data).to have_key('pid')
      end
    end
    describe 'for institutional admin' do
      before do
        sign_in institutional_admin
      end

      it 'restricts API usage' do
        get :show, id: item.id, format: :json
        expect(response.status).to eq 403
      end
    end
  end

  describe 'PUT #update' do

    describe 'for admin' do
      before do
        sign_in admin_user
      end

      it 'accepts extended queue data - state, node, pid' do
        pi_hash = FactoryGirl.create(:work_item_with_state).attributes
        put :update, id: item.id, format: 'json', work_item: pi_hash
        expect(response.status).to eq 200
      end

      it 'sets node to "" when params[:node] == ""' do
        pi_hash = FactoryGirl.create(:work_item_with_state).attributes
        pi_hash[:node] = ""
        put :update, id: item.id, format: 'json', work_item: pi_hash
        expect(assigns(:work_item).node).to eq('')
      end

    end

    describe 'for institutional admin' do
      before do
        sign_in institutional_admin
      end

      it 'restricts institutional admins from API usage when updating by id' do
        put :update, id: item.id, format: 'json'
        expect(response.status).to eq 403
      end

      # it 'restricts institutional admins from API usage when updating by etag' do
      #   put :update, etag: item.etag, name: item.name, bag_date: item.bag_date, format: 'json'
      #   expect(response.status).to eq 403
      # end
    end
  end

  describe 'GET #items_for_restore' do
    describe 'for admin user' do
      before do
        sign_in admin_user
        WorkItem.update_all(action: Pharos::Application::PHAROS_ACTIONS['restore'],
                                 stage: Pharos::Application::PHAROS_STAGES['requested'],
                                 status: Pharos::Application::PHAROS_STATUSES['pend'],
                                 retry: true)
      end

      it 'responds successfully with an HTTP 200 status code' do
        get :index, alt_action: 'restore', format: :json
        expect(response).to be_success
      end

      it 'assigns the correct @items' do
        get :index, alt_action: 'restore', format: :json
        expect(assigns(:items).count).to eq(WorkItem.count)
      end

      it 'does not include items where retry == false' do
        WorkItem.update_all(retry: false)
        get :index, alt_action: 'restore', format: :json
        expect(assigns(:items).count).to eq(0)
      end

    end

    describe 'for institutional admin' do
      before do
        sign_in institutional_admin
        2.times { FactoryGirl.create(:work_item) }
        WorkItem.update_all(action: Pharos::Application::PHAROS_ACTIONS['restore'],
                                 stage: Pharos::Application::PHAROS_STAGES['requested'],
                                 status: Pharos::Application::PHAROS_STATUSES['pend'],
                                 institution: institutional_admin.institution.identifier,
                                 retry: true)

      end

      it 'restricts access to the admin API' do
        get :index, alt_action: 'restore', format: :json
        expect(response.status).to eq 403
      end
    end

    describe 'with object_identifier param' do
      before do
        3.times do
          FactoryGirl.create(:work_item, action: Pharos::Application::PHAROS_ACTIONS['fixity'])
        end
        WorkItem.update_all(action: Pharos::Application::PHAROS_ACTIONS['restore'],
                                 institution: institution.identifier,
                                 retry: true)
        WorkItem.all.limit(2).update_all(object_identifier: 'mickey/mouse')
        sign_in admin_user
      end

      it 'should return only items with the specified object_identifier' do
        get :index, alt_action: 'restore', object_identifier: 'mickey/mouse', format: :json
        expect(assigns(:items).count).to eq(2)
      end
    end
  end

  describe 'GET #items_for_dpn' do
    describe 'for admin user' do
      before do
        sign_in admin_user
        WorkItem.update_all(action: Pharos::Application::PHAROS_ACTIONS['dpn'],
                                 stage: Pharos::Application::PHAROS_STAGES['requested'],
                                 status: Pharos::Application::PHAROS_STATUSES['pend'],
                                 retry: true)
      end

      it 'responds successfully with an HTTP 200 status code' do
        get :index, alt_action: 'dpn', format: :json
        expect(response).to be_success
      end

      it 'assigns the correct @items' do
        get :index, alt_action: 'dpn', format: :json
        expect(assigns(:items).count).to eq(WorkItem.count)
      end

      it 'does not include items where retry == false' do
        WorkItem.update_all(retry: false)
        get :index, alt_action: 'dpn', format: :json
        expect(assigns(:items).count).to eq(0)
      end

    end

    describe 'for institutional admin' do
      before do
        sign_in institutional_admin
        2.times { FactoryGirl.create(:work_item) }
        WorkItem.update_all(action: Pharos::Application::PHAROS_ACTIONS['dpn'],
                                 stage: Pharos::Application::PHAROS_STAGES['requested'],
                                 status: Pharos::Application::PHAROS_STATUSES['pend'],
                                 institution: institutional_admin.institution.identifier,
                                 retry: true)

      end

      it 'restricts access to the admin API' do
        get :index, alt_action: 'dpn', format: :json
        expect(response.status).to eq 403
      end
    end

    describe 'with object_identifier param' do
      before do
        3.times do
          FactoryGirl.create(:work_item, action: Pharos::Application::PHAROS_ACTIONS['fixity'])
        end
        WorkItem.update_all(action: Pharos::Application::PHAROS_ACTIONS['dpn'],
                                 institution: institution.identifier,
                                 retry: true)
        WorkItem.all.limit(2).update_all(object_identifier: 'mickey/mouse')
        sign_in admin_user
      end

      it 'should return only items with the specified object_identifier' do
        get :index, alt_action: 'dpn', object_identifier: 'mickey/mouse', format: :json
        expect(assigns(:items).count).to eq(2)
      end
    end
  end

  describe 'GET #items_for_delete' do
    describe 'for admin user' do
      before do
        sign_in admin_user
        WorkItem.update_all(action: Pharos::Application::PHAROS_ACTIONS['delete'],
                                 stage: Pharos::Application::PHAROS_STAGES['requested'],
                                 status: Pharos::Application::PHAROS_STATUSES['pend'],
                                 retry: true)
      end

      it 'responds successfully with an HTTP 200 status code' do
        get :index, alt_action: 'delete', format: :json
        expect(response).to be_success
      end

      it 'assigns the correct @items' do
        get :index, alt_action: 'delete', format: :json
        expect(assigns(:items).count).to eq(WorkItem.count)
      end

      it 'does not include items where retry == false' do
        WorkItem.update_all(retry: false)
        get :index, alt_action: 'delete', format: :json
        expect(assigns(:items).count).to eq(0)
      end

    end

    describe 'for institutional admin' do
      before do
        sign_in institutional_admin
        2.times { FactoryGirl.create(:work_item) }
        WorkItem.update_all(action: Pharos::Application::PHAROS_ACTIONS['delete'],
                                 stage: Pharos::Application::PHAROS_STAGES['requested'],
                                 status: Pharos::Application::PHAROS_STATUSES['pend'],
                                 institution: institutional_admin.institution.identifier,
                                 retry: true)
      end

      it 'restricts access to the admin API' do
        get :index, alt_action: 'delete', format: :json
        expect(response.status).to eq 403
      end
    end

    describe 'with object_identifier param' do
      before do
        3.times do
          FactoryGirl.create(:work_item,
                             action: Pharos::Application::PHAROS_ACTIONS['delete'],
                             stage: Pharos::Application::PHAROS_STAGES['requested'],
                             status: Pharos::Application::PHAROS_STATUSES['pend'],
                             institution: institutional_admin.institution.identifier,
                             object_identifier: 'mickey/mouse',
                             generic_file_identifier: 'mickey/mouse/club',
                             retry: true)
        end
        wi = WorkItem.last
        wi.generic_file_identifier = 'something/else'
        wi.save
        sign_in admin_user
      end

      it 'should return only items with the specified object_identifier' do
        get :index, alt_action: 'delete', generic_file_identifier: 'mickey/mouse/club', format: :json
        expect(assigns(:items).count).to eq(2)
      end
    end
  end

  describe 'POST #delete_test_items' do
    before do
      sign_in admin_user
      5.times do
        FactoryGirl.create(:work_item, institution: 'test.edu')
      end
    end
    after do
      WorkItem.where(institution: 'test.edu').delete_all
    end

    it 'should return only items with the specified object_identifier' do
      post :index, alt_action: 'delete_test', format: :json
      expect(WorkItem.where(institution: 'test.edu').count).to eq 0
    end
  end

  describe 'POST #set_restoration_status' do
    describe 'for admin user' do
      before do
        sign_in admin_user
        WorkItem.update_all(action: Pharos::Application::PHAROS_ACTIONS['restore'],
                                 stage: Pharos::Application::PHAROS_STAGES['requested'],
                                 status: Pharos::Application::PHAROS_STATUSES['pend'],
                                 retry: false,
                                 object_identifier: 'ned/flanders')
      end

      it 'responds successfully with an HTTP 200 status code' do
        post(:index, alt_action: 'set_restoration_status', format: :json, object_identifier: 'ned/flanders',
             stage: 'Resolve', status: 'Success', note: 'Lightyear', retry: true)
        expect(response).to be_success
      end

      it 'assigns the correct @item' do
        post(:index, alt_action: 'set_restoration_status', format: :json, object_identifier: 'ned/flanders',
             stage: 'Resolve', status: 'Success', note: 'Buzz', retry: true)
        expected_item = WorkItem.where(object_identifier: 'ned/flanders').order(created_at: :desc).first
        expect(assigns(:item).id).to eq(expected_item.id)
      end

      it 'updates the correct @item' do
        WorkItem.first.update(object_identifier: 'homer/simpson')
        post(:index, alt_action: 'set_restoration_status', format: :json, object_identifier: 'ned/flanders',
             stage: 'Resolve', status: 'Success', note: 'Aldrin', retry: true)
        update_count = WorkItem.where(object_identifier: 'ned/flanders',
                                           stage: 'Resolve', status: 'Success', retry: true).count
        expect(update_count).to eq(1)
      end

      it 'returns 404 for no matching records' do
        WorkItem.update_all(object_identifier: 'homer/simpson')
        post(:index, alt_action: 'set_restoration_status', format: :json, object_identifier: 'ned/flanders',
             stage: 'Resolve', status: 'Success', note: 'Neil', retry: true)
        expect(response.status).to eq(404)
      end

      it 'returns 400 for bad request' do
        post(:index, alt_action: 'set_restoration_status', format: :json, object_identifier: 'ned/flanders',
             stage: 'Invalid_Stage', status: 'Invalid_Status', note: 'Armstrong', retry: true)
        expect(response.status).to eq(400)
      end

      it 'updates node, state, pid and needs_admin_review' do
        post(:index, alt_action: 'set_restoration_status', format: :json, object_identifier: 'ned/flanders',
             stage: 'Resolve', status: 'Success', note: 'Lightyear', retry: true,
             node: '10.11.12.13', state: '{JSON data}', pid: 4321, needs_admin_review: true)
        expect(response).to be_success
        wi = WorkItem.where(object_identifier: 'ned/flanders',
                                 action: Pharos::Application::PHAROS_ACTIONS['restore']).order(created_at: :desc).first
        expect(wi.node).to eq('10.11.12.13')
        expect(wi.state).to eq('{JSON data}')
        expect(wi.pid).to eq(4321)
        expect(wi.needs_admin_review).to eq(true)
      end

      it 'clears node, pid and needs_admin_review, updates state' do
        post(:index, alt_action: 'set_restoration_status', format: :json, object_identifier: 'ned/flanders',
             stage: 'Resolve', status: 'Success', note: 'Lightyear', retry: true,
             node: nil, pid: 0, state: '{new JSON data}', needs_admin_review: false)
        expect(response).to be_success
        wi = WorkItem.where(object_identifier: 'ned/flanders',
                                 action: Pharos::Application::PHAROS_ACTIONS['restore']).order(created_at: :desc).first
        expect(wi.node).to eq(nil)
        expect(wi.state).to eq('{new JSON data}')
        expect(wi.pid).to eq(0)
        expect(wi.needs_admin_review).to eq(false)
      end

    end

    describe 'for admin user - with duplicate entries' do
      before do
        sign_in admin_user
        WorkItem.update_all(action: Pharos::Application::PHAROS_ACTIONS['restore'],
                                 stage: Pharos::Application::PHAROS_STAGES['requested'],
                                 status: Pharos::Application::PHAROS_STATUSES['pend'],
                                 retry: false,
                                 object_identifier: 'ned/flanders',
                                 etag: '12345678')
      end

      # PivotalTracker #93375060
      # All Work Items now have the same identifier and etag.
      # When we update the restoration record, it should update only one
      # record (the latest). None of the older restore requests should
      # be touched.
      it 'updates the correct @items' do
        post(:index, alt_action: 'set_restoration_status', format: :json, object_identifier: 'ned/flanders',
             stage: 'Resolve', status: 'Success', note: 'Aldrin', retry: true)
        update_count = WorkItem.where(object_identifier: 'ned/flanders',
                                           stage: 'Resolve', status: 'Success', retry: true).count
        # Should be only one item updated...
        expect(update_count).to eq(1)
        # ... and it should be the most recent
        restore_items = WorkItem.where(object_identifier: 'ned/flanders',
                                            action: Pharos::Application::PHAROS_ACTIONS['restore']).order(created_at: :desc)
        restore_items.each_with_index do |item, index|
          if index == 0
            # first item should be updated
            expect(item.status).to eq('Success')
          else
            # all other items should not be updated
            expect(item.status).to eq(Pharos::Application::PHAROS_STATUSES['pend'])
          end
        end
      end
    end

    describe 'for institutional admin user' do
      before do
        sign_in institutional_admin
        WorkItem.update_all(action: Pharos::Application::PHAROS_ACTIONS['restore'],
                                 stage: Pharos::Application::PHAROS_STAGES['requested'],
                                 status: Pharos::Application::PHAROS_STATUSES['pend'],
                                 retry: false,
                                 object_identifier: 'ned/flanders')
      end

      it 'restricts access to the admin API' do
        post(:index, alt_action: 'set_restoration_status', format: :json, object_identifier: 'ned/flanders',
             stage: 'Resolve', status: 'Success', note: 'Lightyear', retry: true)
        expect(response.status).to eq 403
      end
    end
  end

  describe 'Post #create' do
    describe 'for admin user' do
      let (:attributes) { FactoryGirl.attributes_for(:work_item) }
      before do
        sign_in admin_user
      end

      after do
        WorkItem.delete_all
      end

      it 'should reject no parameters' do
        expect {
          post :create, {}
        }.to raise_error ActionController::ParameterMissing
      end

      it 'should reject a status, stage or action that is not allowed' do
        post :create, work_item: {name: '123456.tar', etag: '1234567890', bag_date: Time.now.utc, user: 'Kelly Croswell', institution: institution.identifier,
                                       bucket: "aptrust.receiving.#{institution.identifier}", date: Time.now.utc, note: 'Note', action: 'File',
                                       stage: "Entry", status: 'Finalized', outcome: 'Outcome', reviewed: false}, format: 'json'
        expect(response.code).to eq '422' #Unprocessable Entity
        expect(JSON.parse(response.body)).to eq( { 'status' => ['Status is not one of the allowed options'],
                                                   'stage' => ['Stage is not one of the allowed options'],
                                                   'action' => ['Action is not one of the allowed options']})
      end

      it 'should accept good parameters via json' do
        expect {
          post :create, work_item: {name: '123456.tar', etag: '1234567890', bag_date: Time.now.utc, user: 'Kelly Croswell', institution: institution.identifier,
                                         bucket: "aptrust.receiving.#{institution.identifier}", date: Time.now.utc, note: 'Note', action: Pharos::Application::PHAROS_ACTIONS['fixity'],
                                         stage: Pharos::Application::PHAROS_STAGES['fetch'], status: Pharos::Application::PHAROS_STATUSES['fail'], outcome: 'Outcome', reviewed: false}, format: 'json'
        }.to change(WorkItem, :count).by(1)
        expect(response.status).to eq(201)
        assigns[:work_item].should be_kind_of WorkItem
        expect(assigns(:work_item).name).to eq '123456.tar'
      end

      it 'should fix an item with a null reviewed flag' do
        post :create, work_item: {name: '123456.tar', etag: '1234567890', bag_date: Time.now.utc, user: 'Kelly Croswell', institution: institution.identifier,
                                       bucket: "aptrust.receiving.#{institution.identifier}", date: Time.now.utc, note: 'Note', action: Pharos::Application::PHAROS_ACTIONS['fixity'],
                                       stage: Pharos::Application::PHAROS_STAGES['fetch'], status: Pharos::Application::PHAROS_STATUSES['fail'], outcome: 'Outcome', reviewed: nil}, format: 'json'
        expect(response.status).to eq(201)
        assigns[:work_item].should be_kind_of WorkItem
        expect(assigns(:work_item).reviewed).to eq(false)
      end
    end

    describe 'for institutional admin' do
      before do
        sign_in institutional_admin
      end

      after do
        WorkItem.delete_all
      end

      it 'restricts institutional admins from API usage' do
        post :create, work_item: {name: '123456.tar', etag: '1234567890', bag_date: Time.now.utc, user: 'Kelly Croswell', institution: institution.identifier,
                                       bucket: "aptrust.receiving.#{institution.identifier}", date: Time.now.utc, note: 'Note', action: Pharos::Application::PHAROS_ACTIONS['fixity'],
                                       stage: Pharos::Application::PHAROS_STAGES['fetch'], status: Pharos::Application::PHAROS_STATUSES['fail'], outcome: 'Outcome', reviewed: false},
             format: 'json'
        expect(response.status).to eq 403
      end
    end
  end

  describe 'Post #review_selected' do
    describe 'as admin user' do
      let!(:working_item) { FactoryGirl.create(:work_item, action: Pharos::Application::PHAROS_ACTIONS['fixity'], status: Pharos::Application::PHAROS_STATUSES['start']) }
      let(:item_id) { "r_#{item.id}" }
      let(:work_id) { "r_#{working_item.id}" }
      before do
        sign_in admin_user
      end

      after do
        WorkItem.delete_all
      end

      it "should update an item's review field to true" do
        post :index, alt_action: 'review_selected', review: [item_id], format: 'js'
        expect(response.status).to eq(200)
        WorkItem.find(item.id).reviewed.should eq(true)
      end

      it 'should not review a working item' do
        post :index, alt_action: 'review_selected', review: [work_id], format: 'js'
        expect(response.status).to eq(200)
        WorkItem.find(working_item.id).reviewed.should eq(false)
      end
    end

    describe 'as institutional_admin' do
      let(:user_id) { "r_#{user_item.id}" }
      before do
        sign_in institutional_admin
      end

      after do
        WorkItem.delete_all
      end

      it "should update an item's review field to true" do
        post :index, alt_action: 'review_selected', review: [user_id], format: 'js'
        expect(response.status).to eq(200)
        WorkItem.find(user_item.id).reviewed.should eq(true)
      end
    end
  end

  describe 'Post #review_all' do
    let!(:failed_item) { FactoryGirl.create(:work_item, action: Pharos::Application::PHAROS_ACTIONS['fixity'], status: Pharos::Application::PHAROS_STATUSES['fail']) }
    let!(:second_item) { FactoryGirl.create(:work_item, action: Pharos::Application::PHAROS_ACTIONS['fixity'], status: Pharos::Application::PHAROS_STATUSES['fail'], bucket: "aptrust.receiving.#{institution.identifier}", institution: institution.identifier) }
    describe 'as admin user' do
      before do
        sign_in admin_user
        session[:purge_datetime] = Time.now.utc
      end

      after do
        WorkItem.delete_all
      end

      it 'should reset the purge datetime in the session variable' do
        time_before = session[:purge_datetime]
        get :index, alt_action: 'review_all'
        session[:purge_datetime].should_not eq(time_before)
      end

      it "should update all item's review fields to true" do
        get :index, alt_action: 'review_all'
        expect(response.status).to eq(302)
        WorkItem.find(failed_item.id).reviewed.should eq(true)
      end
    end

    describe 'as institutional admin user' do
      before do
        sign_in institutional_admin
        session[:purge_datetime] = Time.now.utc
      end

      it "should update all items associated with user's institution's review fields to true" do
        get :index, alt_action: 'review_all'
        expect(response.status).to eq(302)
        WorkItem.find(second_item.id).reviewed.should eq(true)
      end

    end
  end

  describe 'GET #ingested_since' do
    let(:user) { FactoryGirl.create(:user, :admin) }
    let(:other_user) { FactoryGirl.create(:user, :institutional_admin) }
    before do
      10.times do FactoryGirl.create(:ingested_item) end
      get :show, id: item.id
    end

    after do
      WorkItem.delete_all
    end

    it 'admin can get items ingested since' do
      sign_in user
      get :index, alt_action: 'ingested_since', since: '2009-01-01', format: :json
      expect(response).to be_successful
      expect(assigns(:items).length).to eq 10
    end

    it 'missing date causes error' do
      sign_in user
      expected = { 'error' => 'Param since must be a valid datetime' }.to_json
      get :index, alt_action: 'ingested_since', since: '', format: :json
      expect(response.status).to eq 400
      expect(response.body).to eq expected
    end

    it 'non admin users can not use API ingested since route' do
      sign_in other_user
      get :index, alt_action: 'ingested_since', since: '2009-01-01', format: :json
      expect(response.status).to eq 403
    end

  end

  describe 'GET #search' do
    let(:user) { FactoryGirl.create(:user, :admin) }
    before do
      WorkItem.delete_all
    end

    describe 'when not signed in' do
      it 'should redirect to login' do
        get :index, institution_id: 'apt:123'
        expect(response).to redirect_to root_url + 'users/sign_in'
      end
    end

    describe 'when some objects are in the repository and signed in' do
      let!(:item1) { FactoryGirl.create(:work_item, name: '1234567890.tar', etag: '3') }
      let!(:item2) { FactoryGirl.create(:work_item, name: '1238907543.tar', etag: '4') }
      let!(:item3) { FactoryGirl.create(:work_item, name: '1', etag: '1548cdbe82348bdd32mds') }
      let!(:item4) { FactoryGirl.create(:work_item, name: '2', etag: '23045ldk2383xd320932k') }
      before { sign_in user }
      it 'should bring back all objects on an * search' do
        get :index, search_field: 'All Fields', qq: '*'
        expect(response).to be_successful
        expect(assigns(:items).map &:id).to match_array [item1.id, item2.id, item3.id, item4.id]
      end

      it 'should match a partial search on name' do
        get :index, search_field: 'Name', qq: '123'
        expect(response).to be_successful
        expect(assigns(:items).map &:id).to match_array [item1.id, item2.id]
      end

      it 'should match an exact search on name' do
        get :index, search_field: 'Name', qq: '1238907543.tar'
        expect(response).to be_successful
        expect(assigns(:items).map &:id).to match_array [item2.id]
      end

      it 'should match a partial search on etag' do
        get :index, search_field: 'Etag', qq: '32'
        expect(response).to be_successful
        expect(assigns(:items).map &:id).to match_array [item3.id, item4.id]
      end

      it 'should match an exact search on etag' do
        get :index, search_field: 'Etag', qq: '1548cdbe82348bdd32mds'
        expect(response).to be_successful
        expect(assigns(:items).map &:id).to match_array [item3.id]
      end
    end
  end

  describe 'GET #api_search' do
    let!(:item1) { FactoryGirl.create(:work_item,
                                      name: 'item1.tar',
                                      etag: 'etag1',
                                      institution: 'inst1',
                                      retry: true,
                                      reviewed: false,
                                      bag_date: '2014-10-17 14:56:56Z',
                                      action: 'Ingest',
                                      stage: 'Record',
                                      status: 'Success',
                                      node: '10.11.12.13',
                                      object_identifier: 'test.edu/item1',
                                      generic_file_identifier: 'test.edu/item1/file1.pdf') }

    describe 'for admin user' do
      before do
        sign_in admin_user
      end

      it 'returns all records when no criteria specified' do
        get :index, alt_action: 'api_search', format: :json
        assigns(:items).should include(user_item)
        assigns(:items).should include(item)
        assigns(:items).should include(item1)
      end

      # Note: Use strings for true/false, as we'd get in a web
      # request, or SQLite search fails. Also be sure to include
      # the Z at the end of the bag_date string.
      it 'filters down to the right records' do
        get(:index, alt_action: 'api_search', format: :json, name: 'item1.tar',
            etag: 'etag1', institution: 'inst1',
            retry: 'true', reviewed: 'false',
            bag_date: '2014-10-17 14:56:56Z',
            action: 'Ingest', stage: 'Record',
            status: 'Success', object_identifier: 'test.edu/item1',
            generic_file_identifier: 'test.edu/item1/file1.pdf')
        assigns(:items).should_not include(user_item)
        assigns(:items).should_not include(item)
        assigns(:items).should include(item1)
      end

      it 'filters on new fields' do
        get(:index, alt_action: 'api_search', format: :json, node: '10.11.12.13', needs_admin_review: false)
        assigns(:items).should_not include(user_item)
        assigns(:items).should_not include(item)
        assigns(:items).should include(item1)
      end

      it 'filters down to null nodes' do
        get(:index, alt_action: 'api_search', format: :json, node: 'null')
        assigns(:items).should include(user_item)
        assigns(:items).should include(item)
        assigns(:items).should_not include(item1)
      end
    end

    describe 'for institutional admin' do
      before do
        sign_in institutional_admin
      end

      it 'restricts institutional admins from API usage' do
        get :index, alt_action: 'api_search', format: 'json'
        expect(response.status).to eq 403
      end
    end
  end

  describe 'GET #api_index' do
    let!(:item1) { FactoryGirl.create(:work_item, name: 'item1.tar', stage: 'Unpack', institution: institutional_admin.institution.identifier) }
    let!(:item2) { FactoryGirl.create(:work_item, name: '1238907543.tar', stage: 'Unpack', institution: institutional_admin.institution.identifier) }
    let!(:item3) { FactoryGirl.create(:work_item, name: '1', stage: 'Unpack') }
    let!(:item4) { FactoryGirl.create(:work_item, name: '2', stage: 'Unpack') }
    let!(:item5) { FactoryGirl.create(:work_item, name: '1234567890.tar', stage: 'Unpack') }

    describe 'for an admin user' do
      before do
        sign_in admin_user
      end

      it 'returns all items when no other parameters are specified' do
        get :index, format: :json
        assigns(:items).should include(user_item)
        assigns(:items).should include(item)
        assigns(:items).should include(item1)
      end

      it 'filters down to the right records and has the right count' do
        get :index, format: :json, name_contains: 'item1'
        assigns(:items).should_not include(user_item)
        assigns(:items).should_not include(item)
        assigns(:items).should include(item1)
        assigns(:count).should == 1
      end

      it 'returns the correct next and previous links' do
        get :index, format: :json, per_page: 2, page: 2, stage: 'unpack'
        assigns(:next).should == 'http://test.host/member-api/v1/items/?page=3&per_page=2&stage=unpack'
        assigns(:previous).should == 'http://test.host/member-api/v1/items/?page=1&per_page=2&stage=unpack'
      end
    end

    describe 'for an institutional admin user' do
      before do
        sign_in institutional_admin
      end

      it "returns only the items within the user's institution" do
        get :index, format: :json
        assigns(:items).should include(item1)
        assigns(:items).should include(item2)
        assigns(:items).should_not include(item3)
        assigns(:items).should_not include(item4)
        assigns(:items).should_not include(item5)
      end
    end
  end
end
