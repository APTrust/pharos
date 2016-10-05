require 'spec_helper'

describe IntellectualObjectPolicy do

  subject (:intellectual_object_policy) { IntellectualObjectPolicy.new(user, intellectual_object) }
  let(:institution) { FactoryGirl.create(:institution) }

  context 'for an admin user' do
    let(:user) { FactoryGirl.create(:user, :admin, institution_id: institution.id) }
    let(:intellectual_object) { FactoryGirl.create(:intellectual_object) }
    it do
      should permit(:show)
      should permit(:update)
      should_not permit(:edit)
      should permit(:add_event)
      should permit(:soft_delete)
      should permit(:destroy)
    end
  end

  context 'for an institutional admin user' do
    let(:user) { FactoryGirl.create(:user, :institutional_admin,
                                    institution_id: institution.id) }
    describe 'when the object is' do
      describe 'in my institution' do
        let(:intellectual_object) { FactoryGirl.create(:intellectual_object, institution: institution) }
        it do
          should permit(:show)
          should_not permit(:update)
          should_not permit(:edit)
          should_not permit(:add_event)
          should permit(:soft_delete)
          should permit(:destroy)
        end
      end

      describe 'not in my institution' do
        describe 'with consortial access' do
          let(:intellectual_object) { FactoryGirl.create(:consortial_intellectual_object) }
          it do
            should permit(:show)
            should_not permit(:update)
            should_not permit(:edit)
            should_not permit(:add_event)
            should_not permit(:soft_delete)
            should_not permit(:destroy)
          end
        end

        describe 'without consortial access' do
          let(:intellectual_object) { FactoryGirl.create(:restricted_intellectual_object) }
          it do
            should_not permit(:show)
            should_not permit(:update)
            should_not permit(:edit)
            should_not permit(:add_event)
            should_not permit(:soft_delete)
            should_not permit(:destroy)
          end
        end
      end
    end
  end

  context 'for an institutional user' do
    let(:user) { FactoryGirl.create(:user, :institutional_user,
                                    institution_id: institution.id) }
    describe 'when the object is' do
      describe 'in my institution' do
        describe 'and is consortial accessible' do
          let(:intellectual_object) { FactoryGirl.create(:consortial_intellectual_object,
                                                         institution: institution) }
          it do
            should_not permit(:update)
            should_not permit(:edit)
            should_not permit(:add_event)
            should_not permit(:soft_delete)
            should_not permit(:destroy)
            should permit(:show)
          end
        end
        describe 'and is institutional accessible' do
          let(:intellectual_object) { FactoryGirl.create(:institutional_intellectual_object,
                                                         institution: institution) }
          it { should permit(:show) }
        end
        describe 'and is restricted accessible' do
          let(:intellectual_object) { FactoryGirl.create(:restricted_intellectual_object,
                                                         institution: institution) }
          it { should_not permit(:show) }
        end
      end

      describe 'not in my institution' do
        describe 'and it belongs to a consortial accessible object' do
          let(:intellectual_object) { FactoryGirl.create(:consortial_intellectual_object) }
          it do
            should_not permit(:update)
            should_not permit(:edit)
            should_not permit(:add_event)
            should_not permit(:soft_delete)
            should_not permit(:destroy)
            should permit(:show)
          end
        end
        describe 'and it belongs to an institutional accessible object' do
          let(:intellectual_object) { FactoryGirl.create(:institutional_intellectual_object) }
          it { should_not permit(:show) }
        end
        describe 'and is it belongs to a restricted accessible object' do
          let(:intellectual_object) { FactoryGirl.create(:restricted_intellectual_object) }
          it { should_not permit(:show) }
        end
      end
    end
  end

  context 'for an authenticated user without a user group' do
    let(:user) { FactoryGirl.create(:user) }
    let(:intellectual_object) { FactoryGirl.create(:intellectual_object) }
    it do
      should_not permit(:show)
      should_not permit(:update)
      should_not permit(:edit)
      should_not permit(:add_event)
      should_not permit(:soft_delete)
      should_not permit(:destroy)
    end
  end
end