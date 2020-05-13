require 'spec_helper'

RSpec.describe StorageRecordsController, type: :controller do

  before :all do
    StorageRecord.delete_all
    GenericFile.delete_all
    IntellectualObject.delete_all
    User.delete_all
    Institution.delete_all
  end

  after do
    StorageRecord.delete_all
    Checksum.delete_all
    GenericFile.delete_all
    IntellectualObject.delete_all
    User.delete_all
    Institution.delete_all
  end

  let(:url) { 'https://example.com/file.txt' }
  let!(:institution_one) { FactoryBot.create(:member_institution) }
  let!(:institution_two) { FactoryBot.create(:subscription_institution) }
  let!(:admin_user) { FactoryBot.create(:user, :admin, institution: institution_one) }
  let!(:institutional_admin) { FactoryBot.create(:user, :institutional_admin, institution: institution_one) }
  let!(:admin) { FactoryBot.create(:user, :admin) }
  let!(:object_one) { FactoryBot.create(:intellectual_object, institution: institution_one) }
  let!(:object_two) { FactoryBot.create(:intellectual_object, institution: institution_two) }
  let!(:generic_file_one) { FactoryBot.create(:generic_file, intellectual_object: object_one) }
  let!(:generic_file_two) { FactoryBot.create(:generic_file, intellectual_object: object_two) }
  let!(:storage_record_one) { FactoryBot.create(:storage_record, generic_file: generic_file_one, url: 'https://example.com/preservation/sr1') }
  let!(:storage_record_two) { FactoryBot.create(:storage_record, generic_file: generic_file_one, url: 'https://example.com/preservation/sr2') }
  let!(:storage_record_three) { FactoryBot.create(:storage_record, generic_file: generic_file_two, url: 'https://example.com/preservation/sr3') }
  let!(:storage_record_four) { FactoryBot.create(:storage_record, generic_file: generic_file_two, url: 'https://example.com/preservation/sr4') }


  describe '#GET index' do
    describe 'for admin users' do
      before do
        sign_in admin_user
        session[:verified] = true
      end

      it 'filters by generic file identifier' do
        get :index, params: { generic_file_identifier: generic_file_one.identifier }, format: :json
        expect(response).to be_successful
        expect(assigns(:paged_results).size).to eq 2
        expect(assigns(:paged_results).map &:url).to match_array [storage_record_one.url, storage_record_two.url]
      end

    end

    describe 'for institutional admin users' do
      before do
        sign_in institutional_admin
        session[:verified] = true
      end

      it 'denies access' do
        get :index, params: { generic_file_identifier: generic_file_one.identifier }, format: :json
        expect(response.status).to eq(403)
      end
    end
  end

  describe '#POST create' do
    describe 'when not signed in' do
      it 'should redirect to login' do
        post :create, params: { generic_file_identifier: generic_file_one.identifier, url: url }, format: :json
        expect(response.status).to eq (401)
      end
    end

    describe 'for admin users' do
      before do
        sign_in admin_user
        session[:verified] = true
      end

      it 'allows sys admin to create a storage record' do
        post :create, params: { generic_file_identifier: generic_file_one.identifier, url: url }, format: :json
        expect(response.status).to eq (201)
        expect(assigns(:storage_record).url).to eq(url)
      end
    end

    describe 'for institutional admin users' do
      before do
        sign_in institutional_admin
        session[:verified] = true
      end

      it 'denies access' do
        post :create, params: { generic_file_identifier: generic_file_one.identifier }, format: :json
        expect(response.status).to eq(403)
      end
    end
  end

  describe '#DELETE destroy' do
    describe 'when not signed in' do
      it 'should redirect to login' do
        delete :destroy, params: { id: storage_record_one.id }, format: :json
        expect(response.status).to eq (401)
      end
    end

    describe 'for admin users' do
      before do
        sign_in admin_user
        session[:verified] = true
      end

      it 'allows sys admin to delete a storage record' do
        delete :destroy, params: { id: storage_record_one.id }, format: :json
        expect(response.status).to eq (204)
      end
    end

    describe 'for institutional admin users' do
      before do
        sign_in institutional_admin
        session[:verified] = true
      end

      it 'denies access' do
        delete :destroy, params: { id: storage_record_one.id }, format: :json
        expect(response.status).to eq(403)
      end
    end

  end


  # -- No further testing because no other routes are defined
  # -- for this controller.

end
