require 'spec_helper'

RSpec.describe PremisEvent, :type => :model do
  it 'has view partials in the events directory' do
    subject.to_partial_path.should == 'premis_events/premis_event'
  end
end