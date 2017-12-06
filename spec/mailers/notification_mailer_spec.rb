require "spec_helper"

RSpec.describe NotificationMailer, type: :mailer do
  describe 'failed_fixity_notification' do
    let(:institution) { FactoryBot.create(:member_institution) }
    let(:user) { FactoryBot.create(:user, :institutional_admin, institution: institution) }
    let(:event) { FactoryBot.create(:premis_event_fixity_check_fail, institution: institution) }
    let(:email_log) { FactoryBot.create(:fixity_email) }
    let(:mail) { described_class.failed_fixity_notification(event, email_log).deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eq('Failed fixity check on one of your files')
    end

    it 'renders the receiver email' do
      user.institutional_admin? #including this because if the user isn't used somehow for spec to realize it exists.
      expect(mail.to).to include(user.email)
    end

    it 'renders the sender email' do
      expect(mail.from).to eq(['info@aptrust.org'])
    end

    it 'assigns @event_url' do
      expect(mail.body.encoded).to match("http://localhost:3000/events/#{event.id}")
    end
  end

  describe 'restoration_notification' do
    let(:institution) { FactoryBot.create(:member_institution) }
    let(:user) { FactoryBot.create(:user, :institutional_admin, institution: institution) }
    let(:item) { FactoryBot.create(:work_item, institution: institution,
                                    action: Pharos::Application::PHAROS_ACTIONS['restore'],
                                    status: Pharos::Application::PHAROS_STATUSES['success'],
                                    stage: Pharos::Application::PHAROS_STAGES['record']) }
    let(:email_log) { FactoryBot.create(:restoration_email) }
    let(:mail) { described_class.restoration_notification(item, email_log).deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eq('Restoration complete on one of your work items')
    end

    it 'renders the receiver email' do
      user.institutional_admin? #including this because if the user isn't used somehow for spec to realize it exists.
      expect(mail.to).to include(user.email)
    end

    it 'renders the sender email' do
      expect(mail.from).to eq(['info@aptrust.org'])
    end

    it 'assigns @item_url' do
      expect(mail.body.encoded).to match("http://localhost:3000/items/#{item.id}")
    end
  end

  describe 'multiple_failed_fixity_notification' do
    let(:institution) { FactoryBot.create(:member_institution) }
    let(:user) { FactoryBot.create(:user, :institutional_admin, institution: institution) }
    let(:event) { FactoryBot.create(:premis_event_fixity_check_fail, institution: institution) }
    let(:event_two) { FactoryBot.create(:premis_event_fixity_check_fail, institution: institution) }
    let(:events) { [event, event_two] }
    let(:email_log) { FactoryBot.create(:multiple_fixity_email, premis_events: [event, event_two]) }
    let(:mail) { described_class.multiple_failed_fixity_notification(events, email_log, institution).deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eq('Failed fixity check on one or more of your files')
    end

    it 'renders the receiver email' do
      user.institutional_admin? #including this because if the user isn't used somehow for spec to realize it exists.
      expect(mail.to).to include(user.email)
    end

    it 'renders the sender email' do
      expect(mail.from).to eq(['info@aptrust.org'])
    end

    it 'assigns @events_url' do
      expect(mail.body.encoded).to include("http://localhost:3000/events/#{institution.identifier}?event_type=Fixity+Check&outcome=Failure")
    end

    it 'has an email log with proper associations' do
      expect(email_log.premis_events.count).to eq(2)
    end
  end

  describe 'multiple_restoration_notification' do
    let(:institution) { FactoryBot.create(:member_institution) }
    let(:user) { FactoryBot.create(:user, :institutional_admin, institution: institution) }
    let(:item) { FactoryBot.create(:work_item, institution: institution,
                                    action: Pharos::Application::PHAROS_ACTIONS['restore'],
                                    status: Pharos::Application::PHAROS_STATUSES['success'],
                                    stage: Pharos::Application::PHAROS_STAGES['record']) }
    let(:item_two) { FactoryBot.create(:work_item, institution: institution,
                                    action: Pharos::Application::PHAROS_ACTIONS['restore'],
                                    status: Pharos::Application::PHAROS_STATUSES['success'],
                                    stage: Pharos::Application::PHAROS_STAGES['record']) }
    let(:items) { [item, item_two] }
    let(:email_log) { FactoryBot.create(:multiple_restoration_email, work_items: [item, item_two]) }
    let(:mail) { described_class.multiple_restoration_notification(items, email_log, institution).deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eq('Restoration notification on one or more of your bags')
    end

    it 'renders the receiver email' do
      user.institutional_admin? #including this because if the user isn't used somehow for spec to realize it exists.
      expect(mail.to).to include(user.email)
    end

    it 'renders the sender email' do
      expect(mail.from).to eq(['info@aptrust.org'])
    end

    it 'assigns @items_url' do
      expect(mail.body.encoded).to include("http://localhost:3000/items?institution=#{institution.id}&item_action=Restore&stage=Record&status=Success")
    end

    it 'has an email log with proper associations' do
      expect(email_log.work_items.count).to eq(2)
    end
  end

  describe 'deletion_request' do
    let(:institution) { FactoryBot.create(:member_institution) }
    let(:user) { FactoryBot.create(:user, :institutional_admin, institution: institution) }
    let(:object) { FactoryBot.create(:intellectual_object, institution: institution) }
    let(:email_log) { FactoryBot.create(:deletion_request_email, intellectual_object_id: object.id) }
    let(:token) { FactoryBot.create(:confirmation_token, intellectual_object: object) }
    let(:mail) { described_class.deletion_request(object, user, email_log, token).deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eq("#{user.name} has requested deletion of #{object.title}")
    end

    it 'renders the receiver email' do
      user.institutional_admin? #including this because if the user isn't used somehow for spec to realize it exists.
      expect(mail.to).to include(user.email)
    end

    it 'renders the sender email' do
      expect(mail.from).to eq(['info@aptrust.org'])
    end

    it 'assigns @object_url' do
      expect(mail.body.encoded).to include("http://localhost:3000/objects/#{CGI.escape(object.identifier)}")
    end

    it 'assigns @confirmation_url' do
      expect(mail.body.encoded).to include("http://localhost:3000/objects/#{CGI.escape(object.identifier)}/confirm_delete?confirmation_token=#{token.token}&requesting_user_id=#{user.id}")
    end

    it 'has an email log with proper associations' do
      expect(email_log.intellectual_object_id).to eq(object.id)
    end
  end

  describe 'deletion_confirmation' do
    let(:institution) { FactoryBot.create(:member_institution) }
    let(:user) { FactoryBot.create(:user, :institutional_admin, institution: institution) }
    let(:object) { FactoryBot.create(:intellectual_object, institution: institution) }
    let(:email_log) { FactoryBot.create(:deletion_confirmation_email, intellectual_object_id: object.id) }
    let(:token) { FactoryBot.create(:confirmation_token, intellectual_object: object) }
    let(:mail) { described_class.deletion_confirmation(object, user, email_log).deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eq("#{object.title} queued for deletion")
    end

    it 'renders the receiver email' do
      user.institutional_admin? #including this because if the user isn't used somehow for spec to realize it exists.
      expect(mail.to).to include(user.email)
    end

    it 'renders the sender email' do
      expect(mail.from).to eq(['info@aptrust.org'])
    end

    it 'assigns @object_url' do
      expect(mail.body.encoded).to include("http://localhost:3000/objects/#{CGI.escape(object.identifier)}")
    end

    it 'has an email log with proper associations' do
      expect(email_log.intellectual_object_id).to eq(object.id)
    end
  end
end
