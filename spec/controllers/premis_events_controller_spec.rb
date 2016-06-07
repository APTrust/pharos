require 'spec_helper'

RSpec.describe PremisEventsController, type: :controller do
  after do
    Institution.destroy_all
  end

  let(:object) { FactoryGirl.create(:intellectual_object, institution: user.institution, access: 'institution') }
  let(:file) { FactoryGirl.create(:generic_file, intellectual_object: object) }
  let(:event_attrs) { FactoryGirl.attributes_for(:premis_event_fixity_generation) }

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
        get :index, identifier: someone_elses_file.institution.identifier
        expect(response).to be_success
        assigns(:institution).should == someone_elses_file.institution
        assigns(:document_list).length.should == 1
        assigns(:document_list).map(&:id).should == @someone_elses_event.identifier
      end

      it "can view events, even if it's not my intellectual object" do
        get :index, intellectual_object_identifier: someone_elses_object
        expect(response).to be_success
        assigns(:intellectual_object).should == someone_elses_object
        assigns(:document_list).length.should == 1
        assigns(:document_list).map(&:id).should == @someone_elses_event.identifier
      end

      it 'can view objects events by object identifier (API)' do
        get :index, intellectual_object_identifier: someone_elses_object.identifier, use_route: 'events_by_object_identifier_path'
        expect(response).to be_success
        assigns(:intellectual_object).should == someone_elses_object
        assigns(:document_list).length.should == 1
        assigns(:document_list).map(&:id).should == @someone_elses_event.identifier
      end

    end
  end


  describe 'signed in as institutional admin' do
    let(:user) { FactoryGirl.create(:user, :institutional_admin) }
    before { sign_in user }

    describe 'POST create' do
      it 'creates an event for the generic file' do
        file.premis_events.events.count.should == 0
        post :create, generic_file_identifier: file, event: event_attrs
        file.reload

        file.premis_events.events.count.should == 1
        response.should redirect_to generic_file_path(file)
        assigns(:parent_object).should == file
        assigns(:event).should_not be_nil
        flash[:notice].should =~ /Successfully created new event/
      end

      it 'creates an event for the generic file using generic file identifier (API)' do
        file.premis_events.events.count.should == 0
        post :create, generic_file_identifier: URI.escape(file.identifier), event: event_attrs, format: :json, use_route: 'events_by_file_identifier_path'
        file.reload
        file.premis_events.events.count.should == 1
        assigns(:parent_object).should == file
        # API response should be 201/created instead of redirect that the HTML client gets
        expect(response.status).to eq(201)
      end

      it 'creates an event for an intellectual object' do
        object.premis_events.events.count.should == 0
        post :create, intellectual_object_identifier: object, event: event_attrs
        object.reload

        object.premis_events.events.count.should == 1
        response.should redirect_to intellectual_object_path(object)
        assigns(:parent_object).should == object
        assigns(:event).should_not be_nil
        flash[:notice].should =~ /Successfully created new event/
      end


      it 'creates an event for an intellectual object by object identifier' do
        object.premis_events.events.count.should == 0
        post :create, intellectual_object_identifier: URI.escape(object.identifier), event: event_attrs, use_route: 'events_by_object_identifier_path'
        object.reload

        object.premis_events.events.count.should == 1
        response.should redirect_to intellectual_object_path(object)
        assigns(:parent_object).should == object
        assigns(:event).should_not be_nil
        flash[:notice].should =~ /Successfully created new event/
      end


      it 'if it fails, it prints a fail message' do
        file.premis_events.events.count.should == 0
        GenericFile.any_instance.should_receive(:save).and_return(false) # Make it fail
        post :create, generic_file_identifier: file, event: event_attrs
        file.reload
        file.premis_events.events.count.should == 0
        flash[:alert].should =~ /Unable to create event/
      end
    end

    describe "POST create a file where you don't have permission" do
      it 'denies access' do
        someone_elses_file.premis_events.events.count.should == 0
        post :create, generic_file_identifier: someone_elses_file, event: event_attrs
        someone_elses_file.reload

        someone_elses_file.premis_events.events.count.should == 0
        expect(response).to redirect_to root_url
        flash[:alert].should =~ /You are not authorized/
      end
    end

  end


  describe 'signed in as institutional user' do
    let(:user) { FactoryGirl.create(:user, :institutional_user) }
    before { sign_in user }

    describe 'POST create' do
      it 'denies access' do
        file.premis_events.events.count.should == 0
        post :create, generic_file_identifier: file, event: event_attrs
        file.reload

        file.premis_events.events.count.should == 0
        expect(response).to redirect_to root_url
        flash[:alert].should =~ /You are not authorized/
      end
    end

    describe 'GET index' do
      before do
        oldest_time = '2014-01-13 10:15:00 -0600'
        middle_time = '2014-01-13 10:30:00 -0600'
        newest_time = '2014-01-13 10:45:00 -0600'

        @event = file.add_event(event_attrs.merge(date_time: oldest_time))
        @event2 = file.add_event(event_attrs.merge(date_time: newest_time))
        @event3 = file.add_event(event_attrs.merge(date_time: middle_time))
        file.save!

        @someone_elses_event = someone_elses_file.add_event(event_attrs)
        someone_elses_file.save!
      end

      describe 'events for an institution' do
        it 'shows the events for that institution, sorted by time' do
          get :index, identifier: file.institution.identifier
          assigns(:institution).should == file.institution
          assigns(:document_list).length.should == 3
          assigns(:document_list).map(&:id).should == [@event2.identifier.first, @event3.identifier.first, @event.identifier.first]
        end
      end

      describe 'events for an intellectual object' do
        it 'shows the events for that object, sorted by time' do
          get :index, intellectual_object_identifier: object
          expect(response).to be_success
          assigns(:intellectual_object).should == object
          assigns(:document_list).length.should == 3
          assigns(:document_list).map(&:id).should == [@event2.identifier.first, @event3.identifier.first, @event.identifier.first]
        end
      end

      describe 'events for a generic file' do
        it 'shows the events for that file, sorted by time' do
          get :index, generic_file_identifier: file
          expect(response).to be_success
          assigns(:generic_file).should == file
          assigns(:document_list).length.should == 3
          assigns(:document_list).map(&:id).should == [@event2.identifier.first, @event3.identifier.first, @event.identifier.first]
        end
      end

      describe "for an institution where you don't have permission" do
        it 'denies access' do
          get :index, identifier: someone_elses_file.institution.identifier
          expect(response).to redirect_to root_url
          flash[:alert].should =~ /You are not authorized/
        end
      end

      describe "for an intellectual object where you don't have permission" do
        it 'denies access' do
          get :index, intellectual_object_identifier: someone_elses_object
          expect(response).to redirect_to root_url
          flash[:alert].should =~ /You are not authorized/
        end
      end

      describe "for a generic file where you don't have permission" do
        it 'denies access' do
          get :index, generic_file_identifier: someone_elses_file
          expect(response).to redirect_to root_url
          flash[:alert].should =~ /You are not authorized/
        end
      end
    end
  end


  describe 'not signed in' do
    let(:file) { FactoryGirl.create(:generic_file) }

    describe 'POST create' do
      before do
        post :create, generic_file_identifier: file, event: event_attrs
      end

      it 'redirects to login' do
        expect(response).to redirect_to root_url + 'users/sign_in'
        expect(flash[:alert]).to eq 'You need to sign in or sign up before continuing.'
      end
    end

    describe 'GET index' do
      before do
        get :index, identifier: file.institution.identifier
      end

      it 'redirects to login' do
        expect(response).to redirect_to root_url + 'users/sign_in'
        expect(flash[:alert]).to eq 'You need to sign in or sign up before continuing.'
      end
    end
  end
end
