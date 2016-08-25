require 'spec_helper'

describe WorkItemPolicy do
  subject (:work_item_policy) { WorkItemPolicy.new(user, work_item) }
  let(:institution) { FactoryGirl.create(:institution) }
  let(:intellectual_object) { FactoryGirl.create(:intellectual_object, institution: institution) }
  let(:other_inst) { FactoryGirl.create(:institution) }
  let(:other_int_obj) { FactoryGirl.create(:intellectual_object, institution: other_inst) }

  context 'for an admin user' do
    let(:user) { FactoryGirl.create(:user, :admin, institution_id: institution.id) }
    let(:work_item) { FactoryGirl.create(:work_item, institution: institution, intellectual_object: intellectual_object, object_identifier: intellectual_object.identifier)}

    it do
      should permit(:create)
      should permit(:new)
      should permit(:show)
      should permit(:update)
      should permit(:edit)
      should_not permit(:destroy)
    end
  end

  context 'for an institutional admin user' do
    let(:user) { FactoryGirl.create(:user, :institutional_admin,
                                    institution_id: institution.id) }
    describe 'when the item is' do
      describe 'in my institution' do
        let(:work_item) { FactoryGirl.create(:work_item, institution: institution, intellectual_object: intellectual_object, object_identifier: intellectual_object.identifier) }
        it do
          should_not permit(:create)
          should_not permit(:new)
          should permit(:show)
          should permit(:update)
          should permit(:edit)
          should_not permit(:destroy)
        end
      end

      describe 'not in my institution' do
        let(:work_item) { FactoryGirl.create(:work_item, institution: other_inst, intellectual_object: other_int_obj, object_identifier: other_int_obj.identifier)}
        it do
          should_not permit(:create)
          should_not permit(:new)
          should_not permit(:show)
          should_not permit(:update)
          should_not permit(:edit)
          should_not permit(:destroy)
        end
      end
    end
  end

  context 'for an institutional user' do
    let(:user) { FactoryGirl.create(:user, :institutional_user,
                                    institution_id: institution.id) }
    describe 'when the item is' do
      describe 'in my institution' do
        let(:work_item) { FactoryGirl.create(:work_item, institution: institution, intellectual_object: intellectual_object, object_identifier: intellectual_object.identifier) }
        it do
          should_not permit(:create)
          should_not permit(:new)
          should permit(:show)
          should_not permit(:update)
          should_not permit(:edit)
          should_not permit(:destroy)
        end
      end

      describe 'not in my institution' do
        let(:work_item) { FactoryGirl.create(:work_item, institution: other_inst, intellectual_object: other_int_obj, object_identifier: other_int_obj.identifier)}
        it do
          should_not permit(:create)
          should_not permit(:new)
          should_not permit(:show)
          should_not permit(:update)
          should_not permit(:edit)
          should_not permit(:destroy)
        end
      end
    end
  end

  context 'for an authenticated user without a user group' do
    let(:user) { FactoryGirl.create(:user) }
    let(:work_item) { FactoryGirl.create(:work_item, institution: institution, intellectual_object: intellectual_object, object_identifier: intellectual_object.identifier)}
    it do
      should_not permit(:create)
      should_not permit(:new)
      should_not permit(:show)
      should_not permit(:update)
      should_not permit(:edit)
      should_not permit(:destroy)
    end
  end
end
