require 'spec_helper'

describe 'Routes for Users' do
  it 'has a route to generate an API key for that user' do
    expect(patch: 'users/1/generate_api_key')
        .to(route_to(controller: 'users', action: 'generate_api_key', id: '1'))
  end
end