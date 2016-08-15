require 'spec_helper'

describe ApplicationHelper do

  describe '#current_path' do
    it 'should return an updated path with new parameters' do
      #helper.request.path = 'localhost:3000/itemresults'
      @current = 'localhost:3000/itemresults'
      name = 'status'
      value = 'Success'
      expected_result = 'localhost:3000/itemresults?status=Success'
      helper.current_path(name, value).should == expected_result
    end

    it 'should add in search parameters to the search path' do
      helper.request.path = 'localhost:3000/search'
      helper.params[:qq] = '34'
      helper.params[:search_field] = 'Name'
      name = 'status'
      value = 'Success'
      expected_result = 'localhost:3000/?status=Success&search_field=Name&qq=34'
    end
  end

end

