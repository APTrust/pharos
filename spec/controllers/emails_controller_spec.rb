require 'spec_helper'

RSpec.describe EmailsController, type: :controller do

  before :all do
    Email.delete_all
  end

  after do
    Email.delete_all
  end

  let!(:email_one) { FactoryGirl.create(:fixity_email) }
  let!(:email_two) { FactoryGirl.create(:restoration_email) }
  let!(:admin_user) { FactoryGirl.create(:user, :admin) }
  let!(:institutional_admin) { FactoryGirl.create(:user, :institutional_admin) }

  describe '#GET index' do
    describe 'for admin users' do
      before do
        sign_in admin_user
      end

      it 'returns successfully all emails' do
        get :index, format: :json
        expect(response).to be_success
        expect(assigns(:emails).size).to eq 2
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

  describe '#GET show' do
    describe 'for admin users' do
      before do
        sign_in admin_user
      end

      it 'returns successfully the requested email' do
        get :show, params: { id: email_one.id }, format: :json
        expect(response).to be_success
        expect(assigns(:email).email_type).to eq 'fixity'
      end
    end

    describe 'for institutional admin users' do
      before do
        sign_in institutional_admin
      end

      it 'denies access' do
        get :show, params: { id: email_one.id }, format: :json
        expect(response.status).to eq(403)
      end
    end

  end

end
