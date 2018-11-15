require 'spec_helper'

RSpec.describe WorkItemsController, type: :controller do
  let!(:institution) { FactoryBot.create(:member_institution) }
  let!(:admin_user) { FactoryBot.create(:user, :admin) }
  let!(:institutional_admin) { FactoryBot.create(:user, :institutional_admin, institution: institution) }
  let!(:object) { FactoryBot.create(:intellectual_object, institution: institution, access: 'institution') }
  let!(:file) { FactoryBot.create(:generic_file, intellectual_object: object) }
  let!(:item) { FactoryBot.create(:work_item, institution: institution, intellectual_object: object, object_identifier: object.identifier, action: Pharos::Application::PHAROS_ACTIONS['fixity'], status: Pharos::Application::PHAROS_STATUSES['success'], retry: false) }
  let!(:user_item) { FactoryBot.create(:work_item, object_identifier: object.identifier, action: Pharos::Application::PHAROS_ACTIONS['fixity'], institution: institution, status: Pharos::Application::PHAROS_STATUSES['fail'], retry: false) }
  let!(:state_item) { FactoryBot.create(:work_item_state, work_item: item) }
  let!(:user_state_item) { FactoryBot.create(:work_item_state, work_item: user_item) }

  after do
    WorkItemState.delete_all
    WorkItem.delete_all
    GenericFile.delete_all
    IntellectualObject.delete_all
    User.delete_all
    Institution.delete_all
  end

  describe 'GET #index' do
    describe 'for admin user' do
      before do
        sign_in admin_user
      end

      it 'responds successfully with an HTTP 200 status code' do
        get :index
        expect(response).to be_successful
      end

      it 'renders the index template' do
        get :index
        expect(response).to render_template('old_index')
      end

      it 'assigns the requested institution as @institution' do
        get :index
        assigns(:institution).should eq( admin_user.institution)
      end

      it 'responds with an empty results object the call is json' do
        get :index, params: { name: 'name_of_something_not_found' }, format: :json
        expect(response.status).to eq(200)
        data = JSON.parse(response.body)
        expect(data['count']).to eq(0)
        expect(data['next']).to be_nil
        expect(data['previous']).to be_nil
        expect(data['results']).to eq([])
      end

      it 'returns work items where the node is not null' do
        node_item = FactoryBot.create(:work_item, node: 'services.aptrust.org')
        get :index, params: { node_not_empty: 'true' }, format: :json
        expect(response.status).to eq(200)
        data = JSON.parse(response.body)
        expect(data['count']).to eq(1)
        expect(data['results'][0]['id']).to eq(node_item.id)
      end

      it 'returns work items where the node is null' do
        node_item = FactoryBot.create(:work_item, node: nil)
        get :index, params: { node_empty: true }, format: :json
        expect(response.status).to eq(200)
        data = JSON.parse(response.body)
        expect(data['count']).to eq(3)
        expect(data['results'][0]['id']).to eq(node_item.id)
      end

      it 'filters by queued' do
        WorkItem.update_all(queued_at: nil)
        get :index, params: { queued: "true" }, format: :json
        assigns(:items).should be_empty
        get :index, params: { queued: "false" }, format: :json
        data = JSON.parse(response.body)
        expect(data['count']).to eq(2)

        WorkItem.update_all(queued_at: Time.now.utc)
        get :index, params: { queued: "false" }, format: :json
        assigns(:items).should be_empty
        get :index, params: { queued: "true" }, format: :json
        data = JSON.parse(response.body)
        expect(data['count']).to eq(2)
      end

      it 'filters by retry' do
        WorkItem.first.update(retry: true)
        get :index, format: :json
        data = JSON.parse(response.body)
        expect(data['count']).to eq(2)
        WorkItem.update_all(retry: true)
        get :index, params: { retry: 'false' }, format: :json
        assigns(:items).should be_empty
        get :index, params: { retry: 'true' }, format: :json
        data = JSON.parse(response.body)
        expect(data['count']).to eq(2)
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
    end
  end

  describe 'GET #show' do
    describe 'for admin user' do
      before do
        sign_in admin_user
      end
      it 'responds successfully with an HTTP 200 status code' do
        get :show, params: { id: item.id }
        expect(response).to be_successful
      end

      it 'renders the show template' do
        get :show, params: { id: item.id }
        expect(response).to render_template('show')
      end

      it 'assigns the requested item as @work_item' do
        get :show, params: { id: item.id }
        assigns(:work_item).id.should eq(item.id)
      end

      it 'assigns the requested institution as @institution' do
        get :show, params: { id: item.id }
        assigns(:institution).should eq( admin_user.institution)
      end

      it 'exposes :state, :node, or :pid for the admin user' do
        get :show, params: { id: item.id }, format: :json
        data = JSON.parse(response.body)
        expect(data).to have_key('node')
        expect(data).to have_key('pid')
      end

      it 'returns 404, not 500, for item not found' do
        get :show, params: { etag: 'does not exist', name: 'duznot igzist', bag_date: '1901-01-01' }, format: 'json'
        expect(response.status).to eq(404)
      end
    end

    describe 'for institutional admin' do
      before do
        sign_in institutional_admin
      end

      # it 'restricts API usage' do
      #   get :show, params: { etag: item.etag, name: item.name, bag_date: item.bag_date }, format: 'json'
      #   expect(response.status).to eq 403
      # end

      it 'does not expose :state, :node, or :pid to non-admins' do
        get :show, params: { id: item.id }, format: :json
        data = JSON.parse(response.body)
        expect(data).to_not have_key('state')
        expect(data).to_not have_key('node')
        expect(data).to_not have_key('pid')
      end

    end
  end

  describe 'GET #requeue' do
    describe 'for admin user' do
      before do
        sign_in admin_user
      end
      it 'responds successfully with an HTTP 200 status code' do
        get :requeue, params: { id: item.id }
        expect(response).to be_successful
      end

      it 'renders the requeue template' do
        get :requeue, params: { id: item.id }
        expect(response).to render_template('requeue')
      end

      it 'assigns the requested item as @work_item' do
        get :requeue, params: { id: item.id }
        assigns(:work_item).id.should eq(item.id)
      end

      it 'assigns the requested institution as @institution' do
        get :requeue, params: { id: item.id }
        assigns(:institution).should eq( admin_user.institution)
      end

    end

    describe 'for institutional admin' do
      before do
        sign_in institutional_admin
      end

      it 'does not allow the user to requeue the item' do
        get :requeue, params: { id: item.id }, format: :json
        expect(response.status).to eq 403
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
        get :show, params: { id: item.id }, format: :json
        data = JSON.parse(response.body)
        expect(data).to have_key('node')
        expect(data).to have_key('pid')
      end
    end
    describe 'for institutional admin' do
      before do
        sign_in institutional_admin
      end

      it 'does NOT expose :state, :node, or :id through admin #api_show' do
        get :show, params: { id: item.id }, format: :json
        expect(response.status).to eq 200
        data = JSON.parse(response.body)
        expect(data).not_to have_key('state')
        expect(data).not_to have_key('node')
        expect(data).not_to have_key('pid')
      end
    end
  end

  describe 'PUT #update' do

    describe 'for admin' do
      let(:current_dir) { File.dirname(__FILE__) }
      let(:json_file) { File.join(current_dir, '..', 'fixtures', 'work_item_batch.json') }
      let(:raw_json) { File.read(json_file) }
      let(:wi_data) { JSON.parse(raw_json) }
      let(:object) { FactoryBot.create(:intellectual_object) }
      let(:item_one) { FactoryBot.create(:work_item, object_identifier: object.identifier, status: 'Failed') }
      let(:item_two) { FactoryBot.create(:work_item, object_identifier: object.identifier, status: 'Failed') }
      before do
        sign_in admin_user
      end

      it 'accepts extended queue data - state, node, pid' do
        wi_hash = FactoryBot.create(:work_item_extended).attributes
        put :update, params: { id: item.id, format: 'json', work_item: wi_hash }
        expect(response.status).to eq 200
      end

      it 'sets node to "" when params[:node] == ""' do
        wi_hash = FactoryBot.create(:work_item_extended).attributes
        wi_hash['node'] = ""
        put :update, params: { id: item.id, format: 'json', work_item: wi_hash }
        expect(assigns(:work_item).node).to eq('')
      end

      it 'allows the user to update an entire batch of work items' do
        wi_data[0]['id'] = item_one.id
        wi_data[1]['id'] = item_two.id
        put :update, params: { save_batch: true, format: 'json', work_items: {items: wi_data} }
        expect(response.code).to eq '200'
        return_data = JSON.parse(response.body)
        expect(return_data.count).to eq 2
        expect(return_data[0]['id']).to eq item_one.id
        expect(return_data[1]['id']).to eq item_two.id
        expect(return_data[0]['status']).to eq 'Success'
        expect(return_data[1]['status']).to eq 'Success'
      end

      # it 'creates an email log if the item being updated is a completed restoration' do
      #   wi_hash = FactoryBot.create(:work_item_extended, action: Pharos::Application::PHAROS_ACTIONS['restore'],
      #       stage: Pharos::Application::PHAROS_STAGES['record'], status: Pharos::Application::PHAROS_STATUSES['success']).attributes
      #   post :update, params: { id: item.id, work_item: wi_hash }, format: :json
      #   expect(response.status).to eq(200)
      #   email_log = Email.where(item_id: item.id)
      #   expect(email_log.count).to eq(1)
      #   expect(email_log[0].email_type).to eq('restoration')
      # end

    end

    describe 'for institutional admin' do
      before do
        sign_in institutional_admin
      end

      it 'restricts institutional admins from API usage when updating by id' do
        wi_hash = FactoryBot.create(:work_item_extended).attributes
        put :update, params: { id: item.id, format: 'json', work_item: wi_hash }
        expect(response.status).to eq 403
      end

      # it 'restricts institutional admins from API usage when updating by etag' do
      #   put :update, params: { etag: item.etag, name: item.name, bag_date: item.bag_date }, format: 'json'
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
        get :items_for_restore, format: :json
        expect(response).to be_successful
      end

      it 'assigns the correct @items' do
        get :items_for_restore, format: :json
        expect(assigns(:items).count).to eq(WorkItem.count)
      end

      it 'does not include items where retry == false' do
        WorkItem.update_all(retry: false)
        get :items_for_restore, format: :json
        expect(assigns(:items).count).to eq(0)
      end

    end

    describe 'for institutional admin' do
      before do
        sign_in institutional_admin
        2.times { FactoryBot.create(:work_item, institution: institution, intellectual_object: object, object_identifier: object.identifier) }
        WorkItem.update_all(action: Pharos::Application::PHAROS_ACTIONS['restore'],
                                 stage: Pharos::Application::PHAROS_STAGES['requested'],
                                 status: Pharos::Application::PHAROS_STATUSES['pend'],
                                 institution_id: institutional_admin.institution.id,
                                 retry: true)

      end

      it 'restricts access to the admin API' do
        get :items_for_restore, format: :json
        expect(response.status).to eq 403
      end
    end

    describe 'with object_identifier param' do
      before do
        3.times do
          FactoryBot.create(:work_item,institution: institution, intellectual_object: object, object_identifier: object.identifier, action: Pharos::Application::PHAROS_ACTIONS['fixity'])
        end
        WorkItem.update_all(action: Pharos::Application::PHAROS_ACTIONS['restore'],
                            institution_id: institution.id,
                            retry: true)
        WorkItem.all.limit(2).update_all(object_identifier: 'mickey/mouse')
        sign_in admin_user
      end

      it 'should return only items with the specified object_identifier' do
        get :items_for_restore, params: { object_identifier: 'mickey/mouse' }, format: :json
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
        get :items_for_dpn, format: :json
        expect(response).to be_successful
      end

      it 'assigns the correct @items' do
        get :items_for_dpn, format: :json
        expect(assigns(:items).count).to eq(WorkItem.count)
      end

      it 'does not include items where retry == false' do
        WorkItem.update_all(retry: false)
        get :items_for_dpn, format: :json
        expect(assigns(:items).count).to eq(0)
      end

    end

    describe 'for institutional admin' do
      before do
        sign_in institutional_admin
        2.times { FactoryBot.create(:work_item, institution: institution, intellectual_object: object, object_identifier: object.identifier) }
        WorkItem.update_all(action: Pharos::Application::PHAROS_ACTIONS['dpn'],
                            stage: Pharos::Application::PHAROS_STAGES['requested'],
                            status: Pharos::Application::PHAROS_STATUSES['pend'],
                            institution_id: institutional_admin.institution.id,
                            retry: true)

      end

      it 'restricts access to the admin API' do
        get :items_for_dpn, format: :json
        expect(response.status).to eq 403
      end
    end

    describe 'with object_identifier param' do
      before do
        3.times do
          FactoryBot.create(:work_item, action: Pharos::Application::PHAROS_ACTIONS['fixity'], institution: institution, intellectual_object: object, object_identifier: object.identifier)
        end
        WorkItem.update_all(action: Pharos::Application::PHAROS_ACTIONS['dpn'],
                            institution_id: institution.id,
                            retry: true)
        WorkItem.all.limit(2).update_all(object_identifier: 'mickey/mouse')
        sign_in admin_user
      end

      it 'should return only items with the specified object_identifier' do
        get :items_for_dpn, params: { object_identifier: 'mickey/mouse' }, format: :json
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
        get :items_for_delete, format: :json
        expect(response).to be_successful
      end

      it 'assigns the correct @items' do
        get :items_for_delete, format: :json
        expect(assigns(:items).count).to eq(WorkItem.count)
      end

      it 'does not include items where retry == false' do
        WorkItem.update_all(retry: false)
        get :items_for_delete, format: :json
        expect(assigns(:items).count).to eq(0)
      end

    end

    describe 'for institutional admin' do
      before do
        sign_in institutional_admin
        2.times { FactoryBot.create(:work_item, institution: institution, intellectual_object: object, object_identifier: object.identifier) }
        WorkItem.update_all(action: Pharos::Application::PHAROS_ACTIONS['delete'],
                            stage: Pharos::Application::PHAROS_STAGES['requested'],
                            status: Pharos::Application::PHAROS_STATUSES['pend'],
                            institution_id: institutional_admin.institution.id,
                            retry: true)
      end

      it 'restricts access to the admin API' do
        get :items_for_delete, format: :json
        expect(response.status).to eq 403
      end
    end

    describe 'with object_identifier param' do
      before do
        3.times do
          FactoryBot.create(:work_item,
                             action: Pharos::Application::PHAROS_ACTIONS['delete'],
                             stage: Pharos::Application::PHAROS_STAGES['requested'],
                             status: Pharos::Application::PHAROS_STATUSES['pend'],
                             institution: institutional_admin.institution,
                             object_identifier: object.identifier,
                             intellectual_object: object,
                             generic_file_identifier: file.identifier,
                             retry: true)
        end
        new_file = FactoryBot.create(:generic_file)
        wi = WorkItem.last
        wi.generic_file_identifier = new_file.identifier
        wi.save
        sign_in admin_user
      end

      it 'should return only items with the specified object_identifier' do
        get :items_for_delete, params: { generic_file_identifier: file.identifier }, format: :json
        expect(assigns(:items).count).to eq(2)
      end
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
                                 object_identifier: object.identifier)
      end

      it 'responds successfully with an HTTP 200 status code' do
        post(:set_restoration_status, format: :json, params: { object_identifier:object.identifier,
             stage: 'Resolve', status: 'Success', note: 'Lightyear', retry: true })
        expect(response).to be_successful
      end

      it 'assigns the correct @item' do
        post(:set_restoration_status, format: :json, params: { object_identifier: object.identifier,
             stage: 'Resolve', status: 'Success', note: 'Buzz', retry: true })
        expected_item = WorkItem.where(object_identifier: object.identifier).order(created_at: :desc).first
        expect(assigns(:item).id).to eq(expected_item.id)
      end

      it 'updates the correct @item' do
        new_object = FactoryBot.create(:intellectual_object)
        WorkItem.first.update(object_identifier: new_object.identifier, intellectual_object: new_object)
        post(:set_restoration_status, format: :json, params: { object_identifier: object.identifier,
             stage: 'Resolve', status: 'Success', note: 'Aldrin', retry: true })
        update_count = WorkItem.where(object_identifier: object.identifier,
                                           stage: 'Resolve', status: 'Success', retry: true).count
        expect(update_count).to eq(1)
      end

      it 'returns 404 for no matching records' do
        WorkItem.update_all(object_identifier: 'homer/simpson')
        post(:set_restoration_status, format: :json, params: { object_identifier: object.identifier,
             stage: 'Resolve', status: 'Success', note: 'Neil', retry: true })
        expect(response.status).to eq(404)
      end

      it 'returns 400 for bad request' do
        post(:set_restoration_status, format: :json, params: { object_identifier: object.identifier,
             stage: 'Invalid_Stage', status: 'Invalid_Status', note: 'Armstrong', retry: true })
        expect(response.status).to eq(400)
      end

      it 'updates node, pid and needs_admin_review' do
        post(:set_restoration_status, format: :json, params: { object_identifier: object.identifier,
             stage: 'Resolve', status: 'Success', note: 'Lightyear', retry: true,
             node: '10.11.12.13', pid: 4321, needs_admin_review: true })
        expect(response).to be_successful
        wi = WorkItem.where(object_identifier: object.identifier,
                                 action: Pharos::Application::PHAROS_ACTIONS['restore']).order(created_at: :desc).first
        expect(wi.node).to eq('10.11.12.13')
        #expect(wi.work_item_state.state).to eq('{JSON data}')
        expect(wi.pid).to eq(4321)
        expect(wi.needs_admin_review).to eq(true)
      end

      it 'clears node, pid and needs_admin_review, updates state' do
        post :set_restoration_status, params: { object_identifier: object.identifier,
             stage: 'Resolve', status: 'Success', note: 'Lightyear', retry: true,
             node: nil, pid: 0, needs_admin_review: false }, format: :json
             expect(response).to be_successful
        wi = WorkItem.where(object_identifier: object.identifier,
                                 action: Pharos::Application::PHAROS_ACTIONS['restore']).order(created_at: :desc).first
        expect(wi.node).to eq(nil)
        #expect(wi.work_item_state.state).to eq('{new JSON data}')
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
                                 object_identifier: object.identifier,
                                 etag: '12345678')
      end

      # PivotalTracker #93375060
      # All Work Items now have the same identifier and etag.
      # When we update the restoration record, it should update only one
      # record (the latest). None of the older restore requests should
      # be touched.
      it 'updates the correct @items' do
        post(:set_restoration_status, format: :json, params: { object_identifier: object.identifier,
             stage: 'Resolve', status: 'Success', note: 'Aldrin', retry: true })
        update_count = WorkItem.where(object_identifier: object.identifier,
                                           stage: 'Resolve', status: 'Success', retry: true).count
        # Should be only one item updated...
        expect(update_count).to eq(1)
        # ... and it should be the most recent
        restore_items = WorkItem.where(object_identifier: object.identifier,
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
                            object_identifier: object.identifier)
      end

      it 'restricts access to the admin API' do
        post(:set_restoration_status, format: :json, params: { object_identifier: object.identifier,
             stage: 'Resolve', status: 'Success', note: 'Lightyear', retry: true })
        expect(response.status).to eq 403
      end
    end
  end

  describe 'Post #create' do
    describe 'for admin user' do
      let (:attributes) { FactoryBot.attributes_for(:work_item) }
      before do
        sign_in admin_user
      end

      after do
        WorkItem.delete_all
      end

      it 'should reject no parameters' do
        expect {
          post :create, params: {}
        }.to raise_error ActionController::ParameterMissing
      end

      it 'should reject a status, stage or action that is not allowed' do
        name = object.identifier.split('/')[1]
        post(:create, params: { work_item: {
               name: "#{name}.tar",
               etag: '1234567890',
               bag_date: Time.now.utc,
               user: 'Kelly Croswell',
               institution_id: institution.id,
               bucket: "aptrust.receiving.#{institution.identifier}",
               date: Time.now.utc,
               note: 'Note',
               action: 'File',
               stage: "Entry",
               status: 'Finalized',
               outcome: 'Outcome'} }, format: 'json')
        expect(response.code).to eq '422' #Unprocessable Entity
        expect(JSON.parse(response.body)).to eq( { 'status' => ['Status is not one of the allowed options'],
                                                   'stage' => ['Stage is not one of the allowed options'],
                                                   'action' => ['Action is not one of the allowed options']})
      end

      it 'should accept good parameters via json' do
        name = object.identifier.split('/')[1]
        expect {
          post(:create, params: { work_item: {
                 name: "#{name}.tar",
                 etag: '1234567890',
                 bag_date: Time.now.utc,
                 user: 'Kelly Croswell',
                 institution_id: institution.id,
                 bucket: "aptrust.receiving.#{institution.identifier}",
                 date: Time.now.utc,
                 note: 'Note',
                 action: Pharos::Application::PHAROS_ACTIONS['fixity'],
                 stage: Pharos::Application::PHAROS_STAGES['fetch'],
                 status: Pharos::Application::PHAROS_STATUSES['fail'],
                 outcome: 'Outcome'} }, format: 'json')
        }.to change(WorkItem, :count).by(1)
        expect(response.status).to eq(201)
        assigns[:work_item].should be_kind_of WorkItem
        expect(assigns(:work_item).name).to eq "#{name}.tar"
        # For admin user, make sure WorkItem.user is set to exactly
        # what we specify. Non-admin can't do this.
        expect(assigns(:work_item).user).to eq "Kelly Croswell"
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
        post :create, params: { work_item: {name: '123456.tar', etag: '1234567890', bag_date: Time.now.utc, user: 'Kelly Croswell', institution: institution,
                                       bucket: "aptrust.receiving.#{institution.identifier}", date: Time.now.utc, note: 'Note', action: Pharos::Application::PHAROS_ACTIONS['fixity'],
                                       stage: Pharos::Application::PHAROS_STAGES['fetch'], status: Pharos::Application::PHAROS_STATUSES['fail'], outcome: 'Outcome'} },
             format: 'json'
        expect(response.status).to eq 403
      end
    end
  end

  describe 'GET #ingested_since' do
    let(:user) { FactoryBot.create(:user, :admin) }
    let(:other_user) { FactoryBot.create(:user, :institutional_admin) }
    before do
      10.times do FactoryBot.create(:ingested_item) end
      get :show, params: { id: item.id }
    end

    after do
      WorkItem.delete_all
    end

    it 'admin can get items ingested since' do
      sign_in user
      get :ingested_since, params: { since: '2009-01-01' }, format: :json
      expect(response).to be_successful
      expect(assigns(:items).length).to eq 10
    end

    it 'missing date causes error' do
      sign_in user
      expected = { 'error' => 'Param since must be a valid datetime' }.to_json
      get :ingested_since, params: { since: '' }, format: :json
      expect(response.status).to eq 400
      expect(response.body).to eq expected
    end

    it 'non admin users can not use API ingested since route' do
      sign_in other_user
      get :ingested_since, params: { since: '2009-01-01' }, format: :json
      expect(response.status).to eq 403
    end

  end

  describe 'GET #api_search' do
    let!(:item1) { FactoryBot.create(:work_item,
                                      name: 'item1.tar',
                                      etag: 'etag1',
                                      institution: institution,
                                      retry: true,
                                      bag_date: '2014-10-17 14:56:56Z',
                                      action: 'Ingest',
                                      stage: 'Record',
                                      status: 'Success',
                                      node: '10.11.12.13',
                                      object_identifier: object.identifier,
                                      generic_file_identifier: file.identifier) }

    describe 'for admin user' do
      before do
        sign_in admin_user
      end

      it 'returns all records when no criteria specified' do
        get :api_search, format: :json
        assigns(:items).should include(user_item)
        assigns(:items).should include(item)
        assigns(:items).should include(item1)
      end

      # Note: Use strings for true/false, as we'd get in a web
      # request, or SQLite search fails. Also be sure to include
      # the Z at the end of the bag_date string.
      it 'filters down to the right records' do
        get(:api_search, format: :json, params: { name: 'item1.tar',
            etag: 'etag1', institution: institution.id,
            retry: 'true',
            bag_date: '2014-10-17 14:56:56Z',
            action: 'Ingest', stage: 'Record',
            status: 'Success', object_identifier: object.identifier,
            generic_file_identifier: file.identifier })
        assigns(:items).should_not include(user_item)
        assigns(:items).should_not include(item)
        assigns(:items).should include(item1)
      end

      it 'filters on new fields' do
        get(:api_search, format: :json, params: { node: '10.11.12.13', needs_admin_review: false })
        assigns(:items).should_not include(user_item)
        assigns(:items).should_not include(item)
        assigns(:items).should include(item1)
      end

      it 'filters down to null nodes' do
        get(:api_search, format: :json, params: { node: 'null' })
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
        get :api_search, format: 'json'
        expect(response.status).to eq 403
      end
    end
  end

  describe 'GET #api_index' do
    let!(:object1) { FactoryBot.create(:intellectual_object, institution: institutional_admin.institution, identifier: 'item1') }
    let!(:object2) { FactoryBot.create(:intellectual_object, institution: institutional_admin.institution, identifier: '1238907543') }
    let!(:object3) { FactoryBot.create(:intellectual_object, institution: institutional_admin.institution, identifier: '1') }
    let!(:object4) { FactoryBot.create(:intellectual_object, institution: institutional_admin.institution, identifier: '2') }
    let!(:object5) { FactoryBot.create(:intellectual_object, institution: institutional_admin.institution, identifier: '1234567890') }
    let!(:item1) { FactoryBot.create(:work_item, object_identifier: object1.identifier, name: 'item1.tar', stage: 'Unpack', institution: institutional_admin.institution, intellectual_object: object1) }
    let!(:item2) { FactoryBot.create(:work_item, object_identifier: object2.identifier, name: '1238907543.tar', stage: 'Unpack', institution: institutional_admin.institution, intellectual_object: object2) }
    let!(:item3) { FactoryBot.create(:work_item, object_identifier: object3.identifier, name: '1', stage: 'Unpack', intellectual_object: object3) }
    let!(:item4) { FactoryBot.create(:work_item, object_identifier: object4.identifier, name: '2', stage: 'Unpack', intellectual_object: object4) }
    let!(:item5) { FactoryBot.create(:work_item, object_identifier: object5.identifier, name: '1234567890.tar', stage: 'Unpack', intellectual_object: object5) }

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
        get :index, format: :json, params: { name_contains: 'item1' }
        assigns(:items).should_not include(user_item)
        assigns(:items).should_not include(item)
        assigns(:items).should include(item1)
        assigns(:count).should == 1
      end

      it 'can find by name, etag, bag_date' do
        get :index, format: :json, params: { name: item1.name, etag: item1.etag, bag_date: item1.bag_date }
        assigns(:items).should include(item1)
        assigns(:count).should == 1
      end

      it 'returns the correct next and previous links' do
        get :index, format: :json, params: { per_page: 2, page: 2, stage: 'Unpack' }
        assigns(:next).should == 'http://test.host/items.json?page=3&per_page=2&sort=date&stage=Unpack'
        assigns(:previous).should == 'http://test.host/items.json?page=1&per_page=2&sort=date&stage=Unpack'
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

  # describe 'PUT #update for completed restoration' do
  #   describe 'for admin' do
  #     let(:current_dir) { File.dirname(__FILE__) }
  #     let(:json_file) { File.join(current_dir, '..', 'fixtures', 'work_item_batch.json') }
  #     let(:raw_json) { File.read(json_file) }
  #     let(:wi_data) { JSON.parse(raw_json) }
  #     let(:institution) { FactoryBot.create(:member_institution) }
  #     let(:object) { FactoryBot.create(:intellectual_object, institution_id: institution.id) }
  #     let(:item_one) { FactoryBot.create(:work_item, institution_id: institution.id, intellectual_object_id: object.id, object_identifier: object.identifier) }
  #     before do
  #       sign_in admin_user
  #       WorkItem.delete_all
  #     end
  #
  #     it 'triggers an email notification' do
  #       wi_hash = FactoryBot.create(:work_item_extended).attributes
  #       wi_hash['action'] = Pharos::Application::PHAROS_ACTIONS['restore']
  #       wi_hash['status'] = Pharos::Application::PHAROS_STATUSES['success']
  #       wi_hash['stage'] = Pharos::Application::PHAROS_STAGES['record']
  #       expect { put :update, params: { id: item_one.id, format: 'json', work_item: wi_hash }
  #       }.to change(Email, :count).by(1)
  #       expect(assigns(:work_item).stage).to eq('Record')
  #       expect(assigns(:work_item).status).to eq('Success')
  #       expect(assigns(:work_item).action).to eq('Restore')
  #       email_log = Email.where(item_id: assigns(:work_item).id)
  #       expect(email_log.count).to eq(1)
  #       expect(email_log[0].email_type).to eq('restoration')
  #       email = ActionMailer::Base.deliveries.last
  #       expect(email.body.encoded).to eq("Admin Users at #{assigns(:work_item).institution.name},\r\n\r\nThis email notification is to inform you that one of your restoration requests has successfully completed.\r\nThe finished record of the restoration can be found at the following link:\r\n\r\n<a href=\"http://localhost:3000/items/#{assigns(:work_item).id}\" >#{assigns(:work_item).object_identifier}</a>\r\n\r\nPlease contact the APTrust team by replying to this email if you have any questions.\r\n")
  #     end
  #   end
  # end

  describe 'GET #notify_of_successful_restoration' do
    before do
      sign_in admin_user
    end

    it 'creates an email log of the notification email containing the restored items' do
      restored_item = FactoryBot.create(:work_item, action: Pharos::Application::PHAROS_ACTIONS['restore'],
                                         status: Pharos::Application::PHAROS_STATUSES['success'],
                                         stage: Pharos::Application::PHAROS_STAGES['record'])
      expect { get :notify_of_successful_restoration, format: :json }.to change(Email, :count).by(1)
      expect(response.status).to eq(200)
      email = ActionMailer::Base.deliveries.last
      expect(email.body.encoded).to include("http://localhost:3000/items?institution=#{restored_item.institution.id}&item_action=Restore&stage=Record&status=Success")
    end
  end

  describe 'GET #spot_test_restoration' do
    describe 'for an admin user' do
      before do
        sign_in admin_user
      end

      it 'creates an email log of the notification email containing the spot test notice and download link' do
        restored_item = FactoryBot.create(:work_item, action: Pharos::Application::PHAROS_ACTIONS['restore'],
                                          status: Pharos::Application::PHAROS_STATUSES['success'],
                                          stage: Pharos::Application::PHAROS_STAGES['record'],
                                          object_identifier: 'test.edu/bag_name',
                                          note: 'Bag test.edu/bag_name restored to https://s3.amazonaws.com/aptrust.restore.test.edu/bag_name.tar')
        expect { get :spot_test_restoration, params: { id: restored_item.id }, format: :json }.to change(Email, :count).by(1)
        expect(response.status).to eq(200)
        email = ActionMailer::Base.deliveries.last
        expect(email.body.encoded).to include("http://localhost:3000/items/#{restored_item.id}")
        expect(email.body.encoded).to include('https://s3.amazonaws.com/aptrust.restore.test.edu/bag_name.tar')
      end
    end

    describe 'for an institutional admin' do
      before do
        sign_in institutional_admin
      end

      it 'forbids access to the spot test endpoint' do
        get :spot_test_restoration, params: { id: item.id }, format: :json
        expect(response.status).to eq(403)
      end
    end


  end
end
