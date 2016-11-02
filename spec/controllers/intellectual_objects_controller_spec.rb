require 'spec_helper'

RSpec.describe IntellectualObjectsController, type: :controller do

  let(:inst1) { FactoryGirl.create(:institution) }
  let(:inst2) { FactoryGirl.create(:institution) }
  let(:inst_user) { FactoryGirl.create(:user, :institutional_user,
                                       institution: inst1) }
  let(:inst_admin) { FactoryGirl.create(:user, :institutional_admin,
                                       institution: inst1) }
  let(:sys_admin) { FactoryGirl.create(:user, :admin) }
  let!(:obj1) { FactoryGirl.create(:consortial_intellectual_object,
                                   institution: inst2) }
  let!(:obj2) { FactoryGirl.create(:institutional_intellectual_object,
                                   institution: inst1,
                                   identifier: 'test.edu/baggie',
                                   title: 'Aberdeen Wanderers',
                                   description: 'Founded in Aberdeen in 1928.') }
  let!(:obj3) { FactoryGirl.create(:institutional_intellectual_object,
                                   institution: inst2) }
  let!(:obj4) { FactoryGirl.create(:restricted_intellectual_object,
                                   institution: inst1,
                                   title: "Manchester City",
                                   description: 'The other Manchester team.') }
  let!(:obj5) { FactoryGirl.create(:restricted_intellectual_object,
                                   institution: inst2) }
  let!(:obj6) { FactoryGirl.create(:institutional_intellectual_object,
                                   institution: inst1,
                                   bag_name: '12345-abcde',
                                   alt_identifier: 'test.edu/some-bag',
                                   created_at: "2011-10-10T10:00:00Z",
                                   updated_at: "2011-10-10T10:00:00Z") }

  before(:all) do
    WorkItem.delete_all
    IntellectualObject.delete_all
  end

  describe 'GET #index' do

    describe 'when not signed in' do
      it 'should redirect to login' do
        get :index, institution_identifier: 'apt.edu'
        expect(response).to redirect_to root_url + 'users/sign_in'
      end
    end

    describe 'when signed in as institutional user' do
      before do
        sign_in inst_user
      end
      it 'should show results from my institution' do
        get :index, institution_identifier: inst1.identifier
        expect(response).to be_successful
        expect(assigns(:intellectual_objects).size).to eq 3
        expect(assigns(:intellectual_objects).map &:id).to match_array [obj2.id, obj4.id, obj6.id]
      end
    end

    describe 'when signed in as institutional admin' do
      before { sign_in inst_admin }
      it 'should show results from my institution' do
        get :index, institution_identifier: inst1.identifier
        expect(response).to be_successful
        expect(assigns(:intellectual_objects).size).to eq 3
        expect(assigns(:intellectual_objects).map &:id).to match_array [obj2.id, obj4.id, obj6.id]
      end
    end

    describe 'when signed in as system admin' do
      before { sign_in sys_admin }
      it 'should show all results' do
        get :index, {}
        expect(response).to be_successful
        expect(assigns(:intellectual_objects).size).to eq 6
        expect(assigns(:intellectual_objects).map &:id).to match_array [obj1.id, obj2.id, obj3.id,
                                                                        obj4.id, obj5.id, obj6.id]
      end
    end

    describe 'when signed in as any user' do
      it 'should apply filters' do
        [inst_user, inst_admin, sys_admin].each do |user|
          sign_in user

          get :index, created_before: '2016-07-26'
          expect(assigns(:intellectual_objects).size).to eq 1

          get :index, created_after: '2016-07-26'
          expect(assigns(:intellectual_objects).size).to be > 1

          get :index, updated_before: '2016-07-26'
          expect(assigns(:intellectual_objects).size).to eq 1

          get :index, updated_after: '2016-07-26'
          expect(assigns(:intellectual_objects).size).to be > 1

          get :index, description: 'Founded in Aberdeen in 1928.'
          expect(assigns(:intellectual_objects).size).to eq 1

          get :index, description_like: 'Aberdeen'
          expect(assigns(:intellectual_objects).size).to eq 1

          get :index, identifier: "test.edu/baggie"
          expect(assigns(:intellectual_objects).size).to eq 1

          get :index, identifier_like: "baggie"
          expect(assigns(:intellectual_objects).size).to eq 1

          get :index, alt_identifier: "test.edu/some-bag"
          expect(assigns(:intellectual_objects).size).to eq 1

          get :index, alt_identifier_like: "some-bag"
          expect(assigns(:intellectual_objects).size).to eq 1
        end
      end
    end

  end

  describe 'GET #show' do

    describe 'when not signed in' do
      it 'should redirect to login' do
        get :show, intellectual_object_identifier: obj1
        expect(response).to redirect_to root_url + 'users/sign_in'
      end
    end

    describe 'when signed in as institutional user' do
      before { sign_in inst_user }

      it "should show me my institution's object" do
        get :show, intellectual_object_identifier: obj2
        expect(response).to be_successful
        expect(assigns(:intellectual_object)).to eq obj2
      end

      it "should show me another institution's consortial object" do
        get :show, intellectual_object_identifier: obj1
        expect(response).to be_successful
        expect(assigns(:intellectual_object)).to eq obj1
      end

      it "should not show me another institution's private parts" do
        get :show, intellectual_object_identifier: obj3
        expect(response).to redirect_to root_url
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
    end

    describe 'when signed in as institutional admin' do
      before { sign_in inst_admin }

      it "should show me my institution's object" do
        get :show, intellectual_object_identifier: obj2
        expect(response).to be_successful
        expect(assigns(:intellectual_object)).to eq obj2
      end

      it "should show me another institution's consortial object" do
        get :show, intellectual_object_identifier: obj1
        expect(response).to be_successful
        expect(assigns(:intellectual_object)).to eq obj1
      end

      it "should not show me another institution's private parts" do
        get :show, intellectual_object_identifier: obj3
        expect(response).to redirect_to root_url
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
    end

    describe 'when signed in as system admin' do
      before { sign_in sys_admin }

      it "should show me my institution's object" do
        get :show, intellectual_object_identifier: obj2
        expect(response).to be_successful
        expect(assigns(:intellectual_object)).to eq obj2
      end

      it "should show me another institution's consortial object" do
        get :show, intellectual_object_identifier: obj1
        expect(response).to be_successful
        expect(assigns(:intellectual_object)).to eq obj1
      end

      it "should show me another institution's private parts" do
        get :show, intellectual_object_identifier: obj3
        expect(response).to be_successful
        expect(assigns(:intellectual_object)).to eq obj3
      end
    end

  end

  describe 'GET #edit' do
    let(:inst1_obj) { FactoryGirl.create(:consortial_intellectual_object, institution: inst1) }
    let(:inst2_obj) { FactoryGirl.create(:consortial_intellectual_object, institution: inst2) }
    after do
      inst1_obj.destroy
      inst2_obj.destroy
    end

    describe 'when not signed in' do
      it 'should redirect to login' do
        get :edit, intellectual_object_identifier: obj1
        expect(response).to redirect_to root_url + 'users/sign_in'
      end
    end

    describe 'when signed in as institutional user' do
      before { sign_in inst_user }
      it "should not let me edit my institution's objects" do
        get :edit, intellectual_object_identifier: inst1_obj
        expect(response).to redirect_to root_url
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
      it "should not let me edit other institution's objects" do
        get :edit, intellectual_object_identifier: inst2_obj
        expect(response).to redirect_to root_url
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
    end

    describe 'when signed in as institutional admin' do
      before { sign_in inst_admin }
      it "should not let me edit my institution's objects" do
        get :edit, intellectual_object_identifier: inst1_obj
        expect(response).to redirect_to root_url
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
      it "should not let me edit other institution's objects" do
        get :edit, intellectual_object_identifier: inst2_obj
        expect(response).to redirect_to root_url
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
    end

    describe 'when signed in as system admin' do
      before { sign_in sys_admin }
      it 'should not let me edit this' do
        get :edit, intellectual_object_identifier: inst1_obj
        expect(response).to redirect_to root_url
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
      it 'should not let me edit this either' do
        get :edit, intellectual_object_identifier: inst2_obj
        expect(response).to redirect_to root_url
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
    end

  end

  describe 'POST #create' do
    let(:simple_obj) { FactoryGirl.build(:intellectual_object, institution: inst1) }

    after do
      PremisEvent.delete_all
      GenericFile.delete_all
      IntellectualObject.delete_all
    end

    describe 'when not signed in' do
      it 'should respond with redirect (html)' do
        post(:create, institution_identifier: inst1.identifier,
             intellectual_object: simple_obj.attributes)
        expect(response).to redirect_to root_url + 'users/sign_in'
      end
      it 'should respond unauthorized (json)' do
        post(:create, institution_identifier: inst1.identifier,
             intellectual_object: simple_obj.attributes, format: 'json')
        expect(response.code).to eq '401'
      end
    end

    describe 'when signed in as institutional user' do
      before { sign_in inst_user }
      it 'should respond with redirect (html)' do
        post(:create, institution_identifier: inst1.identifier,
             intellectual_object: simple_obj.attributes)
        expect(response).to redirect_to root_url
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
      it 'should respond forbidden (json)' do
        post(:create, institution_identifier: inst1.identifier,
             intellectual_object: simple_obj.attributes, format: 'json')
        expect(response.code).to eq '403'
      end
    end

    describe 'when signed in as institutional admin' do
      before { sign_in inst_admin }
      it 'should respond with redirect (html)' do
        post(:create, institution_identifier: inst1.identifier,
             intellectual_object: simple_obj.attributes)
        expect(response).to redirect_to root_url
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
      it 'should respond forbidden (json)' do
        post(:create, institution_identifier: inst1.identifier,
             intellectual_object: simple_obj.attributes, format: 'json')
        expect(response.code).to eq '403'
      end
    end

    describe 'when signed in as system admin' do
      before { sign_in sys_admin }
      it 'should create a simple object' do
        post(:create, institution_identifier: inst1.identifier,
             intellectual_object: simple_obj.attributes, format: 'json')
        expect(response.code).to eq '201'
        saved_obj = IntellectualObject.where(identifier: simple_obj.identifier).first
        expect(saved_obj).to be_truthy
      end
    end

  end

  describe 'PATCH #update' do

    after do
      PremisEvent.delete_all
      GenericFile.delete_all
      IntellectualObject.delete_all
    end

    describe 'when not signed in' do
      it 'should redirect to login' do
        patch :update, intellectual_object_identifier: obj1, intellectual_object: {title: 'Foo'}
        expect(response).to redirect_to root_url + 'users/sign_in'
      end
    end

    describe 'when signed in as institutional user' do
      before { sign_in inst_user }
      it 'should respond with redirect (html)' do
        patch :update, intellectual_object_identifier: obj1, intellectual_object: {title: 'Foo'}
        expect(response).to redirect_to root_url
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
      it 'should respond forbidden (json)' do
        patch :update, intellectual_object_identifier: obj1, intellectual_object: {title: 'Foo'}, format: :json
        expect(response.code).to eq '403'
      end
    end

    describe 'when signed in as institutional admin' do
      before { sign_in inst_admin }
      it 'should respond with redirect (html)' do
        patch :update, intellectual_object_identifier: obj1, intellectual_object: {title: 'Foo'}
        expect(response).to redirect_to root_url
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
      it 'should respond forbidden (json)' do
        patch :update, intellectual_object_identifier: obj1, intellectual_object: {title: 'Foo'}, format: :json
        expect(response.code).to eq '403'
      end
    end

    describe 'when signed in as system admin' do
      before { sign_in sys_admin }
      it 'should update the object and respond with redirect (html)' do
        patch :update, intellectual_object_identifier: obj1, intellectual_object: {title: 'Foo'}
        expect(response).to redirect_to intellectual_object_path(obj1.identifier)
        saved_obj = IntellectualObject.where(identifier: obj1.identifier).first
        expect(saved_obj.title).to eq 'Foo'
      end
      it 'should update the object and respond with json (json)' do
        patch :update, intellectual_object_identifier: obj1, intellectual_object: {title: 'Food'}, format: :json
        expect(response.status).to eq (200)
        saved_obj = IntellectualObject.where(identifier: obj1.identifier).first
        expect(saved_obj.title).to eq 'Food'
      end
    end

  end

  describe 'DELETE #destroy' do
    let!(:deletable_obj) { FactoryGirl.create(:institutional_intellectual_object,
                                              institution: inst1,
                                              state: 'A') }
    let!(:deleted_obj) { FactoryGirl.create(:institutional_intellectual_object,
                                            institution: inst1,
                                            state: 'D') }
    let!(:obj_pending) { FactoryGirl.create(:institutional_intellectual_object,
                                            institution: inst1,
                                            state: 'A',
                                            identifier: 'college.edu/item') }
    let!(:work_item) { FactoryGirl.create(:work_item,
                                          object_identifier: 'college.edu/item',
                                          action: 'Restore',
                                          stage: 'Requested',
                                          status: 'Pending') }

    after do
      IntellectualObject.delete_all
    end

    describe 'when not signed in' do
      it 'should redirect to login' do
        delete :destroy, intellectual_object_identifier: obj1
        expect(response).to redirect_to root_url + 'users/sign_in'
      end
    end

    describe 'when signed in as institutional user' do
      before { sign_in inst_user }
      it 'should respond with redirect (html)' do
        delete :destroy, intellectual_object_identifier: deletable_obj
        expect(response).to redirect_to root_url
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
      it 'should respond forbidden (json)' do
        delete :destroy, intellectual_object_identifier: deletable_obj, format: :json
        expect(response.code).to eq '403'
      end
    end

    describe 'when signed in as institutional admin' do
      before { sign_in inst_admin }
      it 'should create delete event and redirect (html)' do
        delete :destroy, intellectual_object_identifier: deletable_obj
        expect(response).to redirect_to root_url
        expect(flash[:notice]).to include 'Delete job has been queued'
        reloaded_object = IntellectualObject.find(deletable_obj.id)
        expect(reloaded_object.state).to eq 'D'
        expect(reloaded_object.premis_events.count).to eq 1
        expect(reloaded_object.premis_events[0].event_type).to eq 'delete'
      end

      it 'should not delete already deleted item' do
        delete :destroy, intellectual_object_identifier: deleted_obj
        expect(response).to redirect_to intellectual_object_path(deleted_obj)
        expect(flash[:alert]).to include 'This item has already been deleted'
      end

      it 'should not delete item with pending jobs' do
        delete :destroy, intellectual_object_identifier: obj_pending
        expect(response).to redirect_to intellectual_object_path(obj_pending)
        expect(flash[:alert]).to include 'Your object cannot be deleted'
      end
    end

    describe 'when signed in as system admin' do
      before { sign_in sys_admin }

      it 'should create delete event and return no content' do
        delete :destroy, intellectual_object_identifier: deletable_obj, format: :json
        expect(response.status).to eq(204)
        expect(response.body).to be_empty
        reloaded_object = IntellectualObject.find(deletable_obj.id)
        expect(reloaded_object.state).to eq 'D'
        expect(reloaded_object.premis_events.count).to eq 1
        expect(reloaded_object.premis_events[0].event_type).to eq 'delete'
      end

      it 'should say OK and return no content if the item was previously deleted' do
        delete :destroy, intellectual_object_identifier: deleted_obj, format: :json
        expect(response.status).to eq(204)
        expect(response.body).to be_empty
      end

      it 'should not delete item with pending jobs' do
        delete :destroy, intellectual_object_identifier: obj_pending, format: :json
        expect(response.status).to eq(409)
        data = JSON.parse(response.body)
        expect(data['status']).to eq ('error')
        expect(data['message']).to include 'Your object cannot be deleted'
      end

    end

  end

  describe 'PUT #send_to_dpn' do
    let!(:obj_for_dpn) { FactoryGirl.create(:institutional_intellectual_object,
                                            institution: inst1,
                                            state: 'A',
                                            identifier: 'college.edu/for_dpn') }
    let!(:deleted_obj) { FactoryGirl.create(:institutional_intellectual_object,
                                            institution: inst1,
                                            state: 'D',
                                            identifier: 'college.edu/deleted') }
    let!(:obj_pending) { FactoryGirl.create(:institutional_intellectual_object,
                                            institution: inst1,
                                            state: 'A',
                                            identifier: 'college.edu/pending') }
    let!(:obj_in_dpn) { FactoryGirl.create(:institutional_intellectual_object,
                                            institution: inst1,
                                            state: 'A',
                                            identifier: 'college.edu/in_dpn') }
    let!(:deleted_obj) { FactoryGirl.create(:institutional_intellectual_object,
                                            institution: inst1,
                                            state: 'D') }
    let!(:ingest) { FactoryGirl.create(:work_item,
                                       object_identifier: 'college.edu/for_dpn',
                                       action: 'Ingest',
                                       stage: 'Cleanup',
                                       status: 'Success') }
    let!(:pending_restore) { FactoryGirl.create(:work_item,
                                                object_identifier: 'college.edu/pending',
                                                action: 'Restore',
                                                stage: 'Requested',
                                                status: 'Pending') }
    let!(:dpn_item) { FactoryGirl.create(:work_item,
                                         object_identifier: 'college.edu/in_dpn',
                                         action: 'DPN',
                                         stage: 'Record',
                                         status: 'Success') }

    after do
      IntellectualObject.delete_all
      WorkItem.delete_all
    end

    describe 'when not signed in' do
      it 'should redirect to login' do
        put :send_to_dpn, intellectual_object_identifier: obj_for_dpn
        expect(response).to redirect_to root_url + 'users/sign_in'
      end
    end

    describe 'when signed in as institutional user' do
      before { sign_in inst_user }
      it 'should respond with redirect (html)' do
        put :send_to_dpn, intellectual_object_identifier: obj_for_dpn
        expect(response).to redirect_to root_url
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
      it 'should respond forbidden (json)' do
        put :send_to_dpn, intellectual_object_identifier: obj_for_dpn, format: :json
        expect(response.code).to eq '403'
      end
    end

    # Admin and inst admin can hit this endpoint via HTML or JSON
    describe 'when signed in as institutional admin' do
      before { sign_in inst_admin }
      it 'should respond with redirect (html)' do
        put :send_to_dpn, intellectual_object_identifier: obj_for_dpn
        expect(response).to redirect_to intellectual_object_path(obj_for_dpn)
        expect(flash[:notice]).to include 'Your item has been queued for DPN.'
      end
      it 'should create a DPN work item' do
        count_before = WorkItem.where(action: Pharos::Application::PHAROS_ACTIONS['dpn'],
                                      stage: Pharos::Application::PHAROS_STAGES['requested'],
                                      status: Pharos::Application::PHAROS_STATUSES['pend']).count
        put :send_to_dpn, intellectual_object_identifier: obj_for_dpn
        count_after = WorkItem.where(action: Pharos::Application::PHAROS_ACTIONS['dpn'],
                                     stage: Pharos::Application::PHAROS_STAGES['requested'],
                                     status: Pharos::Application::PHAROS_STATUSES['pend']).count
        expect(count_after).to eq(count_before + 1)
      end
      it 'should reject items that are already in dpn (html)' do
        put :send_to_dpn, intellectual_object_identifier: obj_in_dpn
        expect(response).to redirect_to intellectual_object_path(obj_in_dpn)
        expect(flash[:alert]).to include 'This item has already been sent to DPN.'
      end
      it 'should reject deleted items (html)' do
        put :send_to_dpn, intellectual_object_identifier: deleted_obj
        expect(response).to redirect_to intellectual_object_path(deleted_obj)
        expect(flash[:alert]).to include 'This item has been deleted and cannot be sent to DPN.'
      end
      it 'should reject items with pending work requests (html)' do
        put :send_to_dpn, intellectual_object_identifier: obj_pending
        expect(response).to redirect_to intellectual_object_path(obj_pending)
        expect(flash[:alert]).to include 'Your object cannot be sent to DPN at this time due to a pending'
      end
      it 'should reject items when DPN is disabled (html)' do
        if Pharos::Application.config.show_send_to_dpn_button == false
          begin
            Pharos::Application.config.show_send_to_dpn_button = true
            put :send_to_dpn, intellectual_object_identifier: obj_for_dpn
          ensure
            Pharos::Application.config.show_send_to_dpn_button = false
          end
          expect(response).to redirect_to intellectual_object_path(obj_for_dpn)
          expect(flash[:alert]).to include 'Your object cannot be sent to DPN at this time due to a pending'
        end
      end
    end

    # Admin and inst admin can hit this endpoint via HTML or JSON
    describe 'when signed in as system admin' do
      before { sign_in sys_admin }
      it 'should respond with meaningful json (json)' do
        put :send_to_dpn, intellectual_object_identifier: obj_for_dpn, format: :json
        expect(response.code).to eq '200'
        data = JSON.parse(response.body)
        expect(data['action']).to eq 'DPN'
        expect(data['object_identifier']).to eq obj_for_dpn.identifier
        expect(data['status']).to eq 'Pending'
        expect(data['note']).to eq 'Requested item be sent to DPN'
        expect(data['id']).to be > 0
      end
      it 'should create a DPN work item' do
        count_before = WorkItem.where(action: Pharos::Application::PHAROS_ACTIONS['dpn'],
                                      stage: Pharos::Application::PHAROS_STAGES['requested'],
                                      status: Pharos::Application::PHAROS_STATUSES['pend']).count
        put :send_to_dpn, intellectual_object_identifier: obj_for_dpn, format: :json
        count_after = WorkItem.where(action: Pharos::Application::PHAROS_ACTIONS['dpn'],
                                     stage: Pharos::Application::PHAROS_STAGES['requested'],
                                     status: Pharos::Application::PHAROS_STATUSES['pend']).count
        expect(count_after).to eq(count_before + 1)
      end
      it 'should reject items that are already in dpn (json)' do
        put :send_to_dpn, intellectual_object_identifier: obj_in_dpn, format: :json
        expect(response.code).to eq '409'
        data = JSON.parse(response.body)
        expect(data['status']).to eq 'error'
        expect(data['message']).to eq 'This item has already been sent to DPN.'
      end
      it 'should reject deleted items (json)' do
        put :send_to_dpn, intellectual_object_identifier: deleted_obj, format: :json
        expect(response.code).to eq '409'
        data = JSON.parse(response.body)
        expect(data['status']).to eq 'error'
        expect(data['message']).to eq 'This item has been deleted and cannot be sent to DPN.'
      end
      it 'should reject items with pending work requests (json)' do
        put :send_to_dpn, intellectual_object_identifier: obj_pending, format: :json
        expect(response.code).to eq '409'
        data = JSON.parse(response.body)
        expect(data['status']).to eq 'error'
        expect(data['message']).to include 'Your object cannot be sent to DPN at this time due to a pending'
      end
      it 'should reject items when DPN is disabled (json)' do
        if Pharos::Application.config.show_send_to_dpn_button == false
          begin
            Pharos::Application.config.show_send_to_dpn_button = true
            put :send_to_dpn, intellectual_object_identifier: obj_for_dpn, format: :json
          ensure
            Pharos::Application.config.show_send_to_dpn_button = false
          end
          expect(response.code).to eq '409'
          data = JSON.parse(response.body)
          expect(data['status']).to eq 'error'
          expect(data['message']).to include 'Your object cannot be sent to DPN at this time due to a pending'
        end
      end
    end

  end

  describe 'PUT #restore' do
    let!(:obj_for_restore) { FactoryGirl.create(:institutional_intellectual_object,
                                                institution: inst1,
                                                state: 'A',
                                                identifier: 'college.edu/for_restore') }
    let!(:deleted_obj) { FactoryGirl.create(:institutional_intellectual_object,
                                            institution: inst1,
                                            state: 'D',
                                            identifier: 'college.edu/deleted') }
    let!(:obj_pending) { FactoryGirl.create(:institutional_intellectual_object,
                                            institution: inst1,
                                            state: 'A',
                                            identifier: 'college.edu/pending') }
    let!(:ingest) { FactoryGirl.create(:work_item,
                                       object_identifier: 'college.edu/for_restore',
                                       action: 'Ingest',
                                       stage: 'Cleanup',
                                       status: 'Success') }
    let!(:pending_restore) { FactoryGirl.create(:work_item,
                                                object_identifier: 'college.edu/pending',
                                                action: 'Restore',
                                                stage: 'Requested',
                                                status: 'Pending') }

    after do
      IntellectualObject.delete_all
      WorkItem.delete_all
    end

    describe 'when not signed in' do
      it 'should redirect to login' do
        put :restore, intellectual_object_identifier: obj1
        expect(response).to redirect_to root_url + 'users/sign_in'
      end
    end

    describe 'when signed in as institutional user' do
      before { sign_in inst_user }
      it 'should respond with redirect (html)' do
        put :restore, intellectual_object_identifier: obj_for_restore
        expect(response).to redirect_to root_url
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
      it 'should respond forbidden (json)' do
        put :restore, intellectual_object_identifier: obj_for_restore, format: :json
        expect(response.code).to eq '403'
      end
    end

    # Admin and inst admin can hit this endpoint via HTML or JSON
    describe 'when signed in as institutional admin' do
      before { sign_in inst_admin }
      it 'should respond with redirect (html)' do
        put :restore, intellectual_object_identifier: obj_for_restore
        expect(response).to redirect_to intellectual_object_path(obj_for_restore)
        expect(flash[:notice]).to include 'Your item has been queued for restoration.'
      end
      it 'should create a restore work item' do
        count_before = WorkItem.where(action: Pharos::Application::PHAROS_ACTIONS['restore'],
                                      stage: Pharos::Application::PHAROS_STAGES['requested'],
                                      status: Pharos::Application::PHAROS_STATUSES['pend']).count
        put :restore, intellectual_object_identifier: obj_for_restore
        count_after = WorkItem.where(action: Pharos::Application::PHAROS_ACTIONS['restore'],
                                     stage: Pharos::Application::PHAROS_STAGES['requested'],
                                     status: Pharos::Application::PHAROS_STATUSES['pend']).count
        expect(count_after).to eq(count_before + 1)
      end
      it 'should reject deleted items (html)' do
        put :restore, intellectual_object_identifier: deleted_obj
        expect(response).to redirect_to intellectual_object_path(deleted_obj)
        expect(flash[:alert]).to include 'This item has been deleted and cannot be queued for restoration.'
      end
      it 'should reject items with pending work requests (html)' do
        put :restore, intellectual_object_identifier: obj_pending
        expect(response).to redirect_to intellectual_object_path(obj_pending)
        expect(flash[:alert]).to include 'cannot be queued for restoration at this time due to a pending'
      end
    end

    # Admin and inst admin can hit this endpoint via HTML or JSON
    describe 'when signed in as system admin' do
      before { sign_in sys_admin }
      it 'should respond with meaningful json (json)' do
        put :restore, intellectual_object_identifier: obj_for_restore, format: :json
        expect(response.code).to eq '200'
        data = JSON.parse(response.body)
        expect(data['status']).to eq 'ok'
        expect(data['message']).to eq 'Your item has been queued for restoration.'
        expect(data['work_item_id']).to be > 0
      end
      it 'should create a restore work item' do
        count_before = WorkItem.where(action: Pharos::Application::PHAROS_ACTIONS['restore'],
                                      stage: Pharos::Application::PHAROS_STAGES['requested'],
                                      status: Pharos::Application::PHAROS_STATUSES['pend']).count
        put :restore, intellectual_object_identifier: obj_for_restore, format: :json
        count_after = WorkItem.where(action: Pharos::Application::PHAROS_ACTIONS['restore'],
                                     stage: Pharos::Application::PHAROS_STAGES['requested'],
                                     status: Pharos::Application::PHAROS_STATUSES['pend']).count
        expect(count_after).to eq(count_before + 1)
      end
      it 'should reject deleted items (json)' do
        put :restore, intellectual_object_identifier: deleted_obj, format: :json
        expect(response.code).to eq '409'
        data = JSON.parse(response.body)
        expect(data['status']).to eq 'error'
        expect(data['message']).to eq 'This item has been deleted and cannot be queued for restoration.'
        expect(data['work_item_id']).to eq 0
      end
      it 'should reject items with pending work requests (json)' do
        put :restore, intellectual_object_identifier: obj_pending, format: :json
        expect(response.code).to eq '409'
        data = JSON.parse(response.body)
        expect(data['status']).to eq 'error'
        expect(data['message']).to include 'cannot be queued for restoration at this time due to a pending'
        expect(data['work_item_id']).to eq 0
      end
    end

  end

end
