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
  let!(:institution_two) { FactoryGirl.create(:institution) }
  let!(:admin_user) { FactoryGirl.create(:user, :admin, institution: institution_one) }
  let!(:institutional_admin) { FactoryGirl.create(:user, :institutional_admin, institution: institution_one) }
  let!(:admin) { FactoryGirl.create(:user, :admin) }
  let!(:object_one) { FactoryGirl.create(:intellectual_object, institution: institution_one) }
  let!(:object_two) { FactoryGirl.create(:intellectual_object, institution: institution_two) }
  let!(:generic_file_one) { FactoryGirl.create(:generic_file, intellectual_object: object_one) }
  let!(:generic_file_two) { FactoryGirl.create(:generic_file, intellectual_object: object_two) }
  let!(:checksum_one) { FactoryGirl.create(:checksum, generic_file: generic_file_one, algorithm: 'sha256', digest: '87654321') }
  let!(:checksum_two) { FactoryGirl.create(:checksum, generic_file: generic_file_two, algorithm: 'md5', digest: '12345678') }

  describe '#GET index' do
    describe 'for admin users' do
      before do
        sign_in admin_user
      end

      it 'returns successfully when no parameters are given' do
        get :index, format: :json
        expect(response).to be_success
        expect(assigns(:paged_results).size).to eq 2
      end

      it 'filters by generic file identifier' do
        get :index, generic_file_identifier: generic_file_one.identifier, format: :json
        expect(response).to be_success
        expect(assigns(:paged_results).size).to eq 1
        expect(assigns(:paged_results).map &:id).to match_array [checksum_one.id]
      end

      it 'filters by algorithm' do
        get :index, algorithm: 'md5', format: :json
        expect(response).to be_success
        expect(assigns(:paged_results).size).to eq 1
        expect(assigns(:paged_results).map &:id).to match_array [checksum_two.id]
      end

      it 'filters by digest' do
        get :index, digest: '12345678', format: :json
        expect(response).to be_success
        expect(assigns(:paged_results).size).to eq 1
        expect(assigns(:paged_results).map &:id).to match_array [checksum_two.id]
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

  describe 'POST create' do
    describe 'when not signed in' do
      it 'should redirect to login' do
        post :create, generic_file_identifier: generic_file_one.identifier, checksum: { algorithm: 'md5' }, format: :json
        expect(response.status).to eq (401)
      end
    end

    describe 'when signed in' do
      before { sign_in institutional_admin }
      it 'should be forbidden when the file belongs to your institution' do
        post :create, generic_file_identifier: generic_file_one.identifier, checksum: { algorithm: 'md5', datetime: Time.now, digest: '1234567890' }, format: :json
        expect(response.status).to eq (403)
      end

      it 'should be forbidden when the file does not belong to your institution' do
        post :create, generic_file_identifier: generic_file_two.identifier, checksum: { algorithm: 'md5', datetime: Time.now, digest: '1234567890' }, format: :json
        expect(response.status).to eq (403)
      end
    end

    describe 'when signed in as admin' do
      before { sign_in admin }
      it 'should be successful' do
        post :create, generic_file_identifier: generic_file_one.identifier, checksum: { algorithm: 'md5', datetime: Time.now, digest: '1234567890' }, format: :json
        expect(response.status).to eq (201)
        expect(assigns(:checksum).algorithm).to eq('md5')
      end

      it 'should show errors' do
        post :create, generic_file_identifier: generic_file_one.identifier, checksum: { algorithm: 'md5' }, format: :json
        expect(response.status).to eq (422)
        # we should test for algorithm errors too but the checksum param can't be blank and there are only
        # three allowed attributes, all of which are required
        expect(JSON.parse(response.body)).to eq( {
                                                     'datetime' => ["can't be blank"],
                                                     'digest' => ["can't be blank"]})
      end
    end

  end

end
