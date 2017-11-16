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

  describe '#dpn_process_time' do
    it 'should return a proper process time' do
      queue_date = Time.parse('2017-10-25 18:30:01 UTC')
      complete_date = Time.parse('2017-10-26 06:03:21 UTC')
      dpn_item = FactoryBot.create(:dpn_work_item, queued_at: queue_date, completed_at: complete_date)
      process_time = dpn_process_time(dpn_item)
      process_time.should == '11.56 hours'

      queue_date_two = '2016-09-28T19:39:39Z'
      complete_date_two = '2016-09-29T05:42:37Z'
      dpn_item_two = FactoryBot.create(:dpn_work_item, queued_at: queue_date_two, completed_at: complete_date_two)
      process_time_two = dpn_process_time(dpn_item_two)
      process_time_two.should == '10.05 hours'
    end
  end

end

