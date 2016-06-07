require 'spec_helper'

describe 'Routes for Events' do

  it 'has a route to create events for a generic file' do
    expect(
        post: 'events/apt.org/123/data/file.pdf'
    ).to(
        route_to(controller: 'premis_events',
                 action: 'create',
                 generic_file_identifier: 'apt.org/123/data/file.pdf'
        )
    )
  end

  it "has an index for a generic file's events" do
    expect(
        get: 'events/apt.org/123/data/file.pdf'
    ).to(
        route_to(controller: 'premis_events',
                 action: 'index',
                 generic_file_identifier: 'apt.org/123/data/file.pdf'
        )
    )
  end

  it 'has a route to create events for an intellectual object' do
    expect(
        post: 'events/apt.org/123'
    ).to(
        route_to(controller: 'premis_events',
                 action: 'create',
                 intellectual_object_identifier: 'apt.org/123'
        )
    )
  end

  it "has an index for an intellectual object's events" do
    expect(
        get: 'events/apt.org/123'
    ).to(
        route_to(controller: 'premis_events',
                 action: 'index',
                 intellectual_object_identifier: 'apt.org/123'
        )
    )
  end

  it "has an index for an institution's events" do
    expect(
        get: 'events/testinst.com'
    ).to(
        route_to(controller: 'premis_events',
                 action: 'index',
                 identifier: 'testinst.com'
        )
    )
  end

end