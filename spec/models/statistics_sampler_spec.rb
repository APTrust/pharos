require 'spec_helper'

describe StatisticsSampler do
  before {
    Institution.delete_all
    3.times {FactoryGirl.create(:member_institution) }
  }
  it 'should record statistics' do
    expect{ StatisticsSampler.record_current_statistics }.to change{UsageSample.count}.by(3)
  end
end