require 'spec_helper'

describe ReportsHelper do

  describe '#cost_analysis_member' do
    it 'should return the cost associated with a member institutions stored data' do
      stored_data = 1267820381201928
      cost = 480092.17
      helper.cost_analysis_member(stored_data).should == cost
    end

  end

  describe '#cost_analysis_subscriber' do
    it 'should return the cost associated with a subscriber institutions stored data' do
      stored_data = 126782038120
      cost = 48.43
      helper.cost_analysis_subscriber(stored_data).should == cost
    end
  end

end