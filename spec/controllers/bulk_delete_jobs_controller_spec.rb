require 'spec_helper'

RSpec.describe BulkDeleteJobsController, type: :controller do
  before :all do
    BulkDeleteJob.delete_all
    User.delete_all
    Institution.delete_all
  end

  after :all do
    BulkDeleteJob.delete_all
    User.delete_all
    Institution.delete_all
  end

  let!(:institution_one) { FactoryBot.create(:aptrust) }
  let!(:institution_two) { FactoryBot.create(:member_institution) }
  let!(:admin_user) { FactoryBot.create(:user, :admin, institution: institution_one) }
  let!(:institutional_admin) { FactoryBot.create(:user, :institutional_admin, institution: institution_two) }
  let!(:other_admin) { FactoryBot.create(:user, :admin, institution: institution_one) }
  let!(:bulk_job_one) { FactoryBot.create(:bulk_delete_job, requested_by: admin_user.email, institutional_approver: institutional_admin.email, aptrust_approver: other_admin.email, institution_id: institution_two.id) }
  let!(:bulk_job_two) { FactoryBot.create(:bulk_delete_job, requested_by: admin_user.email, institutional_approver: institutional_admin.email, aptrust_approver: other_admin.email, institution_id: institution_two.id) }
  let!(:bulk_job_three) { FactoryBot.create(:bulk_delete_job, requested_by: admin_user.email, institutional_approver: other_admin.email, aptrust_approver: admin_user.email, institution_id: institution_one.id) }

  describe '#GET index' do
    describe 'for admin users' do
      before do
        sign_in admin_user
      end

      it 'returns successfully with all snapshots' do
        get :index, format: :json
        expect(response).to be_successful
        expect(assigns(:bulk_delete_jobs).size).to eq 3
      end
    end

    describe 'for institutional admin users' do
      before do
        sign_in institutional_admin
      end

      it 'returns only the snapshots that belong to own institution' do
        get :index, format: :json
        expect(response).to be_successful
        expect(assigns(:bulk_delete_jobs).size).to eq 2
        expect(assigns(:bulk_delete_jobs).map &:id).to match_array [bulk_job_one.id, bulk_job_two.id]
      end
    end
  end

  describe '#GET show' do
    describe 'for admin users' do
      before do
        sign_in admin_user
      end

      it 'returns successfully a snapshot from own institution' do
        get :show, params: {id: bulk_job_three.id }, format: :json
        expect(response).to be_successful
        expect(assigns(:bulk_job).id).to eq bulk_job_three.id
      end

      it 'returns successfully a snapshot from other institution' do
        get :show, params: {id: bulk_job_one.id }, format: :json
        expect(response).to be_successful
        expect(assigns(:bulk_job).id).to eq bulk_job_one.id
      end
    end

    describe 'for institutional admin users' do
      before do
        sign_in institutional_admin
      end

      it 'returns successfully a snapshot from own institution' do
        get :show, params: {id: bulk_job_one.id }, format: :json
        expect(response).to be_successful
        expect(assigns(:bulk_job).id).to eq bulk_job_one.id
      end

      it 'shows unauthorized when requesting a snapshot from other institution' do
        get :show, params: {id: bulk_job_three.id }
        expect(response).to redirect_to root_path
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
    end
  end

end
