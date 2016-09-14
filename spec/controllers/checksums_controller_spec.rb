require 'spec_helper'

RSpec.describe ChecksumsController, type: :controller do

  before :all do
    Institution.destroy_all
    GenericFile.destroy_all
    Checksum.destroy_all
  end

  after do
    Institution.destroy_all
    GenericFile.destroy_all
    Checksum.destroy_all
  end

  let!(:institution_one) { FactoryGirl.create(:institution) }
  let!(:admin_user) { FactoryGirl.create(:user, :admin, institution: institution_one) }
  let!(:institutional_admin) { FactoryGirl.create(:user, :institutional_admin, institution: institution_one) }
  let!(:generic_file_one) { FactoryGirl.create(:generic_file) }
  let!(:generic_file_two) { FactoryGirl.create(:generic_file) }
  let!(:checksum_one) { FactoryGirl.create(:checksum, generic_file: generic_file_one, algorithm: 'sha256') }
  let!(:checksum_two) { FactoryGirl.create(:checksum, generic_file: generic_file_two, algorithm: 'sha256') }

  describe '#GET index' do
    describe 'for admin users' do
      before do
        sign_in admin_user
      end

      it 'returns successfully when no parameters are given' do
        get :index, format: :json
        expect(response).to be_success
        expect(assigns(:paged_results).size).to eq 4
      end

      it 'filters by generic file identifier' do
        get :index, generic_file_identifier: generic_file_one.identifier, format: :json
        expect(response).to be_success
        expect(assigns(:paged_results).size).to eq 2
        expect(assigns(:paged_results).map &:id).to include(checksum_one.id)
        expect(assigns(:paged_results).map &:id).not_to include(checksum_two.id)
      end

      it 'filters by algorithm' do
        get :index, algorithm: 'sha256', format: :json
        expect(response).to be_success
        expect(assigns(:paged_results).size).to eq 2
        expect(assigns(:paged_results).map &:id).to match_array [checksum_one.id, checksum_two.id]
      end
    end

    describe 'for institutional admin users' do
      before do
        sign_in institutional_admin
      end

      it 'denies access' do
        get :index, format: :json
        expect(response.status).to eq(403)
      end
    end

  end

end
