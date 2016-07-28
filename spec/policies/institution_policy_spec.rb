require 'spec_helper'

describe InstitutionPolicy do
  subject (:institution_policy) { InstitutionPolicy.new(user, institution) }
  let(:institution) { FactoryGirl.create(:institution) }
  let(:other_institution) { FactoryGirl.create(:institution) }

  context 'for an admin user' do
    let(:user) { FactoryGirl.create(:user, :admin, institution_id: institution.id) }
    describe 'access any institution' do
      it do
        should permit(:create)
        should permit(:new)
        should permit(:show)
        should permit(:update)
        should permit(:edit)
        should permit(:add_user)
        should_not permit(:destroy)
      end
    end

    describe "access an intellectual object's institution" do
      let(:intellectual_object) { FactoryGirl.create(:intellectual_object) }
      let(:institution) { intellectual_object.institution}
      it { should permit(:add_user)}
    end
  end

  context 'for an institutional admin user' do
    describe 'when the institution is' do
      describe 'in my institution' do
        let(:user) { FactoryGirl.create(:user, :institutional_admin, institution_id: institution.id) }
        it do
          should permit(:show)
          should_not permit(:create)
          should_not permit(:new)
          should permit(:update)
          should permit(:edit)
          should permit(:add_user)
          should_not permit(:destroy)
        end
      end

      describe 'not in my institution' do
        let(:user) { FactoryGirl.create(:user, :institutional_admin, institution_id: other_institution.id) }
        it do
          should_not permit(:create)
          should_not permit(:new)
          should_not permit(:show)
          should_not permit(:update)
          should_not permit(:edit)
          should_not permit(:add_user)
          should_not permit(:destroy)
        end
      end
    end
  end

  context 'for an institutional user' do
    describe 'when the institution is' do
      describe 'in my institution' do
        let(:user) { FactoryGirl.create(:user, :institutional_user,
                                        institution_id: institution.id) }
        it do
          should permit(:show)
          should_not permit(:create)
          should_not permit(:new)
          should_not permit(:update)
          should_not permit(:edit)
          should_not permit(:add_user)
          should_not permit(:destroy)
        end
      end

      describe 'not in my institution' do
        let(:user) { FactoryGirl.create(:user, :institutional_user,
                                        institution_id: other_institution.id) }
        it do
          should_not permit(:create)
          should_not permit(:new)
          should_not permit(:show)
          should_not permit(:update)
          should_not permit(:edit)
          should_not permit(:add_user)
          should_not permit(:destroy)
        end
      end
    end
  end

  context 'for an authenticated user without a user group' do
    let(:user) { FactoryGirl.create(:user) }
    it do
      should_not permit(:show)
      should_not permit(:create)
      should_not permit(:new)
      should_not permit(:update)
      should_not permit(:edit)
      should_not permit(:add_user)
      should_not permit(:destroy)
    end
  end
end
