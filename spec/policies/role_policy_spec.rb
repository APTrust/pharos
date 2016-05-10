require 'spec_helper'

describe RolePolicy do

  let(:institution) { FactoryGirl.create(:institution) }
  subject (:role_policy) { RolePolicy.new(user, role) }

  context 'for an admin user' do
    let(:user) { FactoryGirl.create(:user, :admin, institution_id: institution.id )}

    describe 'with admin role' do
      let(:role) { Role.where(name: 'admin').first }
      it { should permit(:add_user) }
    end

    describe 'with institutional_admin role' do
      let(:role) { Role.where(name: 'institutional_admin').first }
      it { should permit(:add_user) }
    end

    describe 'with institutional_user role' do
      let(:role) { Role.where(name: 'institutional_user').first }
      it { should permit(:add_user) }
    end
  end

  context 'for an institutional admin user' do
    let(:user) { FactoryGirl.create(:user, :institutional_admin, institution_id: institution.id )}

    describe 'with admin role' do
      let(:role) { Role.where(name: 'admin').first }
      it { should_not permit(:add_user) }
    end

    describe 'with institutional_admin role' do
      let(:role) { Role.where(name: 'institutional_admin').first }
      it { should permit(:add_user) }
    end

    describe 'with institutional_user role' do
      let(:role) { Role.where(name: 'institutional_user').first }
      it { should permit(:add_user) }
    end
  end

  context 'for an institutional user' do
    let(:user) { FactoryGirl.create(:user, :institutional_user, institution_id: institution.id )}
    describe 'with admin role' do
      let(:role) { Role.where(name: 'admin').first }
      it { should_not permit(:add_user) }
    end

    describe 'with institutional_admin role' do
      let(:role) { Role.where(name: 'institutional_admin').first }
      it { should_not permit(:add_user) }
    end

    describe 'with institutional_user role' do
      let(:role) { Role.where(name: 'institutional_user').first }
      it { should_not permit(:add_user) }
    end
  end

  context 'for an authenticated user without a user group' do
    let(:user) { FactoryGirl.create(:user) }
    describe 'with admin role' do
      let(:role) { Role.where(name: 'admin').first }
      it { should_not permit(:add_user) }
    end

    describe 'with institutional_admin role' do
      let(:role) { Role.where(name: 'institutional_admin').first }
      it { should_not permit(:add_user) }
    end

    describe 'with institutional_user role' do
      let(:role) { Role.where(name: 'institutional_user').first }
      it { should_not permit(:add_user) }
    end
  end
end