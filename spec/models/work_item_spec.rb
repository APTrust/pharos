require 'spec_helper'

ingest = Pharos::Application::PHAROS_ACTIONS['ingest']
delete = Pharos::Application::PHAROS_ACTIONS['delete']
restore = Pharos::Application::PHAROS_ACTIONS['restore']
dpn = Pharos::Application::PHAROS_ACTIONS['dpn']
requested = Pharos::Application::PHAROS_STAGES['requested']
receive = Pharos::Application::PHAROS_STAGES['receive']
record = Pharos::Application::PHAROS_STAGES['record']
clean = Pharos::Application::PHAROS_STAGES['clean']
success = Pharos::Application::PHAROS_STATUSES['success']
failed = Pharos::Application::PHAROS_STATUSES['fail']
pending = Pharos::Application::PHAROS_STATUSES['pend']
started = Pharos::Application::PHAROS_STATUSES['start']

# Creates an item we can save. We'll set action, stage and status
# for various tests below
def setup_item(subject)
  subject.name = 'sample_bag.tar'
  subject.etag = '12345'
  subject.institution = FactoryBot.build(:member_institution, identifier: 'hardknocks.edu')
  subject.bag_date = Time.now()
  subject.bucket = 'aptrust.receiving.hardknocks.edu'
  subject.date = Time.now()
  subject.note = 'Note'
  subject.outcome = 'Outcome'
  subject.user = 'user'
end

