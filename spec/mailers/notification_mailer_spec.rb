require "spec_helper"
require 'rubygems'
require 'zip'

RSpec.describe NotificationMailer, type: :mailer do
  before :all do
    User.delete_all
    PremisEvent.delete_all
    Email.delete_all
    Institution.delete_all
    BulkDeleteJob.delete_all
  end

  after :all do
    User.delete_all
    PremisEvent.delete_all
    Email.delete_all
    Institution.delete_all
    BulkDeleteJob.delete_all
  end

  describe 'failed_fixity_notification' do
    let(:institution) { FactoryBot.create(:member_institution) }
    let(:user) { FactoryBot.create(:user, :institutional_admin, institution: institution) }
    let(:event) { FactoryBot.create(:premis_event_fixity_check_fail, institution: institution) }
    let(:email_log) { FactoryBot.create(:fixity_email) }
    let(:mail) { described_class.failed_fixity_notification(event, email_log).deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eq('[APTrust Demo] - Failed fixity check on one of your files')
    end

    it 'renders the receiver email' do
      user.institutional_admin? #including this because if the user isn't used somehow for spec to realize it exists.
      expect(mail.to).to include(user.email)
    end

    it 'renders the sender email' do
      expect(mail.from).to eq(['help@aptrust.org'])
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
      expect(mail.subject).to eq('[APTrust Demo] - Restoration complete on one of your work items')
    end

    it 'renders the receiver email' do
      user.institutional_admin? #including this because if the user isn't used somehow for spec to realize it exists.
      expect(mail.to).to include(user.email)
    end

    it 'renders the sender email' do
      expect(mail.from).to eq(['help@aptrust.org'])
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
      expect(mail.subject).to eq('[APTrust Demo] - Failed fixity check on one or more of your files')
    end

    it 'renders the receiver email' do
      user.institutional_admin? #including this because if the user isn't used somehow for spec to realize it exists.
      expect(mail.to).to include(user.email)
    end

    it 'renders the sender email' do
      expect(mail.from).to eq(['help@aptrust.org'])
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
      expect(mail.subject).to eq('[APTrust Demo] - Restoration notification on one or more of your bags')
    end

    it 'renders the receiver email' do
      user.institutional_admin? #including this because if the user isn't used somehow for spec to realize it exists.
      expect(mail.to).to include(user.email)
    end

    it 'renders the sender email' do
      expect(mail.from).to eq(['help@aptrust.org'])
    end

    it 'assigns @items_url' do
      expect(mail.body.encoded).to include("http://localhost:3000/items?institution=#{institution.id}&item_action=Restore&stage=Record&status=Success")
    end

    it 'has an email log with proper associations' do
      expect(email_log.work_items.count).to eq(2)
    end
  end

  describe 'spot_test_restoration_notification' do
    let(:institution) { FactoryBot.create(:member_institution) }
    let(:user) { FactoryBot.create(:user, :institutional_admin, institution: institution) }
    let(:item) { FactoryBot.create(:work_item, institution: institution,
                                   action: Pharos::Application::PHAROS_ACTIONS['restore'],
                                   status: Pharos::Application::PHAROS_STATUSES['success'],
                                   stage: Pharos::Application::PHAROS_STAGES['record'],
                                   object_identifier: 'test.edu/bag_name',
                                   note: 'Bag test.edu/bag_name restored to https://s3.amazonaws.com/aptrust.restore.test.edu/bag_name.tar') }
    let(:email_log) { FactoryBot.create(:restoration_email) }
    let(:mail) { described_class.spot_test_restoration_notification(item, email_log).deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eq('[APTrust Demo] - Restoration System Spot Test')
    end

    it 'renders the receiver email' do
      user.institutional_admin? #including this because if the user isn't used somehow for spec to realize it exists.
      expect(mail.to).to include(user.email)
    end

    it 'renders the sender email' do
      expect(mail.from).to eq(['help@aptrust.org'])
    end

    it 'assigns @item_url' do
      expect(mail.body.encoded).to match("http://localhost:3000/items/#{item.id}")
    end

    it 'assigns @download_url' do
      expect(mail.body.encoded).to match('https://s3.amazonaws.com/aptrust.restore.test.edu/bag_name.tar')
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
      expect(mail.subject).to eq("[APTrust Demo] - #{user.name} has requested deletion of #{object.identifier}")
    end

    it 'renders the receiver email' do
      user.institutional_admin? #including this because if the user isn't used somehow for spec to realize it exists.
      expect(mail.to).to include(user.email)
    end

    it 'renders the sender email' do
      expect(mail.from).to eq(['help@aptrust.org'])
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
      expect(mail.subject).to eq("[APTrust Demo] - #{user.name} has requested deletion of #{file.identifier}")
    end

    it 'renders the receiver email' do
      user.institutional_admin? #including this because if the user isn't used somehow for spec to realize it exists.
      expect(mail.to).to include(user.email)
    end

    it 'renders the sender email' do
      expect(mail.from).to eq(['help@aptrust.org'])
    end

    it 'assigns @object_url' do
      expect(mail.body.encoded).to include("http://localhost:3000/files/#{CGI.escape(file.identifier)}")
    end

    it 'assigns @confirmation_url' do
      expect(mail.body.encoded).to include("http://localhost:3000/files/confirm_delete/#{CGI.escape(file.identifier)}?confirmation_token=#{token.token}&format=html&requesting_user_id=#{user.id}")
    end

    it 'has an email log with proper associations' do
      expect(email_log.generic_file_id).to eq(file.id)
    end
  end

  describe 'deletion_confirmation of an intellectual object' do
    let(:institution) { FactoryBot.create(:member_institution) }
    let(:user) { FactoryBot.create(:user, :institutional_admin, institution: institution) }
    let(:user_two) { FactoryBot.create(:user, :institutional_admin, institution: institution) }
    let(:user_three) { FactoryBot.create(:user, :institutional_admin, institution: institution) }
    let(:object) { FactoryBot.create(:intellectual_object, institution: institution) }
    let(:email_log) { FactoryBot.create(:deletion_confirmation_email, intellectual_object_id: object.id) }
    let(:token) { FactoryBot.create(:confirmation_token, intellectual_object: object) }
    let(:mail) { described_class.deletion_confirmation(object, user.id, user.id, email_log).deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eq("[APTrust Demo] - #{object.identifier} queued for deletion")
    end

    it 'renders the receiver email' do
      user.admin?
      user_two.admin?
      user_three.admin? #including this because the user needs to be used somehow for spec to realize it exists.
      expect(mail.to).to include(user.email)
      expect(mail.to).to include(user_two.email)
      expect(mail.to).to include(user_three.email)
      expect(email_log.user_list).to include(user.email)
      expect(email_log.user_list).to include(user_two.email)
      expect(email_log.user_list).to include(user_three.email)
    end

    it 'renders the sender email' do
      expect(mail.from).to eq(['help@aptrust.org'])
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
      expect(mail.subject).to eq("[APTrust Demo] - #{file.identifier} queued for deletion")
    end

    it 'renders the receiver email' do
      user.institutional_admin? #including this because if the user isn't used somehow for spec to realize it exists.
      expect(mail.to).to include(user.email)
    end

    it 'renders the sender email' do
      expect(mail.from).to eq(['help@aptrust.org'])
    end

    it 'assigns @object_url' do
      expect(mail.body.encoded).to include("http://localhost:3000/files/#{CGI.escape(file.identifier)}")
    end

    it 'has an email log with proper associations' do
      expect(email_log.generic_file_id).to eq(file.id)
    end
  end

  describe 'deletion_finished of an intellectual object' do
    let(:institution) { FactoryBot.create(:member_institution) }
    let(:user) { FactoryBot.create(:user, :institutional_admin, institution: institution) }
    let(:object) { FactoryBot.create(:intellectual_object, institution: institution) }
    let(:email_log) { FactoryBot.create(:deletion_finished_email, intellectual_object_id: object.id) }
    let(:token) { FactoryBot.create(:confirmation_token, intellectual_object: object) }
    let(:mail) { described_class.deletion_finished(object, user.id, user.id, email_log).deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eq("[APTrust Demo] - #{object.identifier} deleted.")
    end

    it 'renders the receiver email' do
      user.institutional_admin? #including this because if the user isn't used somehow for spec to realize it exists.
      expect(mail.to).to include(user.email)
    end

    it 'renders the sender email' do
      expect(mail.from).to eq(['help@aptrust.org'])
    end

    it 'assigns @object_url' do
      expect(mail.body.encoded).to include("http://localhost:3000/objects/#{CGI.escape(object.identifier)}")
    end

    it 'has an email log with proper associations' do
      expect(email_log.intellectual_object_id).to eq(object.id)
    end
  end

  describe 'deletion_finished of a generic file' do
    let(:institution) { FactoryBot.create(:member_institution) }
    let(:user) { FactoryBot.create(:user, :institutional_admin, institution: institution) }
    let(:object) { FactoryBot.create(:intellectual_object, institution: institution) }
    let(:file) { FactoryBot.create(:generic_file, intellectual_object: object) }
    let(:email_log) { FactoryBot.create(:deletion_finished_email, generic_file_id: file.id) }
    let(:token) { FactoryBot.create(:confirmation_token, generic_file: file) }
    let(:mail) { described_class.deletion_finished(file, user.id, user.id, email_log).deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eq("[APTrust Demo] - #{file.identifier} deleted.")
    end

    it 'renders the receiver email' do
      user.institutional_admin? #including this because if the user isn't used somehow for spec to realize it exists.
      expect(mail.to).to include(user.email)
    end

    it 'renders the sender email' do
      expect(mail.from).to eq(['help@aptrust.org'])
    end

    it 'assigns @object_url' do
      expect(mail.body.encoded).to include("http://localhost:3000/files/#{CGI.escape(file.identifier)}")
    end

    it 'has an email log with proper associations' do
      expect(email_log.generic_file_id).to eq(file.id)
    end
  end

  describe 'bulk_deletion_inst_admin_approval' do
    let(:institution) { FactoryBot.create(:member_institution) }
    let(:apt) { FactoryBot.create(:aptrust) }
    let(:user) { FactoryBot.create(:user, :institutional_admin, institution: institution) }
    let(:admin_user) { FactoryBot.create(:user, :admin, institution: apt) }
    let(:object) { FactoryBot.create(:intellectual_object, institution: institution) }
    let(:file) { FactoryBot.create(:generic_file, institution: institution) }
    let(:email_log) { FactoryBot.create(:bulk_deletion_request_email, institution_id: institution.id) }
    let(:job) { BulkDeleteJob.create_job(institution, admin_user, [object], [file]) }
    let(:token) { FactoryBot.create(:confirmation_token, institution: institution) }
    let(:ident_list) { [object.identifier, file.identifier] }
    let(:csv) { institution.generate_confirmation_csv(job) }
    let(:mail) { described_class.bulk_deletion_inst_admin_approval(institution, job, {}, email_log, token, csv).deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eq("[APTrust Demo] - #{admin_user.name} has made a bulk deletion request on behalf of #{institution.name}.")
    end

    it 'renders the receiver email' do
      user.admin? #including this because if the user isn't used somehow for spec to realize it exists.
      expect(mail.to).to include(user.email)
    end

    it 'renders the sender email' do
      expect(mail.from).to eq(['help@aptrust.org'])
    end

    it 'assigns @confirmation_url' do
      expect(mail.body.encoded).to include("http://localhost:3000/#{CGI.escape(institution.identifier)}/confirm_bulk_delete_institution?bulk_delete_job_id=#{job.id}&confirmation_token=#{token.token}")
    end

    it 'has an email log with proper associations' do
      expect(email_log.institution_id).to eq(institution.id)
    end

    it 'has a csv attachment' do
      expect(mail.attachments.count).to eq(1)
      attachment = mail.attachments[0]
      attachment.should be_a_kind_of(Mail::Part)
      attachment.content_type.should include('text/csv')
      attachment.filename.should == 'requested_deletions.csv'
    end
  end

  describe 'bulk_deletion_apt_admin_approval' do
    let(:institution) { FactoryBot.create(:member_institution) }
    let(:apt) { FactoryBot.create(:aptrust) }
    let(:user) { FactoryBot.create(:user, :institutional_admin, institution: institution) }
    let(:admin_user) { FactoryBot.create(:user, :admin, institution: apt) }
    let(:object) { FactoryBot.create(:intellectual_object, institution: institution) }
    let(:file) { FactoryBot.create(:generic_file, institution: institution) }
    let(:email_log) { FactoryBot.create(:final_bulk_deletion_confirmation_email, institution_id: institution.id) }
    let(:job) { BulkDeleteJob.create_job(institution, admin_user, [object], [file]) }
    let(:token) { FactoryBot.create(:confirmation_token, institution: institution) }
    let(:csv) { institution.generate_confirmation_csv(job) }
    let(:mail) { described_class.bulk_deletion_apt_admin_approval(institution, job, email_log, token, csv).deliver_now }

    before do
      job.institutional_approver = user.email
      job.save!
    end

    it 'renders the subject' do
      expect(mail.subject).to eq("[APTrust Demo] - #{admin_user.name} and #{user.name} have made a bulk deletion request on behalf of #{institution.name}.")
    end

    it 'renders the receiver email' do
      expect(mail.to).to include(admin_user.email)
    end

    it 'renders the sender email' do
      expect(mail.from).to eq(['help@aptrust.org'])
    end

    it 'assigns @confirmation_url' do
      expect(mail.body.encoded).to include("http://localhost:3000/#{CGI.escape(institution.identifier)}/confirm_bulk_delete_admin?bulk_delete_job_id=#{job.id}&confirmation_token=#{token.token}")
    end

    it 'has an email log with proper associations' do
      expect(email_log.institution_id).to eq(institution.id)
    end

    it 'has a csv attachment' do
      expect(mail.attachments.count).to eq(1)
      attachment = mail.attachments[0]
      attachment.should be_a_kind_of(Mail::Part)
      attachment.content_type.should include('text/csv')
      attachment.filename.should == 'requested_deletions.csv'
    end
  end

  describe 'bulk_deletion_queued' do
    let(:institution) { FactoryBot.create(:member_institution) }
    let(:apt) { FactoryBot.create(:aptrust) }
    let(:user) { FactoryBot.create(:user, :institutional_admin, institution: institution) }
    let(:admin_user) { FactoryBot.create(:user, :admin, institution: apt) }
    let(:other_admin) { FactoryBot.create(:user, :admin, institution: apt) }
    let(:object) { FactoryBot.create(:intellectual_object, institution: institution) }
    let(:file) { FactoryBot.create(:generic_file, institution: institution) }
    let(:email_log) { FactoryBot.create(:final_bulk_deletion_confirmation_email, institution_id: institution.id) }
    let(:job) { BulkDeleteJob.create_job(institution, admin_user, [object], [file]) }
    let(:token) { FactoryBot.create(:confirmation_token, institution: institution) }
    let(:csv) { institution.generate_confirmation_csv(job) }
    let(:mail) { described_class.bulk_deletion_queued(institution, job, email_log, csv).deliver_now }

    before do
      job.institutional_approver = user.email
      job.aptrust_approver = other_admin.email
      job.save!
    end

    it 'renders the subject' do
      expect(mail.subject).to eq("[APTrust Demo] - A bulk deletion request has been successfully queued for #{institution.name}.")
    end

    it 'renders the receiver email' do
      other_admin.admin? #including this because if the user isn't used somehow for spec to realize it exists.
      user.institutional_admin? #including this because if the user isn't used somehow for spec to realize it exists.
      admin_user.institutional_admin? #including this because if the user isn't used somehow for spec to realize it exists.
      expect(mail.to).to include(other_admin.email)
      expect(mail.to).to include(user.email)
      expect(mail.to).to include(admin_user.email)
    end

    it 'renders the sender email' do
      expect(mail.from).to eq(['help@aptrust.org'])
    end

    it 'has an email log with proper associations' do
      expect(email_log.institution_id).to eq(institution.id)
    end

    it 'has a csv attachment' do
      expect(mail.attachments.count).to eq(1)
      attachment = mail.attachments[0]
      attachment.should be_a_kind_of(Mail::Part)
      attachment.content_type.should include('text/csv')
      attachment.filename.should == 'queued_deletions.csv'
    end
  end

  describe 'bulk_deletion_finished' do
    let(:institution) { FactoryBot.create(:member_institution) }
    let(:apt) { FactoryBot.create(:aptrust) }
    let(:user) { FactoryBot.create(:user, :institutional_admin, institution: institution) }
    let(:admin_user) { FactoryBot.create(:user, :admin, institution: apt) }
    let(:other_admin) { FactoryBot.create(:user, :admin, institution: apt) }
    let(:object) { FactoryBot.create(:intellectual_object, institution: institution) }
    let(:file) { FactoryBot.create(:generic_file, institution: institution) }
    let(:email_log) { FactoryBot.create(:bulk_deletion_finished_email, institution_id: institution.id) }
    let(:job) { BulkDeleteJob.create_job(institution, admin_user, [object], [file]) }
    let(:token) { FactoryBot.create(:confirmation_token, institution: institution) }
    let(:csv) { institution.generate_confirmation_csv(job) }
    let(:mail) { described_class.bulk_deletion_finished(institution, job, email_log, csv).deliver_now }

    before do
      job.institutional_approver = user.email
      job.aptrust_approver = other_admin.email
      job.save!
    end

    it 'renders the subject' do
      expect(mail.subject).to eq("[APTrust Demo] - A bulk deletion request has been successfully completed for #{institution.name}.")
    end

    it 'renders the receiver email' do
      other_admin.admin? #including this because if the user isn't used somehow for spec to realize it exists.
      user.institutional_admin? #including this because if the user isn't used somehow for spec to realize it exists.
      admin_user.institutional_admin? #including this because if the user isn't used somehow for spec to realize it exists.
      expect(mail.to).to include(other_admin.email)
      expect(mail.to).to include(user.email)
      expect(mail.to).to include(admin_user.email)
    end

    it 'renders the sender email' do
      expect(mail.from).to eq(['help@aptrust.org'])
    end

    it 'has an email log with proper associations' do
      expect(email_log.institution_id).to eq(institution.id)
    end

    it 'has a csv attachment' do
      expect(mail.attachments.count).to eq(1)
      attachment = mail.attachments[0]
      attachment.should be_a_kind_of(Mail::Part)
      attachment.content_type.should include('text/csv')
      attachment.filename.should == 'finished_deletions.csv'
    end
  end

  describe 'deletion_notification' do
    let(:institution) { FactoryBot.create(:member_institution) }
    let(:apt) { FactoryBot.create(:aptrust) }
    let(:user) { FactoryBot.create(:user, :institutional_admin, institution: institution) }
    let(:admin_user) { FactoryBot.create(:user, :admin, institution: apt) }
    let(:object_one) { FactoryBot.create(:intellectual_object, institution: institution) }
    let(:object_two) { FactoryBot.create(:intellectual_object, institution: institution) }
    let(:file_one) { FactoryBot.create(:generic_file, intellectual_object: object_one) }
    let(:file_two) { FactoryBot.create(:generic_file, intellectual_object: object_two) }
    let(:latest_email) { FactoryBot.create(:deletion_notification_email) }
    let(:item_one) { FactoryBot.create(:work_item, action: 'Delete', status: 'Success', stage: 'Resolve', generic_file: file_one, institution: institution) }
    let(:item_two) { FactoryBot.create(:work_item, action: 'Delete', status: 'Success', stage: 'Resolve', generic_file: file_two, institution: institution) }
    let(:zip) { institution.generate_deletion_zipped_csv([item_one, item_two]) }
    let(:mail) { described_class.deletion_notification(institution) }

    after do
      Institution.remove_directory('test')
    end

    it 'renders the subject' do
      zip.nil? #evaluate zip to force it to get made
      expect(mail.subject).to eq('[APTrust Demo] - New Completed Deletions')
    end

    it 'renders the receiver email' do
      zip.nil? #evaluate zip to force it to get made
      user.institutional_admin? #including this because if the user isn't used somehow for spec to realize it exists.
      expect(mail.to).to include(user.email)
    end

    it 'renders the sender email' do
      zip.nil? #evaluate zip to force it to get made
      expect(mail.from).to eq(['help@aptrust.org'])
    end

    it 'has a zip attachment' do
      zip.nil? #evaluate zip to force it to get made
      expect(mail.attachments.count).to eq(1)
      attachment = mail.attachments[0]
      attachment.should be_a_kind_of(Mail::Part)
      attachment.content_type.should eq('application/zip')
      attachment.filename.should == 'deletions.zip'
    end
  end

  describe 'snapshot_notification' do
    let(:institution) { FactoryBot.create(:member_institution) }
    let(:object) { FactoryBot.create(:intellectual_object, institution: institution) }
    let(:file) { FactoryBot.create(:generic_file, intellectual_object: object) }
    let(:snap_hash) { {institution.name => file.size} }
    let(:mail) { described_class.snapshot_notification(snap_hash).deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eq('[APTrust Demo] - New Snapshots')
    end

    it 'renders the receiver email' do
      expect(mail.to).to include('team@aptrust.org')
    end

    it 'renders the sender email' do
      expect(mail.from).to eq(['help@aptrust.org'])
    end

    it 'includes specific snapshot text' do
      expect(mail.body.encoded).to include('Here are the latest snapshot results broken down by institution.')
    end
  end

  describe 'welcome_email' do
    let(:user) { FactoryBot.create(:user) }
    let(:password) { 'temppassword' }
    let(:mail) { described_class.welcome_email(user, password).deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eq('[APTrust Demo] - Welcome to APTrust!')
    end

    it 'renders the receiver email' do
      expect(mail.to).to include(user.email)
    end

    it 'renders the sender email' do
      expect(mail.from).to eq(['help@aptrust.org'])
    end

    it 'includes specific password text' do
      expect(mail.body.encoded).to include('Temporary password: temppassword')
    end
  end

  describe 'email_verification' do
    let(:user) { FactoryBot.create(:user) }
    let(:token) { FactoryBot.create(:confirmation_token, user: user) }
    let(:mail) { described_class.email_verification(user, token).deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eq('[APTrust Demo] - Verify Your Email')
    end

    it 'renders the receiver email' do
      expect(mail.to).to include(user.email)
    end

    it 'renders the sender email' do
      expect(mail.from).to eq(['help@aptrust.org'])
    end

    it 'assigns @confirmation_url' do
      expect(mail.body.encoded).to include("http://localhost:3000/users/#{user.id}/email_confirmation?confirmation_token=#{token.token}")
    end
  end

  describe 'admin_password_reset' do
    let(:user) { FactoryBot.create(:user) }
    let(:password) { 'newpassword' }
    let(:mail) { described_class.admin_password_reset(user, password).deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eq('[APTrust Demo] - An Admin Has Reset Your Password')
    end

    it 'renders the receiver email' do
      expect(mail.to).to include(user.email)
    end

    it 'renders the sender email' do
      expect(mail.from).to eq(['help@aptrust.org'])
    end

    it 'includes specific password text' do
      expect(mail.body.encoded).to include('Your new password is newpassword')
    end
  end

  describe 'email_verification' do
    let(:user) { FactoryBot.create(:user) }
    let(:token) { FactoryBot.create(:confirmation_token, user: user) }
    let(:mail) { described_class.account_confirmation(user, token).deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eq('[APTrust Demo] - Confirm Your Account')
    end

    it 'renders the receiver email' do
      expect(mail.to).to include(user.email)
    end

    it 'renders the sender email' do
      expect(mail.from).to eq(['help@aptrust.org'])
    end

    it 'assigns @confirmation_url' do
      expect(mail.body.encoded).to include("http://localhost:3000/users/#{user.id}/confirm_account?confirmation_token=#{token.token}")
    end
  end

  describe 'stale_user_notification' do
    let(:user) { FactoryBot.create(:user) }
    let(:mail) { described_class.stale_user_notification([user]).deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eq('[APTrust Demo] - Stale Users')
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq ['team@aptrust.org']
    end

    it 'renders the sender email' do
      expect(mail.from).to eq(['help@aptrust.org'])
    end

    it 'includes specific text about stale users' do
      expect(mail.body.encoded).to include(user.name)
      expect(mail.body.encoded).to include(user.email)
    end
  end
end
