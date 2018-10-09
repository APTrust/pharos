require 'spec_helper'

RSpec.describe GenericFilesController, type: :controller do
  let(:user) { FactoryBot.create(:user, :admin, institution_id: @institution.id) }
  let(:file) { FactoryBot.create(:generic_file) }
  let(:inst_user) { FactoryBot.create(:user, :institutional_admin, institution_id: @institution.id)}
  let(:basic_user) { FactoryBot.create(:user, :institutional_user, institution_id: @institution.id)}
  let(:crazy_file) { FactoryBot.create(:generic_file, identifier: 'uc.edu/cin.scholar.2016-03-03/data/fedora_backup/data/datastreamStore/45/info%3Afedora%2Fsufia%3Ar781wg21b%2Fcontent%2Fcontent.0') }
  let(:question_file) { FactoryBot.create(:generic_file, identifier: 'miami.edu/miami.archiveit5161_us_cuba_policy_masters_archiveit_5161_us_cuba_policy_md5sums_txt?c=5161/data/md5sums.txt?c=5161') }
  let(:parens_file) { FactoryBot.create(:generic_file, identifier: 'miami.edu/miami.edu.chc5200/data/chc5200000040/METAFILES/chc52000000400001001(wav).mtf') }
  let(:deleted_file) { FactoryBot.create(:generic_file, state: 'D') }

  before(:all) do
    User.delete_all
    IntellectualObject.delete_all
    Institution.delete_all
    @institution = FactoryBot.create(:member_institution)
    @another_institution = FactoryBot.create(:subscription_institution)
    @intellectual_object = FactoryBot.create(:consortial_intellectual_object, institution_id: @institution.id)
    @another_intellectual_object = FactoryBot.create(:consortial_intellectual_object, institution_id: @another_institution.id)
    GenericFile.delete_all
  end

  after(:all) do
    GenericFile.delete_all
    User.delete_all
    IntellectualObject.delete_all
    Institution.delete_all
  end

  describe 'GET #index' do
    before do
      sign_in user
      file.add_event(FactoryBot.attributes_for(:premis_event_ingest, institution: @institution, intellectual_object: @intellectual_object))
      file.add_event(FactoryBot.attributes_for(:premis_event_fixity_generation, institution: @institution, intellectual_object: @intellectual_object))
      file.save!
    end

    it 'can index files by intellectual object identifier' do
      get :index, params: { intellectual_object_identifier: @intellectual_object.identifier }, format: :json
      expect(response).to be_successful
      expect(assigns(:intellectual_object)).to eq @intellectual_object
    end

    it 'returns only active files' do
      FactoryBot.create(:generic_file, intellectual_object: @intellectual_object, identifier: 'one', state: 'A')
      FactoryBot.create(:generic_file, intellectual_object: @intellectual_object, identifier: 'two', state: 'D')
      get :index, params: { intellectual_object_identifier: @intellectual_object.identifier }, format: :json
      expect(response).to be_successful
      response_data = JSON.parse(response.body)
      expect(response_data['count']).to eq 1
      expect(response_data['results'][0]['state']).to eq 'A'
    end

  end

  describe 'GET #file_summary' do
    before do
      sign_in user
      file.add_event(FactoryBot.attributes_for(:premis_event_ingest, institution: @institution, intellectual_object: @intellectual_object))
      file.add_event(FactoryBot.attributes_for(:premis_event_fixity_generation, institution: @institution, intellectual_object: @intellectual_object))
      file.save!
    end

    it 'can index files by intellectual object identifier' do
      get :index, params: { alt_action: 'file_summary', intellectual_object_identifier: CGI.escape(@intellectual_object.identifier) }, format: :json
      expect(response).to be_successful
      expect(assigns(:intellectual_object)).to eq @intellectual_object
    end

    it 'returns only active files with uri, size and identifier attributes' do
      FactoryBot.create(:generic_file, intellectual_object: @intellectual_object, uri:'https://one', identifier: 'file_one', state: 'A')
      FactoryBot.create(:generic_file, intellectual_object: @intellectual_object, uri:'https://two', identifier: 'file_two', state: 'D')
      get :index, params: { alt_action: 'file_summary', intellectual_object_identifier: CGI.escape(@intellectual_object.identifier) }, format: :json
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
      file.add_event(FactoryBot.attributes_for(:premis_event_ingest, institution: @institution, intellectual_object: @intellectual_object))
      file.add_event(FactoryBot.attributes_for(:premis_event_fixity_generation, institution: @institution, intellectual_object: @intellectual_object))
      file.save!
    end

    it 'responds successfully' do
      get :show, params: { generic_file_identifier: file.identifier }, format: :html
      expect(response).to render_template('show')
      response.should be_successful
    end

    it 'assigns the generic file' do
      get :show, params: { generic_file_identifier: file.identifier }, format: :html
      assigns(:generic_file).should == file
    end

    it 'assigns events' do
      get :show, params: { generic_file_identifier: file.identifier }, format: :html
      assigns(:events).count.should == file.premis_events.count
    end

    it 'should show the file by identifier for API users' do
      get :show, params: { generic_file_identifier: URI.encode(file.identifier) }, format: :html
      expect(assigns(:generic_file)).to eq file
    end

    it 'responds with the file even when the file identifier is crazy' do
      get :show, params: { generic_file_identifier: crazy_file.identifier }
      expect(assigns(:generic_file)).to eq crazy_file
    end

    it 'should allow files with question marks in the identifier' do
      get :show, params: { generic_file_identifier: question_file.identifier }
      expect(assigns(:generic_file)).to eq question_file
    end

    it 'should allow files with parentheses in the identifier' do
      get :show, params: { generic_file_identifier: parens_file.identifier }
      expect(assigns(:generic_file)).to eq parens_file
    end

  end

  describe 'POST #create' do
    describe 'when not signed in' do
      let(:obj1) { @intellectual_object }
      it 'should redirect to login' do
        post :create, params: { intellectual_object_identifier: obj1.identifier, generic_file: {uri: 'Foo' }, format: :html }
        expect(response).to redirect_to root_url + 'users/sign_in'
        expect(flash[:alert]).to eq 'You need to sign in or sign up before continuing.'
      end
    end

    describe 'when signed in as inst_admin' do
      let(:user) { FactoryBot.create(:user, :institutional_admin, institution_id: @institution.id) }
      let(:obj1) { @intellectual_object }
      before { sign_in user }

      describe "should be forbidden" do
        let(:obj1) { FactoryBot.create(:consortial_intellectual_object) }
        it 'should be forbidden' do
          post :create, params: { intellectual_object_identifier: obj1.identifier, generic_file: {uri: 'path/within/bag', size: 12314121, created_at: '2001-12-31', updated_at: '2003-03-13', file_format: 'text/html', checksums: [{digest: '123ab13df23', algorithm: 'MD6', datetime: '2003-03-13T12:12:12Z'}]} }, format: 'json'
          expect(response.code).to eq '403' # forbidden
          expect(JSON.parse(response.body)).to eq({'status'=>'error','message'=>'You are not authorized to access this page.'})
        end
      end
    end

    describe 'when signed in as inst_user' do
      let(:user) { FactoryBot.create(:user, :institutional_user, institution_id: @institution.id) }
      let(:obj1) { @intellectual_object }
      before { sign_in user }

      describe "should be forbidden" do
        let(:obj1) { FactoryBot.create(:consortial_intellectual_object) }
        it 'should be forbidden' do
          post :create, params: { intellectual_object_identifier: obj1.identifier, generic_file: {uri: 'path/within/bag', size: 12314121, created_at: '2001-12-31', updated_at: '2003-03-13', file_format: 'text/html', checksums: [{digest: '123ab13df23', algorithm: 'MD6', datetime: '2003-03-13T12:12:12Z'}]} }, format: 'json'
          expect(response.code).to eq '403' # forbidden
          expect(JSON.parse(response.body)).to eq({'status'=>'error','message'=>'You are not authorized to access this page.'})
        end
      end
    end

    describe 'when signed in as admin' do
      let(:user) { FactoryBot.create(:user, :admin, institution_id: @institution.id) }
      let(:obj1) { @intellectual_object }
      before { sign_in user }

      it 'should show errors' do
        post :create, params: { intellectual_object_identifier: obj1.identifier, generic_file: {uri: 'bar'} }, format: 'json'
        expect(response.code).to eq '422' #Unprocessable Entity
        expect(JSON.parse(response.body)).to eq( {
                                                     'file_format' => ["can't be blank"],
                                                     'identifier' => ["can't be blank"],
                                                     'size' => ["can't be blank"]})
        # NOTE: while storage_option is a required field it should NOT be included in this error message because it should be set to 'standard' by default
      end

      it 'should update fields' do
        obj1.storage_option = 'Glacier-VA'
        obj1.save!
        post :create, params: { intellectual_object_identifier: obj1.identifier, generic_file: {uri: 'http://s3-eu-west-1.amazonaws.com/mybucket/puppy.jpg', size: 12314121, created_at: '2001-12-31', updated_at: '2003-03-13', file_format: 'text/html', storage_option: 'Glacier-VA', identifier: 'test.edu/12345678/data/mybucket/puppy.jpg', ingest_state: '{[A]}', checksums_attributes: [{digest: '123ab13df23', algorithm: 'MD6', datetime: '2003-03-13T12:12:12Z'}]} }, format: 'json'
        expect(response.code).to eq '201'
        assigns(:generic_file).tap do |file|
          expect(file.uri).to eq 'http://s3-eu-west-1.amazonaws.com/mybucket/puppy.jpg'
          expect(file.identifier).to eq 'test.edu/12345678/data/mybucket/puppy.jpg'
          expect(file.storage_option).to eq 'Glacier-VA'
        end
      end

      it "should match the parent object's storage_type" do
        post :create, params: { intellectual_object_identifier: obj1.identifier, generic_file: {uri: 'http://s3-eu-west-1.amazonaws.com/mybucket/puppy.jpg', size: 12314121, created_at: '2001-12-31', updated_at: '2003-03-13', file_format: 'text/html', storage_option: 'something-else', identifier: 'test.edu/12345678/data/mybucket/puppy.jpg', ingest_state: '{[A]}', checksums_attributes: [{digest: '123ab13df23', algorithm: 'MD6', datetime: '2003-03-13T12:12:12Z'}]} }, format: 'json'
        expect(response.code).to eq '201'
        assigns(:generic_file).tap do |file|
          expect(file.storage_option).to eq 'Standard'
        end
      end

      it 'should add generic file using API identifier' do
        identifier = URI.escape(obj1.identifier)
        post :create, params: { intellectual_object_identifier: identifier, generic_file: {uri: 'http://s3-eu-west-1.amazonaws.com/mybucket/cat.jpg', size: 12314121, created_at: '2001-12-31', updated_at: '2003-03-13', file_format: 'text/html', identifier: 'test.edu/12345678/data/mybucket/cat.jpg', checksums_attributes: [{digest: '123ab13df23', algorithm: 'MD6', datetime: '2003-03-13T12:12:12Z'}]} }, format: 'json'
        expect(response.code).to eq '201'
        assigns(:generic_file).tap do |file|
          expect(file.uri).to eq 'http://s3-eu-west-1.amazonaws.com/mybucket/cat.jpg'
          expect(file.identifier).to eq 'test.edu/12345678/data/mybucket/cat.jpg'
        end
      end

      it 'should create generic files larger than 2GB' do
        identifier = URI.escape(obj1.identifier)
        post :create, params: { intellectual_object_identifier: identifier, generic_file: {uri: 'http://s3-eu-west-1.amazonaws.com/mybucket/dog.jpg', size: 300000000000, created_at: '2001-12-31', updated_at: '2003-03-13', file_format: 'text/html', identifier: 'test.edu/12345678/data/mybucket/dog.jpg', checksums_attributes: [{digest: '123ab13df23', algorithm: 'MD6', datetime: '2003-03-13T12:12:12Z'}]} }, format: 'json'
        expect(response.code).to eq '201'
        assigns(:generic_file).tap do |file|
          expect(file.uri).to eq 'http://s3-eu-west-1.amazonaws.com/mybucket/dog.jpg'
          expect(file.identifier).to eq 'test.edu/12345678/data/mybucket/dog.jpg'
        end
      end
    end
  end

  describe 'POST #create_batch' do
    describe 'when not signed in' do
      let(:obj1) { @intellectual_object }
      it 'should show unauthorized' do
        post(:create_batch, params: { intellectual_object_id: obj1.id, generic_files: [] },
             format: 'json')
        expect(response.code).to eq '401'
      end
    end

    describe 'when signed in as inst admin' do
      let(:obj1) { @intellectual_object }
      let(:user) { FactoryBot.create(:user, :institutional_admin, institution_id: @institution.id) }

      before { sign_in user }
      it 'should show unauthorized' do
        post(:create_batch, params: { intellectual_object_id: obj1.id, generic_files: [] },
             format: 'json')
        expect(response.code).to eq '403'
      end
    end

    describe 'when signed in as inst user' do
      let(:obj1) { @intellectual_object }
      let(:user) { FactoryBot.create(:user, :institutional_user, institution_id: @institution.id) }

      before { sign_in user }
      it 'should show unauthorized' do
        post(:create_batch, params: { intellectual_object_id: obj1.id, generic_files: [] },
             format: 'json')
        expect(response.code).to eq '403'
      end
    end

    describe 'when signed in as admin' do
      let(:user) { FactoryBot.create(:user, :admin, institution_id: @institution.id) }
      let(:obj2) { FactoryBot.create(:consortial_intellectual_object, institution_id: @another_institution.id) }
      let(:batch_obj) { FactoryBot.create(:consortial_intellectual_object, institution_id: @institution.id) }
      let(:current_dir) { File.dirname(__FILE__) }
      let(:json_file) { File.join(current_dir, '..', 'fixtures', 'generic_file_batch.json') }
      let(:raw_json) { File.read(json_file) }
      let(:gf_data) { JSON.parse(raw_json) }

      before { sign_in user }

      describe 'and assigning to an object you do have access to' do
        it 'it should create or update multiple files and their events' do
          files_before = GenericFile.count
          events_before = PremisEvent.count
          checksums_before = Checksum.count
          post :create_batch, params: { intellectual_object_id: batch_obj.id }, body: gf_data.to_json, format: :json
          expect(response.code).to eq '201'
          return_data = JSON.parse(response.body)
          expect(return_data['count']).to eq 2
          expect(return_data['results'][0]['id']).not_to be_nil
          expect(return_data['results'][1]['id']).not_to be_nil
          expect(return_data['results'][0]['state']).to eq 'A'
          expect(return_data['results'][1]['state']).to eq 'A'
          expect(return_data['results'][0]['premis_events'].count).to eq 2
          expect(return_data['results'][1]['premis_events'].count).to eq 2
          expect(return_data['results'][0]['checksums'].count).to eq 2
          expect(return_data['results'][1]['checksums'].count).to eq 2
          files_after = GenericFile.count
          events_after = PremisEvent.count
          checksums_after = Checksum.count
          expect(files_after).to eq(files_before + 2)
          expect(events_after).to eq(events_before + 4)
          expect(checksums_after).to eq(checksums_before + 4)
        end
      end
    end
  end

  describe 'PATCH #update' do
    before(:all) { @file = FactoryBot.create(:generic_file, intellectual_object_id: @intellectual_object.id) }
    let(:file) { @file }

    describe 'when not signed in' do
      it 'should redirect to login' do
        patch :update, params: { intellectual_object_identifier: file.intellectual_object, generic_file_identifier: file, trailing_slash: true }
        expect(response.code).to eq '401'
        #expect(response).to redirect_to root_url + 'users/sign_in'
        #expect(flash[:alert]).to eq 'You need to sign in or sign up before continuing.'
      end
    end

    describe 'when signed in' do
      before { sign_in user }

      describe "and updating a file you don't have access to" do
        let(:user) { FactoryBot.create(:user, :institutional_admin, institution_id: @another_institution.id) }
        it 'should be forbidden' do
          patch :update, params: { intellectual_object_identifier: file.intellectual_object.identifier, generic_file_identifier: file.identifier, generic_file: {size: 99}, format: 'json', trailing_slash: true }
          expect(response.code).to eq '403' # forbidden
          expect(JSON.parse(response.body)).to eq({'status'=>'error','message'=>'You are not authorized to access this page.'})
        end
      end

      describe 'and you have access to the file' do
        let(:new_checksum) { FactoryBot.create(:checksum, generic_file: file) }
        let(:new_event) { FactoryBot.create(:premis_event_validation, generic_file: file) }
        it 'should update the file' do
          patch :update, params: { intellectual_object_identifier: file.intellectual_object.identifier, generic_file_identifier: file, generic_file: {size: 99, ingest_state: '{[D]}', storage_option: 'Glacier-OH'}, format: 'json', trailing_slash: true }
          expect(assigns[:generic_file].size).to eq 99
          expect(assigns[:generic_file].ingest_state).to eq '{[D]}'
          expect(assigns[:generic_file].storage_option).to eq 'Glacier-OH'
          expect(response.code).to eq '200'
        end

        it 'should update the file by identifier (API)' do
          checksum_count = file.checksums.count
          premis_event_count = file.premis_events.count
          file.checksums << new_checksum
          file.premis_events << new_event
          patch :update, params: { generic_file_identifier: URI.escape(file.identifier), id: file.id, generic_file: {size: 99}, format: 'json', trailing_slash: true }
          expect(assigns[:generic_file].size).to eq 99
          expect(response.code).to eq '200'
          file.reload
          expect(file.checksums.count).to eq(checksum_count + 1)
          expect(file.premis_events.count).to eq(premis_event_count + 1)
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    before(:all) {
      @file = FactoryBot.create(:generic_file, intellectual_object_id: @intellectual_object.id)
      @parent_work_item = FactoryBot.create(:work_item,
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
        delete :destroy, params: { generic_file_identifier: file }
        expect(response.code).to eq '401'
        #expect(response).to redirect_to root_url + 'users/sign_in'
        #expect(flash[:alert]).to eq 'You need to sign in or sign up before continuing.'
      end
    end

    describe 'when signed in' do
      before { sign_in user }

      describe "and deleting a file you don't have access to" do
        let(:user) { FactoryBot.create(:user, :institutional_admin, institution_id: @another_institution.id) }
        it 'should be forbidden' do
          delete :destroy, params: { generic_file_identifier: file }, format: 'json'
          expect(response.code).to eq '403' # forbidden
          expect(JSON.parse(response.body)).to eq({'status'=>'error','message'=>'You are not authorized to access this page.'})
        end
      end

      describe 'and you have access to the file' do
        it 'should create an deletion request email and token' do
          count_before = Email.all.count
          delete :destroy, params: { generic_file_identifier: file.identifier }
          count_after = Email.all.count
          expect(count_after).to eq count_before + 1
          email = ActionMailer::Base.deliveries.last
          expect(email.body.encoded).to include("http://localhost:3000/files/#{CGI.escape(file.identifier)}")
          expect(email.body.encoded).to include('has requested the deletion')
          expect(file.confirmation_token.token).not_to be_nil
        end

        it 'should not delete already deleted item' do
          delete :destroy, params: { generic_file_identifier: deleted_file.identifier }
          expect(response).to redirect_to generic_file_path(deleted_file)
          expect(flash[:alert]).to include 'This file has already been deleted'
        end
      end
    end
  end

  describe 'DELETE #confirm_destroy' do
    before(:all) {
      @file = FactoryBot.create(:generic_file, intellectual_object_id: @intellectual_object.id)
      @parent_work_item = FactoryBot.create(:work_item,
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
        delete :confirm_destroy, params: { generic_file_identifier: file }
        expect(response.code).to eq '401'
        #expect(response).to redirect_to root_url + 'users/sign_in'
        #expect(flash[:alert]).to eq 'You need to sign in or sign up before continuing.'
      end
    end

    describe 'when signed in' do
      before { sign_in user }

      describe "and deleting a file you don't have access to" do
        let(:user) { FactoryBot.create(:user, :institutional_admin, institution_id: @another_institution.id) }
        it 'should be forbidden' do
          delete :confirm_destroy, params: { generic_file_identifier: file }, format: 'json'
          expect(response.code).to eq '403' # forbidden
          expect(JSON.parse(response.body)).to eq({'status'=>'error','message'=>'You are not authorized to access this page.'})
        end
      end

      describe 'and you have access to the file' do
        it 'should delete the file' do
          token = FactoryBot.create(:confirmation_token, generic_file: file)
          count_before = Email.all.count
          delete :confirm_destroy, params: { generic_file_identifier: file, confirmation_token: token.token, requesting_user_id: user.id }, format: 'json'
          expect(assigns[:generic_file].state).to eq 'A'
          expect(response.code).to eq '204'
          count_after = Email.all.count
          expect(count_after).to eq count_before + 1
          email = ActionMailer::Base.deliveries.last
          expect(email.body.encoded).to include("http://localhost:3000/files/#{CGI.escape(file.identifier)}")
          expect(email.body.encoded).to include('has been successfully queued for deletion')
        end

        it 'delete the file with html response' do
          file = FactoryBot.create(:generic_file, intellectual_object_id: @intellectual_object.id)
          token = FactoryBot.create(:confirmation_token, generic_file: file)
          delete :confirm_destroy, params: { generic_file_identifier: file, confirmation_token: token.token, requesting_user_id: user.id }, format: 'html'
          expect(response).to redirect_to intellectual_object_path(file.intellectual_object)
          expect(assigns[:generic_file].state).to eq 'A'
          expect(flash[:notice]).to eq "Delete job has been queued for file: #{file.uri}."
        end

        it 'should create a WorkItem with the delete request' do
          file = FactoryBot.create(:generic_file, intellectual_object_id: @intellectual_object.id)
          token = FactoryBot.create(:confirmation_token, generic_file: file)
          delete :confirm_destroy, params: { generic_file_identifier: file, confirmation_token: token.token, requesting_user_id: user.id }, format: 'json'
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

  describe 'GET #finished_destroy' do
    before(:all) {
      @file = FactoryBot.create(:generic_file, intellectual_object_id: @intellectual_object.id)
      @parent_work_item = FactoryBot.create(:work_item,
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
        get :finished_destroy, params: { generic_file_identifier: file }
        expect(response.code).to eq '401'
      end
    end

    describe 'when signed in' do
      before { sign_in user }

      describe "and deleting a file you don't have access to" do
        let(:user) { FactoryBot.create(:user, :institutional_admin, institution_id: @another_institution.id) }
        it 'should be forbidden' do
          get :finished_destroy, params: { generic_file_identifier: file }, format: 'json'
          expect(response.code).to eq '403' # forbidden
          expect(JSON.parse(response.body)).to eq({'status'=>'error','message'=>'You are not authorized to access this page.'})
        end
      end

      describe 'and you have access to the file' do
        let(:user) { FactoryBot.create(:user, :admin) }
        it 'should delete the file' do
          # Record PREMIS ingest and deletion events
          file.add_event(FactoryBot.attributes_for(:premis_event_ingest, date_time: '2010-01-01T10:00:00Z'))
          file.add_event(FactoryBot.attributes_for(:premis_event_deletion, date_time: '2018-01-01T10:00:00Z'))
          count_before = Email.all.count
          get :finished_destroy, params: { generic_file_identifier: file, requesting_user_id: user.id, inst_approver_id: inst_user.id }, format: 'json'
          expect(assigns[:generic_file].state).to eq 'D'
          expect(response.code).to eq '204'
        end

        it 'should raise an exception if there is no PREMIS deletion event' do
          expect {
            get :finished_destroy, params: { generic_file_identifier: file, requesting_user_id: user.id, inst_approver_id: inst_user.id }, format: 'json'
          }.to raise_error("File cannot be marked deleted without first creating a deletion PREMIS event.")
        end

        it 'delete the file with html response' do
          file = FactoryBot.create(:generic_file, intellectual_object_id: @intellectual_object.id)
          # Record PREMIS ingest and deletion events
          file.add_event(FactoryBot.attributes_for(:premis_event_ingest, date_time: '2010-01-01T10:00:00Z'))
          file.add_event(FactoryBot.attributes_for(:premis_event_deletion, date_time: '2018-01-01T10:00:00Z'))
          get :finished_destroy, params: { generic_file_identifier: file, requesting_user_id: user.id, inst_approver_id: inst_user.id }, format: 'html'
          expect(response).to redirect_to intellectual_object_path(file.intellectual_object)
          expect(assigns[:generic_file].state).to eq 'D'
          expect(flash[:notice]).to eq "Delete job has been finished for file: #{file.uri}. File has been marked as deleted."
        end
      end
    end
  end

  describe 'GET #not_checked_since' do
    describe 'when signed in as an admin user' do
      before do
        sign_in user
        PremisEvent.delete_all
        GenericFile.delete_all
      end

      it 'allows access to the API endpoint' do
        get :index, params: { not_checked_since: '2015-01-31T14:31:36Z' }, format: :json
        expect(response.status).to eq 200
      end

      it 'should return only files that have not had a fixity check since the given date' do
        dates = ['2017-01-01T00:00:00Z', '2016-01-01T00:00:00Z', '2015-01-01T00:00:00Z']
        10.times do |i|
          gf = FactoryBot.create(:generic_file, state: 'A')
          event = gf.add_event(FactoryBot.attributes_for(:premis_event_fixity_check, date_time: dates[i % 3]))
        end
        get :index, params: { not_checked_since: '2015-01-01T00:00:00Z', start: 0, rows: 10 }, format: :json
        expect(assigns[:generic_files].length).to eq 3

        get :index, params: { not_checked_since: '2016-01-01T00:00:00Z', start: 0, rows: 10 }, format: :json
        expect(assigns[:generic_files].length).to eq 6

        get :index, params: { not_checked_since: '2017-01-01T00:00:00Z', start: 0, rows: 10 }, format: :json
        expect(assigns[:generic_files].length).to eq 10

        # Should get max 10 results by default if we omit start and rows.
        get :index, params: { not_checked_since: '2017-01-01T00:00:00Z' }, format: :json
        expect(assigns[:generic_files].length).to eq 10
      end

      it 'includes not_checked_since in next link if necessary' do
        3.times do
          FactoryBot.create(:generic_file, state: 'A', last_fixity_check: '1999-01-01')
        end
        get :index, params: { not_checked_since: '2099-12-31', page: 2, per_page: 1 }, format: :json
        expect(response.status).to eq(200)
        data = JSON.parse(response.body)
        expect(data['count']).to eq(3)
        expect(data['next']).to include('not_checked_since=2099-12-31')
        expect(data['previous']).to include('not_checked_since=2099-12-31')
      end

    end
  end

  describe 'PUT #restore' do
    let!(:restore_parent) { FactoryBot.create(:institutional_intellectual_object, institution: @institution, state: 'A', identifier: 'college.edu/for_restore') }
    let!(:file_for_restore) { FactoryBot.create(:generic_file, intellectual_object_id: restore_parent.id, state: 'A', identifier: 'college.edu/for_restore/data/test.pdf') }
    let!(:deleted_parent) { FactoryBot.create(:institutional_intellectual_object, institution: @institution, state: 'D', identifier: 'college.edu/deleted') }
    let!(:deleted_file)  { FactoryBot.create(:generic_file, intellectual_object_id: deleted_parent.id, state: 'D', identifier: 'college.edu/deleted/data/test.pdf') }
    let!(:pending_parent) { FactoryBot.create(:institutional_intellectual_object, institution: @institution, state: 'A', identifier: 'college.edu/pending') }
    let!(:pending_file) { FactoryBot.create(:generic_file, intellectual_object_id: pending_parent.id, state: 'A', identifier: 'college.edu/pending/data/test.pdf') }
    let!(:ingest) { FactoryBot.create(:work_item, object_identifier: 'college.edu/for_restore', action: 'Ingest', stage: 'Cleanup', status: 'Success') }
    let!(:pending_restore) { FactoryBot.create(:work_item, object_identifier: 'college.edu/pending', generic_file_identifier: 'college.edu/pending/data/test.pdf', action: 'Restore', stage: 'Requested', status: 'Pending') }

    after do
      GenericFile.delete_all
      IntellectualObject.delete_all
      WorkItem.delete_all
    end

    describe 'when not signed in' do
      it 'should redirect to login' do
        put :restore, params: { generic_file_identifier: file_for_restore, format: :html }
        expect(response).to redirect_to root_url + 'users/sign_in'
      end
    end

    describe 'when signed in as institutional user' do
      before { sign_in basic_user }
      it 'should respond with redirect (html)' do
        put :restore, params: { generic_file_identifier: file_for_restore }
        expect(response).to redirect_to root_url
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
      it 'should respond forbidden (json)' do
        put :restore, params: { generic_file_identifier: file_for_restore, format: :json }
        expect(response.code).to eq '403'
      end
    end

    # Admin and inst admin can hit this endpoint via HTML or JSON
    describe 'when signed in as institutional admin' do
      before { sign_in inst_user }
      it 'should respond with redirect (html)' do
        put :restore, params: { generic_file_identifier: file_for_restore }
        expect(response).to redirect_to generic_file_path(file_for_restore)
        expect(flash[:notice]).to include 'Your file has been queued for restoration.'
      end
      it 'should create a restore work item' do
        count_before = WorkItem.where(action: Pharos::Application::PHAROS_ACTIONS['restore'],
                                      stage: Pharos::Application::PHAROS_STAGES['requested'],
                                      status: Pharos::Application::PHAROS_STATUSES['pend']).count
        put :restore, params: { generic_file_identifier: file_for_restore }
        count_after = WorkItem.where(action: Pharos::Application::PHAROS_ACTIONS['restore'],
                                     stage: Pharos::Application::PHAROS_STAGES['requested'],
                                     status: Pharos::Application::PHAROS_STATUSES['pend']).count
        expect(count_after).to eq(count_before + 1)
      end
      it 'should reject deleted files (html)' do
        put :restore, params: { generic_file_identifier: deleted_file }
        expect(response).to redirect_to generic_file_path(deleted_file)
        expect(flash[:alert]).to include 'This file has been deleted and cannot be queued for restoration.'
      end
      it 'should reject files with pending work requests (html)' do
        put :restore, params: { generic_file_identifier: pending_file }
        expect(response).to redirect_to generic_file_path(pending_file)
        expect(flash[:alert]).to include 'cannot be queued for restoration at this time due to a pending'
      end
    end

    # Admin and inst admin can hit this endpoint via HTML or JSON
    describe 'when signed in as system admin' do
      before { sign_in user }
      it 'should respond with meaningful json (json)' do
        # This returns a WorkItem object for format JSON
        put :restore, params: { generic_file_identifier: file_for_restore, format: :json }
        expect(response.code).to eq '200'
        data = JSON.parse(response.body)
        expect(data['status']).to eq 'ok'
        expect(data['message']).to eq 'Your file has been queued for restoration.'
        expect(data['work_item_id']).to be > 0
      end
      it 'should create a restore work item' do
        count_before = WorkItem.where(action: Pharos::Application::PHAROS_ACTIONS['restore'],
                                      stage: Pharos::Application::PHAROS_STAGES['requested'],
                                      status: Pharos::Application::PHAROS_STATUSES['pend']).count
        put :restore, params: { generic_file_identifier: file_for_restore }, format: :json
        count_after = WorkItem.where(action: Pharos::Application::PHAROS_ACTIONS['restore'],
                                     stage: Pharos::Application::PHAROS_STAGES['requested'],
                                     status: Pharos::Application::PHAROS_STATUSES['pend']).count
        expect(count_after).to eq(count_before + 1)
      end
      it 'should reject deleted files (json)' do
        put :restore, params: { generic_file_identifier: deleted_file }, format: :json
        expect(response.code).to eq '409'
        data = JSON.parse(response.body)
        expect(data['status']).to eq 'error'
        expect(data['message']).to eq 'This file has been deleted and cannot be queued for restoration.'
        expect(data['work_item_id']).to eq 0
      end
      it 'should reject files with pending work requests (json)' do
        put :restore, params: { generic_file_identifier: pending_file }, format: :json
        expect(response.code).to eq '409'
        data = JSON.parse(response.body)
        expect(data['status']).to eq 'error'
        expect(data['message']).to include 'cannot be queued for restoration at this time due to a pending'
        expect(data['work_item_id']).to eq 0
      end
    end

  end
end
