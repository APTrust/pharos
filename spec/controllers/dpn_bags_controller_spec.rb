require 'spec_helper'

RSpec.describe DpnBagsController, type: :controller do

  before :all do
    DpnBag.delete_all
    User.delete_all
    Institution.delete_all
  end

  after do
    DpnBag.delete_all
    User.delete_all
    Institution.delete_all
  end

  let!(:institution_one) { FactoryBot.create(:member_institution) }
  let!(:institution_two) { FactoryBot.create(:member_institution) }
  let!(:admin_user) { FactoryBot.create(:user, :admin, institution_id: institution_one.id) }
  let!(:institutional_admin) { FactoryBot.create(:user, :institutional_admin, institution_id: institution_two.id) }
  let!(:bag_one) { FactoryBot.create(:dpn_bag, institution_id: institution_one.id, object_identifier: '1234', dpn_created_at: '2018-01-20 04:59:08 -0500', dpn_updated_at: '2018-01-20 04:59:08 -0500') }
  let!(:bag_two) { FactoryBot.create(:dpn_bag, institution_id: institution_one.id, dpn_created_at: '2018-01-19 01:59:41 -0500', dpn_updated_at: '2018-01-19 01:59:41 -0500') }
  let!(:bag_three) { FactoryBot.create(:dpn_bag, institution_id: institution_two.id, dpn_created_at: '2018-01-15 23:00:00 -0500', dpn_updated_at: '2018-01-15 23:00:00 -0500') }
  let!(:bag_four) { FactoryBot.create(:dpn_bag, institution_id: institution_two.id, dpn_created_at: '2018-01-16 20:00:19 -0500', dpn_updated_at: '2018-01-16 20:00:19 -0500') }

  describe '#GET index' do
    describe 'for admin users' do
      before do
        sign_in admin_user
        session[:verified] = true
      end

      it 'returns successfully when no parameters are given' do
        get :index, format: :json
        expect(response).to be_successful
        expect(assigns(:paged_results).size).to eq 4
      end

      it 'filters by identifier' do
        get :index, params: { object_identifier: '1234' }, format: :json
        expect(response).to be_successful
        expect(assigns(:paged_results).size).to eq 1
        expect(assigns(:paged_results).map &:id).to match_array [bag_one.id]
      end

      it 'filters by created_before' do
        get :index, params: { created_before: '2018-01-18 01:00:37 -0500' }, format: :json
        expect(response).to be_successful
        expect(assigns(:paged_results).size).to eq 2
        expect(assigns(:paged_results).map &:id).to match_array [bag_three.id, bag_four.id]
      end

      it 'filters by created_after' do
        get :index, params: { created_after: '2018-01-18 01:00:37 -0500' }, format: :json
        expect(response).to be_successful
        expect(assigns(:paged_results).size).to eq 2
        expect(assigns(:paged_results).map &:id).to match_array [bag_one.id, bag_two.id]
      end

      it 'filters by updated_before' do
        get :index, params: { updated_before: '2018-01-18 01:00:37 -0500' }
        expect(response).to be_successful
        expect(assigns(:paged_results).size).to eq 2
        expect(assigns(:paged_results).map &:id).to match_array [bag_three.id, bag_four.id]
      end

      it 'filters by updated_after' do
        get :index, params: { updated_after: '2018-01-18 01:00:37 -0500' }
        expect(response).to be_successful
        expect(assigns(:paged_results).size).to eq 2
        expect(assigns(:paged_results).map &:id).to match_array [bag_one.id, bag_two.id]
      end
    end

    describe 'for institutional admin users' do
      before do
        sign_in institutional_admin
        session[:verified] = true
      end

      it "allows access only to bags belonging to the user's institution" do
        get :index, format: :json
        expect(response).to be_successful
        expect(assigns(:paged_results).size).to eq 2
      end
    end

  end

  describe 'POST #create' do
    before do
      sign_in admin_user
      session[:verified] = true
    end

    it 'successfully creates the dpn item' do
      post :create, params: { dpn_bag: { institution_id: institution_two.id, object_identifier: 'test.edu/1234', dpn_identifier: '1234387', dpn_size: 1249784, node_1: 'chron', node_2: 'aptrust', node_3: 'hathi', dpn_created_at: '2018-01-16 20:00:19 -0500', dpn_updated_at: '2018-01-16 20:00:19 -0500' } }, format: :json
      expect(response).to be_successful
      assigns(:dpn_bag).institution_id.should eq(institution_two.id)
      assigns(:dpn_bag).object_identifier.should eq('test.edu/1234')
      assigns(:dpn_bag).dpn_identifier.should eq('1234387')
      assigns(:dpn_bag).dpn_size.should eq(1249784)
      assigns(:dpn_bag).node_1.should eq('chron')
      assigns(:dpn_bag).node_2.should eq('aptrust')
      assigns(:dpn_bag).node_3.should eq('hathi')
      assigns(:dpn_bag).dpn_created_at.should eq('2018-01-16 20:00:19 -0500')
      assigns(:dpn_bag).dpn_updated_at.should eq('2018-01-16 20:00:19 -0500')
    end

    describe 'for institutional admin users' do
      before do
        sign_in institutional_admin
        session[:verified] = true
      end

      it 'denies access' do
        post :create, params: { dpn_bag: { institution_id: institution_two.id, object_identifier: 'test.edu/1234', dpn_identifier: 1234387, dpn_size: 1249784, node_1: 'chron', node_2: 'aptrust', node_3: 'hathi', dpn_created_at: Time.now, dpn_updated_at: Time.now } }, format: :json
        expect(response.status).to eq(403)
      end
    end
  end

  describe 'PUT #update' do
    describe 'for admin user' do
      before do
        sign_in admin_user
        session[:verified] = true
      end

      it 'responds successfully' do
        put :update, params: { id: bag_one.id, dpn_bag: { node_1: 'new_node', dpn_size: 1235823945 } }, format: :json
        expect(response).to be_successful
        assigns(:dpn_bag).id.should eq(bag_one.id)
        assigns(:dpn_bag).node_1.should eq('new_node')
        assigns(:dpn_bag).dpn_size.should eq(1235823945)
      end

      it 'responds with a 404 error if the dpn item does not exist' do
        put :update, params: { id: '2345336', dpn_bag: { node_3: 'Testing the update method'} }, format: :json
        expect(response.status).to eq(404)
      end
    end

    describe 'for institutional admin users' do
      before do
        sign_in institutional_admin
        session[:verified] = true
      end

      it 'denies access' do
        put :update, params: { id: bag_three.id, dpn_bag: { node_3: 'Testing the update method'} }, format: :json
        expect(response.status).to eq(403)
      end
    end
  end

  describe 'GET #show' do
    describe 'for admin user' do
      before do
        sign_in admin_user
        session[:verified] = true
      end

      it 'responds successfully' do
        get :show, params: { id: bag_two.id }, format: :json
        expect(response).to be_successful
      end

      it 'responds with a 404 error if the dpn item does not exist' do
        get :show, params: { id: '2345336' }, format: :json
        expect(response.status).to eq(404)
      end
    end

    describe 'for institutional admin users' do
      before do
        sign_in institutional_admin
        session[:verified] = true
      end

      it 'denies access to a bag belonging to another institution' do
        get :show, params: { id: bag_one.id }, format: :json
        expect(response.status).to eq(403)
      end

      it 'allows access to a bag belonging to own institution' do
        get :show, params: { id: bag_three.id }, format: :json
        expect(response).to be_successful
      end
    end
  end


end
