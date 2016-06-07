require 'spec_helper'

describe 'Routing' do
  it 'should route to the index when GET /objects' do
    expect(get: '/objects/aptrust.org').to route_to(controller: 'intellectual_objects', action: 'index', identifier: 'aptrust.org')
    expect(institution_intellectual_objects_path('aptrust.org')).to eq '/objects/aptrust.org'
  end
  it 'should route to the show page when GET /objects/aptrust.org/12345678' do
    expect(get: '/objects/aptrust.org/12345678').to route_to(controller: 'intellectual_objects', action: 'show', intellectual_object_identifier: 'aptrust.org/12345678')
    expect(intellectual_object_path('aptrust.org/12345678')).to eq '/objects/aptrust.org/12345678'
  end
  it 'should route to create when POST /objects/aptrust.org' do
    expect(post: '/objects/aptrust.org').to route_to(controller: 'intellectual_objects', action: 'create', identifier: 'aptrust.org')
  end
end