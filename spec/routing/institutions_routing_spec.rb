require 'spec_helper'

describe InstitutionsController do
  describe 'routing' do

    it 'routes to #index' do
      get('/institutions').should route_to('institutions#index')
    end

    it 'routes to #new' do
      get('/institutions/new').should route_to('institutions#new')
    end

    it 'routes to #show' do
      get('/institutions/test.com').should route_to('institutions#show', :identifier => 'test.com')
    end

    it 'routes to #edit' do
      get('/institutions/test.com/edit').should route_to('institutions#edit', :identifier => 'test.com')
    end

    it 'routes to #create' do
      post('/institutions').should route_to('institutions#create')
    end

    it 'routes to #update' do
      put('/institutions/test.com').should route_to('institutions#update', :identifier => 'test.com')
    end
  end
end