require 'spec_helper'

describe 'Routing' do
  let(:file) { FactoryGirl.create(:generic_file) }
  it 'should route to the show when GET /files/apt.org/123/data/filename.xml' do
    expect(get: '/files/apt.org%2F123%2Fdata%2Ffilename.xml').to route_to(controller: 'generic_files', action: 'show', generic_file_identifier: 'apt.org/123/data/filename.xml')
    expect(generic_file_path('apt.org/123/data/filename.xml')).to eq '/files/apt.org%2F123%2Fdata%2Ffilename.xml'
  end
  it 'should route to create when POST /files/apt.org/123' do
    expect(post: '/files/apt.org%2F123').to route_to(controller: 'generic_files', action: 'create', intellectual_object_identifier: 'apt.org/123')
  end
  it 'should route to index when GET /files/apt.org/123' do
    expect(get: 'files/apt.org%2F123').to route_to(controller: 'generic_files', action: 'index', intellectual_object_identifier: 'apt.org/123')
  end
  it 'should route to update when PATCH /files/apt.org/123/data/filename.xml' do
    expect(patch: '/files/apt.org%2F123%2Fdata%2Ffilename.xml/').to route_to(controller: 'generic_files', action: 'update', generic_file_identifier: 'apt.org/123/data/filename.xml')
  end
end