require 'spec_helper'

RSpec.describe Checksum, :type => :model do
  it { should validate_presence_of (:digest) }
  it { should validate_presence_of (:datetime) }
  it { should validate_presence_of (:algorithm) }

  it 'should properly set a digest' do
    subject.digest = '5d43a9a5fc377fa21fa9c0204b8dc61e'
    subject.digest.should == '5d43a9a5fc377fa21fa9c0204b8dc61e'
  end

  it 'should properly set a datetime' do
    subject.datetime = '2016-05-24T18:40:22Z'
    subject.datetime.should == '2016-05-24T18:40:22Z'
  end

  it 'should properly set an algorithm' do
    subject.algorithm = 'md5'
    subject.algorithm.should == 'md5'
  end
end
