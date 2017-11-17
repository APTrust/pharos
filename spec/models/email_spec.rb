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

  it 'should properly set an intellectual_object_id' do
    subject.intellectual_object_id = 202
    subject.intellectual_object_id.should == 202
  end

  it 'should properly set an user list' do
    subject.user_list = 'help@aptrust.org; info@aptrust.org'
    subject.user_list.should == 'help@aptrust.org; info@aptrust.org'
  end

  it 'should properly set an email text' do
    subject.email_text = 'This is the text of the email.'
    subject.email_text.should == 'This is the text of the email.'
  end

  it 'validates that a fixity check email has an event identifier and nil work item id and object id' do
    subject = FactoryBot.build(:fixity_email, item_id: 105, event_identifier: nil, intellectual_object_id: 202)
    subject.should_not be_valid
    subject.errors[:event_identifier].should include('must not be blank for a failed fixity check email')
    subject.errors[:item_id].should include('must be left blank for a failed fixity check email')
    subject.errors[:intellectual_object_id].should include('must be left blank for a failed fixity check email')
  end

  it 'validates that a restoration email has an item id and nil event identifier and object id' do
    subject = FactoryBot.build(:restoration_email, item_id: nil, event_identifier: '1234-5678', intellectual_object_id: 202)
    subject.should_not be_valid
    subject.errors[:item_id].should include('must not be blank for a restoration notification email')
    subject.errors[:event_identifier].should include('must be left blank for a restoration notification email')
    subject.errors[:intellectual_object_id].should include('must be left blank for a restoration notification email')
  end

  it 'validates that a multiple fixity email has events and not items or an object' do
    item = FactoryBot.create(:work_item)
    subject = FactoryBot.create(:multiple_fixity_email, premis_events: [], work_items: [item])
    subject.should_not be_valid
    #subject.errors[:premis_events].should include('must not be empty for a failed fixity check email')
    subject.errors[:work_items].should include('must be empty for a failed fixity check email')
  end

  it 'validates that a multiple restoration email has items and not events or an object' do
    event = FactoryBot.create(:premis_event_fixity_check_fail)
    subject = FactoryBot.create(:multiple_restoration_email, premis_events: [event], work_items: [])
    subject.should_not be_valid
    #subject.errors[:work_items].should include('must not be empty for a restoration notification email')
    subject.errors[:premis_events].should include('must be empty for a restoration notification email')
  end

  it 'validates that a deletion request email has an object id and nil event and item associations' do
    subject = FactoryBot.build(:deletion_request_email, intellectual_object_id: nil, item_id: 105, event_identifier: '1234-5678')
    subject.should_not be_valid
    subject.errors[:intellectual_object_id].should include('must not be left blank for a deletion request email')
    subject.errors[:event_identifier].should include('must be left blank for a deletion request email')
    subject.errors[:item_id].should include('must be left blank for a deletion request email')
  end

  it 'validates that a deletion confirmation email has an object id and nil event and item associations' do
    subject = FactoryBot.build(:deletion_confirmation_email, intellectual_object_id: nil, item_id: 105, event_identifier: '1234-5678')
    subject.should_not be_valid
    subject.errors[:intellectual_object_id].should include('must not be left blank for a deletion confirmation email')
    subject.errors[:event_identifier].should include('must be left blank for a deletion confirmation email')
    subject.errors[:item_id].should include('must be left blank for a deletion confirmation email')
  end
end
