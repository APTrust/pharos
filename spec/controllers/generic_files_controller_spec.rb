require 'spec_helper'

RSpec.describe GenericFilesController, type: :controller do
  let(:user) { FactoryGirl.create(:user, :admin, institution_id: @institution.id) }
  let(:file) { FactoryGirl.create(:generic_file) }
  let(:inst_user) { FactoryGirl.create(:user, :institutional_admin, institution_id: @institution.id)}

  before(:all) do
    @institution = FactoryGirl.create(:institution)
    @another_institution = FactoryGirl.create(:institution)
    @intellectual_object = FactoryGirl.create(:consortial_intellectual_object, institution_id: @institution.id)
    GenericFile.delete_all
  end

  after(:all) do
    GenericFile.delete_all
  end

  describe 'GET #index' do
    before do
      sign_in user
      file.add_event(FactoryGirl.attributes_for(:premis_event_ingest))
      file.add_event(FactoryGirl.attributes_for(:premis_event_fixity_generation))
      file.save!
    end

    it 'can index files by intellectual object identifier' do
      get :index, intellectual_object_identifier: @intellectual_object.identifier, format: :json
      expect(response).to be_successful
      expect(assigns(:intellectual_object)).to eq @intellectual_object
    end

    it 'returns only active files' do
      FactoryGirl.create(:generic_file, intellectual_object: @intellectual_object, identifier: 'one', state: 'A')
      FactoryGirl.create(:generic_file, intellectual_object: @intellectual_object, identifier: 'two', state: 'D')
      get :index, intellectual_object_identifier: @intellectual_object.identifier, format: :json
      expect(response).to be_successful
      response_data = JSON.parse(response.body)
      expect(response_data.select{|f| f['state'] == 'A'}.count).to eq 1
      expect(response_data.select{|f| f['state'] != 'A'}.count).to eq 0
    end
  end

  describe 'GET #file_summary' do
    before do
      sign_in user
      file.add_event(FactoryGirl.attributes_for(:premis_event_ingest))
      file.add_event(FactoryGirl.attributes_for(:premis_event_fixity_generation))
      file.save!
    end

    it 'can index files by intellectual object identifier' do
      get :index, alt_action: 'file_summary', intellectual_object_identifier: CGI.escape(@intellectual_object.identifier), format: :json
      expect(response).to be_successful
      expect(assigns(:intellectual_object)).to eq @intellectual_object
    end

    it 'returns only active files with uri, size and identifier attributes' do
      FactoryGirl.create(:generic_file, intellectual_object: @intellectual_object, uri:'https://one', identifier: 'file_one', state: 'A')
      FactoryGirl.create(:generic_file, intellectual_object: @intellectual_object, uri:'https://two', identifier: 'file_two', state: 'D')
      get :index, alt_action: 'file_summary', intellectual_object_identifier: CGI.escape(@intellectual_object.identifier), format: :json
      expect(response).to be_successful

      # Reload, or the files don't appear
      @intellectual_object.reload

      active_files = {}
      @intellectual_object.active_files.each do |f|
        key = "#{f.uri}-#{f.size}"
        active_files[key] = f
      end
      response_data = JSON.parse(response.body)
      response_data.each do |file_summary|
        key = "#{file_summary['uri']}-#{file_summary['size']}"
        generic_file = active_files[key]
        expect(generic_file).not_to be_nil
        expect(file_summary['uri']).to eq generic_file.uri
        expect(file_summary['size']).to eq generic_file.size
        expect(file_summary['identifier']).to eq generic_file.identifier
      end
    end
  end

  describe 'GET #show' do
    before do
      sign_in user
      file.add_event(FactoryGirl.attributes_for(:premis_event_ingest))
      file.add_event(FactoryGirl.attributes_for(:premis_event_fixity_generation))
      file.save!
    end

    it 'responds successfully' do
      get :show, generic_file_identifier: file.identifier
      expect(response).to render_template('show')
      response.should be_successful
    end

    it 'assigns the generic file' do
      get :show, generic_file_identifier: file.identifier
      assigns(:generic_file).should == file
    end

    it 'assigns events' do
      get :show, generic_file_identifier: file.identifier
      assigns(:events).count.should == file.premis_events.count
    end

    it 'should show the file by identifier for API users' do
      get :show, generic_file_identifier: URI.encode(file.identifier)
      expect(assigns(:generic_file)).to eq file
    end

  end

  describe 'POST #create' do
    describe 'when not signed in' do
      let(:obj1) { @intellectual_object }
      it 'should redirect to login' do
        post :create, intellectual_object_identifier: obj1.identifier, generic_file: {uri: 'Foo' }
        expect(response).to redirect_to root_url + 'users/sign_in'
        expect(flash[:alert]).to eq 'You need to sign in or sign up before continuing.'
      end
    end

    describe 'when signed in' do
      let(:user) { FactoryGirl.create(:user, :institutional_admin, institution_id: @institution.id) }
      let(:obj1) { @intellectual_object }
      before { sign_in user }

      describe "and assigning to an object you don't have access to" do
        let(:obj1) { FactoryGirl.create(:consortial_intellectual_object) }
        it 'should be forbidden' do
          post :create, intellectual_object_identifier: obj1.identifier, generic_file: {uri: 'path/within/bag', size: 12314121, created_at: '2001-12-31', updated_at: '2003-03-13', file_format: 'text/html', checksums: [{digest: '123ab13df23', algorithm: 'MD6', datetime: '2003-03-13T12:12:12Z'}]}, format: 'json'
          expect(response.code).to eq '403' # forbidden
          expect(JSON.parse(response.body)).to eq({'status'=>'error','message'=>'You are not authorized to access this page.'})
        end
      end

      it 'should show errors' do
        post :create, intellectual_object_identifier: obj1.identifier, generic_file: {uri: 'bar'}, format: 'json'
        expect(response.code).to eq '422' #Unprocessable Entity
        expect(JSON.parse(response.body)).to eq( {
                                                     'checksums' => ["can't be blank"],
                                                     'created_at' => ["can't be blank"],
                                                     'file_format' => ["can't be blank"],
                                                     'identifier' => ["can't be blank"],
                                                     'updated_at' => ["can't be blank"],
                                                     'size' => ["can't be blank"]})
      end

      it 'should update fields' do
        #IntellectualObject.any_instance.should_receive(:update_index)
        post :create, intellectual_object_identifier: obj1.identifier, generic_file: {uri: 'http://s3-eu-west-1.amazonaws.com/mybucket/puppy.jpg', size: 12314121, created_at: '2001-12-31', updated_at: '2003-03-13', file_format: 'text/html', identifier: 'test.edu/12345678/data/mybucket/puppy.jpg', checksums_attributes: [{digest: '123ab13df23', algorithm: 'MD6', datetime: '2003-03-13T12:12:12Z'}]}, format: 'json'
        expect(response.code).to eq '201'
        assigns(:generic_file).tap do |file|
          expect(file.uri).to eq 'http://s3-eu-west-1.amazonaws.com/mybucket/puppy.jpg'
          expect(file.identifier).to eq 'test.edu/12345678/data/mybucket/puppy.jpg'
        end
      end

      it 'should add generic file using API identifier' do
        identifier = URI.escape(obj1.identifier)
        post :create, intellectual_object_identifier: identifier, generic_file: {uri: 'http://s3-eu-west-1.amazonaws.com/mybucket/cat.jpg', size: 12314121, created_at: '2001-12-31', updated_at: '2003-03-13', file_format: 'text/html', identifier: 'test.edu/12345678/data/mybucket/cat.jpg', checksums_attributes: [{digest: '123ab13df23', algorithm: 'MD6', datetime: '2003-03-13T12:12:12Z'}]}, format: 'json'
        expect(response.code).to eq '201'
        assigns(:generic_file).tap do |file|
          expect(file.uri).to eq 'http://s3-eu-west-1.amazonaws.com/mybucket/cat.jpg'
          expect(file.identifier).to eq 'test.edu/12345678/data/mybucket/cat.jpg'
        end
      end

      it 'should create generic files larger than 2GB' do
        identifier = URI.escape(obj1.identifier)
        post :create, intellectual_object_identifier: identifier, generic_file: {uri: 'http://s3-eu-west-1.amazonaws.com/mybucket/dog.jpg', size: 300000000000, created_at: '2001-12-31', updated_at: '2003-03-13', file_format: 'text/html', identifier: 'test.edu/12345678/data/mybucket/dog.jpg', checksums_attributes: [{digest: '123ab13df23', algorithm: 'MD6', datetime: '2003-03-13T12:12:12Z'}]}, format: 'json'
        expect(response.code).to eq '201'
        assigns(:generic_file).tap do |file|
          expect(file.uri).to eq 'http://s3-eu-west-1.amazonaws.com/mybucket/dog.jpg'
          expect(file.identifier).to eq 'test.edu/12345678/data/mybucket/dog.jpg'
        end
      end

    end
  end

  describe 'POST #save_batch' do
    describe 'when not signed in' do
      let(:obj1) { @intellectual_object }
      it 'should show unauthorized' do
        post(:create, save_batch: true, intellectual_object_identifier: obj1.identifier, generic_files: [],
             format: 'json')
        expect(response.code).to eq '401'
      end
    end

    describe 'when signed in' do
      let(:user) { FactoryGirl.create(:user, :institutional_admin, institution_id: @institution.id) }
      let(:obj2) { FactoryGirl.create(:consortial_intellectual_object, institution_id: @another_institution.id) }
      let(:batch_obj) { FactoryGirl.create(:consortial_intellectual_object, institution_id: @institution.id) }
      let(:current_dir) { File.dirname(__FILE__) }
      let(:json_file) { File.join(current_dir, '..', 'fixtures', 'generic_file_batch.json') }
      let(:raw_json) { File.read(json_file) }
      let(:gf_data) { JSON.parse(raw_json) }

      before { sign_in user }

      describe "and assigning to an object you don't have access to" do
        it 'should be forbidden' do
          post(:create, save_batch: true, intellectual_object_identifier: obj2.identifier, generic_files: {},
               format: 'json')
          expect(response.code).to eq '403'
          expect(JSON.parse(response.body)).to eq({'status'=>'error', 'message'=>'You are not authorized to access this page.'})
        end
      end

      describe 'and assigning to an object you do have access to' do
        it 'it should create or update multiple files and their events' do
          # First post is a create
          post(:create, save_batch: true, intellectual_object_id: batch_obj.id, generic_files: {files: gf_data},
               format: 'json')
          expect(response.code).to eq '201'
          return_data = JSON.parse(response.body)
          expect(return_data.count).to eq 2
          expect(return_data[0]['id']).not_to be_nil
          expect(return_data[1]['id']).not_to be_nil
          expect(return_data[0]['state']).to eq 'A'
          expect(return_data[1]['state']).to eq 'A'
          expect(return_data[0]['premis_events'].count).to eq 2
          expect(return_data[1]['premis_events'].count).to eq 2
          expect(return_data[0]['checksums'].count).to eq 2
          expect(return_data[1]['checksums'].count).to eq 2

          # Now alter data and post again. Should be an update.
          id1 = return_data[0]['id']
          id2 = return_data[1]['id']

          # IT IS IMPERATIVE THAT UPDATES CONTAIN THE IDS OF ALL NESTED OBJECTS
          gf_data[0]['file_format'] = 'text/apple'
          gf_data[0]['checksums_attributes'][0]['id'] = return_data[0]['checksums'][0]['id']
          gf_data[0]['checksums_attributes'][1]['id'] = return_data[0]['checksums'][1]['id']
          gf_data[1]['checksums_attributes'][0]['id'] = return_data[1]['checksums'][0]['id']
          gf_data[1]['checksums_attributes'][1]['id'] = return_data[1]['checksums'][1]['id']
          gf_data[0]['premis_events_attributes'][0]['id'] = return_data[0]['premis_events'][0]['id']
          gf_data[0]['premis_events_attributes'][1]['id'] = return_data[0]['premis_events'][1]['id']
          gf_data[1]['premis_events_attributes'][0]['id'] = return_data[1]['premis_events'][0]['id']
          gf_data[1]['premis_events_attributes'][1]['id'] = return_data[1]['premis_events'][1]['id']
          gf_data[1]['file_format'] = 'text/orange'

          post(:update, save_batch: true, intellectual_object_identifier: batch_obj.identifier, generic_files: {files: gf_data},
               format: 'json')
          expect(response.code).to eq '201'
          return_data = JSON.parse(response.body)
          expect(return_data.count).to eq 2
          expect(return_data[0]['id']).to eq id1
          expect(return_data[1]['id']).to eq id2
          expect(return_data[0]['file_format']).to eq 'text/apple'
          expect(return_data[1]['file_format']).to eq 'text/orange'
          expect(return_data[0]['premis_events'].count).to eq 2
          expect(return_data[1]['premis_events'].count).to eq 2
          expect(return_data[0]['checksums'].count).to eq 2
          expect(return_data[1]['checksums'].count).to eq 2
        end
      end
    end
  end

  describe 'PATCH #update' do
    before(:all) { @file = FactoryGirl.create(:generic_file, intellectual_object_id: @intellectual_object.id) }
    let(:file) { @file }

    describe 'when not signed in' do
      it 'should redirect to login' do
        patch :update, intellectual_object_identifier: file.intellectual_object, generic_file_identifier: file, trailing_slash: true
        expect(response).to redirect_to root_url + 'users/sign_in'
        expect(flash[:alert]).to eq 'You need to sign in or sign up before continuing.'
      end
    end

    describe 'when signed in' do
      before { sign_in user }

      describe "and updating a file you don't have access to" do
        let(:user) { FactoryGirl.create(:user, :institutional_admin, institution_id: @another_institution.id) }
        it 'should be forbidden' do
          patch :update, intellectual_object_identifier: file.intellectual_object.identifier, generic_file_identifier: file.identifier, generic_file: {size: 99}, format: 'json', trailing_slash: true
          expect(response.code).to eq '403' # forbidden
          expect(JSON.parse(response.body)).to eq({'status'=>'error','message'=>'You are not authorized to access this page.'})
        end
      end

      describe 'and you have access to the file' do
        it 'should update the file' do
          patch :update, intellectual_object_identifier: file.intellectual_object.identifier, generic_file_identifier: file, generic_file: {size: 99}, format: 'json', trailing_slash: true
          expect(assigns[:generic_file].size).to eq 99
          expect(response.code).to eq '204'
        end

        it 'should update the file by identifier (API)' do
          patch :update, generic_file_identifier: URI.escape(file.identifier), id: file.id, generic_file: {size: 99}, format: 'json', trailing_slash: true
          expect(assigns[:generic_file].size).to eq 99
          expect(response.code).to eq '204'
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    before(:all) {
      @file = FactoryGirl.create(:generic_file, intellectual_object_id: @intellectual_object.id)
      @parent_work_item = FactoryGirl.create(:work_item,
                                                  object_identifier: @intellectual_object.identifier,
                                                  action: Pharos::Application::PHAROS_ACTIONS['ingest'],
                                                  stage: Pharos::Application::PHAROS_STAGES['record'],
                                                  status: Pharos::Application::PHAROS_STATUSES['success'])
    }
    let(:file) { @file }

    after(:all) {
      @parent_work_item.delete
    }

    describe 'when not signed in' do
      it 'should redirect to login' do
        delete :destroy, generic_file_identifier: file
        expect(response).to redirect_to root_url + 'users/sign_in'
        expect(flash[:alert]).to eq 'You need to sign in or sign up before continuing.'
      end
    end

    describe 'when signed in' do
      before { sign_in user }

      describe "and deleting a file you don't have access to" do
        let(:user) { FactoryGirl.create(:user, :institutional_admin, institution_id: @another_institution.id) }
        it 'should be forbidden' do
          delete :destroy, generic_file_identifier: file, format: 'json'
          expect(response.code).to eq '403' # forbidden
          expect(JSON.parse(response.body)).to eq({'status'=>'error','message'=>'You are not authorized to access this page.'})
        end
      end

      describe 'and you have access to the file' do
        it 'should delete the file' do
          delete :destroy, generic_file_identifier: file, format: 'json'
          expect(assigns[:generic_file].state).to eq 'D'
          expect(response.code).to eq '204'
        end

        it 'delete the file with html response' do
          file = FactoryGirl.create(:generic_file, intellectual_object_id: @intellectual_object.id)
          delete :destroy, generic_file_identifier: file
          expect(response).to redirect_to intellectual_object_path(file.intellectual_object)
          expect(assigns[:generic_file].state).to eq 'D'
          expect(flash[:notice]).to eq "Delete job has been queued for file: #{file.uri}"
        end

        it 'should create a WorkItem with the delete request' do
          file = FactoryGirl.create(:generic_file, intellectual_object_id: @intellectual_object.id)
          delete :destroy, generic_file_identifier: file, format: 'json'
          wi = WorkItem.where(generic_file_identifier: file.identifier).first
          expect(wi).not_to be_nil
          expect(wi.object_identifier).to eq @intellectual_object.identifier
          expect(wi.action).to eq Pharos::Application::PHAROS_ACTIONS['delete']
          expect(wi.stage).to eq Pharos::Application::PHAROS_STAGES['requested']
          expect(wi.status).to eq Pharos::Application::PHAROS_STATUSES['pend']
        end

      end
    end
  end

  describe 'GET #not_checked_since' do
    # describe 'when signed in as an admin user' do
    #   before do
    #     sign_in user
    #   end
    #
    #   it 'allows access to the API endpoint' do
    #     get :index, alt_action: 'not_checked_since', date: '2015-01-31T14:31:36Z', format: :json
    #     expect(response.status).to eq 200
    #   end
    # end
  end
end
