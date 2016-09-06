require 'spec_helper'
require 'zlib'

RSpec.describe WorkItemState, type: :model do
  before(:all) do
    WorkItem.destroy_all
    IntellectualObject.destroy_all
    GenericFile.destroy_all
  end

  it { should validate_presence_of(:action) }

  it 'should properly set a work_item_id' do
    subject.work_item_id = 20
    subject.work_item_id.should == 20
  end

  it 'should properly set an action' do
    subject.action = 'Success'
    subject.action.should == 'Success'
  end

  it 'should properly set a zipped state' do
    zipped_text = Zlib::Deflate.deflate('{TEST STRING}')
    subject.state = zipped_text
    Zlib::Inflate.inflate(subject.state).should == '{TEST STRING}'
  end
end
