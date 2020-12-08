# == Schema Information
#
# Table name: bulk_delete_jobs
#
#  id                        :bigint           not null, primary key
#  requested_by              :string
#  institutional_approver    :string
#  aptrust_approver          :string
#  institutional_approval_at :datetime
#  aptrust_approval_at       :datetime
#  note                      :text
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  institution_id            :integer          not null
#
require 'spec_helper'

RSpec.describe BulkDeleteJob, :type => :model do
  it { should validate_presence_of (:requested_by) }
  it { should validate_presence_of (:institution_id) }

  it 'should properly set a requested_by' do
    subject.requested_by = 'kelly.cobb@aptrust.org'
    subject.requested_by.should == 'kelly.cobb@aptrust.org'
  end

  it 'should properly set an institutional_approver' do
    subject.institutional_approver = 'test.user@virginia.edu'
    subject.institutional_approver.should == 'test.user@virginia.edu'
  end

  it 'should properly set an aptrust_approver' do
    subject.aptrust_approver = 'andrew.diamond@aptrust.org'
    subject.aptrust_approver.should == 'andrew.diamond@aptrust.org'
  end

  it 'should properly set an institutional_approval_at' do
    subject.institutional_approval_at = '2016-05-24T18:40:22Z'
    subject.institutional_approval_at.should == '2016-05-24T18:40:22Z'
  end

  it 'should properly set an aptrust_approval_at' do
    subject.aptrust_approval_at = '2016-05-24T18:40:22Z'
    subject.aptrust_approval_at.should == '2016-05-24T18:40:22Z'
  end
end
