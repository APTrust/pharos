require 'spec_helper'

RSpec.describe DpnBag, type: :model do
  before(:all) do
    DpnBag.delete_all
  end

  it { should validate_presence_of(:object_identifier) }
  it { should validate_presence_of(:dpn_identifier) }

  it 'should properly set an institution_id' do
    subject.institution_id = 15
    subject.institution_id.should == 15
  end

  it 'should properly set an object_identifier' do
    subject.object_identifier = 'test.edu/something-1234_5678'
    subject.object_identifier.should == 'test.edu/something-1234_5678'
  end

  it 'should properly set an dpn_identifier' do
    ident = SecureRandom.uuid
    subject.dpn_identifier = ident
    subject.dpn_identifier.should == ident
  end

  it 'should properly set a dpn_size' do
    subject.dpn_size = 15000
    subject.dpn_size.should == 15000
  end

  it 'should properly set node_1' do
    subject.node_1 = 'chron'
    subject.node_1.should == 'chron'
  end

  it 'should properly set node_2' do
    subject.node_2 = 'hathi'
    subject.node_2.should == 'hathi'
  end

  it 'should properly set node_3' do
    subject.node_3 = 'aptrust'
    subject.node_3.should == 'aptrust'
  end

  it 'should properly set dpn_created_at' do
    time = Time.now
    subject.dpn_created_at = time
    subject.dpn_created_at.should == time
  end

  it 'should properly set dpn_updated_at' do
    time = Time.now
    subject.dpn_updated_at = time
    subject.dpn_updated_at.should == time
  end
end
