require 'spec_helper'

RSpec.describe ReportsController, type: :controller do
  before :all do
    Institution.destroy_all
    IntellectualObject.destroy_all
    GenericFile.destroy_all
  end

  after do
    Institution.destroy_all
    IntellectualObject.destroy_all
    GenericFile.destroy_all
  end

  let(:institution_one) { FactoryGirl.create(:institution) }
  let(:institution_two) { FactoryGirl.create(:institution) }
  let(:admin_user) { FactoryGirl.create(:user, :admin, institution: institution_one) }
  let(:institutional_user) { FactoryGirl.create(:user, :institutional_user, institution: institution_two) }
  let(:institutional_admin) { FactoryGirl.create(:user, :institutional_admin, institution: institution_two) }
  let(:intellectual_object_one) { FactoryGirl.create(:intellectual_object, institution: institution_one) }
  let(:intellectual_object_two) { FactoryGirl.create(:intellectual_object, institution: institution_two) }
  let(:generic_file_one) { FactoryGirl.create(:generic_file, intellectual_object: intellectual_object_one) }
  let(:generic_file_two) { FactoryGirl.create(:generic_file, intellectual_object: intellectual_object_two) }

  describe 'GET #index' do
    describe 'for admin users' do
      before do
        sign_in admin_user
      end

      it 'responds successfully with an HTTP 200 status code for own institution' do
        get :index, identifier: institution_one.identifier
        expect(response).to be_success
      end

      it 'responds successfully with an HTTP 200 status code for another institution' do
        get :index, identifier: institution_two.identifier
        expect(response).to be_success
      end
    end

    describe 'for institutional admin users' do
      before do
        sign_in institutional_admin
      end

      it 'responds successfully with an HTTP 200 status code for own institution' do
        get :index, identifier: institution_two.identifier
        expect(response).to be_success
      end

      it 'denies access when the institution is not their own (html)' do
        get :index, identifier: institution_one.identifier
        expect(response.status).to eq(302)
        flash[:alert].should =~ /You are not authorized/
      end

      it 'denies access when the institution is not their own (json)' do
        get :index, identifier: institution_one.identifier, format: :json
        expect(response.status).to eq(403)
      end
    end

  end

end
