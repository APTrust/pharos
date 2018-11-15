require 'spec_helper'

RSpec.describe ConfirmationToken, :type => :model do
  after(:all) do
    IntellectualObject.delete_all
    ConfirmationToken.delete_all
  end

  it { should validate_presence_of(:token) }

  it 'should validate that the token has a parent object or file' do
    subject = FactoryBot.build(:confirmation_token, intellectual_object_id: nil, generic_file_id: nil)
    subject.should_not be_valid
    subject.errors[:intellectual_object_id].should include('or generic_file_id, or institution_id must be present')
    subject.errors[:generic_file_id].should include('or intellectual_object_id, or institution_id must be present')
    subject.errors[:institution_id].should include('or intellectual_object_id, or generic_file_id must be present')
  end

  describe 'An instance' do

    it 'should properly set a token' do
      subject.token = '1234-5678'
      subject.token.should == '1234-5678'
    end
  end

end
