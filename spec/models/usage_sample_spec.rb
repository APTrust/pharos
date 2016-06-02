require 'spec_helper'

RSpec.describe UsageSample, :type => :model do
  it 'should have a hash' do
    subject.data['all'] = '123123'
    expect(subject.data).to eq({'all' => '123123'})
  end

  describe 'on an institution' do
    size = 184512282
    before(:all) { @file =  FactoryGirl.create(:generic_file, size: size ) }
    after :all do
      @file.delete
      # active_fedora is clearning out the relationship when it's deleted so we can't use it, so cache.
      inst = @file.intellectual_object.institution
      @file.intellectual_object.delete
      inst.delete
    end
    let(:generic_file) { @file }
    before do
      subject.institution = generic_file.intellectual_object.institution
      subject.save
    end
    it 'should grab a sample' do
      expect(subject.data).to eq ({'all' => 184512282,
                                   'application/xml' => 184512282})
    end
    it 'should have to_flot' do
      #noinspection RubyArgCount
      subject.stub(:created_at => DateTime.parse('Thu, 16 Jan 2014 20:31:53 UTC +00:00'))
      expect(subject.to_flot).to eq [1389904313, 184512282]
    end
  end

end
