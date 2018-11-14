require 'spec_helper'

RSpec.describe IntellectualObjectsController, type: :controller do

  let(:inst1) { FactoryBot.create(:member_institution) }
  let(:inst2) { FactoryBot.create(:subscription_institution) }
  let(:apt) { FactoryBot.create(:aptrust) }
  let(:inst_user) { FactoryBot.create(:user, :institutional_user,
                                       institution: inst1) }
  let(:inst_admin) { FactoryBot.create(:user, :institutional_admin,
                                       institution: inst1) }
  let(:sys_admin) { FactoryBot.create(:user, :admin, institution: apt) }
  let!(:obj1) { FactoryBot.create(:consortial_intellectual_object,
                                   institution: inst2) }
  let!(:obj2) { FactoryBot.create(:institutional_intellectual_object,
                                   institution: inst1,
                                   identifier: 'test.edu/baggie?c=152',
                                   title: 'Aberdeen Wanderers',
                                   description: 'Founded in Aberdeen in 1928.',
                                   etag: '4d05dc2aa07e411a55ef11bc6ade5ec1',
                                   bag_group_identifier: 'This is a collection.') }
  let!(:obj3) { FactoryBot.create(:institutional_intellectual_object,
                                   institution: inst2) }
  let!(:obj4) { FactoryBot.create(:restricted_intellectual_object,
                                   institution: inst1,
                                   title: 'Manchester City',
                                   description: 'The other Manchester team.',
                                   etag: '4d05dc2aa07e411a55ef11bc6ade5ec2') }
  let!(:obj5) { FactoryBot.create(:restricted_intellectual_object,
                                   institution: inst2) }
  let!(:obj6) { FactoryBot.create(:institutional_intellectual_object,
                                   institution: inst1,
                                   bag_name: '12345-abcde',
                                   alt_identifier: 'test.edu/some-bag',
                                   created_at: '2011-10-10T10:00:00Z',
                                   updated_at: '2011-10-10T10:00:00Z',
                                   etag: '4d05dc2aa07e411a55ef11bc6ade5ec3') }
  let!(:file1) { FactoryBot.create(:generic_file,
                                    intellectual_object: obj2) }
  let!(:event1) { FactoryBot.create(:premis_event_ingest,
                                     intellectual_object: obj2) }
  let!(:event2) { FactoryBot.create(:premis_event_ingest,
                                     generic_file: file1) }

  before(:all) do
    WorkItem.delete_all
    User.delete_all
    PremisEvent.delete_all
    GenericFile.delete_all
    IntellectualObject.delete_all
    Institution.delete_all
  end

  after(:all) do
    WorkItem.delete_all
    User.delete_all
    PremisEvent.delete_all
    GenericFile.delete_all
    IntellectualObject.delete_all
    Institution.delete_all
  end

  describe 'GET #index' do

    describe 'when not signed in' do
      it 'should redirect to login' do
        get :index, params: { institution_identifier: 'apt.edu' }
        expect(response).to redirect_to root_url + 'users/sign_in'
      end
    end

    describe 'when signed in as institutional user' do
      before do
        sign_in inst_user
      end
      it 'should show results from my institution' do
        get :index, params: { institution_identifier: inst1.identifier }
        expect(response).to be_successful
        expect(assigns(:intellectual_objects).size).to eq 3
        expect(assigns(:intellectual_objects).map &:id).to match_array [obj2.id, obj4.id, obj6.id]
      end
    end

    describe 'when signed in as institutional admin' do
      before { sign_in inst_admin }
      it 'should show results from my institution' do
        get :index, params: { institution_identifier: inst1.identifier }
        expect(response).to be_successful
        expect(assigns(:intellectual_objects).size).to eq 3
        expect(assigns(:intellectual_objects).map &:id).to match_array [obj2.id, obj4.id, obj6.id]
      end

      it 'should have an etag for JSON calls' do
        get :index, params: { institution_identifier: inst1.identifier, format: :json }
        expect(response).to be_successful
        expect(assigns(:intellectual_objects).size).to eq 3
        data = JSON.parse(response.body)
        expect(data['results'][0].has_key?('etag')).to be true
        expect(data['results'][0]['etag']).not_to eq 'null'
        #expect(data['results'][0]['etag']).to eq '4d05dc2aa07e411a55ef11bc6ade5ec1'
      end
    end

    describe 'when signed in as system admin' do
      before { sign_in sys_admin }
      it 'should show all results' do
        get :index, params: {}
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

          get :index, params: { created_before: '2016-07-26' }
          expect(assigns(:intellectual_objects).size).to eq 1

          get :index, params: { created_after: '2016-07-26' }
          expect(assigns(:intellectual_objects).size).to be > 1

          get :index, params: { updated_before: '2016-07-26' }
          expect(assigns(:intellectual_objects).size).to eq 1

          get :index, params: { updated_after: '2016-07-26' }
          expect(assigns(:intellectual_objects).size).to be > 1

          get :index, params: { description: 'Founded in Aberdeen in 1928.' }
          expect(assigns(:intellectual_objects).size).to eq 1

          get :index, params: { description_like: 'Aberdeen' }
          expect(assigns(:intellectual_objects).size).to eq 1

          get :index, params: { identifier: 'test.edu/baggie?c=152' }
          expect(assigns(:intellectual_objects).size).to eq 1

          get :index, params: { identifier_like: 'baggie' }
          expect(assigns(:intellectual_objects).size).to eq 1

          get :index, params: { alt_identifier: 'test.edu/some-bag' }
          expect(assigns(:intellectual_objects).size).to eq 1

          get :index, params: { alt_identifier_like: 'some-bag' }
          expect(assigns(:intellectual_objects).size).to eq 1

          get :index, params: { bag_group_identifier: 'This is a collection.' }
          expect(assigns(:intellectual_objects).size).to eq 1

          get :index, params: { bag_group_identifier_like: 'collection' }
          expect(assigns(:intellectual_objects).size).to eq 1
        end
      end
    end

  end

  describe 'GET #show' do

    describe 'when not signed in' do
      it 'should redirect to login' do
        get :show, params: { intellectual_object_identifier: obj1 }
        expect(response).to redirect_to root_url + 'users/sign_in'
      end
    end

    describe 'when signed in as institutional user' do
      before { sign_in inst_user }

      it "should show me my institution's object" do
        get :show, params: { intellectual_object_identifier: obj2 }
        expect(response).to be_successful
        expect(assigns(:intellectual_object)).to eq obj2
      end

      it "should show me another institution's consortial object" do
        get :show, params: { intellectual_object_identifier: obj1 }
        expect(response).to be_successful
        expect(assigns(:intellectual_object)).to eq obj1
      end

      it "should not show me another institution's private parts" do
        get :show, params: { intellectual_object_identifier: obj3 }
        expect(response).to redirect_to root_url
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end

      it 'should allow the object identifier to contain a question mark' do
        get :show, params: { intellectual_object_identifier: obj2 }
        expect(response).to be_successful
        expect(assigns(:intellectual_object)).to eq obj2
      end
    end

    describe 'when signed in as institutional admin' do
      before { sign_in inst_admin }

      it "should show me my institution's object" do
        get :show, params: { intellectual_object_identifier: obj2 }
        expect(response).to be_successful
        expect(assigns(:intellectual_object)).to eq obj2
      end

      it "should show me another institution's consortial object" do
        get :show, params: { intellectual_object_identifier: obj1 }
        expect(response).to be_successful
        expect(assigns(:intellectual_object)).to eq obj1
      end

      it "should not show me another institution's private parts" do
        get :show, params: { intellectual_object_identifier: obj3 }
        expect(response).to redirect_to root_url
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
    end

    describe 'when signed in as system admin' do
      before { sign_in sys_admin }

      it "should show me my institution's object" do
        get :show, params: { intellectual_object_identifier: obj2 }
        expect(response).to be_successful
        expect(assigns(:intellectual_object)).to eq obj2
      end

      it "should show me another institution's consortial object" do
        get :show, params: { intellectual_object_identifier: obj1 }
        expect(response).to be_successful
        expect(assigns(:intellectual_object)).to eq obj1
      end

      it "should show me another institution's private parts" do
        get :show, params: { intellectual_object_identifier: obj3 }
        expect(response).to be_successful
        expect(assigns(:intellectual_object)).to eq obj3
      end

      it 'should serialize files when asked' do
        get :show, params: { intellectual_object_identifier: obj2, format: :json, include_files: 'true' }
        expect(response).to be_successful
        expect(assigns(:intellectual_object)).to eq obj2
        data = JSON.parse(response.body)
        expect(data.has_key?('generic_files')).to be true
        expect(data['generic_files'][0].has_key?('checksums')).to be true
        expect(data.has_key?('premis_events')).to be false
      end

      it 'should serialize events when asked' do
        get :show, params: { intellectual_object_identifier: obj2, format: :json, include_events: 'true' }
        expect(response).to be_successful
        expect(assigns(:intellectual_object)).to eq obj2
        data = JSON.parse(response.body)
        expect(data.has_key?('premis_events')).to be true
        expect(data.has_key?('generic_files')).to be false
      end

      it 'should serialize files and events when asked' do
        get :show, params: { intellectual_object_identifier: obj2, format: :json, include_all_relations: 'true' }
        expect(response).to be_successful
        expect(assigns(:intellectual_object)).to eq obj2
        data = JSON.parse(response.body)
        expect(data.has_key?('premis_events')).to be true
        expect(data.has_key?('generic_files')).to be true
        expect(data['generic_files'][0].has_key?('checksums')).to be true
        expect(data['generic_files'][0].has_key?('premis_events')).to be true
      end

      it 'should serialize files, events, and state when asked' do
        get :show, params: { intellectual_object_identifier: obj2, format: :json, include_all_relations: 'true', with_ingest_state: 'true' }
        expect(response).to be_successful
        expect(assigns(:intellectual_object)).to eq obj2
        data = JSON.parse(response.body)
        expect(data.has_key?('premis_events')).to be true
        expect(data.has_key?('generic_files')).to be true
        expect(data['generic_files'][0].has_key?('checksums')).to be true
        expect(data['generic_files'][0].has_key?('premis_events')).to be true
      end

    end

  end

  describe 'GET #edit' do
    let(:inst1_obj) { FactoryBot.create(:consortial_intellectual_object, institution: inst1) }
    let(:inst2_obj) { FactoryBot.create(:consortial_intellectual_object, institution: inst2) }
    after do
      inst1_obj.destroy
      inst2_obj.destroy
    end

    describe 'when not signed in' do
      it 'should redirect to login' do
        get :edit, params: { intellectual_object_identifier: obj1 }
        expect(response).to redirect_to root_url + 'users/sign_in'
      end
    end

    describe 'when signed in as institutional user' do
      before { sign_in inst_user }
      it "should not let me edit my institution's objects" do
        get :edit, params: { intellectual_object_identifier: inst1_obj }
        expect(response).to redirect_to root_url
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
      it "should not let me edit other institution's objects" do
        get :edit, params: { intellectual_object_identifier: inst2_obj }
        expect(response).to redirect_to root_url
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
    end

    describe 'when signed in as institutional admin' do
      before { sign_in inst_admin }
      it "should not let me edit my institution's objects" do
        get :edit, params: { intellectual_object_identifier: inst1_obj }
        expect(response).to redirect_to root_url
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
      it "should not let me edit other institution's objects" do
        get :edit, params: { intellectual_object_identifier: inst2_obj }
        expect(response).to redirect_to root_url
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
    end

    describe 'when signed in as system admin' do
      before { sign_in sys_admin }
      it 'should not let me edit this' do
        get :edit, params: { intellectual_object_identifier: inst1_obj }
        expect(response).to redirect_to root_url
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
      it 'should not let me edit this either' do
        get :edit, params: { intellectual_object_identifier: inst2_obj }
        expect(response).to redirect_to root_url
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
    end

  end

  describe 'POST #create' do
    let(:simple_obj) { FactoryBot.build(:intellectual_object, institution: inst1, ingest_state: '{[]}', bag_group_identifier: 'collection_one', storage_option: 'Glacier-VA') }
    let(:bad_obj) { FactoryBot.build(:intellectual_object, institution: inst1, ingest_state: '{[]}', bag_group_identifier: 'collection_two', storage_option: 'somewhere-else') }

    after do
      PremisEvent.delete_all
      GenericFile.delete_all
      IntellectualObject.delete_all
    end

    describe 'when not signed in' do
      it 'should respond with redirect (html)' do
        post(:create, params: { institution_identifier: inst1.identifier,
             intellectual_object: simple_obj.attributes }, format: 'html')
        expect(response).to redirect_to root_url + 'users/sign_in'
      end
      it 'should respond unauthorized (json)' do
        post(:create, params: { institution_identifier: inst1.identifier,
             intellectual_object: simple_obj.attributes }, format: 'json')
        expect(response.code).to eq '401'
      end
    end

    describe 'when signed in as institutional user' do
      before { sign_in inst_user }
      it 'should respond with redirect (html)' do
        post(:create, params: { institution_identifier: inst1.identifier,
             intellectual_object: simple_obj.attributes }, format: 'html')
        expect(response).to redirect_to root_url
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
      it 'should respond forbidden (json)' do
        post(:create, params: { institution_identifier: inst1.identifier,
             intellectual_object: simple_obj.attributes }, format: 'json')
        expect(response.code).to eq '403'
      end
    end

    describe 'when signed in as institutional admin' do
      before { sign_in inst_admin }
      it 'should respond with redirect (html)' do
        post(:create, params: { institution_identifier: inst1.identifier,
             intellectual_object: simple_obj.attributes }, format: 'html')
        expect(response).to redirect_to root_url
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
      it 'should respond forbidden (json)' do
        post(:create, params: { institution_identifier: inst1.identifier,
             intellectual_object: simple_obj.attributes }, format: 'json')
        expect(response.code).to eq '403'
      end
    end

    describe 'when signed in as system admin' do
      before { sign_in sys_admin }
      it 'should create a simple object' do
        simple_obj.etag = '90908111'
        post(:create, params: { institution_identifier: inst1.identifier,
             intellectual_object: simple_obj.attributes }, format: 'json')
        expect(response.code).to eq '201'
        saved_obj = IntellectualObject.where(identifier: simple_obj.identifier).first
        expect(saved_obj).to be_truthy
        expect(saved_obj.etag).to eq '90908111'
        expect(saved_obj.bag_group_identifier).to eq 'collection_one'
        expect(saved_obj.storage_option).to eq 'Glacier-VA'
      end

      it 'should reject a storage_option that is not allowed' do
        post(:create, params: { institution_identifier: inst1.identifier,
                                intellectual_object: bad_obj.attributes }, format: 'json')
        expect(response.code).to eq '422' #Unprocessable Entity
        expect(JSON.parse(response.body)).to eq( { 'storage_option' => ['Storage Option is not one of the allowed options']})
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
        patch :update, params: { intellectual_object_identifier: obj1, intellectual_object: {title: 'Foo'} }
        expect(response).to redirect_to root_url + 'users/sign_in'
      end
    end

    describe 'when signed in as institutional user' do
      before { sign_in inst_user }
      it 'should respond with redirect (html)' do
        patch :update, params: { intellectual_object_identifier: obj1, intellectual_object: {title: 'Foo'} }
        expect(response).to redirect_to root_url
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
      it 'should respond forbidden (json)' do
        patch :update, params: { intellectual_object_identifier: obj1, intellectual_object: {title: 'Foo'} }, format: :json
        expect(response.code).to eq '403'
      end
    end

    describe 'when signed in as institutional admin' do
      before { sign_in inst_admin }
      it 'should respond with redirect (html)' do
        patch :update, params: { intellectual_object_identifier: obj1, intellectual_object: {title: 'Foo'} }
        expect(response).to redirect_to root_url
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
      it 'should respond forbidden (json)' do
        patch :update, params: { intellectual_object_identifier: obj1, intellectual_object: {title: 'Foo'} }, format: :json
        expect(response.code).to eq '403'
      end
    end

    describe 'when signed in as system admin' do
      before { sign_in sys_admin }
      it 'should update the object and respond with redirect (html)' do
        patch :update, params: { intellectual_object_identifier: obj1, intellectual_object: {title: 'Foo', storage_option: 'Glacier-VA', ingest_state: '{[A]}'} }
        expect(response).to redirect_to intellectual_object_path(obj1.identifier)
        saved_obj = IntellectualObject.where(identifier: obj1.identifier).first
        expect(saved_obj.title).to eq 'Foo'
        expect(saved_obj.storage_option).to eq 'Glacier-VA'
        expect(saved_obj.ingest_state).to eq '{[A]}'
      end

      it 'should update the object and respond with json (json)' do
        patch :update, params: { intellectual_object_identifier: obj1, intellectual_object: {title: 'Food', ingest_state: '{[D]}', etag: '12345678', bag_group_identifier: 'collection_two'} }, format: :json
        expect(response.status).to eq (200)
        saved_obj = IntellectualObject.where(identifier: obj1.identifier).first
        expect(saved_obj.title).to eq 'Food'
        expect(saved_obj.ingest_state).to eq '{[D]}'
        expect(saved_obj.etag).to eq '12345678'
        expect(saved_obj.bag_group_identifier).to eq 'collection_two'
      end
    end

  end

  describe 'DELETE #destroy' do
    let!(:deletable_obj) { FactoryBot.create(:institutional_intellectual_object,
                                              institution: inst1,
                                              state: 'A') }
    let!(:deleted_obj) { FactoryBot.create(:institutional_intellectual_object,
                                            institution: inst1,
                                            state: 'D') }
    let!(:obj_pending) { FactoryBot.create(:institutional_intellectual_object,
                                            institution: inst1,
                                            state: 'A',
                                            identifier: 'college.edu/item') }
    let!(:work_item) { FactoryBot.create(:work_item,
                                          object_identifier: 'college.edu/item',
                                          action: 'Restore',
                                          stage: 'Requested',
                                          status: 'Pending') }
    let!(:deletable_obj_2) { FactoryBot.create(:institutional_intellectual_object,
                                                institution: inst1, state: 'A') }
    let!(:assc_file) { FactoryBot.create(:generic_file, intellectual_object: deletable_obj_2) }

    after(:all) do
      IntellectualObject.delete_all
    end

    describe 'when not signed in' do
      it 'should redirect to login' do
        delete :destroy, params: { intellectual_object_identifier: obj1 }
        expect(response).to redirect_to root_url + 'users/sign_in'
      end
    end

    describe 'when signed in as institutional user' do
      before { sign_in inst_user }
      it 'should respond with redirect (html)' do
        delete :destroy, params: { intellectual_object_identifier: deletable_obj }
        expect(response).to redirect_to root_url
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
      it 'should respond forbidden (json)' do
        delete :destroy, params: { intellectual_object_identifier: deletable_obj }, format: :json
        expect(response.code).to eq '403'
      end
    end

    describe 'when signed in as institutional admin' do
      before { sign_in inst_admin }

      it 'should create an deletion request email and token' do
        count_before = Email.all.count
        delete :destroy, params: { intellectual_object_identifier: deletable_obj.identifier }
        count_after = Email.all.count
        expect(count_after).to eq count_before + 1
        email = ActionMailer::Base.deliveries.last
        expect(email.body.encoded).to include("http://localhost:3000/objects/#{CGI.escape(deletable_obj.identifier)}")
        expect(email.body.encoded).to include('has requested the deletion')
        expect(deletable_obj.confirmation_token.token).not_to be_nil
      end

      it 'should not delete already deleted item' do
        delete :destroy, params: { intellectual_object_identifier: deleted_obj }
        expect(response).to redirect_to intellectual_object_path(deleted_obj)
        expect(flash[:alert]).to include 'This item has already been deleted'
      end

      it 'should not delete item with pending jobs' do
        delete :destroy, params: { intellectual_object_identifier: obj_pending }
        expect(response).to redirect_to intellectual_object_path(obj_pending)
        expect(flash[:alert]).to include 'Your object cannot be deleted'
      end
    end

    describe 'when signed in as system admin' do
      before { sign_in sys_admin }

      it 'should create an deletion request email and token' do
        count_before = Email.all.count
        delete :destroy, params: { intellectual_object_identifier: deletable_obj.identifier }
        count_after = Email.all.count
        expect(count_after).to eq count_before + 1
        email = ActionMailer::Base.deliveries.last
        expect(email.body.encoded).to include("http://localhost:3000/objects/#{CGI.escape(deletable_obj.identifier)}")
        expect(email.body.encoded).to include('has requested the deletion')
        expect(deletable_obj.confirmation_token.token).not_to be_nil
      end

      # integration tests want to know this request is not honored
      it 'should say conflict and return no content if the item was previously deleted' do
        delete :destroy, params: { intellectual_object_identifier: deleted_obj }, format: :json
        expect(response.status).to eq(409)
        expect(response.body).to be_empty
      end

      it 'should not delete item with pending jobs' do
        delete :destroy, params: { intellectual_object_identifier: obj_pending }, format: :json
        expect(response.status).to eq(409)
        data = JSON.parse(response.body)
        expect(data['status']).to eq ('error')
        expect(data['message']).to include 'Your object cannot be deleted'
      end

    end

  end

  describe 'DELETE #confirm_destroy' do
    let!(:deletable_obj) { FactoryBot.create(:institutional_intellectual_object,
                                             institution: inst1,
                                             state: 'A') }
    let!(:deleted_obj) { FactoryBot.create(:institutional_intellectual_object,
                                           institution: inst1,
                                           state: 'D') }
    let!(:obj_pending) { FactoryBot.create(:institutional_intellectual_object,
                                           institution: inst1,
                                           state: 'A',
                                           identifier: 'college.edu/item') }
    let!(:work_item) { FactoryBot.create(:work_item,
                                         object_identifier: 'college.edu/item',
                                         action: 'Restore',
                                         stage: 'Requested',
                                         status: 'Pending') }
    let!(:deletable_obj_2) { FactoryBot.create(:institutional_intellectual_object,
                                               institution: inst1, state: 'A') }
    let!(:assc_file) { FactoryBot.create(:generic_file, intellectual_object: deletable_obj_2) }

    after(:all) do
      IntellectualObject.delete_all
    end

    describe 'when not signed in' do
      it 'should redirect to login' do
        delete :confirm_destroy, params: { intellectual_object_identifier: obj1 }
        expect(response).to redirect_to root_url + 'users/sign_in'
      end
    end

    describe 'when signed in as institutional user' do
      before { sign_in inst_user }
      it 'should respond with redirect (html)' do
        delete :confirm_destroy, params: { intellectual_object_identifier: deletable_obj }
        expect(response).to redirect_to root_url
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
      it 'should respond forbidden (json)' do
        delete :confirm_destroy, params: { intellectual_object_identifier: deletable_obj }, format: :json
        expect(response.code).to eq '403'
      end
    end

    describe 'when signed in as institutional admin' do
      before { sign_in inst_admin }

      it 'should create delete event and redirect (html) if a correct confirmation token is provided' do
        token = FactoryBot.create(:confirmation_token, intellectual_object: deletable_obj)
        count_before = Email.all.count
        delete :confirm_destroy, params: { intellectual_object_identifier: deletable_obj.identifier, confirmation_token: token.token, requesting_user_id: inst_admin.id }
        assigns[:t].join
        expect(response).to redirect_to root_url
        expect(flash[:notice]).to include 'Delete job has been queued'
        reloaded_object = IntellectualObject.find(deletable_obj.id)
        expect(reloaded_object.state).to eq 'A'
        expect(reloaded_object.premis_events.count).to eq 0
        count_after = Email.all.count
        expect(count_after).to eq count_before + 1
        email = ActionMailer::Base.deliveries.last
        expect(email.body.encoded).to include("http://localhost:3000/objects/#{CGI.escape(deletable_obj.identifier)}")
        expect(email.body.encoded).to include('has been successfully queued for deletion')
      end

      it 'should not delete the object if an incorrect confirmation token is provided' do
        token = FactoryBot.create(:confirmation_token, intellectual_object: deletable_obj)
        count_before = Email.all.count
        delete :confirm_destroy, params: { intellectual_object_identifier: deletable_obj.identifier, confirmation_token: SecureRandom.hex, requesting_user_id: inst_admin.id }
        expect(response).to redirect_to intellectual_object_path(deletable_obj.identifier)
        expect(flash[:alert]).to include 'Your object cannot be deleted at this time due to an invalid confirmation token.'
        reloaded_object = IntellectualObject.find(deletable_obj.id)
        expect(reloaded_object.state).to eq 'A'
        expect(reloaded_object.premis_events.count).to eq 0
        count_after = Email.all.count
        expect(count_after).to eq count_before
      end
    end

    describe 'when signed in as system admin' do
      before { sign_in sys_admin }

      it 'should create delete event' do
        token = FactoryBot.create(:confirmation_token, intellectual_object: deletable_obj)
        count_before = Email.all.count
        delete :confirm_destroy, params: { intellectual_object_identifier: deletable_obj, confirmation_token: token.token, requesting_user_id: inst_admin.id }, format: :json
        assigns[:t].join
        expect(response.status).to eq(204)
        expect(response.body).to be_empty
        reloaded_object = IntellectualObject.find(deletable_obj.id)
        expect(reloaded_object.state).to eq 'A'
        expect(reloaded_object.premis_events.count).to eq 0
        count_after = Email.all.count
        expect(count_after).to eq count_before + 1
        email = ActionMailer::Base.deliveries.last
        expect(email.body.encoded).to include("http://localhost:3000/objects/#{CGI.escape(deletable_obj.identifier)}")
        expect(email.body.encoded).to include('has been successfully queued for deletion')
      end
    end

  end

  describe 'GET #finished_destroy' do
    let!(:deletable_obj) { FactoryBot.create(:institutional_intellectual_object,
                                             institution: inst1,
                                             state: 'A') }
    let!(:deleted_obj) { FactoryBot.create(:institutional_intellectual_object,
                                           institution: inst1,
                                           state: 'D') }
    let!(:obj_pending) { FactoryBot.create(:institutional_intellectual_object,
                                           institution: inst1,
                                           state: 'A',
                                           identifier: 'college.edu/item') }
    let!(:work_item) { FactoryBot.create(:work_item,
                                         object_identifier: 'college.edu/item',
                                         action: 'Restore',
                                         stage: 'Requested',
                                         status: 'Pending') }
    let!(:deletable_obj_2) { FactoryBot.create(:institutional_intellectual_object,
                                               institution: inst1, state: 'A') }
    let!(:assc_file) { FactoryBot.create(:generic_file, intellectual_object: deletable_obj_2) }

    after(:all) do
      IntellectualObject.delete_all
    end

    describe 'when not signed in' do
      it 'should redirect to login' do
        get :finished_destroy, params: { intellectual_object_identifier: obj1 }
        expect(response).to redirect_to root_url + 'users/sign_in'
      end
    end

    describe 'when signed in' do
      before { sign_in user }

      describe "and deleting a file you don't have access to" do
        let(:user) { FactoryBot.create(:user, :institutional_admin, institution_id: inst2.id) }
        it 'should be forbidden' do
          get :finished_destroy, params: { intellectual_object_identifier: obj1 }, format: 'json'
          expect(response.code).to eq '403' # forbidden
          expect(JSON.parse(response.body)).to eq({'status'=>'error','message'=>'You are not authorized to access this page.'})
        end
      end

      describe 'and you have access to the object' do
        let(:user) { FactoryBot.create(:user, :admin) }
        it 'should delete the object' do
          count_before = Email.all.count
          deletion_item = FactoryBot.create(:work_item, action: Pharos::Application::PHAROS_ACTIONS['delete'], object_identifier: deletable_obj.identifier, user: user.email, inst_approver: inst_user.email)
          # Create the ingest and delete events...
          deletable_obj.add_event(FactoryBot.attributes_for(:premis_event_ingest, date_time: '2010-01-01T12:00:00Z'))
          get :finished_destroy, params: { intellectual_object_identifier: deletable_obj, requesting_user_id: user.id, inst_approver_id: inst_user.id }, format: 'json'
          expect(assigns[:intellectual_object].state).to eq 'D'
          reloaded_object = IntellectualObject.find(deletable_obj.id)
          expect(reloaded_object.premis_events.count).to eq 2
          expect(reloaded_object.premis_events.with_type(Pharos::Application::PHAROS_EVENT_TYPES['delete']).count).to eq 1
          expect(response.code).to eq '204'
        end

        it 'should raise exception if object has undeleted files' do
          # Create the ingest and delete events...
          dobj = FactoryBot.create(:intellectual_object)
          deletion_item = FactoryBot.create(:work_item, action: Pharos::Application::PHAROS_ACTIONS['delete'], object_identifier: dobj.identifier, user: user.email, inst_approver: inst_user.email)
          dobj.add_event(FactoryBot.attributes_for(:premis_event_ingest, date_time: '2010-01-01T12:00:00Z'))
          active_file = FactoryBot.create(:generic_file, intellectual_object_id: dobj.id, state: 'A')
          expect{get :finished_destroy, params: { intellectual_object_identifier: dobj, requesting_user_id: user.id, inst_approver_id: inst_user.id }, format: 'json'}.to raise_error("Object cannot be marked deleted until all of its files have been marked deleted.")
        end


        it 'should delete the object with html response' do
          dobj = FactoryBot.create(:intellectual_object)
          deletion_item = FactoryBot.create(:work_item, action: Pharos::Application::PHAROS_ACTIONS['delete'], object_identifier: dobj.identifier, user: user.email, inst_approver: inst_user.email)
          dobj.add_event(FactoryBot.attributes_for(:premis_event_ingest, date_time: '2010-01-01T12:00:00Z'))
          get :finished_destroy, params: { intellectual_object_identifier: dobj, requesting_user_id: user.id, inst_approver_id: inst_user.id }, format: 'html'
          expect(assigns[:intellectual_object].state).to eq 'D'
          reloaded_object = IntellectualObject.find(dobj.id)
          expect(reloaded_object.premis_events.count).to eq 2
          expect(reloaded_object.premis_events.with_type(Pharos::Application::PHAROS_EVENT_TYPES['delete']).count).to eq 1
          expect(flash[:notice]).to eq "Delete job has been finished for object: #{dobj.title}. Object has been marked as deleted."
        end

        it 'should have the correct message when the object was part of a bulk deletion' do
          dobj = FactoryBot.create(:intellectual_object)
          deletion_item = FactoryBot.create(:work_item, action: Pharos::Application::PHAROS_ACTIONS['delete'], object_identifier: dobj.identifier, user: user.email, inst_approver: inst_user.email, aptrust_approver: 'test_user@test.edu')
          dobj.add_event(FactoryBot.attributes_for(:premis_event_ingest, date_time: '2010-01-01T12:00:00Z'))
          get :finished_destroy, params: { intellectual_object_identifier: dobj, requesting_user_id: user.id, inst_approver_id: inst_user.id }, format: 'json'
          expect(assigns[:intellectual_object].state).to eq 'D'
          reloaded_object = IntellectualObject.find(dobj.id)
          expect(reloaded_object.premis_events.count).to eq 2
          expect(reloaded_object.premis_events.with_type(Pharos::Application::PHAROS_EVENT_TYPES['delete']).count).to eq 1
          expect(reloaded_object.premis_events.with_type(Pharos::Application::PHAROS_EVENT_TYPES['delete']).first.outcome_information).to eq "Object deleted as part of bulk deletion at the request of #{user.email}. Institutional Approver: #{inst_user.email}. APTrust Approver: test_user@test.edu"
        end
      end
    end
  end

  describe 'PUT #send_to_dpn' do
    let!(:obj_for_dpn) { FactoryBot.create(:institutional_intellectual_object,
                                            institution: inst1,
                                            state: 'A',
                                            identifier: 'college.edu/for_dpn') }
    let!(:deleted_obj) { FactoryBot.create(:institutional_intellectual_object,
                                            institution: inst1,
                                            state: 'D',
                                            identifier: 'college.edu/deleted') }
    let!(:obj_pending) { FactoryBot.create(:institutional_intellectual_object,
                                            institution: inst1,
                                            state: 'A',
                                            identifier: 'college.edu/pending') }
    let!(:obj_in_dpn) { FactoryBot.create(:institutional_intellectual_object,
                                            institution: inst1,
                                            state: 'A', dpn_uuid: '1234-5678',
                                            identifier: 'college.edu/in_dpn') }
    let!(:deleted_obj) { FactoryBot.create(:institutional_intellectual_object,
                                            institution: inst1,
                                            state: 'D') }
    let!(:ingest) { FactoryBot.create(:work_item,
                                       object_identifier: 'college.edu/for_dpn',
                                       action: 'Ingest',
                                       stage: 'Cleanup',
                                       status: 'Success') }
    let!(:pending_restore) { FactoryBot.create(:work_item,
                                                object_identifier: 'college.edu/pending',
                                                action: 'Restore',
                                                stage: 'Requested',
                                                status: 'Pending') }
    let!(:dpn_item) { FactoryBot.create(:work_item,
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
        put :send_to_dpn, params: { intellectual_object_identifier: obj_for_dpn }
        expect(response).to redirect_to root_url + 'users/sign_in'
      end
    end

    describe 'when signed in as institutional user' do
      before { sign_in inst_user }
      it 'should respond with redirect (html)' do
        put :send_to_dpn, params: { intellectual_object_identifier: obj_for_dpn }
        expect(response).to redirect_to root_url
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
      it 'should respond forbidden (json)' do
        put :send_to_dpn, params: { intellectual_object_identifier: obj_for_dpn }, format: :json
        expect(response.code).to eq '403'
      end
    end

    # Admin and inst admin can hit this endpoint via HTML or JSON
    describe 'when signed in as institutional admin' do
      before { sign_in inst_admin }
      it 'should respond with redirect (html)' do
        put :send_to_dpn, params: { intellectual_object_identifier: obj_for_dpn }
        expect(response).to redirect_to intellectual_object_path(obj_for_dpn)
        expect(flash[:notice]).to include 'Your item has been queued for DPN.'
      end
      it 'should create a DPN work item' do
        count_before = WorkItem.where(action: Pharos::Application::PHAROS_ACTIONS['dpn'],
                                      stage: Pharos::Application::PHAROS_STAGES['requested'],
                                      status: Pharos::Application::PHAROS_STATUSES['pend']).count
        put :send_to_dpn, params: { intellectual_object_identifier: obj_for_dpn }
        count_after = WorkItem.where(action: Pharos::Application::PHAROS_ACTIONS['dpn'],
                                     stage: Pharos::Application::PHAROS_STAGES['requested'],
                                     status: Pharos::Application::PHAROS_STATUSES['pend']).count
        expect(count_after).to eq(count_before + 1)
      end
      it 'should reject items that are already in dpn (html)' do
        put :send_to_dpn, params: { intellectual_object_identifier: obj_in_dpn }
        expect(response).to redirect_to intellectual_object_path(obj_in_dpn)
        expect(flash[:alert]).to include 'This item has already been sent to DPN.'
      end
      it 'should reject deleted items (html)' do
        put :send_to_dpn, params: { intellectual_object_identifier: deleted_obj }
        expect(response).to redirect_to intellectual_object_path(deleted_obj)
        expect(flash[:alert]).to include 'This item has been deleted and cannot be sent to DPN.'
      end
      it 'should reject items with pending work requests (html)' do
        put :send_to_dpn, params: { intellectual_object_identifier: obj_pending }
        expect(response).to redirect_to intellectual_object_path(obj_pending)
        expect(flash[:alert]).to include 'Your object cannot be sent to DPN at this time due to a pending'
      end
      it 'should reject items when DPN is disabled (html)' do
        if Pharos::Application.config.show_send_to_dpn_button == false
          begin
            Pharos::Application.config.show_send_to_dpn_button = true
            put :send_to_dpn, params: { intellectual_object_identifier: obj_for_dpn }
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
        put :send_to_dpn, params: { intellectual_object_identifier: obj_for_dpn }, format: :json
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
        put :send_to_dpn, params: { intellectual_object_identifier: obj_for_dpn }, format: :json
        count_after = WorkItem.where(action: Pharos::Application::PHAROS_ACTIONS['dpn'],
                                     stage: Pharos::Application::PHAROS_STAGES['requested'],
                                     status: Pharos::Application::PHAROS_STATUSES['pend']).count
        expect(count_after).to eq(count_before + 1)
      end
      it 'should reject items that are already in dpn (json)' do
        put :send_to_dpn, params: { intellectual_object_identifier: obj_in_dpn }, format: :json
        expect(response.code).to eq '409'
        data = JSON.parse(response.body)
        expect(data['status']).to eq 'error'
        expect(data['message']).to eq 'This item has already been sent to DPN.'
      end
      it 'should reject deleted items (json)' do
        put :send_to_dpn, params: { intellectual_object_identifier: deleted_obj }, format: :json
        expect(response.code).to eq '409'
        data = JSON.parse(response.body)
        expect(data['status']).to eq 'error'
        expect(data['message']).to eq 'This item has been deleted and cannot be sent to DPN.'
      end
      it 'should reject items with pending work requests (json)' do
        put :send_to_dpn, params: { intellectual_object_identifier: obj_pending }, format: :json
        expect(response.code).to eq '409'
        data = JSON.parse(response.body)
        expect(data['status']).to eq 'error'
        expect(data['message']).to include 'Your object cannot be sent to DPN at this time due to a pending'
      end
      it 'should reject items when DPN is disabled (json)' do
        if Pharos::Application.config.show_send_to_dpn_button == false
          begin
            Pharos::Application.config.show_send_to_dpn_button = true
            put :send_to_dpn, params: { intellectual_object_identifier: obj_for_dpn }, format: :json
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
    let!(:obj_for_restore) { FactoryBot.create(:institutional_intellectual_object,
                                                institution: inst1,
                                                state: 'A',
                                                identifier: 'college.edu/for_restore') }
    let!(:deleted_obj) { FactoryBot.create(:institutional_intellectual_object,
                                            institution: inst1,
                                            state: 'D',
                                            identifier: 'college.edu/deleted') }
    let!(:obj_pending) { FactoryBot.create(:institutional_intellectual_object,
                                            institution: inst1,
                                            state: 'A',
                                            identifier: 'college.edu/pending') }
    let!(:ingest) { FactoryBot.create(:work_item,
                                       object_identifier: 'college.edu/for_restore',
                                       action: 'Ingest',
                                       stage: 'Cleanup',
                                       status: 'Success') }
    let!(:pending_restore) { FactoryBot.create(:work_item,
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
        put :restore, params: { intellectual_object_identifier: obj1 }
        expect(response).to redirect_to root_url + 'users/sign_in'
      end
    end

    describe 'when signed in as institutional user' do
      before { sign_in inst_user }
      it 'should respond with redirect (html)' do
        put :restore, params: { intellectual_object_identifier: obj_for_restore }
        expect(response).to redirect_to root_url
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
      it 'should respond forbidden (json)' do
        put :restore, params: { intellectual_object_identifier: obj_for_restore, format: :json }
        expect(response.code).to eq '403'
      end
    end

    # Admin and inst admin can hit this endpoint via HTML or JSON
    describe 'when signed in as institutional admin' do
      before { sign_in inst_admin }
      it 'should respond with redirect (html)' do
        put :restore, params: { intellectual_object_identifier: obj_for_restore }
        expect(response).to redirect_to intellectual_object_path(obj_for_restore)
        expect(flash[:notice]).to include 'Your item has been queued for restoration.'
      end
      it 'should create a restore work item' do
        count_before = WorkItem.where(action: Pharos::Application::PHAROS_ACTIONS['restore'],
                                      stage: Pharos::Application::PHAROS_STAGES['requested'],
                                      status: Pharos::Application::PHAROS_STATUSES['pend']).count
        put :restore, params: { intellectual_object_identifier: obj_for_restore }
        count_after = WorkItem.where(action: Pharos::Application::PHAROS_ACTIONS['restore'],
                                     stage: Pharos::Application::PHAROS_STAGES['requested'],
                                     status: Pharos::Application::PHAROS_STATUSES['pend']).count
        expect(count_after).to eq(count_before + 1)
      end
      it 'should reject deleted items (html)' do
        put :restore, params: { intellectual_object_identifier: deleted_obj }
        expect(response).to redirect_to intellectual_object_path(deleted_obj)
        expect(flash[:alert]).to include 'This item has been deleted and cannot be queued for restoration.'
      end
      it 'should reject items with pending work requests (html)' do
        put :restore, params: { intellectual_object_identifier: obj_pending }
        expect(response).to redirect_to intellectual_object_path(obj_pending)
        expect(flash[:alert]).to include 'cannot be queued for restoration at this time due to a pending'
      end
    end

    # Admin and inst admin can hit this endpoint via HTML or JSON
    describe 'when signed in as system admin' do
      before { sign_in sys_admin }
      it 'should respond with meaningful json (json)' do
        # This returns a WorkItem object for format JSON
        put :restore, params: { intellectual_object_identifier: obj_for_restore, format: :json }
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
        put :restore, params: { intellectual_object_identifier: obj_for_restore }, format: :json
        count_after = WorkItem.where(action: Pharos::Application::PHAROS_ACTIONS['restore'],
                                     stage: Pharos::Application::PHAROS_STAGES['requested'],
                                     status: Pharos::Application::PHAROS_STATUSES['pend']).count
        expect(count_after).to eq(count_before + 1)
      end
      it 'should reject deleted items (json)' do
        put :restore, params: { intellectual_object_identifier: deleted_obj }, format: :json
        expect(response.code).to eq '409'
        data = JSON.parse(response.body)
        expect(data['status']).to eq 'error'
        expect(data['message']).to eq 'This item has been deleted and cannot be queued for restoration.'
        expect(data['work_item_id']).to eq 0
      end
      it 'should reject items with pending work requests (json)' do
        put :restore, params: { intellectual_object_identifier: obj_pending }, format: :json
        expect(response.code).to eq '409'
        data = JSON.parse(response.body)
        expect(data['status']).to eq 'error'
        expect(data['message']).to include 'cannot be queued for restoration at this time due to a pending'
        expect(data['work_item_id']).to eq 0
      end
    end

  end

end
