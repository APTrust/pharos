require 'spec_helper'

describe InstitutionPolicy do
  subject (:institution_policy) { InstitutionPolicy.new(user, institution) }
  let(:institution) { FactoryBot.create(:member_institution) }
  let(:other_institution) { FactoryBot.create(:subscription_institution) }

  context 'for an admin user' do
    let(:user) { FactoryBot.create(:user, :admin, institution_id: institution.id) }
    describe 'access any institution' do
      it do
        should permit(:create)
        should permit(:new)
        should permit(:show)
        should permit(:update)
        should permit(:edit)
        should permit(:add_user)
        should permit(:deactivate)
        should permit(:reactivate)
        should_not permit(:destroy)
        should permit(:bulk_delete)
        should_not permit(:partial_confirmation_bulk_delete)
        should permit(:final_confirmation_bulk_delete)
        should permit(:finished_bulk_delete)
        #should permit(:destroy) #only turn this line on and above line off when deleting an institution. Otherwise, deletion should be OFF.
      end
    end

    describe "access an intellectual object's institution" do
      let(:intellectual_object) { FactoryBot.create(:intellectual_object) }
      let(:institution) { intellectual_object.institution}
      it { should permit(:add_user)}
    end
  end

  context 'for an institutional admin user' do
    describe 'when the institution is' do
      describe 'in my institution' do
        let(:user) { FactoryBot.create(:user, :institutional_admin, institution_id: institution.id) }
        it do
          should permit(:show)
          should_not permit(:create)
          should_not permit(:new)
          should permit(:update)
          should permit(:edit)
          should permit(:add_user)
          should_not permit(:destroy)
          should_not permit(:deactivate)
          should_not permit(:reactivate)
          should_not permit(:bulk_delete)
          should permit(:partial_confirmation_bulk_delete)
          should_not permit(:final_confirmation_bulk_delete)
          should_not permit(:finished_bulk_delete)
        end
      end

      describe 'not in my institution' do
        let(:user) { FactoryBot.create(:user, :institutional_admin, institution_id: other_institution.id) }
        it do
          should_not permit(:create)
          should_not permit(:new)
          should_not permit(:show)
          should_not permit(:update)
          should_not permit(:edit)
          should_not permit(:add_user)
          should_not permit(:destroy)
          should_not permit(:deactivate)
          should_not permit(:reactivate)
          should_not permit(:bulk_delete)
          should_not permit(:partial_confirmation_bulk_delete)
          should_not permit(:final_confirmation_bulk_delete)
          should_not permit(:finished_bulk_delete)
        end
      end
    end
  end

  context 'for an institutional user' do
    describe 'when the institution is' do
      describe 'in my institution' do
        let(:user) { FactoryBot.create(:user, :institutional_user,
                                        institution_id: institution.id) }
        it do
          should permit(:show)
          should_not permit(:create)
          should_not permit(:new)
          should_not permit(:update)
          should_not permit(:edit)
          should_not permit(:add_user)
          should_not permit(:destroy)
          should_not permit(:deactivate)
          should_not permit(:reactivate)
          should_not permit(:bulk_delete)
          should_not permit(:partial_confirmation_bulk_delete)
          should_not permit(:final_confirmation_bulk_delete)
          should_not permit(:finished_bulk_delete)
        end
      end

      describe 'not in my institution' do
        let(:user) { FactoryBot.create(:user, :institutional_user,
                                        institution_id: other_institution.id) }
        it do
          should_not permit(:create)
          should_not permit(:new)
          should_not permit(:show)
          should_not permit(:update)
          should_not permit(:edit)
          should_not permit(:add_user)
          should_not permit(:destroy)
          should_not permit(:deactivate)
          should_not permit(:reactivate)
          should_not permit(:bulk_delete)
          should_not permit(:partial_confirmation_bulk_delete)
          should_not permit(:final_confirmation_bulk_delete)
          should_not permit(:finished_bulk_delete)
        end
      end
    end
  end

  context 'for an authenticated user without a user group' do
    let(:user) { FactoryBot.create(:user) }
    it do
      should_not permit(:show)
      should_not permit(:create)
      should_not permit(:new)
      should_not permit(:update)
      should_not permit(:edit)
      should_not permit(:add_user)
      should_not permit(:destroy)
      should_not permit(:deactivate)
      should_not permit(:reactivate)
      should_not permit(:bulk_delete)
      should_not permit(:partial_confirmation_bulk_delete)
      should_not permit(:final_confirmation_bulk_delete)
      should_not permit(:finished_bulk_delete)
    end
  end
end
