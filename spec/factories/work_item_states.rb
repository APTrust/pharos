FactoryGirl.define do
  factory :work_item_state do
    work_item { FactoryGirl.create(:work_item) }
    action { work_item.action }
    state {  }
  end
end
