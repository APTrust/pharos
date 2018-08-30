require "spec_helper"

RSpec.describe NotificationMailer, type: :mailer do
  before :all do
    User.delete_all
    PremisEvent.delete_all
    Email.delete_all
    Institution.delete_all
  end

  after :all do
    User.delete_all
    PremisEvent.delete_all
    Email.delete_all
    Institution.delete_all
  end

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

  describe 'deletion_request of an intellectual object' do
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

  describe 'deletion_request of a generic file' do
    let(:institution) { FactoryBot.create(:member_institution) }
    let(:user) { FactoryBot.create(:user, :institutional_admin, institution: institution) }
    let(:object) { FactoryBot.create(:intellectual_object, institution: institution) }
    let(:file) { FactoryBot.create(:generic_file, intellectual_object: object) }
    let(:email_log) { FactoryBot.create(:deletion_request_email, generic_file_id: file.id) }
    let(:token) { FactoryBot.create(:confirmation_token, generic_file: file) }
    let(:mail) { described_class.deletion_request(file, user, email_log, token).deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eq("#{user.name} has requested deletion of #{file.uri}")
    end

    it 'renders the receiver email' do
      user.institutional_admin? #including this because if the user isn't used somehow for spec to realize it exists.
      expect(mail.to).to include(user.email)
    end

    it 'renders the sender email' do
      expect(mail.from).to eq(['info@aptrust.org'])
    end

    it 'assigns @object_url' do
      expect(mail.body.encoded).to include("http://localhost:3000/files/#{CGI.escape(file.identifier)}")
    end

    it 'assigns @confirmation_url' do
      expect(mail.body.encoded).to include("http://localhost:3000/files/confirm_delete/#{CGI.escape(file.identifier)}?confirmation_token=#{token.token}&requesting_user_id=#{user.id}")
    end

    it 'has an email log with proper associations' do
      expect(email_log.generic_file_id).to eq(file.id)
    end
  end

  describe 'deletion_confirmation of an intellectual object' do
    let(:institution) { FactoryBot.create(:member_institution) }
    let(:user) { FactoryBot.create(:user, :institutional_admin, institution: institution) }
    let(:object) { FactoryBot.create(:intellectual_object, institution: institution) }
    let(:email_log) { FactoryBot.create(:deletion_confirmation_email, intellectual_object_id: object.id) }
    let(:token) { FactoryBot.create(:confirmation_token, intellectual_object: object) }
    let(:mail) { described_class.deletion_confirmation(object, user.id, user.id, email_log).deliver_now }

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

  describe 'deletion_confirmation of a generic file' do
    let(:institution) { FactoryBot.create(:member_institution) }
    let(:user) { FactoryBot.create(:user, :institutional_admin, institution: institution) }
    let(:object) { FactoryBot.create(:intellectual_object, institution: institution) }
    let(:file) { FactoryBot.create(:generic_file, intellectual_object: object) }
    let(:email_log) { FactoryBot.create(:deletion_confirmation_email, generic_file_id: file.id) }
    let(:token) { FactoryBot.create(:confirmation_token, generic_file: file) }
    let(:mail) { described_class.deletion_confirmation(file, user.id, user.id, email_log).deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eq("#{file.uri} queued for deletion")
    end

    it 'renders the receiver email' do
      user.institutional_admin? #including this because if the user isn't used somehow for spec to realize it exists.
      expect(mail.to).to include(user.email)
    end

    it 'renders the sender email' do
      expect(mail.from).to eq(['info@aptrust.org'])
    end

    it 'assigns @object_url' do
      expect(mail.body.encoded).to include("http://localhost:3000/files/#{CGI.escape(file.identifier)}")
    end

    it 'has an email log with proper associations' do
      expect(email_log.generic_file_id).to eq(file.id)
    end
  end

  describe 'bulk_deletion_request' do
    let(:institution) { FactoryBot.create(:member_institution) }
    let(:apt) { FactoryBot.create(:aptrust) }
    let(:user) { FactoryBot.create(:user, :institutional_admin, institution: institution) }
    let(:admin_user) { FactoryBot.create(:user, :admin, institution: apt) }
    let(:object) { FactoryBot.create(:intellectual_object, institution: institution) }
    let(:file) { FactoryBot.create(:generic_file, institution: institution) }
    let(:email_log) { FactoryBot.create(:bulk_deletion_request_email, institution_id: institution.id) }
    let(:token) { FactoryBot.create(:confirmation_token, institution: institution) }
    let(:ident_list) { [object.identifier, file.identifier] }
    let(:mail) { described_class.bulk_deletion_inst_admin_approval(institution, ident_list, admin_user.id, email_log, token).deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eq("#{admin_user.name} has made a bulk deletion request on behalf of #{institution.name}.")
    end

    it 'renders the receiver email' do
      admin_user.admin? #including this because if the user isn't used somehow for spec to realize it exists.
      expect(mail.to).to include(admin_user.email)
    end

    it 'renders the sender email' do
      expect(mail.from).to eq(['info@aptrust.org'])
    end

    it 'assigns @confirmation_url' do
      expect(mail.body.encoded).to include("http://localhost:3000/#{CGI.escape(institution.identifier)}/bulk_delete?confirmation_token=#{token.token}&requesting_user_id=#{user.id}&identifiers=[#{CGI.escape(object.identifier)}, #{CGI.escape(file.identifier)}]")
    end

    it 'has an email log with proper associations' do
      expect(email_log.institution_id).to eq(institution.id)
    end
  end

  describe 'bulk_deletion_inst_confirmation' do
    let(:institution) { FactoryBot.create(:member_institution) }
    let(:apt) { FactoryBot.create(:aptrust) }
    let(:user) { FactoryBot.create(:user, :institutional_admin, institution: institution) }
    let(:admin_user) { FactoryBot.create(:user, :admin, institution: apt) }
    let(:object) { FactoryBot.create(:intellectual_object, institution: institution) }
    let(:file) { FactoryBot.create(:generic_file, institution: institution) }
    let(:email_log) { FactoryBot.create(:final_bulk_deletion_confirmation_email, institution_id: institution.id) }
    let(:token) { FactoryBot.create(:confirmation_token, institution: institution) }
    let(:mail) { described_class.bulk_deletion_apt_admin_approval(institution, [object.identifier, file.identifier], admin_user.id, user.id,  email_log, token).deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eq("#{user.name} and #{admin_user.name} have made a bulk deletion request on behalf of #{institution.name}.")
    end

    it 'renders the receiver email' do
      user.institutional_admin? #including this because if the user isn't used somehow for spec to realize it exists.
      expect(mail.to).to include(admin_user.email)
    end

    it 'renders the sender email' do
      expect(mail.from).to eq(['info@aptrust.org'])
    end

    it 'assigns @confirmation_url' do
      expect(mail.body.encoded).to include("http://localhost:3000/#{CGI.escape(institution.identifier)}/confirm_bulk_delete_institution?confirmation_token=#{token.token}&requesting_user_ids=[#{admin_user.id}, #{user.id}]&identifiers=[#{CGI.escape(object.identifier)}, #{CGI.escape(file.identifier)}]")
    end

    it 'has an email log with proper associations' do
      expect(email_log.institution_id).to eq(institution.id)
    end
  end

  describe 'bulk_deletion_final_confirmation' do
    let(:institution) { FactoryBot.create(:member_institution) }
    let(:apt) { FactoryBot.create(:aptrust) }
    let(:user) { FactoryBot.create(:user, :institutional_admin, institution: institution) }
    let(:admin_user) { FactoryBot.create(:user, :admin, institution: apt) }
    let(:other_admin) { FactoryBot.create(:user, :admin, institution: apt) }
    let(:object) { FactoryBot.create(:intellectual_object, institution: institution) }
    let(:file) { FactoryBot.create(:generic_file, institution: institution) }
    let(:email_log) { FactoryBot.create(:final_bulk_deletion_confirmation_email, institution_id: institution.id) }
    let(:token) { FactoryBot.create(:confirmation_token, institution: institution) }
    let(:mail) { described_class.bulk_deletion_queued(institution, [object.identifier, file.identifier], admin_user.id, user.id, other_admin.id, email_log).deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eq("A bulk deletion request has been successfully queued for #{institution.name}.")
    end

    it 'renders the receiver email' do
      other_admin.admin? #including this because if the user isn't used somehow for spec to realize it exists.
      expect(mail.to).to include(other_admin.email)
    end

    it 'renders the sender email' do
      expect(mail.from).to eq(['info@aptrust.org'])
    end

    it 'has an email log with proper associations' do
      expect(email_log.institution_id).to eq(institution.id)
    end
  end

  describe 'snapshot_notification' do
    let(:institution) { FactoryBot.create(:member_institution) }
    let(:object) { FactoryBot.create(:intellectual_object, institution: institution) }
    let(:file) { FactoryBot.create(:generic_file, intellectual_object: object) }
    let(:snap_hash) { {institution.name => file.size} }
    let(:mail) { described_class.snapshot_notification(snap_hash).deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eq('New Snapshots')
    end

    it 'renders the receiver email' do
      expect(mail.to).to include('team@aptrust.org')
      expect(mail.to).to include('chip.german@aptrust.org')
    end

    it 'renders the sender email' do
      expect(mail.from).to eq(['info@aptrust.org'])
    end

    it 'assigns @object_url' do
      expect(mail.body.encoded).to include('Here are the latest snapshot results broken down by institution.')
    end
  end
end
