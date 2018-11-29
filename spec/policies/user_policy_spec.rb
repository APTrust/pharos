require 'spec_helper'

describe UserPolicy do
  subject (:user_policy) { UserPolicy.new(user, other_user) }
  let(:institution) { FactoryBot.create(:member_institution) }

  context 'for an admin user' do
    let(:user) { FactoryBot.create(:user, :admin, institution_id: institution.id) }
    describe 'when the user is any other user' do
      let(:other_user) { FactoryBot.create(:user) }
      it do
        should permit(:create)
        should permit(:new)
        should permit(:show)
        should permit(:update)
        should permit(:edit)
        should permit(:generate_api_key)
        should permit(:edit_password)
        should permit(:update_password)
        should permit(:destroy)
        should permit(:admin_password_reset)
        should permit(:deactivate)
        should permit(:reactivate)
      end
    end
    describe 'when the user is him/herself' do
      let(:other_user) { user }
      it do
        should permit(:generate_api_key)
        should permit(:admin_password_reset)
        should permit(:deactivate)
        should permit(:reactivate)
      end
    end
  end

  context 'for an institutional admin user' do
    let(:user) { FactoryBot.create(:user, :institutional_admin, institution_id: institution.id ) }
    describe 'when the user is any other user ' do
      describe 'in my institution' do
        let(:other_user) { FactoryBot.create(:user, institution_id: institution.id) }
        it do
          should permit(:create)
          should permit(:new)
          should permit(:show)
          should permit(:update)
          should permit(:edit)
          should_not permit(:generate_api_key)
          should_not permit(:edit_password)
          should_not permit(:update_password)
          should permit(:destroy)
          should_not permit(:admin_password_reset)
          should permit(:deactivate)
          should permit(:reactivate)
        end
      end

      describe 'not in my institution' do
        let(:other_user) { FactoryBot.create(:user) }
        it do
          should_not permit(:show)
          should_not permit(:update)
          should_not permit(:edit)
          should_not permit(:generate_api_key)
          should_not permit(:edit_password)
          should_not permit(:update_password)
          should_not permit(:destroy)
          should_not permit(:admin_password_reset)
          should_not permit(:deactivate)
          should_not permit(:reactivate)
        end
      end
    end
    describe 'when the user is him/herself' do
      let(:other_user) { user }
      it do
        should permit(:generate_api_key)
        should_not permit(:admin_password_reset)
        should permit(:deactivate)
        should permit(:reactivate)
      end
    end
  end

  context 'for an institutional user' do
    let(:user) { FactoryBot.create(:user, :institutional_user, institution_id: institution.id) }
    describe 'when the user is' do
      describe 'in my institution' do
        let(:other_user) { FactoryBot.create(:user, institution_id: institution.id) }
        it do
          should_not permit(:create)
          should_not permit(:new)
          should_not permit(:show)
          should_not permit(:update)
          should_not permit(:edit)
          should_not permit(:generate_api_key)
          should_not permit(:edit_password)
          should_not permit(:update_password)
          should_not permit(:destroy)
          should_not permit(:admin_password_reset)
          should_not permit(:deactivate)
          should_not permit(:reactivate)
        end
      end

      describe 'not in my institution' do
        let(:other_user) { FactoryBot.create(:user) }
        it do
          should_not permit(:show)
          should_not permit(:update)
          should_not permit(:edit)
          should_not permit(:generate_api_key)
          should_not permit(:edit_password)
          should_not permit(:update_password)
          should_not permit(:destroy)
          should_not permit(:admin_password_reset)
          should_not permit(:deactivate)
          should_not permit(:reactivate)
        end
      end

      describe 'him/herself' do
        let(:other_user) { user }
        it do
          should permit(:show)
          should permit(:update)
          should permit(:edit)
          should permit(:generate_api_key)
          should permit(:edit_password)
          should permit(:update_password)
          should_not permit(:destroy)
          should_not permit(:admin_password_reset)
          should_not permit(:deactivate)
          should_not permit(:reactivate)
        end
      end
    end
  end

  context 'for an authenticated user without a user group' do
    let(:user) { FactoryBot.create(:user) }
    let(:other_user) { FactoryBot.create(:user, :institutional_user, institution_id: institution.id) }
    it do
      should_not permit(:create)
      should_not permit(:new)
      should_not permit(:show)
      should_not permit(:update)
      should_not permit(:edit)
      should_not permit(:generate_api_key)
      should_not permit(:destroy)
      should_not permit(:admin_password_reset)
      should_not permit(:deactivate)
      should_not permit(:reactivate)
    end
  end
end