require 'spec_helper'

RSpec.describe PremisEvent, :type => :model do

  it { should validate_presence_of(:identifier) }
  it { should validate_presence_of(:event_type) }
  it { should validate_presence_of(:date_time) }
  it { should validate_presence_of(:detail)}
  it { should validate_presence_of(:outcome) }
  it { should validate_presence_of(:outcome_detail) }
  it { should validate_presence_of(:object) }
  it { should validate_presence_of(:agent)}

  it 'has view partials in the events directory' do
    subject.to_partial_path.should == 'premis_events/premis_event'
  end

  describe 'An instance' do
    let(:object) { FactoryGirl.create(:intellectual_object) }
    let(:file) { FactoryGirl.create(:generic_file) }

    it 'should properly set an identifier' do
      exp = SecureRandom.uuid
      subject.identifier = exp
      subject.identifier.should == exp
    end

    it 'should properly set an event_type' do
      subject.event_type = 'deletion'
      subject.event_type.should == 'deletion'
    end

    it 'should properly set a date_time' do
      date = Time.now.to_s
      subject.date_time = date
      subject.date_time.should == date
    end

    it 'should properly set an outcome' do
      subject.outcome = 'Success'
      subject.outcome.should == 'Success'
    end

    it 'should properly set an outcome_detail' do
      exp = "MD5:#{SecureRandom.hex(16)}"
      subject.outcome_detail = exp
      subject.outcome_detail.should == exp
    end

    it 'should properly set an outcome_information' do
      subject.outcome_information = 'Multipart Put using md5 checksum'
      subject.outcome_information.should == 'Multipart Put using md5 checksum'
    end

    it 'should properly set a detail' do
      subject.detail = 'Completed copy to S3 storage'
      subject.detail.should == 'Completed copy to S3 storage'
    end

    it 'should properly set an object' do
      subject.object = 'Goamz S3 Client'
      subject.object.should == 'Goamz S3 Client'
    end

    it 'should properly set an agent' do
      subject.agent = 'https://github.com/crowdmob/goamz'
      subject.agent.should == 'https://github.com/crowdmob/goamz'
    end

    it 'should properly set an intellectual_object_id' do
      subject.intellectual_object = object
      subject.intellectual_object_id.should == object.id
    end

    it 'should properly set an generic_file_id' do
      subject.generic_file = file
      subject.generic_file_id.should == file.id
    end
  end

  describe 'serializable_hash' do
    let(:subject) { FactoryGirl.create(:premis_event_ingest) }

    it 'should set the state to deleted and index the object state' do
      h1 = subject.serializable_hash
      expect(h1.has_key?(:identifier)).to be true
      expect(h1.has_key?(:event_type)).to be true
      expect(h1.has_key?(:date_time)).to be true
      expect(h1.has_key?(:detail)).to be true
      expect(h1.has_key?(:outcome)).to be true
      expect(h1.has_key?(:outcome_detail)).to be true
      expect(h1.has_key?(:outcome_information)).to be true
      expect(h1.has_key?(:object)).to be true
      expect(h1.has_key?(:agent)).to be true
    end
  end
end