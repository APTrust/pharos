require 'spec_helper'

RSpec.describe Email, type: :model do
  it { should validate_presence_of (:email_type) }

  it 'should properly set an email type' do
    subject.email_type = 'fixity'
    subject.email_type.should == 'fixity'
  end

  it 'should properly set an event_identifier' do
    subject.event_identifier = '1234-5678-4ce8-bd44-25c3e76eb267'
    subject.event_identifier.should == '1234-5678-4ce8-bd44-25c3e76eb267'
  end

  it 'should properly set an item_id' do
    subject.item_id = 105
    subject.item_id.should == 105
  end

  it 'should properly set an user list' do
    subject.user_list = 'help@aptrust.org; info@aptrust.org'
    subject.user_list.should == 'help@aptrust.org; info@aptrust.org'
  end

  it 'should properly set an email text' do
    subject.email_text = 'This is the text of the email.'
    subject.email_text.should == 'This is the text of the email.'
  end

  it 'validates that a fixity check email has an event identifier and nil work item id' do
    subject = FactoryGirl.build(:fixity_email, email_type: 'fixity', item_id: 105, event_identifier: nil)
    subject.should_not be_valid
    subject.errors[:event_identifier].should include('must not be blank for a failed fixity check email')
    subject.errors[:item_id].should include('must be left blank for a failed fixity check email')
  end

  it 'validates that a restoration email has an item id and nil event identifier' do
    subject = FactoryGirl.build(:fixity_email, email_type: 'restoration', item_id: nil, event_identifier: '1234-5678')
    subject.should_not be_valid
    subject.errors[:item_id].should include('must not be blank for a restoration notification email')
    subject.errors[:event_identifier].should include('must be left blank for a restoration notification email')
  end

  it 'validates that a multiple fixity email has events and not items' do
    item = FactoryGirl.create(:work_item)
    subject = FactoryGirl.create(:multiple_fixity_email, premis_events: [], work_items: [item])
    subject.should_not be_valid
    #subject.errors[:premis_events].should include('There must be at least one event associated with this type')
    subject.errors[:work_items].should include('There must be no items associated with this type')
  end

  it 'validates that a multiple restoration email has items and not events' do
    event = FactoryGirl.create(:premis_event_fixity_check_fail)
    subject = FactoryGirl.create(:multiple_restoration_email, premis_events: [event], work_items: [])
    subject.should_not be_valid
    #subject.errors[:work_items].should include('There must be at least one item associated with this type')
    subject.errors[:premis_events].should include('There must be no events associated with this type')
  end
end
