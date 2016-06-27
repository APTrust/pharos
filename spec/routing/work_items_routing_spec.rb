require 'spec_helper'

describe 'Routes for Work Items' do
  it 'has a route to create work itemse' do
    expect(post: 'items/')
        .to(route_to(controller: 'work_items', action: 'create'))
  end

  it 'has a route to view the work item index' do
    expect(get: 'items/')
        .to(route_to(controller: 'work_items', action: 'index'))
  end

  it 'has a route to show individual work items' do
    expect(get: 'items/1')
        .to(route_to(controller: 'work_items', action: 'show', id: '1'))
  end
end