require 'spec_helper'

describe 'Routes for Events' do

  it 'has a route to create events for a generic file' do
    expect(post: 'api/v2/events')
        .to(route_to(controller: 'premis_events', action: 'create'))
  end

  it "has an index for a generic file's events" do
    expect(get: 'events/apt.org%2F123%2Fdata%2Ffile.pdf')
        .to(route_to(controller: 'premis_events', action: 'index', file_identifier: 'apt.org/123/data/file.pdf'))
  end

  it "has an index for an intellectual object's events" do
    expect(get: 'events/apt.org%2F123')
        .to(route_to(controller: 'premis_events', action: 'index', object_identifier: 'apt.org/123'))
  end

  it "has an index for an institution's events" do
    expect(get: 'events/testinst.com')
        .to(route_to(controller: 'premis_events', action: 'index', institution_identifier: 'testinst.com'))
  end

end
