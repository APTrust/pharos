require 'spec_helper'

describe DpnWorkItemPolicy do
  subject (:dpn_work_item_policy) { DpnWorkItemPolicy.new(user, dpn_item) }

  context 'for an admin user' do
    let(:user) { FactoryGirl.create(:user, :admin) }
    let(:dpn_item) { FactoryGirl.build(:dpn_work_item)}

    it 'access any dpn work item' do
      should permit(:create)
      should permit(:index)
      should permit(:show)
      should permit(:update)
    end
  end

  context 'for an institutional admin user' do
    let(:user) { FactoryGirl.create(:user, :institutional_admin) }
    let(:dpn_item) { FactoryGirl.build(:dpn_work_item)}

    it 'not access any dpn work item' do
      should_not permit(:create)
      should_not permit(:index)
      should_not permit(:show)
      should_not permit(:update)
    end
  end

  context 'for an institutional user' do
    let(:user) { FactoryGirl.create(:user, :institutional_user) }
    let(:dpn_item) { FactoryGirl.build(:dpn_work_item)}

    it 'not access any dpn work item' do
      should_not permit(:create)
      should_not permit(:index)
      should_not permit(:show)
      should_not permit(:update)
    end
  end
end