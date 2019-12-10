require 'spec_helper'

RSpec.describe PremisEventsController, type: :controller do
  after do
    PremisEvent.delete_all
    IntellectualObject.delete_all
    GenericFile.delete_all
    User.delete_all
    Institution.delete_all
  end

  let(:object) { FactoryBot.create(:intellectual_object, institution: user.institution, access: 'institution') }
  let(:file) { FactoryBot.create(:generic_file, intellectual_object: object) }
  let(:event_attrs) { FactoryBot.attributes_for(:premis_event_fixity_generation,
                                                 intellectual_object_id: object.id,
                                                 intellectual_object_identifier: object.identifier,
                                                 generic_file_id: file.id,
                                                 generic_file_identifier: file.identifier) }
  # An object and a file from a different institution:
  let(:someone_elses_object) { FactoryBot.create(:intellectual_object, access: 'institution',
                                                 identifier: 'miami.edu/miami.archiveit5161_us_cuba_policy_masters_archiveit_5161_us_cuba_policy_md5sums_txt?c=5161') }
  let(:someone_elses_file) { FactoryBot.create(:generic_file, intellectual_object: someone_elses_object,
                                                 identifier: 'miami.edu/miami.archiveit5161_us_cuba_policy_masters_archiveit_5161_us_cuba_policy_md5sums_txt?c=5161/data/md5sums.txt?c=5161') }
  let(:other_event_attrs) { FactoryBot.attributes_for(:premis_event_fixity_generation,
                                                 intellectual_object_id: someone_elses_object.id,
                                                 intellectual_object_identifier: someone_elses_object.identifier,
                                                 generic_file_id: someone_elses_file.id,
                                                 generic_file_identifier: someone_elses_file.identifier) }


  describe 'signed in as admin user' do
    let(:user) { FactoryBot.create(:user, :admin) }
    before do
      sign_in user
      session[:verified] = true
    end

    describe 'GET index' do
      before do
        @someone_elses_event = someone_elses_file.add_event(other_event_attrs)
      end

      it "can view events, even if it's not my institution" do
        get :index, params: { institution_identifier: someone_elses_file.institution.identifier }
        expect(response).to be_successful
        assigns(:parent).should == someone_elses_file.institution
        assigns(:premis_events).length.should == 1
        assigns(:premis_events).map(&:identifier).should == [@someone_elses_event.identifier]
      end

      it "can view events, even if it's not my intellectual object" do
        get :index, params: { object_identifier: someone_elses_object.identifier }
        expect(response).to be_successful
        assigns(:parent).should == someone_elses_object
        assigns(:premis_events).length.should == 1
        assigns(:premis_events).map(&:identifier).should == [@someone_elses_event.identifier]
      end

      it 'can view objects events by object identifier (API)' do
        get :index, params: { object_identifier: someone_elses_object.identifier }
        expect(response).to be_successful
        assigns(:parent).should == someone_elses_object
        assigns(:premis_events).length.should == 1
        assigns(:premis_events).map(&:identifier).should == [@someone_elses_event.identifier]
      end

    end

    describe 'POST create' do

      it 'creates an event for the generic file using generic file identifier (API)' do
        file.premis_events.count.should == 0
        post :create, body: event_attrs.to_json, format: :json
        file.reload
        file.premis_events.count.should == 1
        assigns(:parent).should == file
        expect(response.status).to eq(201)
      end

      it 'creates an event for an intellectual object by object identifier' do
        event_attrs[:generic_file_identifier] = ''
        event_attrs[:generic_file_id] = ''
        object.premis_events.count.should == 0
        post :create, body: event_attrs.to_json, format: :json
        expect(response.status).to eq(201)
        object.reload
        object.premis_events.count.should == 1
        assigns(:parent).should == object
        assigns(:event).should_not be_nil
      end

      # it 'creates an email log if the event created is a failed fixity check' do
      #   expect { post :create, body: fixity_fail.to_json, format: :json }.to change(Email, :count).by(1)
      #   expect(response.status).to eq(201)
      #   email_log = Email.where(event_identifier: '1234-5678-9012-3456')
      #   expect(email_log.count).to eq(1)
      #   expect(email_log[0].email_type).to eq('fixity')
      #   email = ActionMailer::Base.deliveries.last
      #   expect(email.body.encoded).to eq("Admin Users at #{assigns(:event).institution.name},\r\n\r\nThis email notification is to inform you that one of your files failed a fixity check.\r\nThe failed fixity check can be found at the following link:\r\n\r\n<a href=\"http://localhost:3000/events/#{assigns(:event).id}\" >#{assigns(:event).identifier}</a>\r\n\r\nPlease contact the APTrust team by replying to this email if you have any questions.\r\n")
      # end
    end

    describe 'GET notify_of_failed_fixity' do
      it 'creates an email log of the notification email containing the failed fixity checks' do
        fixity_fail = FactoryBot.create(:premis_event_fixity_check_fail,
                                         intellectual_object_id: object.id,
                                         intellectual_object_identifier: object.identifier,
                                         generic_file_id: file.id,
                                         generic_file_identifier: file.identifier,
                                         identifier: '1234-5678-9012-3456')
        expect { get :notify_of_failed_fixity, format: :json }.to change(Email, :count).by(1)
        expect(response.status).to eq(200)
        email = ActionMailer::Base.deliveries.last
        expect(email.body.encoded).to include("http://localhost:3000/events/#{fixity_fail.institution.identifier}?event_type=Fixity+Check&outcome=Failure")
      end
    end
  end

  describe 'signed in as institutional admin' do
    let(:user) { FactoryBot.create(:user, :institutional_admin) }
    before do
      sign_in user
      session[:verified] = true
    end

    describe 'POST create' do
      it 'is forbidden' do
        post :create, body: event_attrs.to_json, format: :json
        expect(response.status).to eq(403)
      end
    end

    describe "POST create a file where you don't have permission" do
      it 'denies access' do
        someone_elses_file.premis_events.count.should == 0
        post :create, body: event_attrs.to_json, format: :json
        someone_elses_file.reload

        someone_elses_file.premis_events.count.should == 0
        expect(response.status).to eq(403)
      end
    end

  end

  describe 'signed in as institutional user' do
    let(:user) { FactoryBot.create(:user, :institutional_user) }
    before do
      sign_in user
      session[:verified] = true
    end

    describe 'POST create' do
      it 'denies access' do
        file.premis_events.count.should == 0
        post :create, body: event_attrs.to_json, format: :json
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
          get :index, params: { institution_identifier: file.institution.identifier }
          assigns(:parent).should == file.institution
          assigns(:premis_events).length.should == 3
          assigns(:premis_events).map(&:identifier).include?(@event.identifier).should be true
          assigns(:premis_events).map(&:identifier).include?(@event2.identifier).should be true
          assigns(:premis_events).map(&:identifier).include?(@event3.identifier).should be true
        end
      end

      describe 'events for an intellectual object' do
        it 'shows the events for that object, sorted by time' do
          get :index, params: { object_identifier: object }
          expect(response).to be_successful
          assigns(:parent).should == object
          assigns(:premis_events).length.should == 3
          assigns(:premis_events).map(&:identifier).include?(@event.identifier).should be true
          assigns(:premis_events).map(&:identifier).include?(@event2.identifier).should be true
          assigns(:premis_events).map(&:identifier).include?(@event3.identifier).should be true
        end
      end

      describe 'events for a generic file' do
        it 'shows the events for that file, sorted by time' do
          get :index, params: { file_identifier: file }, format: :html
          expect(response).to be_successful
          assigns(:parent).should == file
          assigns(:premis_events).length.should == 3
          assigns(:premis_events).map(&:identifier).include?(@event.identifier).should be true
          assigns(:premis_events).map(&:identifier).include?(@event2.identifier).should be true
          assigns(:premis_events).map(&:identifier).include?(@event3.identifier).should be true
        end
      end

      describe "for an institution where you don't have permission" do
        it 'denies access' do
          get :index, params: { institution_identifier: someone_elses_file.institution.identifier }
          expect(response).to redirect_to root_url
          flash[:alert].should =~ /You are not authorized/
        end
      end

      describe "for an intellectual object where you don't have permission" do
        it 'denies access' do
          get :index, params: { object_identifier: someone_elses_object }
          expect(response).to redirect_to root_url
          flash[:alert].should =~ /You are not authorized/
        end
      end

      describe "for a generic file where you don't have permission" do
        it 'denies access' do
          get :index, params: { file_identifier: someone_elses_file }, format: :html
          expect(response).to redirect_to root_url
          flash[:alert].should =~ /You are not authorized/
        end
      end
    end
  end

  describe 'not signed in' do
    let(:user) { FactoryBot.create(:user, :institutional_user) }
    let(:file) { FactoryBot.create(:generic_file) }

    describe 'POST create' do
      before do
        post :create, params: event_attrs, format: :json
      end

      it 'says you are unauthorized' do
        # This is a JSON call, so you get a 401, not a redirect
        expect(response.status).to eq(401)
      end
    end

    describe 'GET index' do
      before do
        get :index, params: { institution_identifier: file.institution.identifier }
      end

      it 'redirects to login' do
        expect(response).to redirect_to root_url + 'users/sign_in'
        expect(flash[:alert]).to eq 'You need to sign in or sign up before continuing.'
      end
    end
  end
end
