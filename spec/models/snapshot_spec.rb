# == Schema Information
#
# Table name: snapshots
#
#  id             :bigint           not null, primary key
#  audit_date     :datetime
#  institution_id :integer
#  apt_bytes      :bigint
#  cost           :decimal(, )
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  snapshot_type  :string
#  cs_bytes       :bigint
#  go_bytes       :bigint
#
require 'spec_helper'

RSpec.describe Snapshot, type: :model do
  after(:all) do
    IntellectualObject.delete_all
    Snapshot.delete_all
  end

  it { should validate_presence_of(:institution_id) }
  it { should validate_presence_of(:audit_date) }
  it { should validate_presence_of(:apt_bytes) }

  describe 'An instance' do

    it 'should properly set an institution_id' do
      subject.institution_id = 5
      subject.institution_id.should == 5
    end

    it 'should properly set an audit_date' do
      subject.audit_date = '2018-02-1 00:00:00 -0000'
      subject.audit_date.should == '2018-02-1 00:00:00 -0000'
    end

    it 'should properly set apt_bytes' do
      subject.apt_bytes = 200000000
      subject.apt_bytes.should == 200000000
    end

    it 'should properly set a cost' do
      subject.cost = 1238.56
      subject.cost.should == 1238.56
    end

    it 'should properly set a snaptshot type' do
      subject.snapshot_type = 'Individual'
      subject.snapshot_type.should == 'Individual'
    end
  end
end
