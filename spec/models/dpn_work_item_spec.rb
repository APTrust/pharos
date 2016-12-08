require 'spec_helper'

RSpec.describe DpnWorkItem, type: :model do
  before(:all) do
    DpnWorkItem.destroy_all
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
end
