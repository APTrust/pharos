require 'spec_helper'

RSpec.describe WorkItemStatesController, type: :controller do

  after do
    User.delete_all
    IntellectualObject.delete_all
    WorkItemState.delete_all
    WorkItem.delete_all
    Institution.delete_all
  end

  let!(:institution) { FactoryBot.create(:member_institution) }
  let!(:admin_user) { FactoryBot.create(:user, :admin) }
  let!(:object) { FactoryBot.create(:intellectual_object, institution: institution, access: 'institution') }
  let!(:item) { FactoryBot.create(:work_item, institution: institution, intellectual_object: object, object_identifier: object.identifier, action: Pharos::Application::PHAROS_ACTIONS['fixity'], status: Pharos::Application::PHAROS_STATUSES['success']) }
  let!(:other_item) { FactoryBot.create(:work_item, institution: institution, intellectual_object: object, object_identifier: object.identifier) }
  let!(:lonely_item) { FactoryBot.create(:work_item, institution: institution, intellectual_object: object, object_identifier: object.identifier) }
  let!(:state_item) { FactoryBot.create(:work_item_state, work_item: item, state: '{JSON data}') }

  describe 'POST #create' do
    before do
      sign_in admin_user
      session[:verified] = true
    end

    it 'successfully creates the state item' do
      post :create, params: { work_item_state: { state: '{JSON data}', work_item_id: other_item.id, action: 'Success' } }, format: :json
      expect(response).to be_successful
      assigns(:state_item).action.should eq('Success')
      assigns(:state_item).state.bytes.should eq("x\x9C\xAB\xF6\n\xF6\xF7SHI,I\xAC\x05\x00\x16\x90\x03\xED".bytes)
      assigns(:state_item).unzipped_state.should eq('{JSON data}')
      assigns(:state_item).work_item_id.should eq(other_item.id)
    end
  end

  describe 'PUT #update' do
    describe 'for admin user' do
      before do
        sign_in admin_user
        session[:verified] = true
      end

      it 'responds successfully with both the action and the state updated' do
        put :update, params: { id: state_item.id, work_item_state: { action: 'NewAction', state: '{NEW JSON data}' } }, format: :json
        expect(response).to be_successful
        assigns(:work_item).id.should eq(item.id)
        assigns(:state_item).id.should eq(state_item.id)
        assigns(:state_item).action.should eq('NewAction')
        assigns(:state_item).state.bytes.should eq("x\x9C\xAB\xF6s\rW\xF0\n\xF6\xF7SHI,I\xAC\x05\x00%\xB9\x04\xF7".bytes)
        assigns(:state_item).unzipped_state.should eq('{NEW JSON data}')
      end
    end
  end

  describe 'GET #show' do
    describe 'for admin user' do
      before do
        sign_in admin_user
        session[:verified] = true
      end

      it 'responds successfully with both the work item and the state item set' do
        get :show, params: { id: state_item.id }, format: :json
        expect(response).to be_successful
        assigns(:work_item).id.should eq(item.id)
        assigns(:state_item).id.should eq(state_item.id)
        assigns(:state_item).state.bytes.should eq("x\x9C\xAB\xF6\n\xF6\xF7SHI,I\xAC\x05\x00\x16\x90\x03\xED".bytes)
        assigns(:state_item).unzipped_state.should eq('{JSON data}')
      end

      it 'responds with a 404 error if the state item does not exist' do
        get :show, params: { id: lonely_item.id }, format: :json
        expect(response.status).to eq(404)
      end
    end
  end

end
