# == Schema Information
#
# Table name: storage_records
#
#  id              :bigint           not null, primary key
#  generic_file_id :integer
#  url             :string
#
require 'spec_helper'

RSpec.describe StorageRecord, type: :model do

  it { should validate_presence_of(:url) }
  it { should validate_uniqueness_of(:url)}

  describe 'An instance' do

    it 'should properly set id' do
      subject.generic_file_id = 800
      subject.generic_file_id.should == 800
    end

    it 'should properly set url' do
      subject.url = "https://example.com/preservation/file1"
      subject.url.should == "https://example.com/preservation/file1"
    end

  end

end
