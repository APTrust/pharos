class BulkDeleteJobsController < ApplicationController
  include FilterCounts
  before_action :authenticate_user!
  before_action :load_institution, only: :index
  before_action :load_job, only: :show
  after_action :verify_authorized

  def index
    authorize @institution, :bulk_delete_job_index?
    (current_user.admin? && @institution.identifier == Pharos::Application::APTRUST_ID) ? @bulk_delete_jobs = BulkDeleteJob.all : @bulk_delete_jobs = BulkDeleteJob.discoverable(current_user).with_institution(@institution.id)
    filter_sort_and_count
    page_results(@bulk_delete_jobs)
    respond_to do |format|
      format.json { render json: { count: @count, next: @next, previous: @previous, results: @paged_results.map{ |job| job.serializable_hash } } }
      format.html { }
    end
  end

  def show
    if @bulk_job.nil?
      authorize current_user, :nil_bulk_job_show?
      respond_to do |format|
        format.json { render body: nil, status: :not_found and return }
        format.html { redirect_to root_url, alert: 'That Bulk Delete Job could not be found.' }
      end
    else
      authorize @bulk_job
      @institution = Institution.find(@bulk_job.institution_id)
      respond_to do |format|
        format.json { render json: @bulk_job.serializable_hash }
        format.html { }
      end
    end
  end

  private

  def load_institution
    if current_user.admin? and params[:institution_id]
      @institution = Institution.find(params[:institution_id])
    elsif current_user.admin? and params[:institution_identifier]
      @institution = Institution.where(identifier: params[:institution_identifier]).first
    else
      @institution = current_user.institution
    end
  end

  def load_job
    if params[:id]
      begin
        @bulk_job = BulkDeleteJob.find(params[:id])
      rescue
        # Don't throw RecordNotFound. Just return 404 above.
      end
    end
  end

  def filter_sort_and_count
    @bulk_delete_jobs = @bulk_delete_jobs
                                .with_institution(params[:institution])
    @selected = {}
    get_institution_counts(@bulk_delete_jobs)
    count = @bulk_delete_jobs.count
    set_page_counts(count)
    case params[:sort]
      when 'date'
        @bulk_delete_jobs = @bulk_delete_jobs.order('updated_at DESC')
      when 'name'
        @bulk_delete_jobs = @bulk_delete_jobs.order('id').reverse_order
      when 'institution'
        @bulk_delete_jobs = @bulk_delete_jobs.joins(:institution).order('institutions.name')
    end
  end

end
