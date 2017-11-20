require 'spec_helper'

RSpec.describe ConfirmationToken, :type => :model do
  after(:all) do
    IntellectualObject.delete_all
    ConfirmationToken.delete_all
  end

  it { should validate_presence_of(:token) }
  it { should validate_presence_of(:intellectual_object) }

  describe 'An instance' do

    it 'should properly set a token' do
      subject.token = '1234-5678'
      subject.token.should == '1234-5678'
    end
  end

end
