require 'spec_helper'

RSpec.describe Role, :type => :model do
  before(:all) do
    Role.destroy_all
  end

  it { should validate_presence_of(:name) }

  it 'should properly set a name' do
    subject.name = 'admin'
    subject.name.should == 'admin'
  end
end
