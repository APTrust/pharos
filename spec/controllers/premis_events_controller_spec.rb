require 'spec_helper'

RSpec.describe PremisEventsController, type: :controller do
  after do
    Institution.destroy_all
  end

  let(:object) { FactoryGirl.create(:intellectual_object, institution: user.institution, access: 'institution') }
  let(:file) { FactoryGirl.create(:generic_file, intellectual_object: object) }
  let(:event_attrs) { FactoryGirl.attributes_for(:premis_event_fixity_generation,
                                                 intellectual_object_id: object.id,
                                                 intellectual_object_identifier: object.identifier,
                                                 generic_file_id: file.id,
                                                 generic_file_identifier: file.identifier) }

  # An object and a file from a different institution:
  let(:someone_elses_object) { FactoryGirl.create(:intellectual_object, access: 'institution') }
  let(:someone_elses_file) { FactoryGirl.create(:generic_file, intellectual_object: someone_elses_object) }


  describe 'signed in as admin user' do
    let(:user) { FactoryGirl.create(:user, :admin) }
    before { sign_in user }

    describe 'GET index' do
      before do
        @someone_elses_event = someone_elses_file.add_event(event_attrs)
        someone_elses_file.save!
      end

      it "can view events, even if it's not my institution" do
        get :index, institution_identifier: someone_elses_file.institution.identifier
        expect(response).to be_success
        assigns(:parent).should == someone_elses_file.institution
        assigns(:premis_events).length.should == 1
        assigns(:premis_events).map(&:identifier).should == [@someone_elses_event.identifier]
      end

      it "can view events, even if it's not my intellectual object" do
        get :index, object_identifier: someone_elses_object
        expect(response).to be_success
        assigns(:parent).should == someone_elses_object
        assigns(:premis_events).length.should == 1
        assigns(:premis_events).map(&:identifier).should == [@someone_elses_event.identifier]
      end

      it 'can view objects events by object identifier (API)' do
        get :index, object_identifier: someone_elses_object.identifier
        expect(response).to be_success
        assigns(:parent).should == someone_elses_object
        assigns(:premis_events).length.should == 1
        assigns(:premis_events).map(&:identifier).should == [@someone_elses_event.identifier]
      end

    end
  end

  describe 'signed in as admin' do
    let(:user) { FactoryGirl.create(:user, :admin) }
    before { sign_in user }

    describe 'POST create' do

      it 'creates an event for the generic file using generic file identifier (API)' do
        file.premis_events.count.should == 0
        post :create, event_attrs.to_json, format: :json
        file.reload
        file.premis_events.count.should == 1
        assigns(:parent).should == file
        expect(response.status).to eq(201)
      end

      it 'creates an event for an intellectual object by object identifier' do
        event_attrs[:generic_file_identifier] = ''
        event_attrs[:generic_file_id] = ''
        object.premis_events.count.should == 0
        post :create, event_attrs.to_json, format: :json
        expect(response.status).to eq(201)
        object.reload
        object.premis_events.count.should == 1
        assigns(:parent).should == object
        assigns(:event).should_not be_nil
      end

    end
  end

  describe 'signed in as institutional admin' do
    let(:user) { FactoryGirl.create(:user, :institutional_admin) }
    before { sign_in user }

    describe 'POST create' do
      it 'is forbidden' do
        post :create, event_attrs.to_json, format: :json
        expect(response.status).to eq(403)
      end
    end

    describe "POST create a file where you don't have permission" do
      it 'denies access' do
        someone_elses_file.premis_events.count.should == 0
        post :create, event_attrs.to_json, format: :json
        someone_elses_file.reload

        someone_elses_file.premis_events.count.should == 0
        expect(response.status).to eq(403)
      end
    end

  end

  describe 'signed in as institutional user' do
    let(:user) { FactoryGirl.create(:user, :institutional_user) }
    before { sign_in user }

    describe 'POST create' do
      it 'denies access' do
        file.premis_events.count.should == 0
        post :create, event_attrs.to_json, format: :json
        file.reload

        file.premis_events.count.should == 0
        expect(response.status).to eq(403)
      end
    end

    describe 'GET index' do
      before do
        oldest_time = '2014-01-13 10:15:00 -0600'
        middle_time = '2014-01-13 10:30:00 -0600'
        newest_time = '2014-01-13 10:45:00 -0600'

        @event = file.add_event(event_attrs.merge(date_time: oldest_time, identifier: SecureRandom.uuid))
        @event2 = file.add_event(event_attrs.merge(date_time: newest_time, identifier: SecureRandom.uuid))
        @event3 = file.add_event(event_attrs.merge(date_time: middle_time, identifier: SecureRandom.uuid))
        file.save!

        @someone_elses_event = someone_elses_file.add_event(event_attrs)
        someone_elses_file.save!
      end

      describe 'events for an institution' do
        it 'shows the events for that institution, sorted by time' do
          get :index, institution_identifier: file.institution.identifier
          assigns(:parent).should == file.institution
          assigns(:premis_events).length.should == 3
          assigns(:premis_events).map(&:identifier).should == [@event.identifier, @event2.identifier, @event3.identifier]
        end
      end

      describe 'events for an intellectual object' do
        it 'shows the events for that object, sorted by time' do
          get :index, object_identifier: object
          expect(response).to be_success
          assigns(:parent).should == object
          assigns(:premis_events).length.should == 3
          assigns(:premis_events).map(&:identifier).should == [@event.identifier, @event2.identifier, @event3.identifier]
        end
      end

      describe 'events for a generic file' do
        it 'shows the events for that file, sorted by time' do
          get :index, file_identifier: file
          expect(response).to be_success
          assigns(:parent).should == file
          assigns(:premis_events).length.should == 3
          assigns(:premis_events).map(&:identifier).should == [@event.identifier, @event2.identifier, @event3.identifier]
        end
      end

      describe "for an institution where you don't have permission" do
        it 'denies access' do
          get :index, institution_identifier: someone_elses_file.institution.identifier
          expect(response).to redirect_to root_url
          flash[:alert].should =~ /You are not authorized/
        end
      end

      describe "for an intellectual object where you don't have permission" do
        it 'denies access' do
          get :index, object_identifier: someone_elses_object
          expect(response).to redirect_to root_url
          flash[:alert].should =~ /You are not authorized/
        end
      end

      describe "for a generic file where you don't have permission" do
        it 'denies access' do
          get :index, file_identifier: someone_elses_file
          expect(response).to redirect_to root_url
          flash[:alert].should =~ /You are not authorized/
        end
      end
    end
  end

  describe 'not signed in' do
    let(:user) { FactoryGirl.create(:user, :institutional_user) }
    let(:file) { FactoryGirl.create(:generic_file) }

    describe 'POST create' do
      before do
        post :create, event_attrs.to_json, format: :json
      end

      it 'says you are unauthorized' do
        # This is a JSON call, so you get a 401, not a redirect
        expect(response.status).to eq(401)
      end
    end

    describe 'GET index' do
      before do
        get :index, institution_identifier: file.institution.identifier
      end

      it 'redirects to login' do
        expect(response).to redirect_to root_url + 'users/sign_in'
        expect(flash[:alert]).to eq 'You need to sign in or sign up before continuing.'
      end
    end
  end
end
