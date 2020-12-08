# == Schema Information
#
# Table name: roles
#
#  id         :integer          not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require 'spec_helper'

RSpec.describe Role, :type => :model do
  before(:all) do
    Role.delete_all
  end

  it { should validate_presence_of(:name) }

  it 'should properly set a name' do
    subject.name = 'admin'
    subject.name.should == 'admin'
  end
end
