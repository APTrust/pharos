require 'spec_helper'

RSpec.describe ChecksumsController, type: :controller do

  before :all do
    Checksum.delete_all
    GenericFile.delete_all
    IntellectualObject.delete_all
    User.delete_all
    Institution.delete_all
  end

  after do
    Checksum.delete_all
    GenericFile.delete_all
    IntellectualObject.delete_all
    User.delete_all
    Institution.delete_all
  end

  let!(:institution_one) { FactoryBot.create(:member_institution) }
  let!(:institution_two) { FactoryBot.create(:subscription_institution) }
  let!(:admin_user) { FactoryBot.create(:user, :admin, institution: institution_one) }
  let!(:institutional_admin) { FactoryBot.create(:user, :institutional_admin, institution: institution_one) }
  let!(:admin) { FactoryBot.create(:user, :admin) }
  let!(:object_one) { FactoryBot.create(:intellectual_object, institution: institution_one) }
  let!(:object_two) { FactoryBot.create(:intellectual_object, institution: institution_two) }
  let!(:generic_file_one) { FactoryBot.create(:generic_file, intellectual_object: object_one) }
  let!(:generic_file_two) { FactoryBot.create(:generic_file, intellectual_object: object_two) }
  let!(:checksum_one) { FactoryBot.create(:checksum, generic_file: generic_file_one, algorithm: 'sha256', digest: '87654321') }
  let!(:checksum_two) { FactoryBot.create(:checksum, generic_file: generic_file_two, algorithm: 'md5', digest: '12345678') }

  describe '#GET index' do
    describe 'for admin users' do
      before do
        sign_in admin_user
        session[:verified] = true
      end

      it 'returns successfully when no parameters are given' do
        get :index, format: :json
        expect(response).to be_successful
        expect(assigns(:paged_results).size).to eq 2
      end

      it 'filters by generic file identifier' do
        get :index, params: { generic_file_identifier: generic_file_one.identifier }, format: :json
        expect(response).to be_successful
        expect(assigns(:paged_results).size).to eq 1
        expect(assigns(:paged_results).map &:id).to match_array [checksum_one.id]
      end

      it 'filters by algorithm' do
        get :index, params: { algorithm: 'md5' }, format: :json
        expect(response).to be_successful
        expect(assigns(:paged_results).size).to eq 1
        expect(assigns(:paged_results).map &:id).to match_array [checksum_two.id]
      end

      it 'filters by digest' do
        get :index, params: { digest: '12345678' }, format: :json
        expect(response).to be_successful
        expect(assigns(:paged_results).size).to eq 1
        expect(assigns(:paged_results).map &:id).to match_array [checksum_two.id]
      end
    end

    describe 'for institutional admin users' do
      before do
        sign_in institutional_admin
        session[:verified] = true
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
        post :create, params: { generic_file_identifier: generic_file_one.identifier, checksum: { algorithm: 'md5' } }, format: :json
        expect(response.status).to eq (401)
      end
    end

    describe 'when signed in' do
      before do
        sign_in institutional_admin
        session[:verified] = true
      end
      it 'should be forbidden when the file belongs to your institution' do
        post :create, params: { generic_file_identifier: generic_file_one.identifier, checksum: { algorithm: 'md5', datetime: Time.now, digest: '1234567890' } }, format: :json
        expect(response.status).to eq (403)
      end

      it 'should be forbidden when the file does not belong to your institution' do
        post :create, params: { generic_file_identifier: generic_file_two.identifier, checksum: { algorithm: 'md5', datetime: Time.now, digest: '1234567890' } }, format: :json
        expect(response.status).to eq (403)
      end
    end

    describe 'when signed in as admin' do
      before do
        sign_in admin
        session[:verified] = true
      end
      it 'should be successful' do
        post :create, params: { generic_file_identifier: generic_file_one.identifier, checksum: { algorithm: 'md5', datetime: Time.now, digest: '1234567890' } }, format: :json
        expect(response.status).to eq (201)
        expect(assigns(:checksum).algorithm).to eq('md5')
      end

      it 'should show errors' do
        post :create, params: { generic_file_identifier: generic_file_one.identifier, checksum: { algorithm: 'md5' } }, format: :json
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