RSpec.describe WorkItem, :type => :model do
  before(:all) do
    WorkItem.delete_all
    IntellectualObject.delete_all
    GenericFile.delete_all
  end

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:etag) }
  it { should validate_presence_of(:bag_date) }
  it { should validate_presence_of(:bucket)}
  it { should validate_presence_of(:user) }
  it { should validate_presence_of(:institution) }
  it { should validate_presence_of(:date) }
  it { should validate_presence_of(:note)}
  it { should validate_presence_of(:action) }
  it { should validate_presence_of(:stage) }
  it { should validate_presence_of(:status) }
  it { should validate_presence_of(:outcome) }

  it 'should say when it is not ingested' do
    subject.action = ''
    subject.ingested?.should == false

    subject.action = ingest
    subject.stage = receive
    subject.status = success
    subject.ingested?.should == false

    subject.action = ingest
    subject.stage = record
    subject.status = failed
    subject.ingested?.should == false
  end

  it 'should say when it is ingested' do
    subject.action = ingest
    subject.stage = record
    subject.status = success
    subject.ingested?.should == true

    subject.stage = clean
    subject.ingested?.should == true

    subject.action = restore
    subject.stage = requested
    subject.status = pending
    subject.ingested?.should == true
  end

  it 'should NOT set object identifier in before_save if not ingested' do
    setup_item(subject)
    subject.action = ingest
    subject.stage = receive
    subject.status = success
    subject.save!
    subject.object_identifier.should == nil
  end

  it 'should set object identifier in before_save if not ingested (single part bag)' do
    FactoryBot.create(:intellectual_object, identifier: 'hardknocks.edu/sample_bag')
    setup_item(subject)
    subject.action = ingest
    subject.stage = record
    subject.status = success
    subject.save!
    subject.object_identifier.should == 'hardknocks.edu/sample_bag'
  end

  it 'should set object identifier in before_save if not ingested (multi part bag)' do
    FactoryBot.create(:intellectual_object, identifier: 'hardknocks.edu/sesame.street')
    setup_item(subject)
    subject.name = 'sesame.street.b046.of249.tar'
    subject.action = ingest
    subject.stage = record
    subject.status = success
    subject.save!
    subject.object_identifier.should == 'hardknocks.edu/sesame.street'
  end

  it 'should set queue fields' do
    subject.work_item_state = FactoryBot.create(:work_item_state, work_item: subject, action: 'Success')
    ts = Time.now
    setup_item(subject)
    subject.action = ingest
    subject.stage = record
    subject.status = pending
    subject.node = "10.11.12.13"
    subject.pid = 808
    subject.needs_admin_review = true

    subject.save!
    subject.reload

    subject.node.should == "10.11.12.13"
    subject.pid.should == 808
    subject.needs_admin_review.should == true
  end

  it 'pretty_state should not choke on nil' do
    subject.work_item_state = FactoryBot.create(:work_item_state, work_item: subject, action: 'Success')
    setup_item(subject)
    subject.work_item_state.state = nil
    subject.pretty_state.should == nil
  end

  it 'pretty_state should not choke on empty string' do
    subject.work_item_state = FactoryBot.create(:work_item_state, work_item: subject, action: 'Success')
    setup_item(subject)
    subject.work_item_state.state = Zlib::Deflate.deflate('')
    subject.pretty_state.should == nil
  end

  it 'pretty_state should produce formatted JSON' do
    subject.work_item_state = FactoryBot.create(:work_item_state, work_item: subject, action: 'Success')
    setup_item(subject)
    subject.work_item_state.state = Zlib::Deflate.deflate('{ "here": "is", "some": ["j","s","o","n"] }')
    pretty_json = <<-eos
{
  "here": "is",
  "some": [
    "j",
    "s",
    "o",
    "n"
  ]
}
    eos
    subject.pretty_state.should == pretty_json.strip
  end

  it 'requeue_item should reset the status, stage, and action to the appropriate fields' do
    subject = FactoryBot.create(:work_item)

    subject.status = Pharos::Application::PHAROS_STATUSES['fail']
    subject.action = Pharos::Application::PHAROS_ACTIONS['delete']
    subject.stage = Pharos::Application::PHAROS_STAGES['validate']
    subject.requeue_item
    subject.status.should == Pharos::Application::PHAROS_STATUSES['pend']
    subject.action.should == Pharos::Application::PHAROS_ACTIONS['delete']
    subject.stage.should ==  Pharos::Application::PHAROS_STAGES['requested']

    subject.status = Pharos::Application::PHAROS_STATUSES['fail']
    subject.action = Pharos::Application::PHAROS_ACTIONS['restore']
    subject.stage = Pharos::Application::PHAROS_STAGES['validate']
    subject.requeue_item
    subject.status.should == Pharos::Application::PHAROS_STATUSES['pend']
    subject.action.should == Pharos::Application::PHAROS_ACTIONS['restore']
    subject.stage.should ==  Pharos::Application::PHAROS_STAGES['requested']

    subject.status = Pharos::Application::PHAROS_STATUSES['fail']
    subject.action = Pharos::Application::PHAROS_ACTIONS['glacier_restore']
    subject.stage = Pharos::Application::PHAROS_STAGES['validate']
    subject.requeue_item
    subject.status.should == Pharos::Application::PHAROS_STATUSES['pend']
    subject.action.should == Pharos::Application::PHAROS_ACTIONS['glacier_restore']
    subject.stage.should ==  Pharos::Application::PHAROS_STAGES['requested']

    subject.status = Pharos::Application::PHAROS_STATUSES['fail']
    subject.action = Pharos::Application::PHAROS_ACTIONS['ingest']
    subject.stage = Pharos::Application::PHAROS_STAGES['validate']
    subject.requeue_item(stage: Pharos::Application::PHAROS_STAGES['fetch'])
    subject.status.should == Pharos::Application::PHAROS_STATUSES['pend']
    subject.action.should == Pharos::Application::PHAROS_ACTIONS['ingest']
    subject.stage.should ==  Pharos::Application::PHAROS_STAGES['receive']

    subject.status = Pharos::Application::PHAROS_STATUSES['fail']
    subject.action = Pharos::Application::PHAROS_ACTIONS['dpn']
    subject.stage = Pharos::Application::PHAROS_STAGES['validate']
    subject.requeue_item(stage: Pharos::Application::PHAROS_STAGES['package'])
    subject.status.should == Pharos::Application::PHAROS_STATUSES['pend']
    subject.action.should == Pharos::Application::PHAROS_ACTIONS['dpn']
    subject.stage.should ==  Pharos::Application::PHAROS_STAGES['requested']
  end

  describe 'work queue methods' do
    ingest_date = Time.parse('2014-06-01')
    before do
      test_obj = FactoryBot.create(:intellectual_object, identifier: 'abc/123')
      FactoryBot.create(:generic_file, identifier: 'abc/123/doc.pdf', intellectual_object_id: test_obj.id)
      3.times do
        ingest_date = ingest_date + 1.days
        FactoryBot.create(:work_item, object_identifier: 'abc/123',
                           action: Pharos::Application::PHAROS_ACTIONS['ingest'],
                           stage: Pharos::Application::PHAROS_STAGES['record'],
                           status: Pharos::Application::PHAROS_STATUSES['success'],
                           date: ingest_date)
      end
    end

    it 'should return the last ingested version when asked' do
      wi = WorkItem.last_ingested_version('abc/123')
      wi.object_identifier.should == 'abc/123'
      wi.date.should == ingest_date
    end

    it 'should create a restoration request when asked' do
      wi = WorkItem.create_restore_request('abc/123', 'mikey@example.com')
      wi.work_item_state = FactoryBot.build(:work_item_state, work_item: wi)
      wi.action.should == Pharos::Application::PHAROS_ACTIONS['restore']
      wi.stage.should == Pharos::Application::PHAROS_STAGES['requested']
      wi.status.should == Pharos::Application::PHAROS_STATUSES['pend']
      wi.note.should == 'Restore requested'
      wi.outcome.should == 'Not started'
      wi.user.should == 'mikey@example.com'
      wi.retry.should == true
      wi.work_item_state.state.should be_nil
      wi.node.should be_nil
      wi.pid.should == 0
      wi.needs_admin_review.should == false
      wi.id.should_not be_nil
    end

    it 'should create a file restoration request when asked' do
      test_file = GenericFile.where(identifier: 'abc/123/doc.pdf').first
      wi = WorkItem.create_restore_request_for_file(test_file, 'mikey@example.com')
      wi.work_item_state = FactoryBot.build(:work_item_state, work_item: wi)
      wi.action.should == Pharos::Application::PHAROS_ACTIONS['restore']
      wi.stage.should == Pharos::Application::PHAROS_STAGES['requested']
      wi.status.should == Pharos::Application::PHAROS_STATUSES['pend']
      wi.note.should == 'Restore requested'
      wi.outcome.should == 'Not started'
      wi.user.should == 'mikey@example.com'
      wi.retry.should == true
      wi.work_item_state.state.should be_nil
      wi.node.should be_nil
      wi.pid.should == 0
      wi.needs_admin_review.should == false
      wi.id.should_not be_nil
      wi.generic_file_identifier.should == test_file.identifier
    end

    it 'should create a glacier restoration request when asked' do
      wi = WorkItem.create_glacier_restore_request('abc/123', 'mikey@example.com')
      wi.work_item_state = FactoryBot.build(:work_item_state, work_item: wi)
      wi.action.should == Pharos::Application::PHAROS_ACTIONS['glacier_restore']
      wi.stage.should == Pharos::Application::PHAROS_STAGES['requested']
      wi.status.should == Pharos::Application::PHAROS_STATUSES['pend']
      wi.note.should == 'Restore requested'
      wi.outcome.should == 'Not started'
      wi.user.should == 'mikey@example.com'
      wi.retry.should == true
      wi.work_item_state.state.should be_nil
      wi.node.should be_nil
      wi.pid.should == 0
      wi.needs_admin_review.should == false
      wi.id.should_not be_nil
    end

    it 'should create a dpn request when asked' do
      wi = WorkItem.create_dpn_request('abc/123', 'mikey@example.com')
      wi.work_item_state = FactoryBot.build(:work_item_state, work_item: wi)
      wi.action.should == Pharos::Application::PHAROS_ACTIONS['dpn']
      wi.stage.should == Pharos::Application::PHAROS_STAGES['requested']
      wi.status.should == Pharos::Application::PHAROS_STATUSES['pend']
      wi.note.should == 'Requested item be sent to DPN'
      wi.outcome.should == 'Not started'
      wi.user.should == 'mikey@example.com'
      wi.retry.should == true
      wi.work_item_state.state.should be_nil
      wi.node.should be_nil
      wi.pid.should == 0
      wi.needs_admin_review.should == false
      wi.id.should_not be_nil
    end

    it 'should create a delete request when asked' do
      wi = WorkItem.create_delete_request('abc/123', 'abc/123/doc.pdf', 'mikey@example.com', 'jeremy@example.com', 'joyce@example.com')
      wi.work_item_state = FactoryBot.build(:work_item_state, work_item: wi)
      wi.action.should == Pharos::Application::PHAROS_ACTIONS['delete']
      wi.stage.should == Pharos::Application::PHAROS_STAGES['requested']
      wi.status.should == Pharos::Application::PHAROS_STATUSES['pend']
      wi.note.should == 'Delete requested'
      wi.outcome.should == 'Not started'
      wi.user.should == 'mikey@example.com'
      wi.inst_approver.should == 'jeremy@example.com'
      wi.aptrust_approver.should == 'joyce@example.com'
      wi.retry.should == true
      wi.generic_file_identifier.should == 'abc/123/doc.pdf'
      wi.work_item_state.state.should be_nil
      wi.node.should be_nil
      wi.pid.should == 0
      wi.needs_admin_review.should == false
      wi.id.should_not be_nil
    end

    it 'should find pending ingest' do
      setup_item(subject)
      subject.action = ingest
      subject.stage = record
      subject.status = pending
      subject.object_identifier = 'abc/123'
      subject.save!

      pending_action = WorkItem.pending_action(subject.object_identifier)
      pending_action.should_not be_nil
      pending_action.action.should == ingest
    end

    it 'should find pending restore' do
      setup_item(subject)
      subject.action = restore
      subject.stage = record
      subject.status = pending
      subject.object_identifier = 'abc/123'
      subject.save!

      pending_action = WorkItem.pending_action(subject.object_identifier)
      pending_action.should_not be_nil
      pending_action.action.should == restore
    end

    it 'should find pending restore for a file' do
      setup_item(subject)
      subject.action = restore
      subject.stage = record
      subject.status = pending
      subject.object_identifier = 'abc/123'
      subject.generic_file_identifier = 'abc/123/data/test.pdf'
      subject.save!

      pending_action = WorkItem.pending_action_for_file(subject.generic_file_identifier)
      pending_action.should_not be_nil
      pending_action.action.should == restore
    end

    it 'should find pending delete' do
      setup_item(subject)
      subject.action = delete
      subject.stage = record
      subject.status = pending
      subject.object_identifier = 'abc/123'
      subject.save!

      pending_action = WorkItem.pending_action(subject.object_identifier)
      pending_action.should_not be_nil
      pending_action.action.should == delete
    end

    it 'should find pending DPN request' do
      setup_item(subject)
      subject.action = dpn
      subject.stage = record
      subject.status = pending
      subject.object_identifier = 'abc/123'
      subject.save!

      pending_action = WorkItem.pending_action(subject.object_identifier)
      pending_action.should_not be_nil
      pending_action.action.should == dpn
    end

    it 'should find ingest by name, etag, bag_date' do
      bag_date = Time.parse('2016-08-31T19:39:39Z')
      setup_item(subject)
      subject.action = ingest
      subject.stage = clean
      subject.status = success
      subject.object_identifier = 'abc/123'
      subject.name = '123.tar'
      subject.etag = '123456789'
      subject.bag_date = bag_date
      subject.save!

      bag_date_1 = subject.bag_date
      bag_date_2 = subject.bag_date + 1.seconds

      item = WorkItem
        .with_name(subject.object_identifier)
        .with_etag(subject.etag)
        .with_bag_date(bag_date_1, bag_date_2)
      item.should_not be_nil
    end

    it 'should find by queued' do
      WorkItem.update_all(queued_at: nil)
      items = WorkItem.queued("true")
      items.should be_empty
      items = WorkItem.queued("false")
      items.should_not be_empty

      WorkItem.update_all(queued_at: ingest_date)
      items = WorkItem.queued("true")
      items.should_not be_empty
      items = WorkItem.queued("false")
      items.should be_empty
    end

    it 'should find by node not empty' do
      WorkItem.update_all(node: 'xyz')
      items = WorkItem.with_unempty_node("true")
      items.should_not be_empty
      items.count.should == WorkItem.all.count
      WorkItem.update_all(node: '')
      items = WorkItem.with_unempty_node("true")
      items.should be_empty
      items = WorkItem.with_unempty_node(nil)
      items.should_not be_empty
    end

    it 'should find by node empty' do
      WorkItem.update_all(node: 'xyz')
      items = WorkItem.with_empty_node("true")
      items.should be_empty
      items = WorkItem.with_empty_node(nil)
      items.should_not be_empty
      WorkItem.update_all(node: '')
      items = WorkItem.with_empty_node("true")
      items.should_not be_empty
      items.count.should == WorkItem.all.count
    end

    it 'should find by pid not empty' do
      WorkItem.update_all(pid: 15)
      items = WorkItem.with_unempty_pid("true")
      items.should_not be_empty
      items.count.should == WorkItem.all.count
      WorkItem.update_all(pid: 0)
      items = WorkItem.with_unempty_pid("true")
      items.should be_empty
      items = WorkItem.with_unempty_pid(nil)
      items.should_not be_empty
    end

    it 'should find by pid empty' do
      WorkItem.update_all(pid: 15)
      items = WorkItem.with_empty_pid("true")
      items.should be_empty
      items = WorkItem.with_empty_pid(nil)
      items.should_not be_empty
      WorkItem.update_all(pid: 0)
      items = WorkItem.with_empty_pid("true")
      items.should_not be_empty
      items.count.should == WorkItem.all.count
    end

  end

  describe 'alert methods' do
    describe 'for failed ingest' do
      it 'failed_ingest should return a list of work items that have failed a specific action' do
        user = FactoryBot.create(:user, :admin)
        item = FactoryBot.create(:work_item, action: ingest, status: failed)
        items = WorkItem.failed_action(Time.now - 24.hours, ingest, user)
        expect(items.first).to eq item
      end

      it 'failed_ingest_count should return the number of work items that have failed a specific action' do
        user = FactoryBot.create(:user, :admin)
        item = FactoryBot.create(:work_item, action: ingest, status: failed)
        count = WorkItem.failed_action_count(Time.now - 24.hours, ingest, user)
        expect(count).to eq 1
      end

      it 'stalled_items should return a list of work items queued 12+ hours ago that have not succeeded, failed, or cancelled' do
        user = FactoryBot.create(:user, :admin)
        item1 = FactoryBot.create(:work_item, queued_at: Time.now - 13.hours, status: pending)
        item2 = FactoryBot.create(:work_item, queued_at: Time.now - 13.hours, status: started)
        items = WorkItem.stalled_items(user)
        expect(items.last.id).to eq item1.id
        expect(items.first.id).to eq item2.id
      end

      it 'stalled_item_counts should return the number of work items queued 12+ hours ago that have not succeeded, failed, or cancelled' do
        user = FactoryBot.create(:user, :admin)
        item1 = FactoryBot.create(:work_item, queued_at: Time.now - 13.hours, status: pending)
        item2 = FactoryBot.create(:work_item, queued_at: Time.now - 13.hours, status: started)
        count = WorkItem.stalled_items_count(user)
        expect(count).to eq 2
      end
    end
  end
end
