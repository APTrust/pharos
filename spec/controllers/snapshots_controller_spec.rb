require 'spec_helper'

RSpec.describe SnapshotsController, type: :controller do
  before :all do
    Snapshot.delete_all
    User.delete_all
    Institution.delete_all
  end

  after :all do
    Snapshot.delete_all
    User.delete_all
    Institution.delete_all
  end

  let!(:institution_one) { FactoryBot.create(:member_institution) }
  let!(:institution_two) { FactoryBot.create(:member_institution) }
  let!(:admin_user) { FactoryBot.create(:user, :admin, institution: institution_one) }
  let!(:institutional_admin) { FactoryBot.create(:user, :institutional_admin, institution: institution_two) }
  let!(:snapshot_one) { FactoryBot.create(:snapshot, institution_id: institution_one.id, audit_date: '2018-02-1 00:00:00 -0000', apt_bytes: 4000000) }
  let!(:snapshot_two) { FactoryBot.create(:snapshot, institution_id: institution_one.id, audit_date: '2018-01-1 00:00:00 -0000', apt_bytes: 3000000) }
  let!(:snapshot_three) { FactoryBot.create(:snapshot, institution_id: institution_one.id, audit_date: '2017-12-1 00:00:00 -0000', apt_bytes: 2000000) }
  let!(:snapshot_four) { FactoryBot.create(:snapshot, institution_id: institution_two.id, audit_date: '2018-02-1 00:00:00 -0000', apt_bytes: 4000000) }
  let!(:snapshot_five) { FactoryBot.create(:snapshot, institution_id: institution_two.id, audit_date: '2018-01-1 00:00:00 -0000', apt_bytes: 3000000) }
  let!(:snapshot_six) { FactoryBot.create(:snapshot, institution_id: institution_two.id, audit_date: '2017-12-1 00:00:00 -0000', apt_bytes: 2000000) }

  describe '#GET index' do
    describe 'for admin users' do
      before do
        sign_in admin_user
        session[:verified] = true
      end

      it 'returns successfully with all snapshots' do
        get :index, format: :json
        expect(response).to be_successful
        expect(assigns(:snapshots).size).to eq 6
      end
    end

    describe 'for institutional admin users' do
      before do
        sign_in institutional_admin
        session[:verified] = true
      end

      it 'returns only the snapshots that belong to own institution' do
        get :index, format: :json
        expect(response).to be_successful
        expect(assigns(:snapshots).size).to eq 3
        expect(assigns(:snapshots).map &:id).to match_array [snapshot_four.id, snapshot_five.id, snapshot_six.id]
      end
    end
  end

  describe '#GET show' do
    describe 'for admin users' do
      before do
        sign_in admin_user
        session[:verified] = true
      end

      it 'returns successfully a snapshot from own institution' do
        get :show, params: {id: snapshot_one.id }, format: :json
        expect(response).to be_successful
        expect(assigns(:snapshot).id).to eq snapshot_one.id
      end

      it 'returns successfully a snapshot from other institution' do
        get :show, params: {id: snapshot_four.id }, format: :json
        expect(response).to be_successful
        expect(assigns(:snapshot).id).to eq snapshot_four.id
      end
    end

    describe 'for institutional admin users' do
      before do
        sign_in institutional_admin
        session[:verified] = true
      end

      it 'returns successfully a snapshot from own institution' do
        get :show, params: {id: snapshot_four.id }, format: :json
        expect(response).to be_successful
        expect(assigns(:snapshot).id).to eq snapshot_four.id
      end

      it 'shows unauthorized when requesting a snapshot from other institution' do
        get :show, params: {id: snapshot_one.id }, format: :json
        expect(response.status).to eq(403)
      end
    end
  end

end
