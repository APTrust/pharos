require 'spec_helper'

describe GenericFilePolicy do
  subject (:generic_file_policy) { GenericFilePolicy.new(user, generic_file) }
  let(:institution) { FactoryBot.create(:member_institution) }

  context 'for an admin user' do
    let(:user) { FactoryBot.create(:user, :admin, institution_id: institution.id) }
    let(:generic_file) { FactoryBot.build(:generic_file)}

    it 'access any generic file' do
      should permit(:add_event)
      should permit(:show)
      should permit(:show)
      should permit(:update)
      should_not permit(:edit)
      should permit(:soft_delete)
      should permit(:destroy)
      should permit(:finished_destroy)
    end
  end

  context 'for an institutional admin user' do
    let(:user) { FactoryBot.create(:user, :institutional_admin,
                                    institution_id: institution.id) }
    context 'access file in my institution' do
      let(:intellectual_object) { FactoryBot.create(:intellectual_object, institution: institution) }
      let(:generic_file) { FactoryBot.create(:generic_file, intellectual_object: intellectual_object) }

      it do
        should permit(:show)
        should permit(:soft_delete)
        should_not permit(:add_event)
        should_not permit(:update)
        should_not permit(:edit)
        should permit(:destroy)
        should_not permit(:finished_destroy)
      end
    end

    context 'access file not in my institution' do
      context 'with consortial access' do
        let(:intellectual_object) { FactoryBot.create(:consortial_intellectual_object) }
        let(:generic_file) { FactoryBot.create(:generic_file, intellectual_object: intellectual_object) }
        it do
          should_not permit(:add_event)
          should permit(:show)
          should_not permit(:update)
          should_not permit(:edit)
          should_not permit(:soft_delete)
          should_not permit(:destroy)
          should_not permit(:finished_destroy)
        end
      end

      context 'without consortial access' do
        let(:intellectual_object) { FactoryBot.create(:restricted_intellectual_object) }
        let(:generic_file) { FactoryBot.create(:generic_file, intellectual_object: intellectual_object) }
        it do
          should_not permit(:add_event)
          should_not permit(:show)
          should_not permit(:update)
          should_not permit(:edit)
          should_not permit(:soft_delete)
          should_not permit(:destroy)
          should_not permit(:finished_destroy)
        end
      end
    end
  end

  context 'for an institutional user' do
    let(:user) { FactoryBot.create(:user, :institutional_user,
                                    institution_id: institution.id) }
    describe 'when the file is' do
      describe 'in my institution' do
        describe 'and it belongs to a consortial accessible object' do
          let(:intellectual_object) { FactoryBot.create(:consortial_intellectual_object, institution: institution) }
          let(:generic_file) { FactoryBot.create(:generic_file, intellectual_object: intellectual_object) }
          it do
            should_not permit(:add_event)
            should_not permit(:update)
            should_not permit(:edit)
            should_not permit(:soft_delete)
            should_not permit(:destroy)
            should permit(:show)
            should_not permit(:finished_destroy)
          end
        end
        describe 'and it belongs to an institutional accessible object' do
          let(:intellectual_object) { FactoryBot.create(:institutional_intellectual_object,
                                                         institution: institution) }
          let(:generic_file) { FactoryBot.create(:generic_file, intellectual_object: intellectual_object) }

          it { should permit(:show) }
        end
        describe 'and is it belongs to a restricted accessible object' do
          let(:intellectual_object) { FactoryBot.create(:restricted_intellectual_object,
                                                         institution: institution) }
          let(:generic_file) { FactoryBot.create(:generic_file, intellectual_object: intellectual_object) }

          it { should_not permit(:show) }
        end
      end

      describe 'not in my institution' do
        describe 'and it belongs to a consortial accessible object' do
          let(:intellectual_object) { FactoryBot.create(:consortial_intellectual_object) }
          let(:generic_file) { FactoryBot.create(:generic_file, intellectual_object: intellectual_object) }
          it do
            should_not permit(:add_event)
            should_not permit(:update)
            should_not permit(:edit)
            should_not permit(:soft_delete)
            should_not permit(:destroy)
            should permit(:show)
            should_not permit(:finished_destroy)
          end
        end
        describe 'and it belongs to an institutional accessible object' do
          let(:intellectual_object) { FactoryBot.create(:institutional_intellectual_object) }
          let(:generic_file) { FactoryBot.create(:generic_file, intellectual_object: intellectual_object) }

          it { should_not permit(:show) }
        end
        describe 'and is it belongs to a restricted accessible object' do
          let(:intellectual_object) { FactoryBot.create(:restricted_intellectual_object) }
          let(:generic_file) { FactoryBot.create(:generic_file, intellectual_object: intellectual_object) }

          it { should_not permit(:show) }
        end
      end
    end
  end

  context 'with an authenticated user without a user group' do
    let(:user) { FactoryBot.build(:user) }
    let(:generic_file) { FactoryBot.build(:generic_file)}

    it do
      should_not permit(:show)
      should_not permit(:update)
      should_not permit(:edit)
      should_not permit(:add_event)
      should_not permit(:soft_delete)
      should_not permit(:destroy)
      should_not permit(:finished_destroy)
    end
  end
end
