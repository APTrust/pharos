require 'spec_helper'

RSpec.describe DpnWorkItem, type: :model do
  before(:all) do
    DpnWorkItem.delete_all
  end

  it { should validate_presence_of(:task) }
  it { should validate_presence_of(:identifier) }

  it 'should properly set a node' do
    subject.remote_node = 'Chronopolis'
    subject.remote_node.should == 'Chronopolis'
  end

  it 'should properly set a task' do
    subject.task = 'ingest'
    subject.task.should == 'ingest'
  end

  it 'should properly set an identifier' do
    subject.identifier = '1234567890'
    subject.identifier.should == '1234567890'
  end

  it 'should properly set queued_at' do
    date = Time.parse('2016-08-31T19:39:39Z')
    subject.queued_at = date
    subject.queued_at.should == date
  end

  it 'should properly set completed_at' do
    date = Time.parse('2016-09-31T19:39:39Z')
    subject.completed_at = date
    subject.completed_at.should == date
  end

  it 'should properly set a note' do
    subject.note = 'Something new'
    subject.note.should == 'Something new'
  end

  it 'should properly set a state' do
    subject.state = 'This is a new state.'
    subject.state.should == 'This is a new state.'
  end

  it 'should validate that task is one of the allowed options' do
    subject = FactoryGirl.build(:dpn_work_item, task: 'not_allowed')
    subject.should_not be_valid
    subject.errors[:task].should include('Task is not one of the allowed options')
  end


  describe 'filters' do
    let(:item1) { FactoryGirl.create(:dpn_work_item) }
    let(:item2) { FactoryGirl.create(:dpn_work_item) }
    let(:item3) { FactoryGirl.create(:dpn_work_item) }

    it 'should filter by complete' do
      item1.completed_at = nil
      item2.completed_at = Time.now.utc
      item3.completed_at = Time.now.utc
      item1.save
      item2.save
      item3.save
      items = DpnWorkItem.is_completed('true')
      items.count.should == 2
    end

    it 'should filter by incomplete' do
      item1.completed_at = nil
      item2.completed_at = Time.now.utc
      item3.completed_at = Time.now.utc
      item1.save
      item2.save
      item3.save
      items = DpnWorkItem.is_not_completed('true')
      items.count.should == 1
    end
  end

  describe 'alert methods' do
    it 'stalled_dpn_replications should return a list of dpn work items that have stalled during dpn replication' do
      item = FactoryGirl.create(:dpn_work_item, queued_at: Time.now - 25.hours, completed_at: nil)
      items = DpnWorkItem.stalled_dpn_replications
      expect(items.first).to eq item
    end

    it 'stalled_dpn_replication_counts should return the number of dpn work items that have stalled during dpn replication' do
      item = FactoryGirl.create(:dpn_work_item, queued_at: Time.now - 25.hours, completed_at: nil)
      count = DpnWorkItem.stalled_dpn_replication_count
      expect(count).to eq 1
    end
  end
end
