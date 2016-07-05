require 'spec_helper'

describe 'Routing' do
  it 'should route to search when GET /search/?q=bagname.txt' do
    expect(get: 'search/?q=bagname.txt').to route_to(controller: 'catalog', action: 'search', q: 'bagname.txt')
  end
end