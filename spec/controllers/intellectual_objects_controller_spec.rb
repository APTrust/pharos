require 'spec_helper'

RSpec.describe IntellectualObjectsController, type: :controller do
  after do
    Institution.destroy_all
  end

  describe 'search' do

    before(:all) do
      IntellectualObject.destroy_all
      Institution.destroy_all
    end

    describe 'when not signed in' do
      it 'should redirect to login' do
        get :index, institution_identifier: 'apt.edu'
        expect(response).to redirect_to root_url + 'users/sign_in'
      end
    end

    describe 'when some objects are in the repository and signed in' do
      let(:another_institution) { FactoryGirl.create(:institution) }
      let!(:obj1) { FactoryGirl.create(:consortial_intellectual_object, institution: another_institution) }
      let!(:obj2) { FactoryGirl.create(:institutional_intellectual_object, institution: user.institution, title: 'Aberdeen Wanderers Rugby Football Club', description: 'a Scottish rugby union club. It was founded in Aberdeen in 1928.') }
      let!(:obj3) { FactoryGirl.create(:institutional_intellectual_object,  institution: another_institution) }
      let!(:obj4) { FactoryGirl.create(:restricted_intellectual_object, institution: user.institution, title: "The 2nd Workers' Cultural Palace Station", description: 'a station of Line 2 of the Guangzhou Metro.') }
      let!(:obj5) { FactoryGirl.create(:restricted_intellectual_object, institution: another_institution) }
      let!(:obj6) { FactoryGirl.create(:institutional_intellectual_object, institution: user.institution, bag_name: '12345-abcde', alt_identifier: ['test.edu/some-bag']) }
      before { sign_in user }
      describe 'as an institutional user' do
        let(:user) { FactoryGirl.create(:user, :institutional_user) }
        describe 'and viewing my institution' do
          it 'should show the results that I have access to that belong to the institution' do
            get :index, institution_identifier: user.institution_identifier
            expect(response).to be_successful
            expect(assigns(:intellectual_objects).size).to eq 3
            expect(assigns(:intellectual_objects).map &:id).to match_array [obj2.id, obj4.id, obj6.id]
          end

          it 'should match a partial search on title' do
            get :index, institution_identifier: user.institution_identifier, q: 'Rugby', search_field: 'title'
            expect(response).to be_successful
            expect(assigns(:intellectual_objects).map &:id).to match_array [obj2.id]
          end
          it 'should match a partial search on description' do
            get :index, institution_identifier: user.institution_identifier, q: 'Guangzhou', search_field: 'description'
            expect(response).to be_successful
            expect(assigns(:intellectual_objects).map &:id).to match_array [obj4.id]
          end
          it 'should match an exact search on identifier' do
            get :index, institution_identifier: user.institution_identifier, q: obj4.identifier, search_field: 'identifier'
            expect(response).to be_successful
            expect(assigns(:intellectual_objects).map &:id).to match_array [obj4.id]
          end
          it 'should match an exact search on bag name' do
            get :index, institution_identifier: user.institution_identifier, q: '12345-abcde', search_field: 'bag_name'
            expect(response).to be_successful
            expect(assigns(:intellectual_objects).map &:id).to match_array [obj6.id]
          end
          it 'should match an exact search on alternate identifiers' do
            get :index, institution_identifier: user.institution_identifier, q: 'test.edu/some-bag', search_field: 'alt_identifier'
            expect(response).to be_successful
            expect(assigns(:intellectual_objects).map &:id).to match_array [obj6.id]
          end
        end

        describe 'and viewing another institution' do
          it 'should redirect' do
            get :index, institution_identifier: another_institution.identifier
            expect(response).to redirect_to root_url
            expect(flash[:alert]).to eq 'You are not authorized to access this page.'
          end
        end
      end

      describe 'when signed in as an admin' do
        let(:user) { FactoryGirl.create(:user, :admin) }
        describe 'and viewing another institution' do
          it 'should show the results that I have access to that belong to the institution' do
            get :index, institution_identifier: another_institution.identifier
            expect(response).to be_successful
            expect(assigns(:intellectual_objects).size).to eq 3
            expect(assigns(:intellectual_objects).map &:id).to match_array [obj1.id, obj3.id, obj5.id]
          end
        end
      end
    end
  end

  describe 'view an object' do
    let(:obj1) { FactoryGirl.create(:consortial_intellectual_object) }
    after { obj1.destroy }

    describe 'when not signed in' do
      it 'should redirect to login' do
        get :show, intellectual_object_identifier: obj1
        expect(response).to redirect_to root_url + 'users/sign_in'
      end
    end

    describe 'when signed in' do
      let(:user) { FactoryGirl.create(:user, :institutional_user) }
      before { sign_in user }

      it 'should show the object' do
        get :show, intellectual_object_identifier: obj1
        expect(response).to be_successful
        expect(assigns(:intellectual_object)).to eq obj1
      end

      it 'should show the object by identifier for API users' do
        get :show, intellectual_object_identifier: CGI.escape(obj1.identifier)
        expect(response).to be_successful
        expect(assigns(:intellectual_object)).to eq obj1
      end

      it 'should include only active generic files for API users' do
        FactoryGirl.create(:generic_file, intellectual_object: obj1, identifier: 'one', state: 'A')
        FactoryGirl.create(:generic_file, intellectual_object: obj1, identifier: 'two', state: 'D')
        get(:show, intellectual_object_identifier: CGI.escape(obj1.identifier),
            include_relations: true, format: :json)
        expect(response).to be_successful
        expect(assigns(:intellectual_object)).to eq obj1
        response_data = JSON.parse(response.body)
        expect(response_data['generic_files'].select{|f| f['state'] == 'A'}.count).to eq 1
        expect(response_data['generic_files'].select{|f| f['state'] != 'A'}.count).to eq 0
      end


    end
  end

  describe 'edit an object' do
    after { obj1.destroy }

    describe 'when not signed in' do
      let(:obj1) { FactoryGirl.create(:consortial_intellectual_object) }
      it 'should redirect to login' do
        get :edit, intellectual_object_identifier: obj1
        expect(response).to redirect_to root_url + 'users/sign_in'
      end
    end

    describe 'when signed in' do
      let(:obj1) { FactoryGirl.create(:consortial_intellectual_object, institution: user.institution) }
      describe 'as an institutional_user' do
        let(:user) { FactoryGirl.create(:user, :institutional_user) }
        before { sign_in user }
        it 'should be unauthorized' do
          get :edit, intellectual_object_identifier: obj1
          expect(response).to redirect_to root_url
          expect(flash[:alert]).to eq 'You are not authorized to access this page.'
        end
      end

      describe 'as an institutional_admin' do
        let(:user) { FactoryGirl.create(:user, :institutional_admin) }
        before { sign_in user }
        it 'should be unauthorized' do
          get :edit, intellectual_object_identifier: obj1
          expect(response).to redirect_to root_url
          expect(flash[:alert]).to eq 'You are not authorized to access this page.'
        end
      end

      describe 'as an admin' do
        let(:user) { FactoryGirl.create(:user, :admin) }
        before { sign_in user }
        it 'should not show the object' do
          get :edit, intellectual_object_identifier: obj1
          expect(response).to redirect_to root_url
          expect(flash[:alert]).to eq 'You are not authorized to access this page.'
        end
      end
    end
  end

  describe 'update an object' do
    let(:obj1) { FactoryGirl.create(:institutional_intellectual_object) }
    after { obj1.destroy }

    describe 'when not signed in' do
      let(:obj1) { FactoryGirl.create(:consortial_intellectual_object) }
      it 'should redirect to login' do
        patch :update, intellectual_object_identifier: obj1, intellectual_object: {title: 'Foo' }
        expect(response).to redirect_to root_url + 'users/sign_in'
      end
    end

    describe 'when signed in as an admin user' do
      let(:user) { FactoryGirl.create(:user, :admin) }
      let(:obj1) { FactoryGirl.create(:institutional_intellectual_object) }

      before {
        sign_in user
      }

      it 'should update fields' do
        patch :update, intellectual_object_identifier: obj1, intellectual_object: {title: 'Foo'}
        expect(response).to redirect_to intellectual_object_path(obj1)
        expect(assigns(:intellectual_object).title).to eq 'Foo'
      end

      it 'should update via json' do
        patch :update, intellectual_object_identifier: obj1, intellectual_object: {title: 'Foo'}, format: :json
        expect(response).to be_successful
        expect(assigns(:intellectual_object).title).to eq 'Foo'
      end

      it 'should update fields when called with identifier (API)' do
        put :update, intellectual_object_identifier: CGI.escape(obj1.identifier), intellectual_object: {title: 'Foo'}
        expect(assigns(:intellectual_object).title).to eq 'Foo'
      end
    end

    describe 'when signed in as an institutional admin' do
      let(:inst_user) { FactoryGirl.create(:user, :institutional_admin) }
      before do
        sign_in inst_user
      end

      it 'should restrict API usage' do
        patch :update, intellectual_object_identifier: CGI.escape(obj1.identifier), intellectual_object: {title: 'Foo'}
        expect(response.status).to eq 302
      end
    end
  end

  describe 'create an object' do
    let(:user) { FactoryGirl.create(:user, :institutional_admin) }
    let(:any_institution) { FactoryGirl.create(:institution) }
    def sample_object
      {
          institution_id: user.institution_id,
          title: 'Test Title',
          access: 'consortia',
          description: '',
          identifier: 'ncsu.edu/ncsu.1840.16-388',
          alt_identifier: [],
          bag_name: '',
          premis_events: [
              { identifier: '6b0f1c45-99e3-4636-4e46-d9498573d029',
                type: 'ingest',
                date_time: '2014-07-14T15:11:01-04:00',
                detail: 'Copied all files to perservation bucket',
                outcome: 'Success',
                outcome_detail: '1 files copied',
                object: 'Goamz S3 Client',
                agent: 'https://github.com/crowdmob/goamz',
                outcome_information: 'Multipart put using md5 checksum'
              },
              { identifier: '6b0f1c45-99e3-4636-4e46-d9498573d029',
                type: 'identifier_assignment',
                date_time: '2014-07-14T15:11:02-04:00',
                detail: 'Assigned bag identifier',
                outcome: 'Success',
                outcome_detail: 'ncsu.edu/ncsu.1840.16-388',
                object: 'APTrust bagman',
                agent: 'https://github.com/APTrust/bagman',
                outcome_information: 'Institution domain + tar file name'
              }
          ],
          generic_files: [
              { uri: 'https://s3.amazonaws.com/aptrust.test.preservation/47e00844-a53a-46de-5d93-d8ecff0e0e4b',
                size: 4853,
                created: '2014-04-25T14:06:39-04:00',
                modified: '2014-04-25T14:06:39-04:00',
                file_format: 'application/xml',
                identifier: 'ncsu.edu/ncsu.1840.16-388/data/metadata.xml',
                checksum: [
                    { algorithm: 'md5',
                      digest: '1202ef3562a201060bbdb5a7c6d37d91',
                      datetime: '2014-04-25T14:06:39-04:00'
                    },
                    { algorithm: 'sha256',
                      digest: '7a3a8623f60d5f0174d0099f851475ddbb1fb4b5aa74859e1e67dac8629cc6b6',
                      datetime: '2014-07-14T19:10:58Z'
                    }
                ],
                premis_events: [
                    { identifier: '155fb018-5ba0-440c-62a0-fc5dfe30dfd3',
                      type: 'fixity_check',
                      date_time: '2014-07-14T15:10:58-04:00',
                      detail: 'Fixity check against registered hash',
                      outcome: 'Success',
                      outcome_detail: 'md5:1202ef3562a201060bbdb5a7c6d37d91',
                      object: 'Go crypto/md5',
                      agent: 'http://golang.org/pkg/crypto/md5/',
                      outcome_information: 'Fixity matches'
                    },
                    { identifier: 'd656fd3b-5876-4e21-6449-44a3f6df3b81',
                      type: 'ingest',
                      date_time: '2014-07-14T15:10:58-04:00',
                      detail: 'Completed copy to S3',
                      outcome: 'Success',
                      outcome_detail: '',
                      object: 'bagman + goamz s3 client',
                      agent: 'https://github.com/APTrust/bagman',
                      outcome_information: 'Put using md5 checksum'
                    },
                    { identifier: '1f5671c6-ca2e-4b98-4847-54407338e7f6',
                      type: 'fixity_generation',
                      date_time: '2014-07-14T19:10:58Z',
                      detail: 'Calculated new fixity value',
                      outcome: 'Success',
                      outcome_detail: 'sha256:7a3a8623f60d5f0174d0099f851475ddbb1fb4b5aa74859e1e67dac8629cc6b6',
                      object: 'Go language crypto/sha256',
                      agent: 'http://golang.org/pkg/crypto/sha256/',
                      outcome_information: ''
                    },
                    { identifier: '9f6f4e83-e796-4a19-49af-c8feaf9fd167',
                      type: 'identifier_assignment',
                      date_time: '2014-07-14T19:10:58Z',
                      detail: 'Assigned new institution.bag/path identifier',
                      outcome: 'Success',
                      outcome_detail: 'ncsu.edu/ncsu.1840.16-388/data/metadata.xml',
                      object: 'APTrust bag processor',
                      agent: 'https://github.com/APTrust/bagman',
                      outcome_information: ''
                    },
                    { identifier: '318a6e86-8b0a-4e73-5f54-9e3ccd98a5b3',
                      type: 'identifier_assignment',
                      date_time: '2014-07-14T19:10:58Z',
                      detail: 'Assigned new storage URL identifier',
                      outcome: 'Success',
                      outcome_detail: 'https://s3.amazonaws.com/aptrust.test.preservation/e189b329-cfe6-41be-4d9c-bac1d6e7c592',
                      object: 'Go uuid library + goamz S3 library',
                      agent: 'http://github.com/nu7hatch/gouuid',
                      outcome_information: ''
                    }
                ]
              },
              { uri: 'https://s3.amazonaws.com/aptrust.test.preservation/eb41cb20-0c60-4725-4402-ba38002a79b8',
                size: 72,
                created: '2014-04-25T14:06:39-04:00',
                modified: '2014-04-25T14:06:39-04:00',
                file_format: 'text/plain',
                identifier: 'ncsu.edu/ncsu.1840.16-388/data/object.properties',
                checksum: [
                    { algorithm: 'md5',
                      digest: '3ab392455183820d9f6a5c641ec1dea7',
                      datetime: '2014-04-25T14:06:39-04:00'
                    },
                    { algorithm: 'sha256',
                      digest: 'b6458735857c41c66c26782231a963656666a1b59bdf1cc45422c15702aa4c4e',
                      datetime: '2014-07-14T19:10:58Z'
                    }
                ],
                premis_events: [
                    { identifier: '74eb8c26-88ab-444f-4aab-d7f9c2cef550',
                      type: 'fixity_check',
                      date_time: '2014-07-14T15:10:58-04:00',
                      detail: 'Fixity check against registered hash',
                      outcome: 'Success',
                      outcome_detail: 'md5:3ab392455183820d9f6a5c641ec1dea7',
                      object: 'Go crypto/md5',
                      agent: 'http://golang.org/pkg/crypto/md5/',
                      outcome_information: 'Fixity matches'
                    },
                    { identifier: '8e04d3a0-097b-4600-60fb-56e16ebba46f',
                      type: 'ingest',
                      date_time: '2014-07-14T15:10:58-04:00',
                      detail: 'Completed copy to S3',
                      outcome: 'Success',
                      outcome_detail: '',
                      object: 'bagman + goamz s3 client',
                      agent: 'https://github.com/APTrust/bagman',
                      outcome_information: 'Put using md5 checksum'
                    },
                    { identifier: 'ce53b4f9-9ada-4d72-695c-21cb118f5918',
                      type: 'fixity_generation',
                      date_time: '2014-07-14T19:10:58Z',
                      detail: 'Calculated new fixity value',
                      outcome: 'Success',
                      outcome_detail: 'sha256:b6458735857c41c66c26782231a963656666a1b59bdf1cc45422c15702aa4c4e',
                      object: 'Go language crypto/sha256',
                      agent: 'http://golang.org/pkg/crypto/sha256/',
                      outcome_information: ''
                    },
                    { identifier: '42f07e80-c025-40fe-6784-0c397be03556',
                      type: 'identifier_assignment',
                      date_time: '2014-07-14T19:10:58Z',
                      detail: 'Assigned new institution.bag/path identifier',
                      outcome: 'Success',
                      outcome_detail: 'ncsu.edu/ncsu.1840.16-388/data/object.properties',
                      object: 'APTrust bag processor',
                      agent: 'https://github.com/APTrust/bagman',
                      outcome_information: ''
                    },
                    { identifier: 'a517c55a-f5b8-4313-7db2-13c65ed9baa0',
                      type: 'identifier_assignment',
                      date_time: '2014-07-14T19:10:58Z',
                      detail: 'Assigned new storage URL identifier',
                      outcome: 'Success',
                      outcome_detail: 'https://s3.amazonaws.com/aptrust.test.preservation/5925dc09-94b4-4b49-79f0-e2a9832a41be',
                      object: 'Go uuid library + goamz S3 library',
                      agent: 'http://github.com/nu7hatch/gouuid',
                      outcome_information: ''
                    }
                ]
              },
          ]
      }
    end

    describe 'when not signed in' do
      it 'should redirect to login' do
        post :create, institution_identifier: FactoryGirl.create(:institution).identifier, intellectual_object: {title: 'Foo' }
        expect(response).to redirect_to root_url + 'users/sign_in'
        expect(flash[:alert]).to eq 'You need to sign in or sign up before continuing.'
      end
    end

    describe 'when signed in' do
      before { sign_in user }

      it 'should only allow assigning institutions you have access to' do
        post :create, institution_identifier: FactoryGirl.create(:institution).identifier, intellectual_object: {title: 'Foo'}, format: :json
        expect(response.code).to eq '403' # forbidden
        expect(JSON.parse(response.body)).to eq({'status'=>'error','message'=>'You are not authorized to access this page.'})
      end

      it 'should show errors' do
        post :create, institution_identifier: user.institution_identifier, intellectual_object: {title: 'Foo'}, format: :json
        expect(response.code).to eq '422' #Unprocessable Entity
        expect(JSON.parse(response.body)).to eq({'identifier' => ["can't be blank"],'access' => ["can't be blank"]})
      end

      it 'should update fields' do
        post :create, institution_identifier: user.institution_identifier, intellectual_object: {title: 'Foo', identifier: 'test.edu/124', access: 'restricted', bag_name: '124'}, format: :json
        expect(response.code).to eq '200'
        expect(assigns(:institution).intellectual_objects.map &:id).to match_array [assigns(:intellectual_object).id]
        expect(assigns(:intellectual_object).title).to eq 'Foo'
        expect(assigns(:intellectual_object).identifier).to eq 'test.edu/124'
        expect(assigns(:intellectual_object).bag_name).to eq '124'
      end

      it 'should use the institution parameter in the URL, not from the json' do
        expect {
          post :create, institution_identifier: user.institution_identifier, intellectual_object: {title: 'Foo', identifier: 'test.edu/123', access: 'restricted'}, format: :json
          expect(response.code).to eq '200'
          expect(assigns(:institution).intellectual_objects.map &:id).to match_array [assigns(:intellectual_object).id]
          expect(assigns(:intellectual_object).title).to eq 'Foo'
          expect(assigns(:intellectual_object).institution_id).to eq user.institution_id
        }.to change(IntellectualObject, :count).by(1)
      end

    end

    describe 'when signed in as an admin' do
      let(:admin_user) { FactoryGirl.create(:user, :admin) }
      before { sign_in admin_user }

      it 'should create all nested items when include relations flag is true' do
        expect {
          post :create, institution_identifier: any_institution.identifier, include_nested: 'true', intellectual_object: [sample_object], format: :json
          expect(response.code).to eq '200'
          expect(assigns(:institution).intellectual_objects.map &:id).to match_array [assigns(:intellectual_object).id]
          expect(assigns(:intellectual_object).title).to eq 'Test Title'
          expect(assigns(:intellectual_object).bag_name).to eq 'ncsu.1840.16-388'
        }.to change(IntellectualObject, :count).by(1)
      end

      it 'should roll back when nested items are invalid' do
        obj = sample_object()
        obj[:identifier] = 'ncsu.edu/ncsu.ahchoo'
        obj[:premis_events].each { |pe| pe[:identifier] += '_1' }
        obj[:generic_files].each { |gf|
          gf[:identifier] += '_1'
          gf[:premis_events].each { |pe| pe[:identifier] += '_1' }
        }
        # Missing format is invalid. This will cause create_from_json
        # to fail after it's already built up some generic files and
        # events.
        obj[:generic_files][1][:file_format] = ''
        expect {
          post :create, institution_identifier: any_institution.identifier, include_nested: 'true', intellectual_object: obj, format: :json
          expect(response.code).to eq '422'
        }.to change(IntellectualObject, :count).by(0)
      end
    end
  end

  describe 'destroy an object' do
    describe 'when not signed in' do
      let(:obj1) { FactoryGirl.create(:consortial_intellectual_object) }
      after { obj1.destroy }
      it 'should redirect to login' do
        delete :destroy, intellectual_object_identifier: obj1
        expect(response).to redirect_to root_url + 'users/sign_in'
      end
    end

    describe 'when signed in' do
      let(:user) { FactoryGirl.create(:user, :institutional_admin) }
      let(:obj1) { FactoryGirl.create(:consortial_intellectual_object, institution: user.institution) }
      before { sign_in user }
      after { WorkItem.delete_all }

      it 'should update via json' do
        pi = FactoryGirl.create(:ingested_item, object_identifier: obj1.identifier)
        delete :destroy, intellectual_object_identifier: obj1, format: :json
        expect(response.code).to eq '204'
        expect(assigns(:intellectual_object).state).to eq 'D'
      end

      it 'should update via html' do
        pi = FactoryGirl.create(:ingested_item, object_identifier: obj1.identifier)
        delete :destroy, intellectual_object_identifier: obj1
        expect(response).to redirect_to root_path
        expect(flash[:notice]).to eq "Delete job has been queued for object: #{obj1.title}. Depending on the size of the object, it may take a few minutes for all associated files to be marked as deleted."
        expect(assigns(:intellectual_object).state).to eq 'D'
      end
    end
  end

  describe 'restore an object' do
    describe 'when not signed in' do
      let(:obj1) { FactoryGirl.create(:consortial_intellectual_object) }
      after { obj1.destroy }

      it 'should redirect to login' do
        get :index, q: obj1, alt_action: 'restore', institution_identifier: obj1.institution.identifier
        expect(response).to redirect_to root_url + 'users/sign_in'
      end

    end

    describe 'when signed in as an admin' do
      let(:user) { FactoryGirl.create(:user, :admin) }
      let(:obj1) { FactoryGirl.create(:consortial_intellectual_object) }

      before do
        5.times do
          FactoryGirl.create(:ingested_item)
        end
        WorkItem.update_all(object_identifier: obj1.identifier)
        WorkItem.first.update(object_identifier: 'some.edu/some.bag')
        request.env['HTTP_REFERER'] = 'OzzyOsbourne'
        sign_in user
      end

      after do
        WorkItem.delete_all
      end

      it 'should mark only the latest work item for restore' do
        get :index, q: obj1, alt_action: 'restore', institution_identifier: obj1.institution.identifier
        expect(response).to redirect_to obj1
        count = WorkItem.where(action: Pharos::Application::PHAROS_ACTIONS['restore'],
                                    stage: Pharos::Application::PHAROS_STAGES['requested'],
                                    status: Pharos::Application::PHAROS_STATUSES['pend'],
                                    retry: true).count
        expect(count).to eq(1)
      end

    end

    describe 'when signed in as an institutional admin' do
      let(:user) { FactoryGirl.create(:user, :institutional_admin) }
      let(:obj1) { FactoryGirl.create(:consortial_intellectual_object, institution: user.institution) }

      before do
        FactoryGirl.create(:ingested_item)
        WorkItem.update_all(object_identifier: obj1.identifier)
        request.env['HTTP_REFERER'] = 'OzzyOsbourne'
        sign_in user
      end

      after do
        WorkItem.delete_all
      end

      it 'should mark the work item for restore' do
        get :index, q: obj1, alt_action: 'restore', institution_identifier: obj1.institution.identifier
        expect(response).to redirect_to obj1
        count = WorkItem.where(action: Pharos::Application::PHAROS_ACTIONS['restore'],
                                    stage: Pharos::Application::PHAROS_STAGES['requested'],
                                    status: Pharos::Application::PHAROS_STATUSES['pend']).count
        expect(count).to eq(1)

      end
    end
  end

  describe 'send an object to dpn' do
    describe 'when not signed in' do
      let(:obj1) { FactoryGirl.create(:consortial_intellectual_object) }
      after { obj1.destroy }

      it 'should redirect to login' do
        get :index, q: obj1, alt_action: 'dpn', institution_identifier: obj1.institution.identifier
        expect(response).to redirect_to root_url + 'users/sign_in'
      end

    end

    describe 'when signed in as an admin' do
      let(:user) { FactoryGirl.create(:user, :admin) }
      let(:obj1) { FactoryGirl.create(:consortial_intellectual_object) }

      before do
        FactoryGirl.create(:ingested_item)
        WorkItem.update_all(object_identifier: obj1.identifier)
        request.env['HTTP_REFERER'] = 'OzzyOsbourne'
        sign_in user
      end

      after do
        WorkItem.delete_all
      end

      it 'should mark the work item as sent to dpn' do
        get :index, q: obj1, alt_action: 'dpn', institution_identifier: obj1.institution.identifier
        expect(response).to redirect_to obj1
        count = WorkItem.where(action: Pharos::Application::PHAROS_ACTIONS['dpn'],
                                    stage: Pharos::Application::PHAROS_STAGES['requested'],
                                    status: Pharos::Application::PHAROS_STATUSES['pend'],
                                    retry: true).count
        expect(count).to eq(1)
      end

    end

    describe 'when signed in as an institutional admin' do
      let(:user) { FactoryGirl.create(:user, :institutional_admin) }
      let(:obj1) { FactoryGirl.create(:consortial_intellectual_object, institution: user.institution) }

      before do
        FactoryGirl.create(:ingested_item)
        WorkItem.update_all(object_identifier: obj1.identifier)
        request.env['HTTP_REFERER'] = 'OzzyOsbourne'
        sign_in user
      end

      after do
        WorkItem.delete_all
      end

      it 'should mark the work item as sent to dpn' do
        get :index, q: obj1, alt_action: 'dpn', institution_identifier: obj1.institution.identifier
        expect(response).to redirect_to obj1
        count = WorkItem.where(action: Pharos::Application::PHAROS_ACTIONS['dpn'],
                                    stage: Pharos::Application::PHAROS_STAGES['requested'],
                                    status: Pharos::Application::PHAROS_STATUSES['pend']).count
        expect(count).to eq(1)

      end
    end
  end

  describe 'GET #api_index' do

    describe 'for an admin user' do
      let(:user) { FactoryGirl.create(:user, :admin) }
      let(:another_institution) { FactoryGirl.create(:institution) }
      let!(:object1) { FactoryGirl.create(:consortial_intellectual_object, bag_name: 'item1-for-hire', institution: user.institution) }
      let!(:object2) { FactoryGirl.create(:consortial_intellectual_object, bag_name: '1', institution: user.institution) }
      let!(:object3) { FactoryGirl.create(:consortial_intellectual_object, bag_name: '2', institution: another_institution) }
      let!(:object4) { FactoryGirl.create(:consortial_intellectual_object, bag_name: '3', institution: another_institution) }
      let!(:object5) { FactoryGirl.create(:consortial_intellectual_object, bag_name: '4', institution: another_institution) }
      before do
        sign_in user
      end

      it 'returns all items when no other parameters are specified' do
        get :index, format: :json, per_page: 1000
        assigns(:intellectual_objects).should include(object1)
        assigns(:intellectual_objects).should include(object2)
        assigns(:intellectual_objects).should include(object3)
      end

      it 'filters down to the right records and has the right count' do
        ident_parts = object1.identifier.split('/')
        get :index, format: :json, name_contains: ident_parts[1]
        assigns(:intellectual_objects).should_not include(object2)
        assigns(:intellectual_objects).should_not include(object3)
        assigns(:intellectual_objects).should include(object1)
        assigns(:count).should == 1
      end

      it 'returns the correct next and previous links' do
        get :index, format: :json, per_page: 2, page: 2, updated_since: '2014-06-03T15:28:39+00:00'
        assigns(:next).should == 'http://test.host/member-api/v1/objects/?page=3&per_page=2&updated_since=2014-06-03T15:28:39+00:00'
        assigns(:previous).should == 'http://test.host/member-api/v1/objects/?page=1&per_page=2&updated_since=2014-06-03T15:28:39+00:00'
      end
    end

    describe 'for an institutional admin user' do
      let(:user) { FactoryGirl.create(:user, :institutional_admin) }
      let(:another_institution) { FactoryGirl.create(:institution) }
      let!(:object1) { FactoryGirl.create(:consortial_intellectual_object, bag_name: 'item1-for-hire', institution: user.institution) }
      let!(:object2) { FactoryGirl.create(:consortial_intellectual_object, bag_name: '1', institution: user.institution) }
      let!(:object3) { FactoryGirl.create(:consortial_intellectual_object, bag_name: '2', institution: another_institution) }
      before do
        sign_in user
      end

      it "returns only the items within the user's institution" do
        get :index, format: :json, per_page: 100
        assigns(:intellectual_objects).should include(object1)
        assigns(:intellectual_objects).should include(object2)
        assigns(:intellectual_objects).should_not include(object3)
      end
    end
  end
end
